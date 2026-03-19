class_name BarrierBase
extends EntityBase
## BarrierBase - Base class for all barrier entities.
## Placed on the BuildGrid (1x1 cells). Has HealthComponent + BuffDebuffComponent.
## Supports visual connection with adjacent barriers of the same type.
## Checks all 8 directions (cardinal + diagonal) for smooth wall runs at any angle.
## On death: frees grid cells, notifies neighbors to update visuals, requests navmesh rebake.

signal build_completed_signal()

# Build state
var build_time: float = 3.0
var build_timer: float = 0.0
var is_building: bool = true
var is_built: bool = false

# Cost tracking (for sell refund)
var base_cost_energy: float = 0.0
var base_cost_materials: float = 0.0

# Connection / adjacency
var is_connectable: bool = false
var connected_neighbors: Dictionary = {}  # { Vector2i direction : BarrierBase }

# Health bar
var health_bar: Node3D = null
var health_bar_width: float = 1.0
var _health_bar_visible: bool = false

# Reference to the BuildGrid (set by whoever spawns the barrier)
var build_grid: BuildGrid = null

# All 8 directions for neighbor checks (cardinal + diagonal)
const NEIGHBOR_DIRS: Array[Vector2i] = [
	Vector2i(1, 0),   # East
	Vector2i(-1, 0),  # West
	Vector2i(0, 1),   # South
	Vector2i(0, -1),  # North
	Vector2i(1, 1),   # Southeast
	Vector2i(-1, 1),  # Southwest
	Vector2i(1, -1),  # Northeast
	Vector2i(-1, -1), # Northwest
]


func _ready() -> void:
	super._ready()
	add_to_group("barrier")


func initialize(p_entity_id: String, p_entity_type: String, p_data: Dictionary = {}) -> void:
	super.initialize(p_entity_id, p_entity_type, p_data)

	build_time = float(data.get("build_time", 3.0))
	base_cost_energy = float(data.get("cost_energy", 0))
	base_cost_materials = float(data.get("cost_materials", 0))
	is_connectable = data.get("connectable", false)

	# Create health bar above the barrier
	_setup_health_bar()

	# Start construction
	_start_building()


func _process(delta: float) -> void:
	if is_building:
		_process_build(delta)


# ---------------------------------------------------------------------------
# Health bar
# ---------------------------------------------------------------------------

func _setup_health_bar() -> void:
	var mesh_scale: Array = data.get("mesh_scale", [1.0, 1.0, 1.0])
	var barrier_height: float = 1.0
	if mesh_scale is Array and mesh_scale.size() >= 2:
		barrier_height = float(mesh_scale[1])
	health_bar_width = max(float(grid_size), 1.0)

	health_bar = VisualGenerator.create_health_bar(health_bar_width)
	health_bar.position.y = barrier_height + 0.3
	health_bar.visible = false  # Hidden until damaged
	add_child(health_bar)

	if health_component:
		health_component.health_changed.connect(_on_health_changed)
		health_component.died.connect(_on_died)


func _on_health_changed(current_hp: float, max_hp: float) -> void:
	if health_bar and max_hp > 0.0:
		var percent: float = current_hp / max_hp
		VisualGenerator.update_health_bar(health_bar, percent, health_bar_width)

		# Show health bar only when damaged
		if percent < 1.0 and not _health_bar_visible:
			health_bar.visible = true
			_health_bar_visible = true
		elif percent >= 1.0 and _health_bar_visible:
			health_bar.visible = false
			_health_bar_visible = false


func _on_died(_killer: Node) -> void:
	_free_grid_cells()
	_notify_neighbors_disconnected()
	GameBus.audio_play_3d.emit("barrier.%s.destroyed" % entity_id, global_position)


# ---------------------------------------------------------------------------
# Build process
# ---------------------------------------------------------------------------

func _start_building() -> void:
	is_building = true
	is_built = false
	build_timer = 0.0

	if visual_node:
		visual_node.scale = Vector3.ZERO

	if health_bar:
		health_bar.visible = false

	if health_component:
		health_component.is_invulnerable = true

	GameBus.build_started.emit(self, entity_id, grid_position)


func _process_build(delta: float) -> void:
	build_timer += delta
	var progress: float = clampf(build_timer / build_time, 0.0, 1.0)

	if visual_node:
		visual_node.scale = Vector3.ONE * progress

	if progress >= 1.0:
		_complete_build()


func _complete_build() -> void:
	is_building = false
	is_built = true

	if visual_node:
		visual_node.scale = Vector3.ONE

	if health_component:
		health_component.is_invulnerable = false

	# Discover and visually connect to adjacent same-type barriers
	if is_connectable:
		_update_connections()

	GameBus.build_completed.emit(self, entity_id, grid_position)
	GameBus.audio_play_3d.emit("barrier.%s.build_complete" % entity_id, global_position)
	build_completed_signal.emit()


# ---------------------------------------------------------------------------
# Grid cells
# ---------------------------------------------------------------------------

func _free_grid_cells() -> void:
	if build_grid:
		build_grid.free_cells(grid_position, grid_size)


# ---------------------------------------------------------------------------
# Connection / adjacency logic
# ---------------------------------------------------------------------------

## Scan all 8 neighbor directions. If a neighbor cell is occupied by a barrier
## with the same entity_id, store the reference and tell both sides to refresh visuals.
func _update_connections() -> void:
	connected_neighbors.clear()
	for dir: Vector2i in NEIGHBOR_DIRS:
		var neighbor_pos: Vector2i = grid_position + dir
		var neighbor: BarrierBase = _get_neighbor_barrier(neighbor_pos)
		if neighbor and neighbor.entity_id == entity_id:
			connected_neighbors[dir] = neighbor
			# Tell the neighbor about us too
			neighbor.connected_neighbors[-dir] = self
			neighbor._update_connection_visual()
	_update_connection_visual()


## Called when a neighboring barrier of the same type is destroyed.
func _notify_neighbors_disconnected() -> void:
	for dir: Vector2i in connected_neighbors:
		var neighbor: BarrierBase = connected_neighbors[dir]
		if is_instance_valid(neighbor):
			neighbor.connected_neighbors.erase(-dir)
			neighbor._update_connection_visual()
	connected_neighbors.clear()


## Override in subclasses to change the mesh/material when connections change.
func _update_connection_visual() -> void:
	pass


## Helper: get the BarrierBase occupying a neighboring cell (if any).
func _get_neighbor_barrier(neighbor_grid_pos: Vector2i) -> BarrierBase:
	var barriers: Array = EntityRegistry.get_all(EntityRegistry.TYPE_BARRIER)
	for b: Node in barriers:
		if b is BarrierBase and is_instance_valid(b) and b.grid_position == neighbor_grid_pos:
			return b as BarrierBase
	return null


## Returns an array of directions (Vector2i) that have connected same-type neighbors.
func get_connected_directions() -> Array[Vector2i]:
	var dirs: Array[Vector2i] = []
	for dir: Vector2i in connected_neighbors:
		dirs.append(dir)
	return dirs


# ---------------------------------------------------------------------------
# Death / cleanup
# ---------------------------------------------------------------------------

func die(killer: Node = null) -> void:
	_free_grid_cells()
	GameState.buildings_lost += 1
	super.die(killer)


func get_sell_refund() -> Dictionary:
	return {
		"energy": base_cost_energy * 0.75,
		"materials": base_cost_materials * 0.75,
	}
