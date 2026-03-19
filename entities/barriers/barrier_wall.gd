class_name BarrierWall
extends BarrierBase
## BarrierWall - Solid wall barrier that links smoothly at any angle.
## Creates connector meshes between adjacent walls in all 8 directions,
## so diagonal wall runs look like continuous barricades rather than
## isolated blocks with gaps.

# Connector meshes keyed by direction Vector2i
var _connector_meshes: Dictionary = {}  # { Vector2i : MeshInstance3D }


func _ready() -> void:
	super._ready()
	add_to_group("wall")


func initialize(p_entity_id: String, p_entity_type: String, p_data: Dictionary = {}) -> void:
	super.initialize(p_entity_id, p_entity_type, p_data)


## Override: update the visual connectors between this wall and its neighbors.
func _update_connection_visual() -> void:
	# Remove stale connectors
	for dir: Vector2i in _connector_meshes.keys():
		if not connected_neighbors.has(dir):
			var mesh: MeshInstance3D = _connector_meshes[dir]
			if is_instance_valid(mesh):
				mesh.queue_free()
			_connector_meshes.erase(dir)

	# Add new connectors where neighbors exist but we have no mesh yet
	for dir: Vector2i in connected_neighbors:
		if _connector_meshes.has(dir):
			continue
		_create_connector(dir)


## Create a connector mesh bridging this wall to its neighbor.
## Handles cardinal (N/S/E/W) and diagonal (NE/NW/SE/SW) directions.
func _create_connector(dir: Vector2i) -> void:
	var mesh_scale: Array = data.get("mesh_scale", [1.0, 1.5, 1.0])
	var wall_height: float = float(mesh_scale[1]) if mesh_scale.size() >= 2 else 1.5
	var wall_width_x: float = float(mesh_scale[0]) if mesh_scale.size() >= 1 else 1.0
	var wall_width_z: float = float(mesh_scale[2]) if mesh_scale.size() >= 3 else 1.0

	var connector := MeshInstance3D.new()
	connector.name = "Connector_%d_%d" % [dir.x, dir.y]

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.html(data.get("mesh_color", "#888888"))
	mat.albedo_color.a = 1.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	mat.roughness = 0.8
	mat.metallic = 0.2

	var is_diagonal: bool = dir.x != 0 and dir.y != 0

	if is_diagonal:
		# Diagonal connector: rotated box bridging the diagonal gap
		# Distance between cell centers along diagonal = sqrt(2) * CELL_SIZE
		# We create a box stretched along that diagonal
		var cell: float = BuildGrid.CELL_SIZE
		var thickness: float = min(wall_width_x, wall_width_z) * 0.85
		var diag_length: float = sqrt(2.0) * cell

		var box := BoxMesh.new()
		box.size = Vector3(diag_length, wall_height, thickness)
		box.material = mat

		connector.mesh = box
		# Position at midpoint between this cell and the neighbor
		connector.position = Vector3(
			float(dir.x) * cell / 2.0,
			wall_height / 2.0,
			float(dir.y) * cell / 2.0
		)
		# Rotate to align with the diagonal
		# atan2 gives the angle from the X-axis to the direction vector in the XZ plane
		connector.rotation.y = -atan2(float(dir.y), float(dir.x))
	else:
		# Cardinal connector: simple box bridging the gap along one axis
		var box := BoxMesh.new()

		if dir.x != 0:
			# East/West
			var gap: float = BuildGrid.CELL_SIZE - wall_width_x
			if gap <= 0.0:
				return
			box.size = Vector3(gap, wall_height, wall_width_z)
			connector.position = Vector3(
				dir.x * (wall_width_x / 2.0 + gap / 2.0),
				wall_height / 2.0,
				0.0
			)
		else:
			# North/South
			var gap: float = BuildGrid.CELL_SIZE - wall_width_z
			if gap <= 0.0:
				return
			box.size = Vector3(wall_width_x, wall_height, gap)
			connector.position = Vector3(
				0.0,
				wall_height / 2.0,
				dir.y * (wall_width_z / 2.0 + gap / 2.0)
			)

		box.material = mat
		connector.mesh = box

	add_child(connector)
	_connector_meshes[dir] = connector
