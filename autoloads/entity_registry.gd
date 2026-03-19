extends Node
## EntityRegistry - Tracks all live entities by type and position.
## Uses a pre-allocated flat-array spatial grid for fast proximity queries.
## Zero per-frame allocations: cell arrays are cleared and refilled in-place.

# Entities stored by type: { "tower": [node1, node2], "enemy": [...], ... }
var _entities: Dictionary = {}

# Entity type constants
const TYPE_TOWER := "tower"
const TYPE_ENEMY := "enemy"
const TYPE_UNIT := "unit"
const TYPE_BARRIER := "barrier"
const TYPE_BUILDING := "building"
const TYPE_CENTRAL := "central_tower"
const TYPE_PROJECTILE := "projectile"
const TYPE_CORPSE := "corpse"

# --- Spatial Grid ---
# Flat 2D grid indexed by integer.  No Dictionaries, no per-frame allocations.
# World covers roughly 0-300 in XZ.  Grid extends a bit beyond for safety.
const CELL_SIZE: float = 16.0
const GRID_DIM: int = 21          # 21 × 16 = 336, covers 0 .. 336
const GRID_TOTAL: int = 441       # GRID_DIM * GRID_DIM

# Per-type grids.  Each value is a flat Array of GRID_TOTAL Arrays (pre-allocated once).
# { entity_type : Array[Array] }
var _type_grids: Dictionary = {}
# Frame when each type's grid was last rebuilt.  { entity_type : int }
var _type_frame: Dictionary = {}


func _ready() -> void:
	GameBus.entity_spawned.connect(_on_entity_spawned)
	GameBus.entity_removed.connect(_on_entity_removed)


# =============================================================================
# Registration (unchanged API)
# =============================================================================

func register(entity: Node, entity_type: String) -> void:
	if not _entities.has(entity_type):
		_entities[entity_type] = []
	if entity not in _entities[entity_type]:
		_entities[entity_type].append(entity)


func unregister(entity: Node, entity_type: String) -> void:
	if _entities.has(entity_type):
		_entities[entity_type].erase(entity)


func get_all(entity_type: String) -> Array:
	return _entities.get(entity_type, [])


func get_count(entity_type: String) -> int:
	return _entities.get(entity_type, []).size()


# =============================================================================
# Spatial Grid Internals
# =============================================================================

func _cell_index_from_pos(pos: Vector3) -> int:
	var cx: int = clampi(int(pos.x / CELL_SIZE), 0, GRID_DIM - 1)
	var cz: int = clampi(int(pos.z / CELL_SIZE), 0, GRID_DIM - 1)
	return cz * GRID_DIM + cx


func _cell_coords(pos: Vector3) -> Vector2i:
	return Vector2i(
		clampi(int(pos.x / CELL_SIZE), 0, GRID_DIM - 1),
		clampi(int(pos.z / CELL_SIZE), 0, GRID_DIM - 1))


func _ensure_grid(entity_type: String) -> Array:
	## Return the spatial grid for *entity_type*, rebuilding it if it is stale.
	## Grids are rebuilt at most once per frame per type.
	var frame: int = Engine.get_process_frames()

	# Allocate the grid the first time this type is seen.
	if not _type_grids.has(entity_type):
		var grid: Array = []
		grid.resize(GRID_TOTAL)
		for i in range(GRID_TOTAL):
			grid[i] = []
		_type_grids[entity_type] = grid
		_type_frame[entity_type] = -1

	if _type_frame[entity_type] == frame:
		return _type_grids[entity_type]

	# Rebuild: clear every cell in-place (no new Arrays), then re-bucket.
	_type_frame[entity_type] = frame
	var grid: Array = _type_grids[entity_type]
	for i in range(GRID_TOTAL):
		grid[i].clear()
	for entity: Node in _entities.get(entity_type, []):
		if not is_instance_valid(entity) or not entity.is_inside_tree():
			continue
		grid[_cell_index_from_pos(entity.global_position)].append(entity)
	return grid


# =============================================================================
# Spatial Queries
# =============================================================================

