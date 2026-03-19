class_name EnemyBase
extends EntityBase
## EnemyBase - Base class for all enemies.
## Spawns with HealthComponent, CombatComponent, MovementComponent, BuffDebuffComponent.
## Moves toward player base center. Shows health bar above head.
## On death: spawns corpse, emits entity_died via EntityBase.die().

const BASE_CENTER := Vector3(150.0, 0.0, 150.0)
const HEALTH_BAR_HEIGHT_OFFSET := 0.5  # Extra height above mesh top

var enemy_data: Dictionary = {}
var health_bar: Node3D = null
var health_bar_width: float = 1.0
var ai_node: Node = null
var _attack_tween: Tween = null

# Frame-stagger slot for AI processing.  Each enemy gets a random slot so
# expensive AI work is distributed evenly across frames when counts are high.
var _frame_slot: int = 0


func _ready() -> void:
	entity_type = "enemy"
	_frame_slot = randi()
	super._ready()
	add_to_group("enemy")


func initialize_enemy(enemy_id: String, p_data: Dictionary, difficulty_mult: Dictionary = {}) -> void:
	enemy_data = p_data.duplicate(true)

	# Apply difficulty scaling multipliers
	if not difficulty_mult.is_empty():
		enemy_data["hp"] = float(enemy_data.get("hp", 100)) * difficulty_mult.get("hp_mult", 1.0)
		enemy_data["damage"] = float(enemy_data.get("damage", 0)) * difficulty_mult.get("damage_mult", 1.0)
		# Size-based flat armor bonus (small +1/10min, large +1/5min, huge +2/5min)
		var armor_bonus: float = difficulty_mult.get("armor_bonus", 0.0)
		enemy_data["armor"] = float(enemy_data.get("armor", 0)) + armor_bonus
		# Attack range scaling (+5% per minute past 10 minutes)
		var range_mult: float = difficulty_mult.get("attack_range_mult", 1.0)
		if range_mult > 1.0:
			enemy_data["attack_range"] = float(enemy_data.get("attack_range", 0)) * range_mult
		# Late-game movement speed bonus (+5% per minute past 15 minutes)
		var speed_bonus: float = difficulty_mult.get("speed_bonus", 0.0)
		if speed_bonus > 0.0:
			enemy_data["speed"] = float(enemy_data.get("speed", 5.0)) * (1.0 + speed_bonus)

	# Add components before initialize
	_add_components()

	# Initialize via EntityBase (registers with EntityRegistry, creates visual)
	initialize(enemy_id, "enemy", enemy_data)

	# Configure combat target type based on role
	_configure_target_type()

	# Setup health bar above head
	_setup_health_bar()

	# Connect health changes to health bar update
	if health_component:
		health_component.health_changed.connect(_on_health_changed)
		health_component.died.connect(_on_died)

	# Add to flying group if applicable
	if movement_component and movement_component.is_flying:
		add_to_group("flying")

	# Connect attack visual
	if combat_component:
		combat_component.attack_fired.connect(_on_attack_fired)

	# Start moving toward base center
	if movement_component:
		movement_component.move_to(BASE_CENTER)


func _add_components() -> void:
	var health := HealthComponent.new()
	health.name = "HealthComponent"
	add_child(health)

	var combat := CombatComponent.new()
	combat.name = "CombatComponent"
	add_child(combat)

	var movement := MovementComponent.new()
	movement.name = "MovementComponent"
	add_child(movement)

	var buff := BuffDebuffComponent.new()
	buff.name = "BuffDebuffComponent"
	add_child(buff)


func _configure_target_type() -> void:
	if not combat_component:
		return

	var target_priority: String = enemy_data.get("target_priority", "nearest")
	match target_priority:
		"towers":
			combat_component.target_type = "tower"
		"units":
			combat_component.target_type = "unit"
		"walls":
			combat_component.target_type = "barrier"
		"central_tower":
			combat_component.target_type = "central_tower"
		_:
			combat_component.target_type = "tower"


func _setup_health_bar() -> void:
	# Determine height based on mesh scale
	var scale_arr: Variant = enemy_data.get("mesh_scale", [1.0, 1.0, 1.0])
	var mesh_height: float = 1.0
	if scale_arr is Array and scale_arr.size() >= 2:
		mesh_height = float(scale_arr[1])

	health_bar_width = max(0.6, mesh_height * 0.8)
	health_bar = VisualGenerator.create_health_bar(health_bar_width, true)
	health_bar.position.y = mesh_height + HEALTH_BAR_HEIGHT_OFFSET
	add_child(health_bar)


func _on_health_changed(current_hp: float, max_hp: float) -> void:
	if health_bar and max_hp > 0.0:
		health_bar.visible = current_hp < max_hp
		VisualGenerator.update_health_bar(health_bar, current_hp / max_hp, health_bar_width)


func _on_died(killer: Node) -> void:
	# Spawn corpse at death position
	_spawn_corpse()


func _spawn_corpse() -> void:
	var corpse_scene := preload("res://entities/enemies/corpse.gd")
	var corpse := Node3D.new()
	corpse.set_script(corpse_scene)
	corpse.name = "Corpse_%s" % entity_id
	if is_inside_tree():
		get_tree().current_scene.add_child(corpse)
		corpse.global_position = global_position
		corpse.setup(enemy_data)
	GameBus.corpse_spawned.emit(global_position, entity_id)


