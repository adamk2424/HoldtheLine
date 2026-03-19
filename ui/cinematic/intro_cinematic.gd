extends CanvasLayer
## IntroCinematic - Full intro sequence with dropship takeoff, camera pan, and base orbit.
## Phase 1 (0-6s): Dropship lifts off, camera follows it up as it flies away.
## Phase 2 (6-9s): First text fades in/out over dark overlay.
## Phase 3 (9-15s): Camera orbits base from above, second text fades in/out.
## Skippable via click or any key.

signal cinematic_finished

# UI elements
var _overlay: ColorRect
var _text_label_1: Label
var _text_label_2: Label
var _skip_label: Label

# 3D elements
var _cinematic_camera: Camera3D
var _dropship: Node3D
var _engine_light: OmniLight3D

# References
var _iso_camera: IsometricCamera
var _scene_root: Node3D
var _base_center: Vector3

# State
var _tween: Tween = null
var _is_playing: bool = false
var _is_finished: bool = false
var _track_dropship: bool = false
var _orbit_active: bool = false
var _orbit_angle: float = 0.0

const ORBIT_RADIUS: float = 60.0
const ORBIT_HEIGHT: float = 50.0
const ORBIT_SPEED: float = 0.5

const LINE_1: String = "The last dropships have departed."
const LINE_2: String = "You are all that is left. You must Survive."


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()


func _build_ui() -> void:
	# Full-screen overlay (starts transparent, used for text background)
	_overlay = ColorRect.new()
	_overlay.name = "CinematicOverlay"
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	_overlay.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_overlay)

	# First line of text
	_text_label_1 = Label.new()
	_text_label_1.text = LINE_1
	_text_label_1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text_label_1.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_text_label_1.set_anchors_preset(Control.PRESET_CENTER)
	_text_label_1.offset_left = -400
	_text_label_1.offset_right = 400
	_text_label_1.offset_top = -40
	_text_label_1.offset_bottom = 10
	_text_label_1.add_theme_font_size_override("font_size", 28)
	_text_label_1.add_theme_color_override("font_color", Color(0.7, 0.8, 0.7))
	_text_label_1.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	_text_label_1.add_theme_constant_override("shadow_offset_x", 2)
	_text_label_1.add_theme_constant_override("shadow_offset_y", 2)
	_text_label_1.modulate.a = 0.0
	add_child(_text_label_1)

	# Second line of text
	_text_label_2 = Label.new()
	_text_label_2.text = LINE_2
	_text_label_2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text_label_2.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_text_label_2.set_anchors_preset(Control.PRESET_CENTER)
	_text_label_2.offset_left = -400
	_text_label_2.offset_right = 400
	_text_label_2.offset_top = -40
	_text_label_2.offset_bottom = 10
	_text_label_2.add_theme_font_size_override("font_size", 24)
	_text_label_2.add_theme_color_override("font_color", Color(0.9, 0.6, 0.3))
	_text_label_2.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	_text_label_2.add_theme_constant_override("shadow_offset_x", 2)
	_text_label_2.add_theme_constant_override("shadow_offset_y", 2)
	_text_label_2.modulate.a = 0.0
	add_child(_text_label_2)

	# Skip hint
	_skip_label = Label.new()
	_skip_label.text = "Click or press any key to skip"
	_skip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_skip_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_skip_label.offset_left = -150
	_skip_label.offset_right = 150
	_skip_label.offset_top = -50
	_skip_label.offset_bottom = -20
	_skip_label.add_theme_font_size_override("font_size", 14)
	_skip_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	_skip_label.modulate.a = 0.0
	add_child(_skip_label)


func play(camera: IsometricCamera, base_center: Vector3) -> void:
	_iso_camera = camera
	_base_center = base_center
	_scene_root = camera.get_parent()

	# Disable player camera control during cinematic
	_iso_camera.set_process(false)
	_iso_camera.set_process_unhandled_input(false)

	# Create a dedicated cinematic camera
	_cinematic_camera = Camera3D.new()
	_cinematic_camera.name = "CinematicCamera"
	_cinematic_camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	_cinematic_camera.fov = 50.0
	_cinematic_camera.near = 0.1
	_cinematic_camera.far = 500.0
	_cinematic_camera.current = true
	_scene_root.add_child(_cinematic_camera)

	_create_dropship()

	_is_playing = true
	_is_finished = false
	visible = true

	_run_sequence()


func _create_dropship() -> void:
	_dropship = Node3D.new()
	_dropship.name = "Dropship"

	var model_path := "res://assets/models/dropship.glb"
	var model: Node3D = null

	# Try standard ResourceLoader first (works when Godot has imported the .glb)
	if ResourceLoader.exists(model_path):
		var dropship_scene: PackedScene = load(model_path) as PackedScene
		if dropship_scene:
			model = dropship_scene.instantiate()

	# Fallback: load GLB at runtime via GLTFDocument (bypasses import system)
	if not model:
		var gltf_doc := GLTFDocument.new()
		var gltf_state := GLTFState.new()
		var err := gltf_doc.append_from_file(ProjectSettings.globalize_path(model_path), gltf_state)
		if err == OK:
			model = gltf_doc.generate_scene(gltf_state)

	if model:
		model.scale = Vector3(0.8, 0.8, 0.8)
		model.rotation_degrees.y = -45.0  # Orient toward flight direction (+X, +Z)
		_dropship.add_child(model)
	else:
		push_warning("[IntroCinematic] Could not load dropship model, using fallback box")
		var fallback := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(2.5, 1.2, 5.0)
		fallback.mesh = box
		_dropship.add_child(fallback)

	# Engine glow light
	_engine_light = OmniLight3D.new()
	_engine_light.position = Vector3(0, -0.3, -3.0)
	_engine_light.light_color = Color(0.9, 0.5, 0.1)
	_engine_light.light_energy = 3.0
	_engine_light.omni_range = 6.0
	_dropship.add_child(_engine_light)

	# Position dropship near base on the ground
	_dropship.position = _base_center + Vector3(8.0, 5.0, 8.0)
	_scene_root.add_child(_dropship)


