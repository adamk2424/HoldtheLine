class_name EnemyAIMelee
extends Node
## EnemyAIMelee - AI for melee/swarm/bruiser enemies.
## Handles: thrasher, brute, polus (leap), blight_mite (self_destruct), gorger (frenzy).
## Move to nearest player entity. When in range: stop and attack. If target dies: find new.

var enemy: EnemyBase = null
var current_target: Node = null
var _retarget_timer: float = 0.0
const RETARGET_INTERVAL: float = 1.0

# Leap ability state (Polus)
var _has_leap: bool = false
var _leap_range: float = 4.0
var _leap_cooldown: float = 3.0
var _leap_timer: float = 0.0

# Self-destruct ability state (Blight Mite)
var _has_self_destruct: bool = false
var _self_destruct_damage: float = 80.0
var _self_destruct_radius: float = 2.0

# Frenzy ability state (Gorger)
var _has_frenzy: bool = false
var _frenzy_hp_threshold: float = 0.3
var _frenzy_attack_speed_bonus: float = 0.5
var _frenzy_move_speed_bonus: float = 0.25
var _frenzy_active: bool = false

# Ignores barriers state
var _ignores_barriers: bool = false


func _ready() -> void:
	enemy = get_parent() as EnemyBase
	if not enemy:
		push_warning("[EnemyAIMelee] Parent is not EnemyBase")
		return

	# Override CombatComponent targeting -- we handle it manually
	if enemy.combat_component:
		enemy.combat_component.is_active = false

	# Parse specials
	var specials: Array = enemy.enemy_data.get("specials", [])
	for special: Dictionary in specials:
		var stype: String = special.get("type", "")
		match stype:
			"leap":
				_has_leap = true
				_leap_range = float(special.get("range", 4.0))
				_leap_cooldown = float(special.get("cooldown", 3.0))
			"self_destruct":
				_has_self_destruct = true
				_self_destruct_damage = float(special.get("damage", 80.0))
				_self_destruct_radius = float(special.get("radius", 2.0))
			"frenzy":
				_has_frenzy = true
				_frenzy_hp_threshold = float(special.get("hp_threshold", 0.3))
				_frenzy_attack_speed_bonus = float(special.get("attack_speed_bonus", 0.5))
				_frenzy_move_speed_bonus = float(special.get("move_speed_bonus", 0.25))

	_ignores_barriers = enemy.enemy_data.get("ignores_barriers", false)

	# Self-destruct enemies trigger on death
	if _has_self_destruct and enemy.health_component:
		enemy.health_component.died.connect(_on_died_self_destruct)


func _process(delta: float) -> void:
	if not enemy or not enemy.is_initialized:
		return
	if enemy.health_component and enemy.health_component.is_dead:
		return
	if not GameState.is_game_active:
		return

	# Update leap cooldown
	if _has_leap:
		_leap_timer += delta

	# Stagger expensive AI work across frames when enemy counts are high.
	if not enemy.should_process_ai():
		return

	# Check frenzy activation
	if _has_frenzy and not _frenzy_active:
		_check_frenzy()

	_retarget_timer += delta
	if _retarget_timer >= RETARGET_INTERVAL:
		_retarget_timer = 0.0
		_update_target()

	_update_behavior(delta)


func _update_target() -> void:
	# Check if current target is still valid
	if current_target and (not is_instance_valid(current_target) or not current_target.is_inside_tree()):
		current_target = null

	if current_target and current_target is EntityBase:
		if current_target.health_component and current_target.health_component.is_dead:
			current_target = null

	if not current_target:
		# Blight Mite: prioritize barriers/buildings
		var target_priority: String = enemy.enemy_data.get("target_priority", "nearest")
		if target_priority == "walls":
			current_target = enemy.find_nearest_structure()
		elif target_priority == "units":
			# Gorger: prioritize player units
			var units: Array = EntityRegistry.get_all("unit")
			var best: Node = null
			var best_dist: float = INF
			for u: Node in units:
				if not is_instance_valid(u) or not u.is_inside_tree():
					continue
				if u is EntityBase and u.health_component and u.health_component.is_dead:
					continue
				var d: float = enemy.global_position.distance_squared_to(u.global_position)
				if d < best_dist:
					best_dist = d
					best = u
			current_target = best if best else enemy.find_nearest_player_entity()
		else:
			current_target = enemy.find_nearest_player_entity()

	# If path to target is blocked by barriers, attack the barrier in front of us
	if current_target and not _ignores_barriers and enemy.movement_component and enemy.movement_component.is_path_blocked:
		var nearby_barrier := EntityRegistry.get_nearest(enemy.global_position, "barrier")
		if nearby_barrier and is_instance_valid(nearby_barrier) and nearby_barrier.is_inside_tree():
			var barrier_dist: float = enemy.global_position.distance_to(nearby_barrier.global_position)
			var melee_reach: float = enemy.combat_component.get_effective_range() + 1.5
			if barrier_dist <= melee_reach:
				# Barrier is right here — attack it instead of trying to path around
				current_target = nearby_barrier
				return
		# No barrier within reach; try to find a reachable player target
		var target_priority: String = enemy.enemy_data.get("target_priority", "nearest")
		if target_priority != "walls":
			var reachable := enemy.find_nearest_reachable_player_entity()
			if reachable:
				current_target = reachable
				return
		# Fallback: target any nearby barrier
		if nearby_barrier and is_instance_valid(nearby_barrier) and nearby_barrier.is_inside_tree():
			current_target = nearby_barrier