func _on_attack_fired(target: Node) -> void:
	_play_attack_wobble(target)


func _play_attack_wobble(target: Node) -> void:
	if not visual_node:
		return
	if _attack_tween and _attack_tween.is_valid():
		_attack_tween.kill()

	var lunge := Vector3(0, 0.1, 0)
	if target and is_instance_valid(target):
		var dir: Vector3 = (target.global_position - global_position)
		dir.y = 0
		if dir.length_squared() > 0.01:
			lunge = dir.normalized() * 0.2 + Vector3(0, 0.05, 0)

	var base_pos: Vector3 = visual_node.position
	_attack_tween = create_tween()
	_attack_tween.tween_property(visual_node, "position", base_pos + lunge, 0.07)
	_attack_tween.tween_property(visual_node, "position", base_pos, 0.13)


## Start march mode: disable expensive components while the enemy is far from
## the base.  Only MovementComponent runs (cheap direct movement).  Called by
## SpawnSystem after the full entity (including AI node) is assembled.
func start_march_mode() -> void:
	if not movement_component:
		return
	movement_component.march_mode = true
	movement_component.entered_combat_zone.connect(_enter_combat_zone, CONNECT_ONE_SHOT)
	# Disable non-essential _process callbacks to save dispatch overhead.
	if combat_component:
		combat_component.set_process(false)
	if ai_node:
		ai_node.set_process(false)


func _enter_combat_zone() -> void:
	## Re-enable full AI and combat processing when reaching the base area.
	if combat_component:
		combat_component.set_process(true)
	if ai_node:
		ai_node.set_process(true)


## Returns true if this enemy should run expensive AI work this frame.
## Two layers of throttling:
##   1. Count-based stagger: spreads AI ticks across frames at high enemy counts.
##   2. Frame budget: defers work entirely when the frame is already over budget.
## Movement still runs every frame — only targeting and behavior are deferred.
func should_process_ai() -> bool:
	if not FrameBudget.has_budget():
		return false
	var count: int = EntityRegistry.get_count("enemy")
	if count < 150:
		return true
	var skip: int
	if count < 250:
		skip = 2
	elif count < 400:
		skip = 3
	else:
		skip = 5
	return (Engine.get_process_frames() + _frame_slot) % skip == 0


## Find the nearest player-owned entity (tower, building, unit, central_tower).
## Returns null if nothing found within max_range.
## Delegates to EntityRegistry's spatial hash for fast lookups.
func find_nearest_player_entity(max_range: float = INF) -> Node:
	return EntityRegistry.get_nearest_multi(
		global_position, ["tower", "building", "unit", "central_tower"], max_range)


## Find the nearest player entity reachable via navmesh (not blocked by walls).
## Checks closest candidates first; returns null if none are reachable.
func find_nearest_reachable_player_entity() -> Node:
	if not movement_component:
		return null

	var candidates: Array[Dictionary] = []
	for etype: String in ["tower", "building", "unit", "central_tower"]:
		var entities: Array = EntityRegistry.get_all(etype)
		for ent: Node in entities:
			if not is_instance_valid(ent) or not ent.is_inside_tree():
				continue
			if ent is EntityBase and ent.health_component and ent.health_component.is_dead:
				continue
			var dist_sq: float = global_position.distance_squared_to(ent.global_position)
			candidates.append({"entity": ent, "dist_sq": dist_sq})

	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["dist_sq"] < b["dist_sq"])

	var max_checks: int = mini(8, candidates.size())
	for i: int in range(max_checks):
		var ent: Node = candidates[i]["entity"]
		if movement_component.is_position_reachable(ent.global_position):
			return ent

	return null


## Find nearest player entity that is a structure (tower, building, barrier, central_tower).
func find_nearest_structure(max_range: float = INF) -> Node:
	return EntityRegistry.get_nearest_multi(
		global_position, ["tower", "building", "barrier", "central_tower"], max_range)


## Find nearest enemy (allied to this enemy) for healer support targeting.
func find_nearest_damaged_ally(max_range: float) -> Node:
	var me := self
	return EntityRegistry.get_nearest_with_filter(
		global_position, "enemy", max_range,
		func(ent: Node) -> bool:
			if ent == me:
				return false
			if ent is EntityBase and ent.health_component:
				if ent.health_component.is_dead:
					return false
				return ent.health_component.current_hp < ent.health_component.max_hp
			return false
	)


## Find the lowest HP player entity in range (for sniper targeting).
func find_lowest_hp_player_entity(max_range: float) -> Node:
	var best: Node = null
	var best_hp: float = INF

	for etype: String in ["tower", "building", "unit", "central_tower"]:
		var entities: Array = EntityRegistry.get_in_range(global_position, etype, max_range)
		for ent: Node in entities:
			if ent is EntityBase and ent.health_component:
				if ent.health_component.is_dead:
					continue
				if ent.health_component.current_hp < best_hp:
					best_hp = ent.health_component.current_hp
					best = ent
	return best
