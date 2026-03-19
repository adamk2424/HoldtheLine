class_name GameSession
extends Node3D
## GameSession - Orchestrates a single game run.
## Sets up the map, places starting buildings, manages game flow.

var game_map: GameMap
var build_grid: BuildGrid
var grid_cursor: GridCursor
var iso_camera: IsometricCamera
var spawn_manager: SpawnManager

# UI references
var hud: CanvasLayer
var build_menu: CanvasLayer
var pause_menu: CanvasLayer
var game_over_screen: CanvasLayer
var level_complete_screen: CanvasLayer
var intro_cinematic: CanvasLayer

# System node references
var resource_system: Node
var score_system: Node
var save_system: Node
var combat_system: Node
var spawn_system: Node
var difficulty_system: Node
var selection_system: Node
var command_system: Node
var population_system: Node
var corpse_system: Node
var upgrade_system: Node
var sell_system: Node

var _is_initialized: bool = false


func _ready() -> void:
	_setup_scene()
	_setup_ui()
	_setup_systems()
	_connect_signals()
	# Delay start to let everything initialize
	get_tree().create_timer(0.1).timeout.connect(_begin_intro)


func _setup_scene() -> void:
	# Create map
	var map_scene := preload("res://map/game_map.tscn")
	game_map = map_scene.instantiate()
	add_child(game_map)

	# Create build grid
	var grid_scene := preload("res://grid/build_grid.tscn")
	build_grid = grid_scene.instantiate()
	add_child(build_grid)

	# Wire build grid to game map for navmesh rebuilding
	game_map.build_grid = build_grid

	# Create grid cursor
	var cursor_scene := preload("res://grid/grid_cursor.tscn")
	grid_cursor = cursor_scene.instantiate()
	build_grid.add_child(grid_cursor)

	# Create camera
	var camera_scene := preload("res://camera/isometric_camera.tscn")
	iso_camera = camera_scene.instantiate()
	add_child(iso_camera)

	# Focus camera on grid center
	iso_camera.focus_on(build_grid.get_grid_center_world())

	# Create spawn manager
	spawn_manager = SpawnManager.new()
	spawn_manager.name = "SpawnManager"
	add_child(spawn_manager)


func _setup_ui() -> void:
	# HUD
	var hud_scene := preload("res://ui/hud/hud.tscn")
	hud = hud_scene.instantiate()
	add_child(hud)

	# Build Menu
	var build_menu_scene := preload("res://ui/build_menu/build_menu.tscn")
	build_menu = build_menu_scene.instantiate()
	add_child(build_menu)

	# Pause Menu
	var PauseMenuScript := preload("res://ui/menus/pause_menu.gd")
	pause_menu = CanvasLayer.new()
	pause_menu.set_script(PauseMenuScript)
	pause_menu.name = "PauseMenu"
	add_child(pause_menu)

	# Game Over Screen
	var GameOverScript := preload("res://ui/menus/game_over_screen.gd")
	game_over_screen = CanvasLayer.new()
	game_over_screen.set_script(GameOverScript)
	game_over_screen.name = "GameOverScreen"
	add_child(game_over_screen)

	# Level Complete Screen
	var LevelCompleteScript := preload("res://ui/menus/level_complete_screen.gd")
	level_complete_screen = CanvasLayer.new()
	level_complete_screen.set_script(LevelCompleteScript)
	level_complete_screen.name = "LevelCompleteScreen"
	level_complete_screen.layer = 26  # Above game over screen
	add_child(level_complete_screen)

	# Intro Cinematic
	var IntroScript := preload("res://ui/cinematic/intro_cinematic.gd")
	intro_cinematic = CanvasLayer.new()
	intro_cinematic.set_script(IntroScript)
	intro_cinematic.name = "IntroCinematic"
	add_child(intro_cinematic)

	print("[GameSession] UI initialized")


