class_name EnemyAIFlying
extends Node
## EnemyAIFlying - AI for flying enemies: scrit, gloom_wing.
## Sets is_flying=true on MovementComponent (ignores navmesh).
## Flies at height 5.0 above ground.
## Scrit: erratic random target switching.
## Gloom Wing: bombing_run AoE targeting tower clusters.

const FLIGHT_HEIGHT: float = 5.0

var enemy: EnemyBase = null
var current_target: Node = null
var _retarget_timer: float = 0.0
const RETARGET_INTERVAL: float = 0.8

# Bombing run state (Gloom Wing)
var _has_bombing_run: bool = false
var _bomb_damage: float = 35.0
var _bomb_radius: float = 2.0
var _bomb_splash_percent: float = 0.6

# Random target switching (Scrit)
var _random_targeting: bool = false
var _attacks_on_target: int = 0
var _max_attacks_before_switch: int = 3

# Target priority from data
var _target_priority: String = "nearest"


func _ready() -> void:
	enemy = get_parent() as EnemyBase
	if not enemy:
		push_warning("[EnemyAIFlying] Parent is not EnemyBase")
		return

	# Ensure flying state
	if enemy.movement_component:
		enemy.movement_component.is_flying = true

	if not enemy.is_in_group("flying"):
		enemy.add_to_group("flying")

	# Override CombatComponent auto-targeting
	if enemy.combat_component:
		enemy.combat_component.is_active = false

	# Set initial flying height
	enemy.global_position.y = FLIGHT_HEIGHT

	_target_priority = enemy.enemy_data.get("target_priority", "nearest")

	# Check for random targeting (Scrit)
	if _target_priority == "random":
		_random_targeting = true

	# Parse specials
	var specials: Array = enemy.enemy_data.get("specials", [])
	for special: Dictionary in specials:
		if special.get("type", "") == "bombing_run":
			_has_bombing_run = true
			_bomb_damage = float(special.get("damage", 35.0))
			_bomb_radius = float(special.get("radius", 2.0))
			_bomb_splash_percent = float(special.get("splash_percent", 0.6))


func _process(delta: float) -> void:
	if not enemy or not enemy.is_initialized:
		return
	if enemy.health_component and enemy.health_component.is_dead:
		return
	if not GameState.is_game_active:
		return

	# Enforce flight height
	enemy.global_position.y = FLIGHT_HEIGHT

	# Stagger expensive AI work across frames when enemy counts are high.
	if not enemy.should_process_ai():
		return

	_retarget_timer += delta
	if _retarget_timer >= RETARGET_INTERVAL:
		_retarget_timer = 0.0
		_update_target()

	_update_behavior(delta)


func _update_target() -> void:
	# Validate current target
	if current_target and (not is_instance_valid(current_target) or not current_target.is_inside_tree()):
		current_target = null

	if current_target and current_target is EntityBase:
		if current_target.health_component and current_target.health_component.is_dead:
			current_target = null

	# Scrit: switch targets after a few attacks
	if _random_targeting and current_target and _attacks_on_target >= _max_attacks_before_switch:
		current_target = null
		_attacks_on_target = 0

	if not current_target:
		if _random_targeting:
			current_target = _find_random_target()
		elif _target_priority == "towers":
			# Gloom Wing: prioritize tower clusters
			current_target = EntityRegistry.get_nearest(enemy.global_position, "tower")
			if not current_target:
				current_target = enemy.find_nearest_player_entity()
		else:
			if not enemy.combat_component:
				return
			var attack_range: float = enemy.combat_component.get_effective_range()
			var nearest := enemy.find_nearest_player_entity(attack_range)
			if nearest:
				current_target = nearest
			else:
				current_target = enemy.find_nearest_player_entity()


func _find_random_target() -> Node:
	# Pick a random player entity
	var all_targets: Array = []
	for etype: String in ["tower", "building", "unit", "central_tower"]:
		var entities: Array = EntityRegistry.get_all(etype)
		for ent: Node in entities:
			if is_instance_valid(ent) and ent.is_inside_tree():
				if ent is EntityBase and ent.health_component and not ent.health_component.is_dead:
					all_targets.append(ent)

	if all_targets.is_empty():
		return null
	return all_targets[randi() % all_targets.size()]


func _update_behavior(delta: float) -> void:
	if not enemy.combat_component or not enemy.movement_component:
		return

	var attack_range: float = enemy.combat_component.get_effective_range()

	if current_target and is_instance_valid(current_target) and current_target.is_inside_tree():
		# Use XZ distance for flying units
		var enemy_xz := Vector3(enemy.global_position.x, 0.0, enemy.global_position.z)
		var target_xz := Vector3(current_target.global_position.x, 0.0, current_target.global_position.z)
		var dist: float = enemy_xz.distance_to(target_xz)

		if dist <= attack_range:
			# In range: stop and fire
			if enemy.movement_component.is_moving:
				enemy.movement_component.stop()
			_perform_attack(delta)
		else:
			# Move toward target (at flight height)
			var fly_target := Vector3(
				current_target.global_position.x,
				FLIGHT_HEIGHT,
				current_target.global_position.z
			)
			enemy.movement_component.move_to(fly_target)
	else:
		# No target: fly toward base center
		var fly_dest := Vector3(EnemyBase.BASE_CENTER.x, FLIGHT_HEIGHT, EnemyBase.BASE_CENTER.z)
		if not enemy.movement_component.is_moving:
			enemy.movement_component.move_to(fly_dest)


func _perform_attack(delta: float) -> void:
	if not current_target or not is_instance_valid(current_target):
		return

	var combat := enemy.combat_component
	combat._attack_timer += delta
	if combat._attack_timer >= combat.attack_rate:
		combat._attack_timer = 0.0
		combat.current_target = current_target
		combat._perform_attack()
		_attacks_on_target += 1

		# Gloom Wing: bombing run AoE on attack
		if _has_bombing_run:
			_perform_bombing_run(current_target.global_position)


func _perform_bombing_run(target_pos: Vector3) -> void:
	# Deal AoE damage at target location
	var splash_dmg: float = _bomb_damage * _bomb_splash_percent
	for etype: String in ["tower", "building", "unit", "barrier", "central_tower"]:
		var targets: Array = EntityRegistry.get_in_range(target_pos, etype, _bomb_radius)
		for target: Node in targets:
			if not is_instance_valid(target) or not target.is_inside_tree():
				continue
			if target == current_target:
				continue  # Primary target already took full damage from attack
			if target is EntityBase and target.health_component:
				target.health_component.take_damage(splash_dmg, enemy)

	GameBus.aoe_triggered.emit(target_pos, _bomb_radius, splash_dmg, enemy)
	GameBus.audio_play_3d.emit("enemy.gloom_wing.bomb", target_pos)
