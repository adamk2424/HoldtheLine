class_name ProductionBuildingBase
extends EntityBase
## ProductionBuildingBase - Base class for all production buildings.
## Production uses a simple inline Timer + queue array. No separate queue node.

# Production - inline queue (no separate ProductionQueue node needed for UI compat)
var production_queue: RefCounted = null  # Lightweight object for UI to read state
var produces: Array = []
var max_queue_size: int = 5
var _build_queue: Array = []  # Array of unit_id strings
var _build_timer: Timer = null
var _is_producing: bool = false
var _current_build_time: float = 0.0
var build_speed_multiplier: float = 1.0

# Upgrades
var upgrade_level: int = 0
var max_upgrade_level: int = 3
var upgrades_data: Array = []
var is_upgrading: bool = false
var _upgrade_timer: float = 0.0
var _upgrade_time: float = 0.0

# Grid
var build_grid: BuildGrid = null

# Health bar
var health_bar: Node3D = null
var _health_bar_width: float = 2.0

# Spawn offset for produced units
var _spawn_offset: float = 3.0

# Rally point
var rally_point: Vector3 = Vector3.ZERO
var has_rally_point: bool = false

# Unit class registry for spawning the correct script type
const UNIT_CLASSES: Dictionary = {
	"repair_drone": "res://entities/units/drone_repair.gd",
	"shield_drone": "res://entities/units/drone_shield.gd",
	"disruptor_drone": "res://entities/units/drone_disruptor.gd",
	"sentinel": "res://entities/units/mech_sentinel.gd",
	"juggernaut": "res://entities/units/mech_juggernaut.gd",
	"striker": "res://entities/units/vehicle_striker.gd",
	"siege_walker": "res://entities/units/vehicle_siege_walker.gd",
}


func _ready() -> void:
	super._ready()
	add_to_group("production_buildings")

	# Create build timer directly on this node
	_build_timer = Timer.new()
	_build_timer.name = "BuildTimer"
	_build_timer.one_shot = true
	_build_timer.timeout.connect(_on_build_timer_timeout)
	add_child(_build_timer)

	# Create a lightweight proxy so UI can read queue state via duck typing
	production_queue = _QueueProxy.new(self)


func initialize(p_entity_id: String, p_entity_type: String, p_data: Dictionary = {}) -> void:
	super.initialize(p_entity_id, p_entity_type, p_data)

	produces = data.get("produces", [])
	max_queue_size = int(data.get("max_queue", 5))
	upgrades_data = data.get("upgrades", [])
	max_upgrade_level = upgrades_data.size()

	var grid_sz: Variant = data.get("grid_size", [2, 2])
	if grid_sz is Array and grid_sz.size() >= 1:
		_spawn_offset = float(grid_sz[0]) * 0.5 + 1.5

	_create_health_bar()

	if health_component:
		health_component.health_changed.connect(_on_health_changed)
		health_component.died.connect(_on_died)

	GameBus.upgrade_requested.connect(_on_upgrade_requested)


func _process(delta: float) -> void:
	_process_upgrade(delta)
	_update_health_bar_rotation()


# ========== Production API ==========

func queue_unit(unit_id: String) -> bool:
	if unit_id not in produces:
		return false
	if _build_queue.size() >= max_queue_size:
		return false

	var unit_data: Dictionary = GameData.get_unit(unit_id)
	if unit_data.is_empty():
		return false

	var energy_cost: float = float(unit_data.get("cost_energy", 0))
	var material_cost: float = float(unit_data.get("cost_materials", 0))
	if not GameState.can_afford(energy_cost, material_cost):
		GameBus.resources_insufficient.emit(energy_cost, material_cost)
		return false

	var pop_cost: int = int(unit_data.get("pop_cost", 1))
	if not GameState.add_population(pop_cost):
		return false

	if not GameState.spend_resources(energy_cost, material_cost):
		GameState.free_population(pop_cost)
		return false

	_build_queue.append(unit_id)
	GameBus.unit_queued.emit(self, unit_id)

	if not _is_producing:
		_start_building()

	return true