func _setup_systems() -> void:
	# Instantiate all game systems as children of GameSession.
	# Uses file_exists checks to gracefully handle missing scripts during parallel development.
	var system_defs: Array = [
		["ResourceSystem", "res://systems/resource_system.gd"],
		["ScoreSystem", "res://systems/score_system.gd"],
		["SaveSystem", "res://systems/save_system.gd"],
		["CombatSystem", "res://systems/combat_system.gd"],
		["SpawnSystem", "res://systems/spawn_system.gd"],
		["DifficultySystem", "res://systems/difficulty_system.gd"],
		["SelectionSystem", "res://systems/selection_system.gd"],
		["CommandSystem", "res://systems/command_system.gd"],
		["PopulationSystem", "res://systems/population_system.gd"],
		["CorpseSystem", "res://systems/corpse_system.gd"],
		["UpgradeSystem", "res://systems/upgrade_system.gd"],
		["SellSystem", "res://systems/sell_system.gd"],
	]

	for def: Array in system_defs:
		var sys_name: String = def[0]
		var sys_path: String = def[1]
		var node := _try_load_system(sys_name, sys_path)
		if node:
			match sys_name:
				"ResourceSystem": resource_system = node
				"ScoreSystem": score_system = node
				"SaveSystem": save_system = node
				"CombatSystem": combat_system = node
				"SpawnSystem": spawn_system = node
				"DifficultySystem": difficulty_system = node
				"SelectionSystem": selection_system = node
				"CommandSystem": command_system = node
				"PopulationSystem": population_system = node
				"CorpseSystem": corpse_system = node
				"UpgradeSystem": upgrade_system = node
				"SellSystem": sell_system = node

	# Wire cross-system references
	_wire_system_references()

	print("[GameSession] Systems initialized")


func _try_load_system(sys_name: String, script_path: String) -> Node:
	if not ResourceLoader.exists(script_path):
		print("[GameSession] System script not found (skipping): %s" % script_path)
		return null

	var script := load(script_path)
	if script == null:
		push_warning("[GameSession] Failed to load system script: %s" % script_path)
		return null

	var node := Node.new()
	node.set_script(script)
	node.name = sys_name
	add_child(node)
	return node


func _wire_system_references() -> void:
	# SpawnSystem needs access to SpawnManager for spawn positions
	if spawn_system and "spawn_manager" in spawn_system:
		spawn_system.spawn_manager = spawn_manager

	# DifficultySystem needs access to SpawnSystem for boss spawning
	if difficulty_system and "spawn_system" in difficulty_system and spawn_system:
		difficulty_system.spawn_system = spawn_system

	# SellSystem needs BuildGrid to free cells on sell
	if sell_system and sell_system.has_method("set_build_grid"):
		sell_system.set_build_grid(build_grid)


func _connect_signals() -> void:
	GameBus.central_tower_destroyed.connect(_on_central_tower_destroyed)
	GameBus.game_over.connect(_on_game_over)
	GameBus.build_requested.connect(_on_build_requested)
	GameBus.level_completed.connect(_on_level_completed)


func _on_build_requested(entity_id: String, grid_pos: Vector2i, size: int) -> void:
	print("[GameSession] Build requested: %s at %s size %d" % [entity_id, grid_pos, size])
	_place_entity(entity_id, grid_pos, size)


func _begin_intro() -> void:
	GameState.reset_state()
	_place_starting_buildings()
	_place_starting_walls()

	# Play intro cinematic, then start game
	if intro_cinematic:
		var base_center: Vector3 = build_grid.get_grid_center_world()
		intro_cinematic.cinematic_finished.connect(_start_game)
		intro_cinematic.play(iso_camera, base_center)
	else:
		_start_game()


func _start_game() -> void:
	GameState.is_game_active = true
	GameBus.game_started.emit()
	_is_initialized = true
	print("[GameSession] Game started!")


func _place_starting_buildings() -> void:
	# Place Central Tower at grid center
	var center := Vector2i(BuildGrid.GRID_SIZE / 2 - 1, BuildGrid.GRID_SIZE / 2 - 1)  # 3x3
	_place_entity("central_tower", center, 3)

	# Place 3 starting production buildings nearby
	_place_entity("drone_printer", Vector2i(center.x - 4, center.y), 2)
	_place_entity("mech_bay", Vector2i(center.x + 4, center.y - 1), 3)
	_place_entity("war_factory", Vector2i(center.x, center.y + 5), 3)

	# Place 12 autocannon turrets equally spaced around the outer walls
	_place_perimeter_turrets(center)

	# Place 4 of each decorative building inside the base
	_place_decorative_buildings(center)

	print("[GameSession] Starting buildings placed")