func get_nearest(position: Vector3, entity_type: String, max_range: float = INF) -> Node:
	var grid: Array = _ensure_grid(entity_type)
	var center := _cell_coords(position)

	var nearest: Node = null
	var nearest_dist_sq: float = INF
	var range_sq: float = max_range * max_range if max_range != INF else INF

	var cell_range: int
	if max_range != INF:
		cell_range = ceili(max_range / CELL_SIZE) + 1
	else:
		cell_range = GRID_DIM

	var min_cx: int = maxi(0, center.x - cell_range)
	var max_cx: int = mini(GRID_DIM - 1, center.x + cell_range)
	var min_cz: int = maxi(0, center.y - cell_range)
	var max_cz: int = mini(GRID_DIM - 1, center.y + cell_range)

	for gz in range(min_cz, max_cz + 1):
		var row: int = gz * GRID_DIM
		for gx in range(min_cx, max_cx + 1):
			var bucket: Array = grid[row + gx]
			if bucket.is_empty():
				continue
			for entity: Node in bucket:
				var dist_sq: float = position.distance_squared_to(entity.global_position)
				if dist_sq < nearest_dist_sq and dist_sq <= range_sq:
					nearest_dist_sq = dist_sq
					nearest = entity
	return nearest


func get_in_range(position: Vector3, entity_type: String, max_range: float) -> Array:
	var grid: Array = _ensure_grid(entity_type)
	var center := _cell_coords(position)
	var cell_range: int = ceili(max_range / CELL_SIZE) + 1
	var range_sq: float = max_range * max_range
	var result: Array = []

	var min_cx: int = maxi(0, center.x - cell_range)
	var max_cx: int = mini(GRID_DIM - 1, center.x + cell_range)
	var min_cz: int = maxi(0, center.y - cell_range)
	var max_cz: int = mini(GRID_DIM - 1, center.y + cell_range)

	for gz in range(min_cz, max_cz + 1):
		var row: int = gz * GRID_DIM
		for gx in range(min_cx, max_cx + 1):
			var bucket: Array = grid[row + gx]
			if bucket.is_empty():
				continue
			for entity: Node in bucket:
				if position.distance_squared_to(entity.global_position) <= range_sq:
					result.append(entity)
	return result


func get_nearest_with_filter(position: Vector3, entity_type: String, max_range: float, filter: Callable) -> Node:
	var grid: Array = _ensure_grid(entity_type)
	var center := _cell_coords(position)
	var nearest: Node = null
	var nearest_dist_sq: float = INF
	var range_sq: float = max_range * max_range if max_range != INF else INF

	var cell_range: int
	if max_range != INF:
		cell_range = ceili(max_range / CELL_SIZE) + 1
	else:
		cell_range = GRID_DIM

	var min_cx: int = maxi(0, center.x - cell_range)
	var max_cx: int = mini(GRID_DIM - 1, center.x + cell_range)
	var min_cz: int = maxi(0, center.y - cell_range)
	var max_cz: int = mini(GRID_DIM - 1, center.y + cell_range)

	for gz in range(min_cz, max_cz + 1):
		var row: int = gz * GRID_DIM
		for gx in range(min_cx, max_cx + 1):
			var bucket: Array = grid[row + gx]
			if bucket.is_empty():
				continue
			for entity: Node in bucket:
				if not filter.call(entity):
					continue
				var dist_sq: float = position.distance_squared_to(entity.global_position)
				if dist_sq < nearest_dist_sq and dist_sq <= range_sq:
					nearest_dist_sq = dist_sq
					nearest = entity
	return nearest


func get_nearest_multi(position: Vector3, entity_types: Array, max_range: float = INF) -> Node:
	## Find the nearest entity across multiple entity types.
	var best: Node = null
	var best_dist_sq: float = INF
	for etype: String in entity_types:
		var candidate := get_nearest(position, etype, max_range)
		if candidate:
			var dist_sq: float = position.distance_squared_to(candidate.global_position)
			if dist_sq < best_dist_sq:
				best_dist_sq = dist_sq
				best = candidate
	return best


# =============================================================================
# Utility
# =============================================================================

func get_all_types() -> Array:
	return _entities.keys()


func get_total_count() -> int:
	var total := 0
	for type_list: Array in _entities.values():
		total += type_list.size()
	return total


func clear_all() -> void:
	_entities.clear()
	_type_grids.clear()
	_type_frame.clear()


func clear_type(entity_type: String) -> void:
	if _entities.has(entity_type):
		_entities[entity_type].clear()
	_type_grids.erase(entity_type)
	_type_frame.erase(entity_type)


func _cleanup_invalid() -> void:
	for entity_type: String in _entities:
		var valid: Array = []
		for entity: Node in _entities[entity_type]:
			if is_instance_valid(entity) and entity.is_inside_tree():
				valid.append(entity)
		_entities[entity_type] = valid


func _on_entity_spawned(entity: Node, entity_type: String, _entity_id: String) -> void:
	register(entity, entity_type)


func _on_entity_removed(entity: Node, entity_type: String) -> void:
	unregister(entity, entity_type)
