class_name SpawnSystem
extends Node
## SpawnSystem - Handles continuous enemy spawning with per-unit rate control.
## Each enemy type has its own spawns_per_60s rate and ramp_in scalar.
## spawns_per_60s = total individual units spawned per 60s at full rate.
## ramp_in = starting fraction of spawn rate (0.01-1.0), ramps to 1.0 over 5 minutes.
## spawn_group = number of units spawned together at one location per spawn event.
## Surges multiply all spawn rates by surge_spawn_multiplier during surge duration.

var spawn_manager: SpawnManager = null
var difficulty_system: Node = null  # Reference set by GameSession

# Scaling data from difficulty_scaling.json
var _difficulty_data: Dictionary = {}
var _ramp_in_duration: float = 300.0  # 5 minutes
var _global_spawn_scale_per_minute: float = 0.1  # +10% per minute after start time
var _global_spawn_scale_start: float = 180.0  # 3 minutes before scaling kicks in

# Enemy unlock schedule from difficulty_scaling.json
var _unlock_schedule: Array = []

# Per-enemy spawn state
var _spawn_accumulators: Dictionary = {}  # enemy_id -> float
var _enemy_unlock_times: Dictionary = {}  # enemy_id -> game_time when unlocked
var _unlocked_enemies: Array[String] = []  # ordered list of unlocked enemy IDs

# Runtime state
var _current_enemy_count: int = 0
var _is_spawning: bool = false
var _surge_multiplier: float = 1.0
var _surge_direction: int = -1  # -1 = all edges, 0-3 = specific edge


func _ready() -> void:
	_load_difficulty_data()
	GameBus.game_started.connect(_on_game_started)
	GameBus.entity_died.connect(_on_entity_died)
	GameBus.surge_started.connect(_on_surge_started)
	GameBus.surge_ended.connect(_on_surge_ended)


func _load_difficulty_data() -> void:
	_difficulty_data = GameData.get_difficulty_scaling()
	_ramp_in_duration = float(_difficulty_data.get("ramp_in_duration_seconds", 300.0))
	_global_spawn_scale_per_minute = float(_difficulty_data.get("global_spawn_scale_per_minute", 0.1))
	_global_spawn_scale_start = float(_difficulty_data.get("global_spawn_scale_start_seconds", 180.0))
	_unlock_schedule = _difficulty_data.get("enemy_unlock_schedule", [])


func _process(delta: float) -> void:
	if not _is_spawning or not GameState.is_game_active:
		return

	var current_time: float = GameState.game_time

	# Check for newly unlocked enemies
	_check_unlocks(current_time)

	# Global spawn scaling: +10% per minute after start time
	var global_scale: float = 1.0
	if current_time > _global_spawn_scale_start:
		var minutes_past_start: float = (current_time - _global_spawn_scale_start) / 60.0
		global_scale = 1.0 + (_global_spawn_scale_per_minute * minutes_past_start)

	# Accumulate and spawn for each unlocked enemy type
	for enemy_id: String in _unlocked_enemies:
		var edata: Dictionary = GameData.get_enemy(enemy_id)
		if edata.is_empty():
			continue

		# Skip boss-role enemies (handled by DifficultySystem)
		if edata.get("role", "") == "boss":
			continue

		var spawns_per_60s: float = float(edata.get("spawns_per_60s", 10))
		var spawn_group: int = maxi(1, int(edata.get("spawn_group", 1)))
		var ramp_in: float = float(edata.get("ramp_in", 1.0))

		# Calculate ramp-in multiplier: lerp from ramp_in to 1.0 over ramp_in_duration
		var unlock_time: float = _enemy_unlock_times.get(enemy_id, 0.0)
		var time_since_unlock: float = current_time - unlock_time
		var ramp_mult: float = lerpf(ramp_in, 1.0, clampf(time_since_unlock / _ramp_in_duration, 0.0, 1.0))

		# Spawn event rate: spawns_per_60s is total units, divide by spawn_group for events
		var events_per_second: float = (spawns_per_60s * ramp_mult * global_scale) / float(spawn_group) / 60.0

		# Apply surge multiplier
		if _surge_multiplier > 1.0:
			events_per_second *= _surge_multiplier

		# Accumulate
		_spawn_accumulators[enemy_id] += events_per_second * delta

		# Spawn when accumulator >= 1.0
		while _spawn_accumulators[enemy_id] >= 1.0:
			_spawn_accumulators[enemy_id] -= 1.0
			_spawn_enemy_group(enemy_id, edata, spawn_group)