func _place_perimeter_turrets(center: Vector2i) -> void:
	## Place 12 autocannons equally spaced around the hexagonal wall perimeter.
	## The hex wall has half-width 32 and half-height 32, quarter-width 16.
	## We place turrets just inside the wall on all 6 edges (2 per edge).
	## Positions are computed by interpolating along each hex edge, then offset inward.
	var hw: int = 32
	var hh: int = 32
	var qw: int = 16

	# 6 vertices of the hex (same as wall, flat-top orientation), slightly inset
	var inset: int = 3
	var v: Array[Vector2] = [
		Vector2(center.x - qw, center.y - hh) + Vector2(inset, inset),       # 0 top-left
		Vector2(center.x + qw, center.y - hh) + Vector2(-inset, inset),      # 1 top-right
		Vector2(center.x + hw, center.y) + Vector2(-inset, 0),               # 2 right
		Vector2(center.x + qw, center.y + hh) + Vector2(-inset, -inset),     # 3 bottom-right
		Vector2(center.x - qw, center.y + hh) + Vector2(inset, -inset),      # 4 bottom-left
		Vector2(center.x - hw, center.y) + Vector2(inset, 0),                # 5 left
	]

	# Place 2 turrets per edge at 1/3 and 2/3 along each edge
	var turret_positions: Array[Vector2i] = []
	for i in range(6):
		var a := v[i]
		var b := v[(i + 1) % 6]
		turret_positions.append(Vector2i(roundi(a.x + (b.x - a.x) / 3.0), roundi(a.y + (b.y - a.y) / 3.0)))
		turret_positions.append(Vector2i(roundi(a.x + 2.0 * (b.x - a.x) / 3.0), roundi(a.y + 2.0 * (b.y - a.y) / 3.0)))

	for pos in turret_positions:
		_place_entity("autocannon", pos, 1, true)

	print("[GameSession] 12 autocannon turrets placed around perimeter")


func _place_decorative_buildings(center: Vector2i) -> void:
	## Place 4 each of Barracks (3x2), Warehouse (3x2), Office (2x2)
	## scattered inside the base to fill it out.

	# Barracks - 4 placed in a ring around the center
	_place_entity("barracks", Vector2i(center.x - 12, center.y - 8), 3)
	_place_entity("barracks", Vector2i(center.x + 10, center.y - 8), 3)
	_place_entity("barracks", Vector2i(center.x - 12, center.y + 8), 3)
	_place_entity("barracks", Vector2i(center.x + 10, center.y + 8), 3)

	# Warehouses - 4 placed at intermediate positions
	_place_entity("warehouse", Vector2i(center.x - 8, center.y - 15), 3)
	_place_entity("warehouse", Vector2i(center.x + 6, center.y - 15), 3)
	_place_entity("warehouse", Vector2i(center.x - 8, center.y + 14), 3)
	_place_entity("warehouse", Vector2i(center.x + 6, center.y + 14), 3)

	# Offices - 4 placed in gaps
	_place_entity("office", Vector2i(center.x - 16, center.y - 2), 2)
	_place_entity("office", Vector2i(center.x + 15, center.y - 2), 2)
	_place_entity("office", Vector2i(center.x - 3, center.y - 12), 2)
	_place_entity("office", Vector2i(center.x - 3, center.y + 11), 2)

	print("[GameSession] Decorative buildings placed (4 barracks, 4 warehouses, 4 offices)")

	# Depots and containers in the outer zone (between inner buildings and walls)
	_place_outer_zone_structures(center)


