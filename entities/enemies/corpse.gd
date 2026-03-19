class_name EnemyCorpse
extends Node3D
## EnemyCorpse - Simple visual corpse that fades out over 10 seconds.
## Displays a flat colored shape at the death position.

const FADE_DURATION_DEFAULT: float = 10.0

var _fade_duration: float = 10.0
var _fade_timer: float = 0.0
var _mesh_instance: MeshInstance3D = null
var _material: StandardMaterial3D = null
var _original_color: Color = Color.GRAY


func setup(enemy_data: Dictionary) -> void:
	# Create a flat shape at ground level representing the fallen enemy
	_mesh_instance = MeshInstance3D.new()

	var box := BoxMesh.new()
	# Use enemy mesh scale but flatten it
	var scale_arr: Variant = enemy_data.get("mesh_scale", [1.0, 1.0, 1.0])
	var scale_x: float = 1.0
	var scale_z: float = 1.0
	if scale_arr is Array and scale_arr.size() >= 3:
		scale_x = float(scale_arr[0])
		scale_z = float(scale_arr[2])

	box.size = Vector3(scale_x, 0.1, scale_z)

	_material = StandardMaterial3D.new()
	var color_hex: String = enemy_data.get("mesh_color", "#888888")
	_original_color = Color.html(color_hex).darkened(0.4)
	_material.albedo_color = _original_color
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.roughness = 1.0
	box.material = _material

	_mesh_instance.mesh = box
	_mesh_instance.position.y = 0.05  # Slightly above ground
	add_child(_mesh_instance)

	# Scale corpse lifetime with entity pressure to keep node count down.
	var total: int = EntityRegistry.get_count("enemy") + EntityRegistry.get_count("corpse")
	if total > 400:
		_fade_duration = 1.0
	elif total > 250:
		_fade_duration = 3.0
	else:
		_fade_duration = FADE_DURATION_DEFAULT

	# Register as corpse
	EntityRegistry.register(self, EntityRegistry.TYPE_CORPSE)


func _process(delta: float) -> void:
	_fade_timer += delta

	if _fade_timer >= _fade_duration:
		_expire()
		return

	# Fade alpha over time
	if _material:
		var alpha: float = 1.0 - (_fade_timer / _fade_duration)
		_material.albedo_color = Color(
			_original_color.r,
			_original_color.g,
			_original_color.b,
			alpha
		)


func _expire() -> void:
	EntityRegistry.unregister(self, EntityRegistry.TYPE_CORPSE)
	GameBus.corpse_expired.emit(global_position)
	queue_free()
