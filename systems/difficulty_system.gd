class_name DifficultySystem
extends Node
## DifficultySystem - Manages difficulty scaling over time.
## Scales enemy HP, damage, armor based on difficulty_scaling.json multipliers per minute.
## Triggers surges every surge_interval_seconds with 10% acceleration per minute.
## Triggers boss spawn at 150s, then every 120s with 10% shorter intervals each time.
## Emits GameBus.surge_started, surge_ended, boss_spawned.

var spawn_system: SpawnSystem = null  # Reference set by GameSession

# Difficulty data from JSON
var _difficulty_data: Dictionary = {}
var _surge_interval: float = 30.0
var _surge_duration: float = 5.0
var _surge_variance: float = 10.0
var _surge_acceleration: float = 0.1  # 10% faster per minute
var _boss_interval: float = 150.0  # First boss at ~2.5 min
var _boss_repeat_interval: float = 120.0  # Then every 2 min
var _boss_decrease_percent: float = 0.1  # 10% shorter each time
var _boss_enemy_ids: Array = ["behemoth"]

# Runtime timers
var _surge_timer: float = 0.0
var _boss_timer: float = 0.0
var _surge_end_timer: float = 0.0
var _next_surge_at: float = 0.0  # Computed with variance
var _next_boss_at: float = 0.0  # First boss target time
var _boss_spawn_count: int = 0
var _is_active: bool = false
var _is_surge_active: bool = false


func _ready() -> void:
	_load_data()
	GameBus.game_started.connect(_on_game_started)


func _load_data() -> void:
	_difficulty_data = GameData.get_difficulty_scaling()
	_surge_interval = float(_difficulty_data.get("surge_interval_seconds", 30.0))
	_surge_duration = float(_difficulty_data.get("surge_duration_seconds", 5.0))
	_surge_variance = float(_difficulty_data.get("surge_interval_variance", 10.0))
	_surge_acceleration = float(_difficulty_data.get("surge_acceleration_per_minute", 0.1))
	_boss_interval = 150.0  # First boss at 2.5 min per design doc
	_boss_repeat_interval = 120.0  # Subsequent bosses every 2 min
	_boss_decrease_percent = float(_difficulty_data.get("boss_interval_decrease_percent", 0.1))
	_boss_enemy_ids = _difficulty_data.get("boss_enemy_ids", ["behemoth"])


func _process(delta: float) -> void:
	if not _is_active or not GameState.is_game_active:
		return

	# Update surge timer
	_surge_timer += delta
	if not _is_surge_active and _surge_timer >= _next_surge_at:
		_start_surge()

	# Update surge duration
	if _is_surge_active:
		_surge_end_timer += delta
		if _surge_end_timer >= _surge_duration:
			_end_surge()

	# Update boss timer
	var minutes_elapsed: float = GameState.game_time / 60.0

	# Late-game boss override: clamp interval to late-game value after 20 min
	if minutes_elapsed >= 20.0:
		var late_interval: float = _get_late_game_boss_interval(minutes_elapsed)
		if _next_boss_at > late_interval:
			_next_boss_at = late_interval

	_boss_timer += delta
	if _boss_timer >= _next_boss_at:
		_boss_timer -= _next_boss_at
		_spawn_boss()
		_boss_spawn_count += 1

		if minutes_elapsed >= 20.0:
			_next_boss_at = _get_late_game_boss_interval(minutes_elapsed)
		else:
			# Normal boss interval (10% shorter each time)
			var shrink_factor: float = pow(1.0 - _boss_decrease_percent, _boss_spawn_count)
			_next_boss_at = _boss_repeat_interval * shrink_factor
			_next_boss_at += randf_range(-30.0, 30.0)
			_next_boss_at = max(30.0, _next_boss_at)


func _get_current_surge_interval() -> float:
	## Apply 10% acceleration per minute to surge interval.
	var minutes_elapsed: float = GameState.game_time / 60.0
	var accel_factor: float = pow(1.0 - _surge_acceleration, minutes_elapsed)
	return max(5.0, _surge_interval * accel_factor)


func _compute_next_surge_time() -> void:
	## Set next surge target with variance applied.
	var base_interval: float = _get_current_surge_interval()
	_next_surge_at = base_interval + randf_range(-_surge_variance, _surge_variance)
	_next_surge_at = max(3.0, _next_surge_at)


func _start_surge() -> void:
	_is_surge_active = true
	_surge_timer = 0.0
	_surge_end_timer = 0.0
	GameState.is_surge_active = true
	GameState.surge_count += 1

	# Pick a random direction for the surge
	var surge_direction: int = randi() % 4  # 0=N, 1=S, 2=E, 3=W

	GameBus.surge_started.emit()
	GameBus.audio_play.emit("game.surge_started")

	# Tell spawn system to concentrate spawns on one edge during surge
	if spawn_system:
		spawn_system.set_surge_direction(surge_direction)

	var dir_names: Array = ["North", "South", "East", "West"]
	print("[DifficultySystem] Surge #%d started from %s! Duration: %.0fs" % [
		GameState.surge_count, dir_names[surge_direction], _surge_duration
	])


