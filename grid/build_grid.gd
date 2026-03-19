class_name BuildGrid
extends Node3D
## BuildGrid - Manages the 120x120 build grid centered in the 300x300 world.
## Handles occupancy, placement validation, and coordinate conversion.

const GRID_SIZE: int = 120
const CELL_SIZE: float = 1.0
const WORLD_SIZE: float = 300.0

# Grid offset: center the 120x120 grid in the 300x300 world
var grid_origin: Vector3 = Vector3(
	(WORLD_SIZE - GRID_SIZE * CELL_SIZE) / 2.0,
	0.0,
	(WORLD_SIZE - GRID_SIZE * CELL_SIZE) / 2.0
)

# Occupancy grid: -1 = free, >= 0 = entity instance ID
var _occupancy: Array = []

func _ready() -> void:
	_init_occupancy()
	GameBus.navmesh_needs_rebake.connect(_on_navmesh_needs_rebake)


func _init_occupancy() -> void:
	_occupancy.resize(GRID_SIZE * GRID_SIZE)
	_occupancy.fill(-1)


# --- Public API ---

func is_cell_free(grid_pos: Vector2i, size: int = 1) -> bool:
	for x in range(grid_pos.x, grid_pos.x + size):
		for y in range(grid_pos.y, grid_pos.y + size):
			if not _is_valid_cell(Vector2i(x, y)):
				return false
			if _get_cell(Vector2i(x, y)) != -1:
				return false
	return true


func occupy_cells(grid_pos: Vector2i, size: int, entity_id: int) -> void:
	for x in range(grid_pos.x, grid_pos.x + size):
		for y in range(grid_pos.y, grid_pos.y + size):
			_set_cell(Vector2i(x, y), entity_id)
	GameBus.navmesh_needs_rebake.emit()


func free_cells(grid_pos: Vector2i, size: int) -> void:
	for x in range(grid_pos.x, grid_pos.x + size):
		for y in range(grid_pos.y, grid_pos.y + size):
			_set_cell(Vector2i(x, y), -1)
	GameBus.navmesh_needs_rebake.emit()


func grid_to_world(grid_pos: Vector2i, size: int = 1) -> Vector3:
	var offset: float = (size * CELL_SIZE) / 2.0
	return Vector3(
		grid_origin.x + grid_pos.x * CELL_SIZE + offset,
		0.0,
		grid_origin.z + grid_pos.y * CELL_SIZE + offset
	)


func world_to_grid(world_pos: Vector3) -> Vector2i:
	var local_x: float = world_pos.x - grid_origin.x
	var local_z: float = world_pos.z - grid_origin.z
	return Vector2i(
		int(floor(local_x / CELL_SIZE)),
		int(floor(local_z / CELL_SIZE))
	)


func is_in_grid(world_pos: Vector3) -> bool:
	var grid_pos := world_to_grid(world_pos)
	return _is_valid_cell(grid_pos)


func get_grid_center_world() -> Vector3:
	return grid_to_world(Vector2i(GRID_SIZE / 2, GRID_SIZE / 2))


func snap_to_grid(world_pos: Vector3, size: int = 1) -> Vector3:
	var grid_pos := world_to_grid(world_pos)
	return grid_to_world(grid_pos, size)


## Returns the entity instance ID occupying the given cell, -1 if free, -2 if out of bounds.
func get_cell_occupant(grid_pos: Vector2i) -> int:
	return _get_cell(grid_pos)


## Returns true if the given cell is valid (within grid bounds).
func is_valid_cell(grid_pos: Vector2i) -> bool:
	return _is_valid_cell(grid_pos)


# --- Internal ---

func _is_valid_cell(grid_pos: Vector2i) -> bool:
	return grid_pos.x >= 0 and grid_pos.x < GRID_SIZE and grid_pos.y >= 0 and grid_pos.y < GRID_SIZE


func _get_cell(grid_pos: Vector2i) -> int:
	if not _is_valid_cell(grid_pos):
		return -2  # Out of bounds
	return _occupancy[grid_pos.y * GRID_SIZE + grid_pos.x]


func _set_cell(grid_pos: Vector2i, value: int) -> void:
	if _is_valid_cell(grid_pos):
		_occupancy[grid_pos.y * GRID_SIZE + grid_pos.x] = value


func _on_navmesh_needs_rebake() -> void:
	# Handled by GameMap
	pass