func _run_sequence() -> void:
	var dropship_start: Vector3 = _dropship.position
	# Camera starts offset from dropship, looking at it from the side
	var cam_start: Vector3 = dropship_start + Vector3(-18.0, 4.0, -12.0)
	_cinematic_camera.position = cam_start
	_cinematic_camera.look_at(dropship_start)

	_tween = create_tween()

	# Show skip hint
	_tween.tween_property(_skip_label, "modulate:a", 0.5, 0.5)

	# === Phase 1: Dropship takeoff (0-6s) ===
	_tween.tween_callback(func() -> void: _track_dropship = true)

	# Dropship lifts off slowly then accelerates upward and away
	var dropship_end: Vector3 = _base_center + Vector3(40.0, 90.0, 40.0)
	_tween.parallel().tween_property(
		_dropship, "position", dropship_end, 5.5
	).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)

	# Camera rises to follow the departing ship
	var cam_follow: Vector3 = cam_start + Vector3(5.0, 50.0, 5.0)
	_tween.parallel().tween_property(
		_cinematic_camera, "position", cam_follow, 5.5
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

	# Engine intensifies during takeoff
	_tween.parallel().tween_property(_engine_light, "light_energy", 10.0, 3.0)

	# End of Phase 1 - stop tracking, hide dropship
	_tween.tween_callback(func() -> void:
		_track_dropship = false
		_dropship.visible = false
	)

	# === Phase 2: First text (6-9s) ===
	# Darken overlay for text readability
	_tween.tween_property(_overlay, "color:a", 0.7, 1.0)

	# Fade in text 1
	_tween.tween_property(_text_label_1, "modulate:a", 1.0, 1.0)

	# Hold
	_tween.tween_interval(1.8)

	# Fade out text 1
	_tween.tween_property(_text_label_1, "modulate:a", 0.0, 1.0)

	# === Phase 3: Base orbit + second text (9-15s) ===
	# Lighten overlay so base is visible, start orbit
	_tween.tween_property(_overlay, "color:a", 0.25, 1.0)
	_tween.tween_callback(_start_orbit)

	# Brief pause to let orbit establish
	_tween.tween_interval(0.5)

	# Fade in text 2
	_tween.tween_property(_text_label_2, "modulate:a", 1.0, 1.25)

	# Hold while orbiting
	_tween.tween_interval(3.0)

	# Fade out text 2, overlay, and skip label together
	_tween.tween_property(_text_label_2, "modulate:a", 0.0, 1.25)
	_tween.parallel().tween_property(_overlay, "color:a", 0.0, 1.25)
	_tween.parallel().tween_property(_skip_label, "modulate:a", 0.0, 0.75)

	# Brief settle before handing off
	_tween.tween_interval(0.3)

	# Done
	_tween.tween_callback(_finish)


func _start_orbit() -> void:
	_orbit_active = true
	_orbit_angle = 0.0
	_update_orbit_position()


func _update_orbit_position() -> void:
	if not _cinematic_camera:
		return
	var x: float = _base_center.x + cos(_orbit_angle) * ORBIT_RADIUS
	var z: float = _base_center.z + sin(_orbit_angle) * ORBIT_RADIUS
	_cinematic_camera.position = Vector3(x, ORBIT_HEIGHT, z)
	_cinematic_camera.look_at(_base_center + Vector3(0, 2, 0))


func _process(delta: float) -> void:
	if not _is_playing:
		return

	if _track_dropship and _dropship and _cinematic_camera:
		_cinematic_camera.look_at(_dropship.position)

	if _orbit_active and _cinematic_camera:
		_orbit_angle += ORBIT_SPEED * delta
		_update_orbit_position()


func _finish() -> void:
	if _is_finished:
		return
	_is_finished = true
	_is_playing = false
	_track_dropship = false
	_orbit_active = false

	# Clean up 3D elements
	if _dropship:
		_dropship.queue_free()
		_dropship = null
	if _cinematic_camera:
		_cinematic_camera.queue_free()
		_cinematic_camera = null

	# Restore player camera
	if _iso_camera:
		_iso_camera.set_process(true)
		_iso_camera.set_process_unhandled_input(true)
		if _iso_camera.camera:
			_iso_camera.camera.current = true

	visible = false
	cinematic_finished.emit()


func skip() -> void:
	if _is_finished:
		return
	if _tween and _tween.is_valid():
		_tween.kill()
	_overlay.color.a = 0.0
	_text_label_1.modulate.a = 0.0
	_text_label_2.modulate.a = 0.0
	_skip_label.modulate.a = 0.0
	_finish()


func _input(event: InputEvent) -> void:
	if not _is_playing:
		return
	if event is InputEventMouseButton and event.pressed:
		skip()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed:
		skip()
		get_viewport().set_input_as_handled()
