extends Node3D
## Test hex wall perimeter navmesh carving.

var _game_map: Node = null
var _build_grid: Node = null
var _enemy: Node = null
var _start_pos: Vector3 = Vector3.ZERO
var _base_world: Vector3 = Vector3.ZERO
var _phase: String = "setup"
var _frame: int = 0

func _ready() -> void:
	print("=== HEX WALL NAVMESH TEST ===")

	var map_scene: PackedScene = preload("res://map/game_map.tscn")
	_game_map = map_scene.instantiate()
	add_child(_game_map)

	var grid_scene: PackedScene = preload("res://grid/build_grid.tscn")
	_build_grid = grid_scene.instantiate()
	add_child(_build_grid)
	_game_map.build_grid = _build_grid

	GameState.reset_state()
	GameState.is_game_active = true

	var center: Vector2i = Vector2i(BuildGrid.GRID_SIZE / 2 - 1, BuildGrid.GRID_SIZE / 2 - 1)
	_base_world = _build_grid.grid_to_world(center, 1)

	# Place hex walls (same as GameSession._place_starting_walls)
	var placed: Dictionary = {}
	var wall_count: int = 0
	for li: int in range(2):
		var hw: int = 50 - li
		var hh: int = 50 - li
		var qw: int = 25 - li
		var hex: Array[Vector2i] = [
			Vector2i(center.x - qw, center.y - hh),
			Vector2i(center.x + qw, center.y - hh),
			Vector2i(center.x + hw, center.y),
			Vector2i(center.x + qw, center.y + hh),
			Vector2i(center.x - qw, center.y + hh),
			Vector2i(center.x - hw, center.y),
		]
		for i: int in range(6):
			var cells: Array[Vector2i] = _line(hex[i], hex[(i + 1) % 6])
			for cell: Vector2i in cells:
				if not placed.has(cell):
					placed[cell] = true
					_build_grid.occupy_cells(cell, 1, 99999 + wall_count)
					wall_count += 1

	print("[TEST] %d wall cells placed" % wall_count)

	# Count occupied
	var occ: int = 0
	for row: int in range(BuildGrid.GRID_SIZE):
		for col: int in range(BuildGrid.GRID_SIZE):
			if _build_grid.get_cell_occupant(Vector2i(col, row)) != -1:
				occ += 1
	print("[TEST] Occupied cells: %d" % occ)
	print("[TEST] Base center = %s" % str(_base_world))

	# Rebuild navmesh synchronously
	_game_map.rebake_navigation()

	var nav_mesh: NavigationMesh = _game_map.navigation_region.navigation_mesh
	if nav_mesh:
		print("[TEST] NavMesh: %d verts, %d polys" % [nav_mesh.vertices.size(), nav_mesh.get_polygon_count()])
	else:
		print("[TEST] ERROR: no navmesh!")

	_phase = "wait_sync"
	_frame = 0


func _physics_process(_delta: float) -> void:
	if _phase == "wait_sync":
		_frame += 1
		if _frame >= 5:
			_do_path_test()
			_spawn_enemy()
			_phase = "track"
			_frame = 0

	elif _phase == "track":
		_frame += 1
		if (_frame == 30 or _frame == 100 or _frame == 200 or _frame == 300) and is_instance_valid(_enemy):
			var pos: Vector3 = _enemy.global_position
			print("[TEST] [F%d] pos=(%.1f,%.1f,%.1f) moved=%.1f" % [
				_frame, pos.x, pos.y, pos.z, pos.distance_to(_start_pos)])
		if _frame >= 300:
			_evaluate()


func _do_path_test() -> void:
	var map_rid: RID = get_world_3d().navigation_map
	var spawn: Vector3 = Vector3(_base_world.x, 0, 5)

	var path: PackedVector3Array = NavigationServer3D.map_get_path(map_rid, spawn, _base_world, true)
	print("[TEST] Path spawn->center: %d waypoints" % path.size())
	if path.size() > 2:
		print("[TEST]   GOOD: multi-waypoint (routes around walls)")
	elif path.size() == 2:
		print("[TEST]   BAD: straight line (goes through walls)")
	else:
		print("[TEST]   NO PATH FOUND")


func _spawn_enemy() -> void:
	GameBus.game_started.emit()
	var edata: Dictionary = GameData.get_enemy("thrasher")
	_enemy = EnemyBase.new()
	_enemy.name = "TestThrasher"
	_enemy.position = Vector3(_base_world.x, 0, 5)
	add_child(_enemy)
	_enemy.initialize_enemy("thrasher", edata, {})
	var ai: Node = EnemyAIMelee.new()
	ai.name = "EnemyAIMelee"
	_enemy.add_child(ai)
	_enemy.ai_node = ai
	_start_pos = _enemy.global_position
	print("[TEST] Enemy spawned at %s" % str(_start_pos))


func _evaluate() -> void:
	var pos: Vector3 = _enemy.global_position
	var moved: float = pos.distance_to(_start_pos)
	print("[TEST] Final: (%.1f,%.1f,%.1f) moved=%.1f" % [pos.x, pos.y, pos.z, moved])
	if moved > 5.0:
		print("[TEST] PASS: enemy moved")
	else:
		print("[TEST] FAIL: enemy stuck")
	get_tree().quit(0)


func _line(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var dx: int = absi(to.x - from.x)
	var dy: int = absi(to.y - from.y)
	var sx: int = 1 if from.x < to.x else -1
	var sy: int = 1 if from.y < to.y else -1
	var err: int = dx - dy
	var x: int = from.x
	var y: int = from.y
	while true:
		cells.append(Vector2i(x, y))
		if x == to.x and y == to.y:
			break
		var e2: int = 2 * err
		if e2 > -dy:
			err -= dy
			x += sx
		if e2 < dx:
			err += dx
			y += sy
	return cells