func cancel_production(index: int) -> bool:
	if index < 0 or index >= _build_queue.size():
		return false

	var unit_id: String = _build_queue[index]
	var unit_data: Dictionary = GameData.get_unit(unit_id)
	if not unit_data.is_empty():
		GameState.refund_resources(
			float(unit_data.get("cost_energy", 0)),
			float(unit_data.get("cost_materials", 0))
		)
		GameState.free_population(int(unit_data.get("pop_cost", 1)))

	_build_queue.remove_at(index)

	if index == 0:
		_is_producing = false
		_build_timer.stop()
		_current_build_time = 0.0
		if not _build_queue.is_empty():
			_start_building()

	return true


func can_produce(unit_id: String) -> bool:
	return unit_id in produces


func get_queue_size() -> int:
	return _build_queue.size()


func _start_building() -> void:
	if _build_queue.is_empty():
		_is_producing = false
		return

	var unit_id: String = _build_queue[0]
	var unit_data: Dictionary = GameData.get_unit(unit_id)
	_current_build_time = float(unit_data.get("build_time", 5.0))
	_is_producing = true

	var effective_time: float = _current_build_time / build_speed_multiplier
	_build_timer.start(effective_time)

	GameBus.unit_production_started.emit(self, unit_id)


func _on_build_timer_timeout() -> void:
	if _build_queue.is_empty():
		_is_producing = false
		return

	var unit_id: String = _build_queue[0]
	_build_queue.remove_at(0)
	_is_producing = false
	_current_build_time = 0.0

	# Spawn the unit
	var unit: Node = _spawn_unit(unit_id)
	if unit:
		GameBus.unit_production_completed.emit(self, unit_id, unit)
		if has_rally_point and unit is UnitBase and unit.movement_component:
			unit.movement_component.move_to(rally_point)
	else:
		push_warning("[Production] Failed to spawn %s from %s" % [unit_id, entity_id])
		GameBus.unit_production_completed.emit(self, unit_id, null)

	# Start next in queue
	if not _build_queue.is_empty():
		_start_building()


# ========== Upgrade API ==========

func request_upgrade() -> bool:
	if is_upgrading:
		return false
	if upgrade_level >= max_upgrade_level:
		return false

	var upgrade_data: Dictionary = upgrades_data[upgrade_level]
	var energy_cost: float = float(upgrade_data.get("cost_energy", 0))
	var material_cost: float = float(upgrade_data.get("cost_materials", 0))

	if not GameState.spend_resources(energy_cost, material_cost):
		return false

	is_upgrading = true
	_upgrade_time = float(upgrade_data.get("time", 15))
	_upgrade_timer = 0.0

	var upgrade_name: String = upgrade_data.get("name", "Upgrade %d" % (upgrade_level + 1))
	GameBus.upgrade_started.emit(self, upgrade_name)

	return true


func _process_upgrade(delta: float) -> void:
	if not is_upgrading:
		return

	_upgrade_timer += delta
	if _upgrade_timer >= _upgrade_time:
		_complete_upgrade()


func _complete_upgrade() -> void:
	is_upgrading = false
	_upgrade_timer = 0.0

	var upgrade_data: Dictionary = upgrades_data[upgrade_level]
	var upgrade_name: String = upgrade_data.get("name", "Upgrade %d" % (upgrade_level + 1))

	upgrade_level += 1
	GameState.set_tech_level(entity_id, upgrade_level)

	_apply_upgrade_effects(upgrade_level)

	GameBus.upgrade_completed.emit(self, upgrade_name)


func _apply_upgrade_effects(_level: int) -> void:
	pass


# ========== Unit Spawning ==========

func set_rally_point(pos: Vector3) -> void:
	rally_point = pos
	has_rally_point = true