func _place_outer_zone_structures(center: Vector2i) -> void:
	## Place 25 depots (2x2) and 25 containers (1x1) scattered in the outer zone
	## between ~15-28 tiles from center, filling the space before the walls.

	# Depot positions (2x2) - spread around all directions, 25% closer to center
	var depot_positions: Array[Vector2i] = [
		# North sector
		Vector2i(center.x - 8, center.y - 19),
		Vector2i(center.x + 4, center.y - 21),
		Vector2i(center.x + 11, center.y - 17),
		Vector2i(center.x - 2, center.y - 24),
		# Northeast sector
		Vector2i(center.x + 15, center.y - 14),
		Vector2i(center.x + 21, center.y - 5),
		# East sector
		Vector2i(center.x + 17, center.y - 8),
		Vector2i(center.x + 19, center.y + 4),
		Vector2i(center.x + 15, center.y + 11),
		Vector2i(center.x + 23, center.y + 0),
		# South sector
		Vector2i(center.x + 6, center.y + 19),
		Vector2i(center.x - 4, center.y + 21),
		Vector2i(center.x - 11, center.y + 17),
		Vector2i(center.x + 2, center.y + 25),
		# Southwest sector
		Vector2i(center.x - 15, center.y + 14),
		Vector2i(center.x - 21, center.y + 5),
		# West sector
		Vector2i(center.x - 17, center.y + 6),
		Vector2i(center.x - 19, center.y - 4),
		Vector2i(center.x - 15, center.y - 11),
		Vector2i(center.x - 23, center.y + 0),
		# Diagonals / fill
		Vector2i(center.x - 14, center.y - 15),
		Vector2i(center.x + 14, center.y + 15),
		Vector2i(center.x - 9, center.y + 23),
		Vector2i(center.x + 9, center.y - 23),
		Vector2i(center.x + 20, center.y + 8),
	]

	for pos in depot_positions:
		_place_entity("depot", pos, 2)

	# Container positions (1x1) - smaller, scattered in gaps, 25% closer to center
	var container_positions: Array[Vector2i] = [
		# North
		Vector2i(center.x - 5, center.y - 23),
		Vector2i(center.x + 8, center.y - 20),
		Vector2i(center.x - 11, center.y - 18),
		Vector2i(center.x + 2, center.y - 26),
		Vector2i(center.x - 6, center.y - 26),
		# Northeast
		Vector2i(center.x + 18, center.y - 6),
		Vector2i(center.x + 17, center.y - 11),
		# East
		Vector2i(center.x + 21, center.y + 2),
		Vector2i(center.x + 17, center.y + 9),
		Vector2i(center.x + 24, center.y - 2),
		# Southeast
		Vector2i(center.x + 12, center.y + 18),
		Vector2i(center.x + 2, center.y + 23),
		Vector2i(center.x + 8, center.y + 21),
		# South
		Vector2i(center.x - 8, center.y + 20),
		Vector2i(center.x - 14, center.y + 18),
		Vector2i(center.x - 2, center.y + 26),
		Vector2i(center.x + 6, center.y + 26),
		# Southwest
		Vector2i(center.x - 18, center.y + 9),
		Vector2i(center.x - 17, center.y + 14),
		# West
		Vector2i(center.x - 21, center.y + 2),
		Vector2i(center.x - 18, center.y - 6),
		Vector2i(center.x - 15, center.y + 11),
		Vector2i(center.x - 24, center.y + 2),
		# Northwest
		Vector2i(center.x - 12, center.y - 21),
		Vector2i(center.x - 8, center.y - 27),
	]

	for pos in container_positions:
		_place_entity("container", pos, 1)

	print("[GameSession] Outer zone: 25 depots + 25 containers placed")


