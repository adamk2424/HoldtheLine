class_name IsometricCamera
extends Node3D
## IsometricCamera - WASD pan, scroll zoom, edge pan for isometric 3D view.

@export var pan_speed: float = 20.0
@export var zoom_speed: float = 2.0
@export var min_zoom: float = 10.0
@export var max_zoom: float = 60.0
@export var edge_pan_margin: float = 20.0  # pixels from screen edge
@export var edge_pan_enabled: bool = true

var camera: Camera3D
var _current_zoom: float = 30.0
var _target_zoom: float = 30.0

# Camera angle: isometric (roughly 45 degrees down, rotated 45 degrees)
const CAMERA_ANGLE_X: float = -45.0
const CAMERA_ANGLE_Y: float = -45.0

# Map bounds
const MAP_MIN: float = 0.0
const MAP_MAX: float = 300.0


func _ready() -> void:
	# Start at map center
	position = Vector3(150.0, 0.0, 150.0)

	# Create Camera3D child
	camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = 45.0
	camera.near = 0.1
	camera.far = 500.0
	camera.current = true
	add_child(camera)

	_update_camera_transform()

	# Load settings
	edge_pan_enabled = MetaProgress.edge_pan_enabled
	pan_speed = MetaProgress.camera_speed


func _process(delta: float) -> void:
	# Sync settings each frame so changes from the settings menu apply immediately
	edge_pan_enabled = MetaProgress.edge_pan_enabled
	pan_speed = MetaProgress.camera_speed

	_handle_pan(delta)
	_handle_zoom(delta)
	_handle_edge_pan(delta)
	_clamp_position()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_target_zoom = max(min_zoom, _target_zoom - zoom_speed * 2.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_target_zoom = min(max_zoom, _target_zoom + zoom_speed * 2.0)


func _handle_pan(delta: float) -> void:
	var input_dir := Vector2.ZERO
	if Input.is_action_pressed("move_up"):
		input_dir.y -= 1
	if Input.is_action_pressed("move_down"):
		input_dir.y += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1

	if input_dir != Vector2.ZERO:
		input_dir = input_dir.normalized()
		# Move relative to camera rotation (isometric)
		var forward := Vector3(-1, 0, 1).normalized()
		var right := Vector3(1, 0, 1).normalized()
		var move := (right * input_dir.x + forward * input_dir.y) * pan_speed * delta
		position += move


func _handle_zoom(delta: float) -> void:
	if Input.is_action_pressed("zoom_in"):
		_target_zoom = max(min_zoom, _target_zoom - zoom_speed * delta * 10.0)
	if Input.is_action_pressed("zoom_out"):
		_target_zoom = min(max_zoom, _target_zoom + zoom_speed * delta * 10.0)

	_current_zoom = lerp(_current_zoom, _target_zoom, 8.0 * delta)
	_update_camera_transform()


func _handle_edge_pan(delta: float) -> void:
	if not edge_pan_enabled:
		return
	var viewport := get_viewport()
	if not viewport:
		return
	var mouse_pos := viewport.get_mouse_position()
	var screen_size := viewport.get_visible_rect().size

	# In windowed mode, only edge-pan if the mouse is actually inside the window
	if not DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		if mouse_pos.x < 0 or mouse_pos.y < 0 or mouse_pos.x > screen_size.x or mouse_pos.y > screen_size.y:
			return

	var pan := Vector2.ZERO

	if mouse_pos.x < edge_pan_margin:
		pan.x -= 1
	elif mouse_pos.x > screen_size.x - edge_pan_margin:
		pan.x += 1
	if mouse_pos.y < edge_pan_margin:
		pan.y -= 1
	elif mouse_pos.y > screen_size.y - edge_pan_margin:
		pan.y += 1

	if pan != Vector2.ZERO:
		var forward := Vector3(-1, 0, 1).normalized()
		var right := Vector3(1, 0, 1).normalized()
		var move := (right * pan.x + forward * pan.y) * pan_speed * delta * 0.75
		position += move


func _update_camera_transform() -> void:
	if not camera:
		return
	camera.rotation_degrees = Vector3(CAMERA_ANGLE_X, CAMERA_ANGLE_Y, 0)
	# Position camera behind and above pivot
	var offset := Vector3(0, 0, _current_zoom)
	camera.position = offset.rotated(Vector3.RIGHT, deg_to_rad(CAMERA_ANGLE_X))
	camera.position = camera.position.rotated(Vector3.UP, deg_to_rad(CAMERA_ANGLE_Y))


func _clamp_position() -> void:
	position.x = clamp(position.x, MAP_MIN, MAP_MAX)
	position.z = clamp(position.z, MAP_MIN, MAP_MAX)
	position.y = 0


func screen_to_world(screen_pos: Vector2) -> Vector3:
	if not camera:
		return Vector3.ZERO
	var from := camera.project_ray_origin(screen_pos)
	var dir := camera.project_ray_normal(screen_pos)
	# Intersect with ground plane (y=0)
	if dir.y == 0:
		return Vector3.ZERO
	var t := -from.y / dir.y
	if t < 0:
		return Vector3.ZERO
	return from + dir * t


func focus_on(world_pos: Vector3) -> void:
	position = Vector3(world_pos.x, 0, world_pos.z)
	_clamp_position()