func _check_unlocks(current_time: float) -> void:
	for entry: Dictionary in _unlock_schedule:
		var unlock_time: float = float(entry.get("time", entry.get("unlock_time", 0)))
		var enemy_id: String = entry.get("enemy_id", "")
		if enemy_id.is_empty():
			continue
		if unlock_time <= current_time and not _unlocked_enemies.has(enemy_id):
			var edata: Dictionary = GameData.get_enemy(enemy_id)
			if edata.is_empty():
				continue
			# Skip boss-role enemies from regular spawning
			if edata.get("role", "") == "boss":
				continue
			_unlocked_enemies.append(enemy_id)
			_spawn_accumulators[enemy_id] = 0.0
			_enemy_unlock_times[enemy_id] = current_time
			print("[SpawnSystem] Unlocked enemy: %s at %.0fs" % [enemy_id, current_time])


func _spawn_enemy_group(enemy_id: String, _edata: Dictionary, group_size: int) -> void:
	var spawn_pos: Vector3 = _get_spawn_position()
	for i: int in range(group_size):
		# Small offset so grouped enemies don't stack exactly on top of each other
		var offset := Vector3.ZERO
		if i > 0:
			offset = Vector3(randf_range(-1.5, 1.5), 0, randf_range(-1.5, 1.5))
		var enemy := create_enemy(enemy_id, spawn_pos + offset)
		if enemy:
			_current_enemy_count += 1


func _get_spawn_position() -> Vector3:
	if spawn_manager:
		# During surges, concentrate spawns on the surge direction edge
		if _surge_direction >= 0:
			var edge_points: Array[Vector3] = spawn_manager.get_spawn_points_on_edge(_surge_direction)
			if not edge_points.is_empty():
				return edge_points[randi() % edge_points.size()]
		return spawn_manager.get_random_spawn_point()
	# Fallback: random edge position
	var edge: int = randi() % 4
	match edge:
		0: return Vector3(randf_range(10, 290), 0, 5)
		1: return Vector3(randf_range(10, 290), 0, 295)
		2: return Vector3(295, 0, randf_range(10, 290))
		3: return Vector3(5, 0, randf_range(10, 290))
	return Vector3(5, 0, 5)


## Called by DifficultySystem to focus surge spawns on one edge.
func set_surge_direction(edge: int) -> void:
	_surge_direction = edge


## Called by DifficultySystem when surge ends to restore all-edge spawning.
func clear_surge_direction() -> void:
	_surge_direction = -1


## Enemy Factory: instantiate the correct enemy with appropriate AI child.
func create_enemy(enemy_id: String, spawn_pos: Vector3) -> EnemyBase:
	var edata: Dictionary = GameData.get_enemy(enemy_id)
	if edata.is_empty():
		push_warning("[SpawnSystem] No enemy data found for: %s" % enemy_id)
		return null

	# Create the enemy entity
	var enemy := EnemyBase.new()
	enemy.name = "%s_%d" % [enemy_id, randi()]
	enemy.position = spawn_pos

	# Add to scene tree first so components can initialize properly
	if is_inside_tree():
		get_tree().current_scene.add_child(enemy)
	else:
		push_warning("[SpawnSystem] Not in tree, cannot spawn enemy")
		enemy.queue_free()
		return null

	# Calculate difficulty multipliers with size-based armor
	var difficulty_mult: Dictionary = _get_difficulty_multipliers()
	var size_cat: String = edata.get("size", "small")
	difficulty_mult["armor_bonus"] = get_armor_bonus_for_size(size_cat)

	# Initialize enemy (adds components, sets up health bar, starts moving)
	enemy.initialize_enemy(enemy_id, edata, difficulty_mult)

	# Add AI AFTER initialization so _ready() can access components and enemy_data
	var ai_node: Node = _create_ai_node(enemy_id, edata)
	if ai_node:
		enemy.add_child(ai_node)
		enemy.ai_node = ai_node

	# Enemies far from the base use cheap direct movement with AI/combat disabled.
	# Full processing activates when they reach the combat zone near structures.
	var pos := enemy.global_position
	if pos.x < 70.0 or pos.x > 230.0 or pos.z < 70.0 or pos.z > 230.0:
		enemy.start_march_mode()

	# Emit spawned signal
	GameBus.enemy_spawned.emit(enemy, enemy_id, spawn_pos)

	return enemy