func clear_rally_point() -> void:
	rally_point = Vector3.ZERO
	has_rally_point = false


func _spawn_unit(unit_id: String) -> Node:
	var unit_data: Dictionary = GameData.get_unit(unit_id)
	if unit_data.is_empty():
		return null

	var spawn_pos: Vector3 = _get_spawn_position()

	var unit: UnitBase = _create_unit_instance(unit_id)
	if not unit:
		return null

	unit.name = unit_id + "_" + str(randi())
	unit.position = spawn_pos

	var health := HealthComponent.new()
	health.name = "HealthComponent"
	unit.add_child(health)

	var combat := CombatComponent.new()
	combat.name = "CombatComponent"
	unit.add_child(combat)

	var movement := MovementComponent.new()
	movement.name = "MovementComponent"
	movement.enforce_boundaries = true
	unit.add_child(movement)

	var buff := BuffDebuffComponent.new()
	buff.name = "BuffDebuffComponent"
	unit.add_child(buff)

	get_tree().current_scene.add_child(unit)

	var modified_data: Dictionary = _get_modified_unit_data(unit_data)
	unit.initialize(unit_id, "unit", modified_data)

	return unit


func _create_unit_instance(unit_id: String) -> UnitBase:
	if UNIT_CLASSES.has(unit_id):
		var script: GDScript = load(UNIT_CLASSES[unit_id])
		if script:
			return script.new() as UnitBase
	return UnitBase.new()


func _get_spawn_position() -> Vector3:
	var angle: float = randf() * TAU
	var offset := Vector3(cos(angle) * _spawn_offset, 0.0, sin(angle) * _spawn_offset)
	return global_position + offset


func _get_modified_unit_data(base_data: Dictionary) -> Dictionary:
	return base_data.duplicate(true)


# ========== Health Bar ==========

func _create_health_bar() -> void:
	var mesh_scale: Array = data.get("mesh_scale", [2.0, 1.0, 2.0])
	_health_bar_width = max(1.0, float(mesh_scale[0]) if mesh_scale.size() >= 1 else 2.0)

	var height: float = 1.5
	if mesh_scale.size() >= 2:
		height = float(mesh_scale[1])

	health_bar = VisualGenerator.create_health_bar(_health_bar_width)
	health_bar.position.y = height + 0.5
	add_child(health_bar)


func _on_health_changed(current_hp: float, max_hp: float) -> void:
	if health_bar and max_hp > 0.0:
		VisualGenerator.update_health_bar(health_bar, current_hp / max_hp, _health_bar_width)


func _on_died(_killer: Node) -> void:
	_free_grid_cells()
	GameState.buildings_lost += 1


func _free_grid_cells() -> void:
	if build_grid:
		build_grid.free_cells(grid_position, grid_size)


func _update_health_bar_rotation() -> void:
	if health_bar:
		var cam := get_viewport().get_camera_3d()
		if cam:
			health_bar.global_rotation = cam.global_rotation


func _on_upgrade_requested(entity: Node, _upgrade_index: int) -> void:
	if entity == self:
		request_upgrade()


# ========== Queue Proxy (for UI compatibility) ==========
# Lightweight object the UI reads via duck typing (pq.queue, pq.is_producing, etc.)

class _QueueProxy extends RefCounted:
	var _building: ProductionBuildingBase

	func _init(b: ProductionBuildingBase) -> void:
		_building = b

	var queue: Array:
		get: return _building._build_queue

	var is_producing: bool:
		get: return _building._is_producing

	var current_build_time: float:
		get: return _building._current_build_time

	var current_build_progress: float:
		get:
			if not _building._is_producing or _building._current_build_time <= 0.0:
				return 0.0
			if not _building._build_timer:
				return 0.0
			var elapsed: float = _building._current_build_time - _building._build_timer.time_left
			return clampf(elapsed, 0.0, _building._current_build_time)

	func get_queue_size() -> int:
		return _building._build_queue.size()
