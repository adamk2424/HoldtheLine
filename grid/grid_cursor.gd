class_name GridCursor
extends Node3D
## GridCursor - Ghost preview for building placement.
## Shows a transparent preview mesh at the cursor's grid position.

var current_grid_pos: Vector2i = Vector2i.ZERO
var current_size: int = 1
var current_entity_id: String = ""
var is_active: bool = false
var is_valid_placement: bool = false

var _preview_mesh: MeshInstance3D = null
var _valid_material: StandardMaterial3D
var _invalid_material: StandardMaterial3D

@onready var build_grid: BuildGrid = get_parent() as BuildGrid


func _ready() -> void:
	_setup_materials()
	visible = false


func _setup_materials() -> void:
	_valid_material = StandardMaterial3D.new()
	_valid_material.albedo_color = Color(0.0, 1.0, 0.0, 0.4)
	_valid_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_valid_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	_invalid_material = StandardMaterial3D.new()
	_invalid_material.albedo_color = Color(1.0, 0.0, 0.0, 0.4)
	_invalid_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_invalid_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED


func activate(entity_id: String) -> void:
	current_entity_id = entity_id
	var data := GameData.get_entity_data(entity_id)
	var raw_grid_size: Variant = data.get("grid_size", 1)
	if raw_grid_size is Array:
		current_size = int(raw_grid_size[0])
	else:
		current_size = int(raw_grid_size)
	is_active = true
	_create_preview(data)
	visible = true


func deactivate() -> void:
	is_active = false
	current_entity_id = ""
	visible = false
	if _preview_mesh:
		_preview_mesh.queue_free()
		_preview_mesh = null


func update_position(world_pos: Vector3) -> void:
	if not is_active or not build_grid:
		return
	current_grid_pos = build_grid.world_to_grid(world_pos)
	var snapped_pos := build_grid.grid_to_world(current_grid_pos, current_size)
	global_position = snapped_pos

	is_valid_placement = build_grid.is_cell_free(current_grid_pos, current_size)
	_update_material()


func get_placement_position() -> Vector3:
	return build_grid.grid_to_world(current_grid_pos, current_size)


func _create_preview(data: Dictionary) -> void:
	if _preview_mesh:
		_preview_mesh.queue_free()

	var mesh_shape: String = data.get("mesh_shape", "box")
	var mesh_scale: Array = data.get("mesh_scale", [1.0, 1.0, 1.0])

	_preview_mesh = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(
		current_size * BuildGrid.CELL_SIZE,
		float(mesh_scale[1]) if mesh_scale.size() > 1 else 1.0,
		current_size * BuildGrid.CELL_SIZE
	)
	_preview_mesh.mesh = box
	_preview_mesh.position.y = box.size.y / 2.0
	add_child(_preview_mesh)
	_update_material()


func _update_material() -> void:
	if _preview_mesh:
		_preview_mesh.material_override = _valid_material if is_valid_placement else _invalid_material