func _end_surge() -> void:
	_is_surge_active = false
	_surge_end_timer = 0.0
	GameState.is_surge_active = false
	GameBus.surge_ended.emit()
	GameBus.audio_play.emit("game.surge_ended")

	# Reset spawn system to all-direction spawning
	if spawn_system:
		spawn_system.clear_surge_direction()

	# Compute when the next surge should happen
	_compute_next_surge_time()

	print("[DifficultySystem] Surge #%d ended" % GameState.surge_count)


func _spawn_boss() -> void:
	if not spawn_system:
		push_warning("[DifficultySystem] No SpawnSystem reference, cannot spawn boss")
		return

	var boss_id: String = _boss_enemy_ids[randi() % _boss_enemy_ids.size()]
	var boss := spawn_system.spawn_boss(boss_id)
	if boss:
		print("[DifficultySystem] Boss #%d (%s) spawned at %.0fs!" % [
			_boss_spawn_count + 1, boss_id, GameState.game_time
		])


## Get current difficulty multipliers for display or other systems.
## Accounts for late-game accelerated scaling after 15 minutes.
func get_current_multipliers() -> Dictionary:
	var minutes_elapsed: float = GameState.game_time / 60.0
	var hp_scale: float = float(_difficulty_data.get("enemy_hp_scale_per_minute", 0.01))
	var damage_scale: float = float(_difficulty_data.get("enemy_damage_scale_per_minute", 0.01))

	# Apply accelerated scaling phases (2x/4x/8x after 15/20/25 min)
	var effective_hp: float = _get_accelerated_scaling(minutes_elapsed, hp_scale)
	var effective_damage: float = _get_accelerated_scaling(minutes_elapsed, damage_scale)
	var speed_bonus: float = _get_late_game_speed_bonus(minutes_elapsed)

	# Early ramp: +10% per minute past 2 minutes for HP and speed
	var early_ramp_bonus: float = 0.0
	if minutes_elapsed >= 2.0:
		early_ramp_bonus = 0.10 * (minutes_elapsed - 2.0)
	var accel_phase: String = _get_acceleration_phase_name(minutes_elapsed)

	# Combat scaling: +5% per minute past 10 minutes to damage and attack range
	var combat_bonus: float = 0.0
	if minutes_elapsed >= 10.0:
		combat_bonus = 0.05 * (minutes_elapsed - 10.0)

	return {
		"hp_mult": 1.0 + effective_hp + early_ramp_bonus,
		"damage_mult": (1.0 + effective_damage) * (1.0 + combat_bonus),
		"attack_range_mult": 1.0 + combat_bonus,
		"speed_bonus": speed_bonus + early_ramp_bonus,
		"accel_phase": accel_phase,
		"minutes_elapsed": minutes_elapsed,
		"surge_count": GameState.surge_count,
		"is_surge_active": _is_surge_active,
	}


## Calculates effective scaling value with late-game acceleration phases.
## Each phase contributes duration * base_rate * phase_multiplier for smooth transitions.
func _get_accelerated_scaling(minutes_elapsed: float, base_rate: float) -> float:
	const PHASE_1_START: float = 15.0  # 2x begins
	const PHASE_2_START: float = 20.0  # 4x begins
	const PHASE_3_START: float = 25.0  # 8x begins

	if minutes_elapsed <= PHASE_1_START:
		return base_rate * minutes_elapsed

	var total: float = base_rate * PHASE_1_START  # 0-15 at 1x

	var phase1_minutes: float = minf(minutes_elapsed, PHASE_2_START) - PHASE_1_START
	total += base_rate * phase1_minutes * 2.0

	if minutes_elapsed > PHASE_2_START:
		var phase2_minutes: float = minf(minutes_elapsed, PHASE_3_START) - PHASE_2_START
		total += base_rate * phase2_minutes * 4.0

	if minutes_elapsed > PHASE_3_START:
		var phase3_minutes: float = minutes_elapsed - PHASE_3_START
		total += base_rate * phase3_minutes * 8.0

	return total


## Returns additive movement speed bonus for late game.
## +5% per minute past 15 minutes.
func _get_late_game_speed_bonus(minutes_elapsed: float) -> float:
	if minutes_elapsed < 15.0:
		return 0.0
	return 0.05 * (minutes_elapsed - 15.0)


## Returns boss spawn interval for late game (20+ minutes).
## 20-25 min: every 30s. After 25 min: decreases by 5s per minute until continuous.
func _get_late_game_boss_interval(minutes_elapsed: float) -> float:
	if minutes_elapsed < 25.0:
		return 30.0
	return maxf(1.0, 30.0 - 5.0 * (minutes_elapsed - 25.0))


## Returns a human-readable name for the current acceleration phase.
func _get_acceleration_phase_name(minutes_elapsed: float) -> String:
	if minutes_elapsed < 15.0:
		return "normal"
	elif minutes_elapsed < 20.0:
		return "accelerated_2x"
	elif minutes_elapsed < 25.0:
		return "accelerated_4x"
	else:
		return "accelerated_8x"


func _on_game_started() -> void:
	_is_active = true
	_surge_timer = 0.0
	_boss_timer = 0.0
	_surge_end_timer = 0.0
	_is_surge_active = false
	_boss_spawn_count = 0

	# First boss at ~150s (+/- 30s)
	_next_boss_at = _boss_interval + randf_range(-30.0, 30.0)

	# First surge interval
	_compute_next_surge_time()

	print("[DifficultySystem] Difficulty system active")
