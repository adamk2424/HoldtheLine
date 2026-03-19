class_name EnemyAIRanged
extends Node
## EnemyAIRanged - AI for ranged enemies: slinker, bile_spitter.
## Move toward base until within attack_range of a target, then stop and fire.
## Bile Spitter: applies corrosive_impact (armor reduction + acid pool).

var enemy: EnemyBase = null
var current_target: Node = null
var _retarget_timer: float = 0.0
const RETARGET_INTERVAL: float = 0.8

# Corrosive impact state (Bile Spitter)
var _has_corrosive: bool = false
var _corrosive_armor_reduction: int = 1
var _corrosive_armor_duration: float = 10.0
var _corrosive_max_stacks: int = 3
var _corrosive_pool_damage: float = 5.0
var _corrosive_pool_duration: float = 3.0

# Target priority from data
var _target_priority: String = "nearest"


func _ready() -> void:
	enemy = get_parent() as EnemyBase
	if not enemy:
		push_warning("[EnemyAIRanged] Parent is not EnemyBase")
		return

	# Override CombatComponent auto-targeting
	if enemy.combat_component:
		enemy.combat_component.is_active = false

	_target_priority = enemy.enemy_data.get("target_priority", "nearest")

	# Check for corrosive_impact special (Bile Spitter)
	var specials: Array = enemy.enemy_data.get("specials", [])
	for special: Dictionary in specials:
		if special.get("type", "") == "corrosive_impact":
			_has_corrosive = true
			_corrosive_armor_reduction = int(special.get("armor_reduction", 1))
			_corrosive_armor_duration = float(special.get("armor_duration", 10.0))
			_corrosive_max_stacks = int(special.get("max_stacks", 3))
			_corrosive_pool_damage = float(special.get("pool_damage", 5.0))
			_corrosive_pool_duration = float(special.get("pool_duration", 3.0))


func _process(delta: float) -> void:
	if not enemy or not enemy.is_initialized:
		return
	if enemy.health_component and enemy.health_component.is_dead:
		return
	if not GameState.is_game_active:
		return

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

	if not current_target:
		current_target = _find_best_target()

	# If path to target is blocked, try to find a reachable target through gaps first
	if current_target and enemy.movement_component and enemy.movement_component.is_path_blocked:
		var reachable := enemy.find_nearest_reachable_player_entity()
		if reachable:
			current_target = reachable
			return
		var barrier := EntityRegistry.get_nearest(enemy.global_position, "barrier")
		if barrier and is_instance_valid(barrier) and barrier.is_inside_tree():
			current_target = barrier


func _find_best_target() -> Node:
	if not enemy.combat_component:
		return null

	var attack_range: float = enemy.combat_component.get_effective_range()

	# Target priority: towers (Bile Spitter, Slinker with tower priority)
	if _target_priority == "towers":
		var tower := EntityRegistry.get_nearest(enemy.global_position, "tower", attack_range)
		if tower:
			return tower

	# Default: nearest player entity in range
	var nearest := enemy.find_nearest_player_entity(attack_range)
	if nearest:
		return nearest

	# No target in range: find any player entity to move toward
	return enemy.find_nearest_player_entity()


func _update_behavior(delta: float) -> void:
	if not enemy.combat_component or not enemy.movement_component:
		return

	var attack_range: float = enemy.combat_component.get_effective_range()

	if current_target and is_instance_valid(current_target) and current_target.is_inside_tree():
		var dist: float = enemy.global_position.distance_to(current_target.global_position)

		if dist <= attack_range:
			# In range: stop and fire
			if enemy.movement_component.is_moving:
				enemy.movement_component.stop()
			_perform_attack(delta)
		else:
			# Move toward target until in range
			enemy.movement_component.move_to(current_target.global_position)
	else:
		# No target found: move toward base center
		if not enemy.movement_component.is_moving:
			enemy.movement_component.move_to(EnemyBase.BASE_CENTER)


func _perform_attack(delta: float) -> void:
	if not current_target or not is_instance_valid(current_target):
		return

	var combat := enemy.combat_component
	combat._attack_timer += delta
	if combat._attack_timer >= combat.attack_rate:
		combat._attack_timer = 0.0
		combat.current_target = current_target
		combat._perform_attack()

		# Corrosive impact: apply armor reduction after attack
		if _has_corrosive and current_target is EntityBase:
			_apply_corrosive(current_target)


func _apply_corrosive(target: EntityBase) -> void:
	if not target.buff_debuff_component:
		return

	# Apply stacking armor reduction debuff
	var stack_id: String = "corrosive_%d_%d" % [enemy.get_instance_id(), randi() % 1000]
	target.buff_debuff_component.apply_debuff(
		stack_id,
		"armor",
		float(_corrosive_armor_reduction),
		_corrosive_armor_duration,
		enemy
	)

	# Spawn acid pool visual/damage at target position
	if _corrosive_pool_damage > 0.0:
		_spawn_acid_pool(target.global_position)


func _spawn_acid_pool(pos: Vector3) -> void:
	# Create a timed AoE damage zone
	if not enemy.is_inside_tree():
		return

	var pool := AoEEffect.new()
	enemy.get_tree().current_scene.add_child(pool)
	pool.global_position = pos
	pool.setup(_corrosive_pool_damage, _corrosive_pool_duration, enemy, "acid")