## Spawn a boss enemy (called by DifficultySystem).
func spawn_boss(enemy_id: String) -> EnemyBase:
	var spawn_pos: Vector3 = _get_spawn_position()
	var edata: Dictionary = GameData.get_enemy(enemy_id)
	if edata.is_empty():
		return null

	var enemy := EnemyBase.new()
	enemy.name = "Boss_%s_%d" % [enemy_id, randi()]
	enemy.position = spawn_pos

	if is_inside_tree():
		get_tree().current_scene.add_child(enemy)
	else:
		enemy.queue_free()
		return null

	var difficulty_mult: Dictionary = _get_difficulty_multipliers()
	var size_cat: String = edata.get("size", "huge")
	difficulty_mult["armor_bonus"] = get_armor_bonus_for_size(size_cat)
	enemy.initialize_enemy(enemy_id, edata, difficulty_mult)

	# Add AI AFTER initialization so _ready() can access components and enemy_data
	var ai_node := EnemyAIBoss.new()
	ai_node.name = "EnemyAIBoss"
	enemy.add_child(ai_node)
	enemy.ai_node = ai_node

	# Bosses far from the base also use march mode.
	var pos := enemy.global_position
	if pos.x < 70.0 or pos.x > 230.0 or pos.z < 70.0 or pos.z > 230.0:
		enemy.start_march_mode()

	GameBus.enemy_spawned.emit(enemy, enemy_id, spawn_pos)

	return enemy


func _create_ai_node(_enemy_id: String, edata: Dictionary) -> Node:
	var role: String = edata.get("role", "melee")

	match role:
		"boss":
			var ai := EnemyAIBoss.new()
			ai.name = "EnemyAIBoss"
			return ai
		"flying":
			var ai := EnemyAIFlying.new()
			ai.name = "EnemyAIFlying"
			return ai
		"support", "special":
			var ai := EnemyAISpecial.new()
			ai.name = "EnemyAISpecial"
			return ai
		"ranged", "ranged_elite":
			var ai := EnemyAIRanged.new()
			ai.name = "EnemyAIRanged"
			return ai
		_:
			# swarm, bruiser, melee, tank, and any other ground melee enemies
			var ai := EnemyAIMelee.new()
			ai.name = "EnemyAIMelee"
			return ai


func _get_difficulty_multipliers() -> Dictionary:
	var minutes_elapsed: float = GameState.game_time / 60.0
	var hp_scale: float = float(_difficulty_data.get("enemy_hp_scale_per_minute", 0.01))
	var damage_scale: float = float(_difficulty_data.get("enemy_damage_scale_per_minute", 0.01))

	# Calculate effective scaled minutes accounting for late-game acceleration:
	# Before 15 min: normal linear scaling
	# 15-20 min: 2x rate, 20-25 min: 4x rate, 25+ min: 8x rate
	var effective_hp_minutes: float = _get_accelerated_minutes(minutes_elapsed, hp_scale)
	var effective_damage_minutes: float = _get_accelerated_minutes(minutes_elapsed, damage_scale)

	# Movement speed bonus: +5% per minute past 15 minutes
	var speed_bonus: float = _get_late_game_speed_bonus(minutes_elapsed)

	# Attack range and damage bonus: +5% per minute past 10 minutes
	var combat_bonus: float = _get_combat_scaling_bonus(minutes_elapsed)

	return {
		"hp_mult": 1.0 + effective_hp_minutes,
		"damage_mult": (1.0 + effective_damage_minutes) * (1.0 + combat_bonus),
		"speed_bonus": speed_bonus,
		"attack_range_mult": 1.0 + combat_bonus,
	}