func _place_starting_walls() -> void:
	# Place a hexagonal perimeter of wall_basic barriers around the base area.
	# 65 units wide x 65 units tall, 1 wall thick.
	var center := Vector2i(BuildGrid.GRID_SIZE / 2 - 1, BuildGrid.GRID_SIZE / 2 - 1)
	var placed := {}  # Track placed positions to avoid duplicates

	for layer in range(1):
		var half_w: int = 32 - layer
		var half_h: int = 32 - layer
		var quarter_w: int = 16 - layer

		# 6 vertices of the hexagon (flat-top orientation)
		var vertices: Array[Vector2i] = [
			Vector2i(center.x - quarter_w, center.y - half_h),  # top-left
			Vector2i(center.x + quarter_w, center.y - half_h),  # top-right
			Vector2i(center.x + half_w, center.y),              # right
			Vector2i(center.x + quarter_w, center.y + half_h),  # bottom-right
			Vector2i(center.x - quarter_w, center.y + half_h),  # bottom-left
			Vector2i(center.x - half_w, center.y),              # left
		]

		# Draw walls along each edge
		for i in range(6):
			var from := vertices[i]
			var to := vertices[(i + 1) % 6]
			var cells := _get_line_cells(from, to)
			for cell in cells:
				if not placed.has(cell):
					placed[cell] = true
					_place_entity("wall_basic", cell, 1)

	print("[GameSession] Starting hexagonal wall perimeter placed")


