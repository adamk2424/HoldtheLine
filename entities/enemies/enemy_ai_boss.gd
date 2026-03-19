class_name EnemyAIBoss
extends Node
## EnemyAIBoss - AI for boss enemy (behemoth).
## Massive HP, moves slowly toward base center.
## ground_slam: periodic AoE attack (every 8s) that damages all player entities in radius 8.
## Emits boss_spawned signal on ready.

var enemy: EnemyBase = null
var current_target: Node = null
var _retarget_timer: float = 0.0
const RETARGET_INTERVAL: float = 1.5

# Ground slam state
var _slam_timer: float = 0.0
var _slam_cooldown: float = 8.0
var _slam_radius: float = 8.0
var _slam_damage: float = 50.0


func _ready() -> void:
	enemy = get_parent() as EnemyBase
	if not enemy:
		push_warning("[EnemyAIBoss] Parent is not EnemyBase")
		return

	# Override CombatComponent auto-targeting
	if enemy.combat_component:
		enemy.combat_component.is_active = false

	# Parse ground slam parameters from specials
	var specials: Array = enemy.enemy_data.get("specials", [])
	for special: Dictionary in specials:
		if special.get("type", "") == "ground_slam":
			_slam_radius = float(special.get("radius", 8.0))
			_slam_damage = float(special.get("damage", 50.0))
			_slam_cooldown = float(special.get("cooldown", 8.0))

	# Emit boss_spawned signal
	GameBus.boss_spawned.emit(enemy)
	GameBus.audio_play_3d.emit("enemy.behemoth.spawn", enemy.global_position)


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

	# Ground slam timer
	_slam_timer += delta
	if _slam_timer >= _slam_cooldown:
		_slam_timer = 0.0
		_perform_ground_slam()

	# Retarget
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
		# Boss targets nearest player entity
		current_target = enemy.find_nearest_player_entity()


func _update_behavior(delta: float) -> void:
	if not enemy.combat_component or not enemy.movement_component:
		return

	var attack_range: float = enemy.combat_component.get_effective_range()

	if current_target and is_instance_valid(current_target) and current_target.is_inside_tree():
		var dist: float = enemy.global_position.distance_to(current_target.global_position)

		if dist <= attack_range:
			# In range: stop and melee attack
			if enemy.movement_component.is_moving:
				enemy.movement_component.stop()
			_perform_melee_attack(delta)
		else:
			# Move toward target (slowly)
			enemy.movement_component.move_to(current_target.global_position)
	else:
		# No target: move toward base center
		if not enemy.movement_component.is_moving:
			enemy.movement_component.move_to(EnemyBase.BASE_CENTER)


func _perform_melee_attack(delta: float) -> void:
	if not current_target or not is_instance_valid(current_target):
		return

	var combat := enemy.combat_component
	combat._attack_timer += delta
	if combat._attack_timer >= combat.attack_rate:
		combat._attack_timer = 0.0
		combat.current_target = current_target
		combat._perform_attack()


func _perform_ground_slam() -> void:
	# AoE damage to all player entities in radius
	var slam_pos: Vector3 = enemy.global_position

	# Damage all player entity types in radius
	for etype: String in ["tower", "building", "unit", "barrier", "central_tower"]:
		var targets: Array = EntityRegistry.get_in_range(slam_pos, etype, _slam_radius)
		for target: Node in targets:
			if not is_instance_valid(target) or not target.is_inside_tree():
				continue
			if target is EntityBase and target.health_component:
				target.health_component.take_damage(_slam_damage, enemy)

	# Emit AoE signal for visual/audio feedback
	GameBus.aoe_triggered.emit(slam_pos, _slam_radius, _slam_damage, enemy)
	GameBus.audio_play_3d.emit("enemy.behemoth.ground_slam", slam_pos)

	# Spawn visual AoE effect
	_spawn_slam_visual(slam_pos)


func _spawn_slam_visual(pos: Vector3) -> void:
	if not enemy.is_inside_tree():
		return

	var aoe := AoEEffect.new()
	enemy.get_tree().current_scene.add_child(aoe)
	aoe.global_position = pos
	# Setup with 0 damage since we already dealt damage manually
	# This is just for the visual ring effect
	aoe.setup(0.0, _slam_radius, enemy, "none")