## Calculates the effective scaling value accounting for acceleration phases.
## Each phase contributes its own duration * rate * phase_multiplier, so
## transitions between phases are smooth (no sudden jumps).
func _get_accelerated_minutes(minutes_elapsed: float, base_rate: float) -> float:
	# Phase boundaries
	const PHASE_1_START: float = 15.0  # 2x begins
	const PHASE_2_START: float = 20.0  # 4x begins
	const PHASE_3_START: float = 25.0  # 8x begins

	if minutes_elapsed <= PHASE_1_START:
		# All time at 1x rate
		return base_rate * minutes_elapsed

	# Minutes in each phase
	var normal_minutes: float = PHASE_1_START  # 0-15 at 1x
	var phase1_minutes: float = minf(minutes_elapsed, PHASE_2_START) - PHASE_1_START  # 15-20 at 2x
	var phase2_minutes: float = 0.0
	var phase3_minutes: float = 0.0

	if minutes_elapsed > PHASE_2_START:
		phase2_minutes = minf(minutes_elapsed, PHASE_3_START) - PHASE_2_START  # 20-25 at 4x

	if minutes_elapsed > PHASE_3_START:
		phase3_minutes = minutes_elapsed - PHASE_3_START  # 25+ at 8x

	var total: float = (
		base_rate * normal_minutes * 1.0
		+ base_rate * phase1_minutes * 2.0
		+ base_rate * phase2_minutes * 4.0
		+ base_rate * phase3_minutes * 8.0
	)
	return total


## Returns additive movement speed bonus for late game.
## +5% per minute past 15 minutes (0.05 per minute).
func _get_late_game_speed_bonus(minutes_elapsed: float) -> float:
	if minutes_elapsed < 15.0:
		return 0.0
	var minutes_past_threshold: float = minutes_elapsed - 15.0
	return 0.05 * minutes_past_threshold


## Returns +5% per minute past 10 minutes for enemy damage and attack range.
func _get_combat_scaling_bonus(minutes_elapsed: float) -> float:
	if minutes_elapsed < 10.0:
		return 0.0
	return 0.05 * (minutes_elapsed - 10.0)


## Calculate flat armor bonus based on enemy size and time elapsed.
## Design: small +1 per 10min, large +1 per 5min, huge +2 per 5min.
## After 15 minutes, armor gains are accelerated (2x/4x/8x rate).
func get_armor_bonus_for_size(size_category: String) -> float:
	var minutes_elapsed: float = GameState.game_time / 60.0
	var armor_data: Dictionary = _difficulty_data.get("armor_scaling", {})
	var size_data: Dictionary = armor_data.get(size_category, {})
	if size_data.is_empty():
		return 0.0
	var amount: float = float(size_data.get("amount", 0))
	var interval: float = float(size_data.get("interval_minutes", 999))
	if interval <= 0.0:
		return 0.0

	# Use accelerated effective minutes for armor scaling after 15 min
	var effective_minutes: float = _get_effective_armor_minutes(minutes_elapsed)
	return amount * floor(effective_minutes / interval)


## Converts real minutes into effective minutes for armor scaling,
## applying late-game acceleration (2x/4x/8x after 15/20/25 min).
func _get_effective_armor_minutes(minutes_elapsed: float) -> float:
	const PHASE_1_START: float = 15.0
	const PHASE_2_START: float = 20.0
	const PHASE_3_START: float = 25.0

	if minutes_elapsed <= PHASE_1_START:
		return minutes_elapsed

	var effective: float = PHASE_1_START  # 0-15 at 1x

	var phase1_minutes: float = minf(minutes_elapsed, PHASE_2_START) - PHASE_1_START
	effective += phase1_minutes * 2.0

	if minutes_elapsed > PHASE_2_START:
		var phase2_minutes: float = minf(minutes_elapsed, PHASE_3_START) - PHASE_2_START
		effective += phase2_minutes * 4.0

	if minutes_elapsed > PHASE_3_START:
		var phase3_minutes: float = minutes_elapsed - PHASE_3_START
		effective += phase3_minutes * 8.0

	return effective


func _on_game_started() -> void:
	_is_spawning = true
	_current_enemy_count = 0
	_spawn_accumulators.clear()
	_enemy_unlock_times.clear()
	_unlocked_enemies.clear()
	print("[SpawnSystem] Spawning started (per-unit rate system)")


func _on_entity_died(entity: Node, entity_type: String, _entity_id: String, _killer: Node) -> void:
	if entity_type == "enemy":
		_current_enemy_count = max(0, _current_enemy_count - 1)


func _on_surge_started() -> void:
	_surge_multiplier = float(_difficulty_data.get("surge_spawn_multiplier", 3.0))


func _on_surge_ended() -> void:
	_surge_multiplier = 1.0
