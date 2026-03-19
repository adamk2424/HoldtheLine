extends PanelContainer
## Minimap - Shows 300x300 map as a small rectangle with entity dots and camera viewport.
## Green dots: player buildings/units. Red dots: enemies. Blue rectangle: camera viewport.
## Updates every 0.5 seconds.

var _draw_control: Control
var _update_timer: float = 0.0
const UPDATE_INTERVAL: float = 0.5
const MINIMAP_SIZE: float = 180.0
const MAP_WORLD_SIZE: float = 300.0


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	name = "Minimap"
	custom_minimum_size = Vector2(MINIMAP_SIZE + 8, MINIMAP_SIZE + 8)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.08, 0.95)
	style.border_color = Color(0.2, 0.5, 0.3, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(4)
	add_theme_stylebox_override("panel", style)

	_draw_control = Control.new()
	_draw_control.name = "MinimapDraw"
	_draw_control.custom_minimum_size = Vector2(MINIMAP_SIZE, MINIMAP_SIZE)
	_draw_control.draw.connect(_on_draw)
	add_child(_draw_control)


func _process(delta: float) -> void:
	_update_timer += delta
	if _update_timer >= UPDATE_INTERVAL:
		_update_timer -= UPDATE_INTERVAL
		_draw_control.queue_redraw()


func _world_to_minimap(world_pos: Vector3) -> Vector2:
	var x: float = (world_pos.x / MAP_WORLD_SIZE) * MINIMAP_SIZE
	var y: float = (world_pos.z / MAP_WORLD_SIZE) * MINIMAP_SIZE
	return Vector2(x, y)


func _on_draw() -> void:
	# Draw map background
	_draw_control.draw_rect(
		Rect2(Vector2.ZERO, Vector2(MINIMAP_SIZE, MINIMAP_SIZE)),
		Color(0.1, 0.12, 0.08, 1.0)
	)

	# Draw grid area (120x120 centered in 300x300)
	var grid_offset: float = (MAP_WORLD_SIZE - 120.0) / 2.0
	var grid_start := Vector2(grid_offset / MAP_WORLD_SIZE * MINIMAP_SIZE, grid_offset / MAP_WORLD_SIZE * MINIMAP_SIZE)
	var grid_size: float = (120.0 / MAP_WORLD_SIZE) * MINIMAP_SIZE
	_draw_control.draw_rect(
		Rect2(grid_start, Vector2(grid_size, grid_size)),
		Color(0.15, 0.18, 0.12, 0.5)
	)

	# Draw player buildings (green)
	var towers: Array = EntityRegistry.get_all("tower")
	var buildings: Array = EntityRegistry.get_all("building")
	var central: Array = EntityRegistry.get_all("central_tower")
	var barriers: Array = EntityRegistry.get_all("barrier")

	for entity: Node in central:
		if is_instance_valid(entity) and entity.is_inside_tree():
			var pos := _world_to_minimap(entity.global_position)
			_draw_control.draw_circle(pos, 4.0, Color(0.2, 0.6, 1.0))

	for entity: Node in towers:
		if is_instance_valid(entity) and entity.is_inside_tree():
			var pos := _world_to_minimap(entity.global_position)
			_draw_control.draw_circle(pos, 2.5, Color(0.2, 1.0, 0.3))

	for entity: Node in buildings:
		if is_instance_valid(entity) and entity.is_inside_tree():
			var pos := _world_to_minimap(entity.global_position)
			_draw_control.draw_circle(pos, 3.0, Color(0.3, 0.8, 0.4))

	for entity: Node in barriers:
		if is_instance_valid(entity) and entity.is_inside_tree():
			var pos := _world_to_minimap(entity.global_position)
			_draw_control.draw_rect(
				Rect2(pos - Vector2(1.5, 1.5), Vector2(3, 3)),
				Color(0.5, 0.5, 0.5)
			)

	# Draw player units (bright green)
	var units: Array = EntityRegistry.get_all("unit")
	for entity: Node in units:
		if is_instance_valid(entity) and entity.is_inside_tree():
			var pos := _world_to_minimap(entity.global_position)
			_draw_control.draw_circle(pos, 2.0, Color(0.4, 1.0, 0.4))

	# Draw enemies (red)
	var enemies: Array = EntityRegistry.get_all("enemy")
	for entity: Node in enemies:
		if is_instance_valid(entity) and entity.is_inside_tree():
			var pos := _world_to_minimap(entity.global_position)
			_draw_control.draw_circle(pos, 2.0, Color(1.0, 0.2, 0.2))

	# Draw camera viewport rectangle (blue)
	_draw_camera_rect()


func _draw_camera_rect() -> void:
	# Find the IsometricCamera in the scene tree
	var camera_nodes := get_tree().get_nodes_in_group("entities")
	var camera_pivot: Node3D = null

	# Look for the IsometricCamera node
	for node in get_tree().root.get_children():
		var found := _find_camera_pivot(node)
		if found:
			camera_pivot = found
			break

	if not camera_pivot:
		return

	var cam_pos := camera_pivot.global_position
	# Approximate visible area based on zoom
	var view_half_size: float = 25.0  # Approximate visible world units
	var top_left := _world_to_minimap(Vector3(cam_pos.x - view_half_size, 0, cam_pos.z - view_half_size))
	var size := Vector2(view_half_size * 2.0 / MAP_WORLD_SIZE * MINIMAP_SIZE, view_half_size * 2.0 / MAP_WORLD_SIZE * MINIMAP_SIZE)

	_draw_control.draw_rect(
		Rect2(top_left, size),
		Color(0.3, 0.5, 1.0, 0.6),
		false,
		1.5
	)


func _find_camera_pivot(node: Node) -> Node3D:
	if node is IsometricCamera:
		return node as Node3D
	for child in node.get_children():
		var result := _find_camera_pivot(child)
		if result:
			return result
	return null


func _gui_input(event: InputEvent) -> void:
	# Click on minimap to move camera
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local_pos: Vector2 = event.position - Vector2(4, 4)  # Account for margin
		var world_x: float = (local_pos.x / MINIMAP_SIZE) * MAP_WORLD_SIZE
		var world_z: float = (local_pos.y / MINIMAP_SIZE) * MAP_WORLD_SIZE

		var camera_pivot := _find_camera_pivot(get_tree().root)
		if camera_pivot and camera_pivot is IsometricCamera:
			camera_pivot.focus_on(Vector3(world_x, 0, world_z))