func _update_behavior(delta: float) -> void:
	if not enemy.combat_component or not enemy.movement_component:
		return

	if current_target and is_instance_valid(current_target) and current_target.is_inside_tree():
		var dist: float = enemy.global_position.distance_to(current_target.global_position)
		var attack_range: float = enemy.combat_component.get_effective_range()

		# Barriers have collision boxes that keep enemies away from their center,
		# so extend effective melee range when targeting them.
		var effective_range: float = attack_range
		if current_target is EntityBase and current_target.entity_type == "barrier":
			effective_range += 1.0

		# Blight Mite: self-destruct on contact
		if _has_self_destruct and dist <= effective_range + 0.5:
			_trigger_self_destruct()
			return

		if dist <= effective_range:
			if enemy.movement_component.is_moving:
				enemy.movement_component.stop()
			_perform_attack()
		else:
			# Leap check: if blocked by barrier and leap is ready
			if _has_leap and _leap_timer >= _leap_cooldown and dist < _leap_range + 2.0:
				_perform_leap()
			else:
				enemy.movement_component.move_to(current_target.global_position)
	else:
		if not enemy.movement_component.is_moving:
			enemy.movement_component.move_to(EnemyBase.BASE_CENTER)


func _perform_attack() -> void:
	if not current_target or not is_instance_valid(current_target):
		return

	var combat := enemy.combat_component
	combat._attack_timer += get_process_delta_time()
	if combat._attack_timer >= combat.attack_rate:
		combat._attack_timer = 0.0
		combat.current_target = current_target
		combat._perform_attack()


func _check_frenzy() -> void:
	if not enemy.health_component:
		return
	var hp_ratio: float = enemy.health_component.current_hp / enemy.health_component.max_hp
	if hp_ratio <= _frenzy_hp_threshold:
		_frenzy_active = true
		# Apply frenzy buffs
		if enemy.combat_component:
			enemy.combat_component.attack_rate *= (1.0 - _frenzy_attack_speed_bonus)
		if enemy.movement_component:
			enemy.movement_component.speed *= (1.0 + _frenzy_move_speed_bonus)
		GameBus.audio_play_3d.emit("enemy.gorger.frenzy", enemy.global_position)


func _perform_leap() -> void:
	_leap_timer = 0.0
	if not current_target or not is_instance_valid(current_target):
		return

	# Teleport toward target (simplified leap)
	var direction: Vector3 = (current_target.global_position - enemy.global_position).normalized()
	var leap_dist: float = min(_leap_range, enemy.global_position.distance_to(current_target.global_position))
	enemy.global_position += direction * leap_dist
	enemy.global_position.y = 0.0

	GameBus.audio_play_3d.emit("enemy.polus.leap", enemy.global_position)


func _trigger_self_destruct() -> void:
	# Deal AoE damage at current position
	var pos: Vector3 = enemy.global_position
	for etype: String in ["tower", "building", "unit", "barrier", "central_tower"]:
		var targets: Array = EntityRegistry.get_in_range(pos, etype, _self_destruct_radius)
		for target: Node in targets:
			if not is_instance_valid(target) or not target.is_inside_tree():
				continue
			if target is EntityBase and target.health_component:
				target.health_component.take_damage(_self_destruct_damage, enemy)

	GameBus.aoe_triggered.emit(pos, _self_destruct_radius, _self_destruct_damage, enemy)
	GameBus.audio_play_3d.emit("enemy.blight_mite.explode", pos)

	# Kill self
	if enemy.health_component:
		enemy.health_component.take_damage(enemy.health_component.max_hp * 10.0, enemy)


func _on_died_self_destruct(_killer: Node) -> void:
	# Also trigger explosion on death (if killed before reaching target)
	if not _has_self_destruct:
		return
	_trigger_self_destruct()
