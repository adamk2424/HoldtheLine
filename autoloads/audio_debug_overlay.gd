extends Node
## AudioDebugOverlay - Shows floating WAV filename labels at active 3D emitters.
## Toggle with F3. Attenuation radius toggle with Shift+F3.
## Only active when AudioManager.LIVE_TOOL_ENABLED is true.

var _enabled: bool = false
var _show_radius: bool = false
var _labels: Dictionary = {}  # player instance_id -> { label: Label3D, timer: float }
var _radius_meshes: Dictionary = {}  # player instance_id -> MeshInstance3D
const LINGER_TIME: float = 1.0


func _ready() -> void:
	if not AudioManager.LIVE_TOOL_ENABLED:
		set_process(false)
		set_process_input(false)
		return
	set_process(true)


func _input(event: InputEvent) -> void:
	if not AudioManager.LIVE_TOOL_ENABLED:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F3:
			if event.shift_pressed:
				_show_radius = not _show_radius
				_update_radius_visibility()
			else:
				_enabled = not _enabled
				if not _enabled:
					_clear_all()
				print("[AudioDebugOverlay] %s" % ("ON" if _enabled else "OFF"))


func _process(delta: float) -> void:
	if not _enabled:
		return

	var scene := get_tree().current_scene
	if not scene or not scene is Node3D:
		return

	var emitters := AudioManager.get_active_3d_emitters()
	var active_ids: Dictionary = {}

	for emitter in emitters:
		var player: AudioStreamPlayer3D = emitter["player"]
		var file: String = emitter["file"]
		var pid: int = player.get_instance_id()
		active_ids[pid] = true

		if _labels.has(pid):
			# Update position and reset timer
			var entry: Dictionary = _labels[pid]
			entry["label"].global_position = player.global_position + Vector3(0, 1.5, 0)
			entry["label"].text = file
			entry["timer"] = LINGER_TIME
			if _radius_meshes.has(pid):
				_radius_meshes[pid].global_position = player.global_position
		else:
			# Create new label
			var label := Label3D.new()
			label.text = file
			label.font_size = 32
			label.pixel_size = 0.01
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			label.no_depth_test = true
			label.modulate = Color(1, 1, 1, 0.9)
			label.global_position = player.global_position + Vector3(0, 1.5, 0)
			scene.add_child(label)
			_labels[pid] = {"label": label, "timer": LINGER_TIME}

			if _show_radius:
				_create_radius_mesh(pid, player)

	# Update linger timers for labels not currently active
	var to_remove: Array[int] = []
	for pid in _labels:
		if not active_ids.has(pid):
			_labels[pid]["timer"] -= delta
			if _labels[pid]["timer"] <= 0.0:
				to_remove.append(pid)
			else:
				var t: float = _labels[pid]["timer"] / LINGER_TIME
				_labels[pid]["label"].modulate.a = t

	for pid in to_remove:
		_remove_label(pid)


func _create_radius_mesh(pid: int, player: AudioStreamPlayer3D) -> void:
	var scene := get_tree().current_scene
	if not scene:
		return
	var mesh_instance := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = player.max_distance
	sphere.height = player.max_distance * 2.0
	sphere.radial_segments = 16
	sphere.rings = 8
	mesh_instance.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.3, 0.9, 0.5, 0.05)
	mat.cull_mode = BaseMaterial3D.CULL_FRONT
	mat.no_depth_test = true
	mesh_instance.material_override = mat
	mesh_instance.global_position = player.global_position
	scene.add_child(mesh_instance)
	_radius_meshes[pid] = mesh_instance


func _update_radius_visibility() -> void:
	if _show_radius:
		for pid in _labels:
			if not _radius_meshes.has(pid):
				var obj := instance_from_id(pid)
				if obj and obj is AudioStreamPlayer3D:
					_create_radius_mesh(pid, obj)
	else:
		for pid in _radius_meshes:
			if is_instance_valid(_radius_meshes[pid]):
				_radius_meshes[pid].queue_free()
		_radius_meshes.clear()


func _remove_label(pid: int) -> void:
	if _labels.has(pid):
		if is_instance_valid(_labels[pid]["label"]):
			_labels[pid]["label"].queue_free()
		_labels.erase(pid)
	if _radius_meshes.has(pid):
		if is_instance_valid(_radius_meshes[pid]):
			_radius_meshes[pid].queue_free()
		_radius_meshes.erase(pid)


func _clear_all() -> void:
	for pid in _labels.keys():
		_remove_label(pid)
	_labels.clear()
	_radius_meshes.clear()