func _get_line_cells(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var dx := absi(to.x - from.x)
	var dy := absi(to.y - from.y)
	var sx: int = 1 if from.x < to.x else -1
	var sy: int = 1 if from.y < to.y else -1
	var err := dx - dy
	var x := from.x
	var y := from.y

	while true:
		cells.append(Vector2i(x, y))
		if x == to.x and y == to.y:
			break
		var e2 := 2 * err
		if e2 > -dy:
			err -= dy
			x += sx
		if e2 < dx:
			err += dx
			y += sy

	return cells


func _place_entity(entity_id: String, grid_pos: Vector2i, size: int, pre_built: bool = false) -> void:
	if not build_grid.is_cell_free(grid_pos, size):
		push_warning("[GameSession] Cannot place %s at %s - cells occupied" % [entity_id, grid_pos])
		return

	var data := GameData.get_entity_data(entity_id)
	if data.is_empty():
		push_warning("[GameSession] No data found for: %s" % entity_id)
		return

	# Create entity using the appropriate specialized class
	var entity: EntityBase
	var category: String = data.get("category", "")
	if entity_id == "central_tower":
		entity = CentralTower.new()
	elif category == "offensive":
		entity = TowerOffensive.new()
	elif category == "resource":
		entity = TowerResource.new()
	elif category == "support":
		entity = TowerSupport.new()
	elif entity_id.begins_with("wall_"):
		entity = BarrierWall.new()
	elif entity_id.begins_with("barrier_") or entity_id == "energy_barrier":
		entity = BarrierEnergy.new()
	elif entity_id.begins_with("wire_"):
		entity = BarrierWire.new()
	elif _is_production_building(entity_id):
		entity = _create_production_building(entity_id)
	else:
		entity = EntityBase.new()
	entity.name = entity_id + "_" + str(randi())
	var world_pos := build_grid.grid_to_world(grid_pos, size)
	entity.position = world_pos
	entity.grid_position = grid_pos
	entity.grid_size = size

	# Add health component
	var health := HealthComponent.new()
	health.name = "HealthComponent"
	entity.add_child(health)

	# Add combat component if entity has damage
	if data.get("damage", 0) > 0:
		var combat := CombatComponent.new()
		combat.name = "CombatComponent"
		entity.add_child(combat)

	# Add buff/debuff component
	var buff := BuffDebuffComponent.new()
	buff.name = "BuffDebuffComponent"
	entity.add_child(buff)

	# Add collision body so enemies cannot walk through structures
	var body := StaticBody3D.new()
	body.name = "CollisionBody"
	body.collision_layer = 2  # buildings layer
	body.collision_mask = 0
	var col_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	var col_width: float = size * build_grid.CELL_SIZE
	var mesh_scale: Variant = data.get("mesh_scale", [1.0, 1.0, 1.0])
	var col_height: float = 2.0
	if mesh_scale is Array and mesh_scale.size() >= 2:
		col_height = max(1.0, float(mesh_scale[1]))
	box.size = Vector3(col_width, col_height, col_width)
	col_shape.shape = box
	col_shape.position = Vector3(0.0, col_height / 2.0, 0.0)
	body.add_child(col_shape)
	entity.add_child(body)

	add_child(entity)

	# Determine entity type
	var entity_type := "building"
	if entity_id == "central_tower":
		entity_type = "central_tower"
	elif entity_id.begins_with("wall_") or entity_id.begins_with("barrier_") or entity_id.begins_with("wire_"):
		entity_type = "barrier"
	elif data.get("category", "") in ["offensive", "resource", "support"]:
		entity_type = "tower"

	# Give the entity a reference to the build grid so it can free cells on death
	if "build_grid" in entity:
		entity.build_grid = build_grid

	entity.initialize(entity_id, entity_type, data)
	build_grid.occupy_cells(grid_pos, size, entity.get_instance_id())
	print("[GameSession] Placed %s at world pos %s, visual=%s, is_building=%s" % [entity_id, entity.position, entity.visual_node != null, entity.get("is_building")])


	# Skip build animation for pre-placed starting structures
	if pre_built and entity is TowerBase:
		entity.is_building = false
		entity.is_built = true
		entity.build_timer = entity.build_time
		if entity.visual_node:
			entity.visual_node.scale = Vector3.ONE
		if entity.health_bar:
			entity.health_bar.visible = false
		if entity.combat_component:
			entity.combat_component.is_active = true
		if entity.health_component:
			entity.health_component.is_invulnerable = false

	GameBus.build_completed.emit(entity, entity_id, grid_pos)


func _is_production_building(entity_id: String) -> bool:
	return not GameData.get_production_building(entity_id).is_empty()


func _create_production_building(entity_id: String) -> ProductionBuildingBase:
	match entity_id:
		"drone_printer":
			var script := load("res://entities/buildings/drone_printer.gd")
			return script.new() as ProductionBuildingBase
		"mech_bay":
			var script := load("res://entities/buildings/mech_bay.gd")
			return script.new() as ProductionBuildingBase
		"war_factory":
			var script := load("res://entities/buildings/war_factory.gd")
			return script.new() as ProductionBuildingBase
		_:
			return ProductionBuildingBase.new()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("speed_slow"):
		GameState.set_game_speed(0.75)
	elif event.is_action_pressed("speed_normal"):
		GameState.set_game_speed(1.0)
	elif event.is_action_pressed("speed_fast"):
		GameState.set_game_speed(1.25)
	elif event.is_action_pressed("pause_game"):
		if GameState.is_paused:
			get_tree().paused = false
			GameState.is_paused = false
			GameBus.game_resumed.emit()
		elif GameState.is_game_active:
			get_tree().paused = true
			GameState.is_paused = true
			GameBus.game_paused.emit()


func _on_central_tower_destroyed() -> void:
	GameBus.game_over.emit(GameState.game_time)


func _on_level_completed(level_id: String, rewards: Dictionary) -> void:
	GameState.is_game_active = false
	MetaProgress.record_game_result(GameState.game_time, GameState.enemies_killed)
	
	# Show level complete screen instead of game over
	var level_data := LevelSystem.get_level_data(level_id)
	if level_complete_screen and level_complete_screen.has_method("show_level_complete"):
		level_complete_screen.show_level_complete(level_data, rewards, GameState.game_time)
		level_complete_screen.continue_requested.connect(_return_to_level_select)
		level_complete_screen.replay_requested.connect(_replay_level)
	
	print("[GameSession] Level Complete! %s - Time: %s, Kills: %d" % [
		level_data.get("name", level_id), GameState.get_game_time_formatted(), GameState.enemies_killed
	])


func _return_to_level_select() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _replay_level() -> void:
	# Restart current level
	var current_level := GameState.selected_level_id
	GameState.reset_state()
	GameState.selected_level_id = current_level
	get_tree().reload_current_scene()


func _on_game_over(_survival_time: float) -> void:
	GameState.is_game_active = false
	MetaProgress.record_game_result(_survival_time, GameState.enemies_killed)
	print("[GameSession] Game Over! Time: %s, Kills: %d" % [
		GameState.get_game_time_formatted(), GameState.enemies_killed
	])
