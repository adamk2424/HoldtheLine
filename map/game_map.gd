class_name GameMap
extends Node3D
## GameMap - 300x300 game world with ground plane, lighting, and navigation.
## Interior (buildable area) has a concrete/industrial floor.
## Exterior has a rocky wasteland look.

const MAP_SIZE: float = 300.0
const MAP_HALF: float = 150.0
const GRID_AREA: float = 120.0

var navigation_region: NavigationRegion3D
var _ground_body: StaticBody3D
var _rebake_queued: bool = false
var build_grid: Node = null  # Set by GameSession after setup


func _ready() -> void:
	_create_ground()
	_create_lighting()
	_create_navigation()
	GameBus.navmesh_needs_rebake.connect(_on_navmesh_needs_rebake)


func _create_ground() -> void:
	# Static body for raycasting
	_ground_body = StaticBody3D.new()
	_ground_body.name = "GroundBody"
	_ground_body.collision_layer = 1

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(MAP_SIZE, 0.1, MAP_SIZE)
	collision.shape = shape
	collision.position = Vector3(MAP_HALF, -0.05, MAP_HALF)
	_ground_body.add_child(collision)
	add_child(_ground_body)

	# --- Exterior: rocky wasteland ground ---
	_create_wasteland()

	# --- Interior: concrete base floor ---
	_create_base_floor()


func _create_wasteland() -> void:
	var wasteland := MeshInstance3D.new()
	wasteland.name = "WastelandGround"
	var plane := BoxMesh.new()
	plane.size = Vector3(MAP_SIZE, 0.1, MAP_SIZE)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.22, 0.18, 0.14, 1.0)  # Sandy brown/grey rock
	mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	mat.roughness = 0.95
	mat.metallic = 0.0
	plane.material = mat

	wasteland.mesh = plane
	wasteland.position = Vector3(MAP_HALF, -0.05, MAP_HALF)
	add_child(wasteland)

	# Scatter some rocky terrain variation patches across the wasteland
	_create_terrain_patches()


func _create_terrain_patches() -> void:
	# Add irregular darker/lighter patches to break up the flat wasteland
	var rng := RandomNumberGenerator.new()
	rng.seed = 42  # Deterministic for consistency

	var grid_start_x: float = (MAP_SIZE - GRID_AREA) / 2.0
	var grid_end_x: float = grid_start_x + GRID_AREA
	var grid_start_z: float = grid_start_x
	var grid_end_z: float = grid_end_x

	for i in range(80):
		var px: float = rng.randf_range(5.0, MAP_SIZE - 5.0)
		var pz: float = rng.randf_range(5.0, MAP_SIZE - 5.0)

		# Skip patches inside the base area (they'd be hidden under concrete)
		if px > grid_start_x - 2 and px < grid_end_x + 2 and pz > grid_start_z - 2 and pz < grid_end_z + 2:
			continue

		var patch := MeshInstance3D.new()
		var patch_mesh := BoxMesh.new()
		var sx: float = rng.randf_range(3.0, 12.0)
		var sz: float = rng.randf_range(3.0, 12.0)
		var sy: float = rng.randf_range(0.05, 0.25)
		patch_mesh.size = Vector3(sx, sy, sz)

		var patch_mat := StandardMaterial3D.new()
		# Vary between darker rock and lighter dusty patches
		var shade: float = rng.randf_range(-0.06, 0.06)
		patch_mat.albedo_color = Color(
			0.22 + shade,
			0.18 + shade * 0.8,
			0.14 + shade * 0.6,
			1.0
		)
		patch_mat.roughness = rng.randf_range(0.85, 1.0)
		patch_mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
		patch_mesh.material = patch_mat

		patch.mesh = patch_mesh
		patch.position = Vector3(px, -0.02 + sy / 2.0, pz)
		# Slight random rotation for organic feel
		patch.rotation.y = rng.randf_range(0, TAU)
		add_child(patch)


func _create_base_floor() -> void:
	# Main concrete slab
	var base := MeshInstance3D.new()
	base.name = "BaseFloor"
	var slab := BoxMesh.new()
	slab.size = Vector3(GRID_AREA, 0.15, GRID_AREA)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.35, 0.37, 1.0)  # Cool grey concrete
	mat.roughness = 0.85
	mat.metallic = 0.05
	mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	slab.material = mat

	base.mesh = slab
	base.position = Vector3(MAP_HALF, 0.0, MAP_HALF)
	add_child(base)

	# Concrete panel lines (subtle grid of expansion joints)
	_create_concrete_joints()

	# Edge trim / border around the base
	_create_base_border()


func _create_concrete_joints() -> void:
	# Subtle darker lines every 10 units to simulate concrete slab joints
	var joint_mesh := ImmediateMesh.new()
	var joint_mat := StandardMaterial3D.new()
	joint_mat.albedo_color = Color(0.28, 0.28, 0.30, 0.4)
	joint_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	joint_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	var start_x: float = (MAP_SIZE - GRID_AREA) / 2.0
	var start_z: float = start_x
	var y: float = 0.08

	joint_mesh.surface_begin(Mesh.PRIMITIVE_LINES, joint_mat)

	# Horizontal joints every 10 units
	for i in range(0, int(GRID_AREA) + 1, 10):
		var z: float = start_z + float(i)
		joint_mesh.surface_add_vertex(Vector3(start_x, y, z))
		joint_mesh.surface_add_vertex(Vector3(start_x + GRID_AREA, y, z))

	# Vertical joints every 10 units
	for i in range(0, int(GRID_AREA) + 1, 10):
		var x: float = start_x + float(i)
		joint_mesh.surface_add_vertex(Vector3(x, y, start_z))
		joint_mesh.surface_add_vertex(Vector3(x, y, start_z + GRID_AREA))

	joint_mesh.surface_end()

	var joint_inst := MeshInstance3D.new()
	joint_inst.name = "ConcreteJoints"
	joint_inst.mesh = joint_mesh
	add_child(joint_inst)


func _create_base_border() -> void:
	# Raised border strips around the edge of the buildable area
	var start: float = (MAP_SIZE - GRID_AREA) / 2.0
	var border_width: float = 0.8
	var border_height: float = 0.2

	var border_mat := StandardMaterial3D.new()
	border_mat.albedo_color = Color(0.3, 0.3, 0.32, 1.0)
	border_mat.roughness = 0.7
	border_mat.metallic = 0.15
	border_mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED

	var sides: Array = [
		# [position, size]
		[Vector3(MAP_HALF, border_height / 2.0, start - border_width / 2.0),
		 Vector3(GRID_AREA + border_width * 2, border_height, border_width)],  # North
		[Vector3(MAP_HALF, border_height / 2.0, start + GRID_AREA + border_width / 2.0),
		 Vector3(GRID_AREA + border_width * 2, border_height, border_width)],  # South
		[Vector3(start - border_width / 2.0, border_height / 2.0, MAP_HALF),
		 Vector3(border_width, border_height, GRID_AREA)],  # West
		[Vector3(start + GRID_AREA + border_width / 2.0, border_height / 2.0, MAP_HALF),
		 Vector3(border_width, border_height, GRID_AREA)],  # East
	]

	for i in sides.size():
		var border := MeshInstance3D.new()
		border.name = "BaseBorder_%d" % i
		var bm := BoxMesh.new()
		bm.size = sides[i][1]
		bm.material = border_mat
		border.mesh = bm
		border.position = sides[i][0]
		add_child(border)


func _create_lighting() -> void:
	# Directional light (sun)
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-45, -30, 0)
	sun.light_color = Color(1.0, 0.95, 0.9)
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 200.0
	add_child(sun)

	# Environment
	var env := WorldEnvironment.new()
	env.name = "WorldEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.12, 0.1, 0.08)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.35, 0.3, 0.25)
	environment.ambient_light_energy = 0.5
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.18, 0.15, 0.12)
	environment.fog_density = 0.003
	env.environment = environment
	add_child(env)


func _create_navigation() -> void:
	navigation_region = NavigationRegion3D.new()
	navigation_region.name = "NavigationRegion3D"

	var nav_mesh := NavigationMesh.new()

	var vertices := PackedVector3Array([
		Vector3(0, 0, 0),
		Vector3(MAP_SIZE, 0, 0),
		Vector3(MAP_SIZE, 0, MAP_SIZE),
		Vector3(0, 0, MAP_SIZE)
	])
	nav_mesh.vertices = vertices
	nav_mesh.add_polygon(PackedInt32Array([0, 1, 2]))
	nav_mesh.add_polygon(PackedInt32Array([0, 2, 3]))

	navigation_region.navigation_mesh = nav_mesh
	add_child(navigation_region)


func rebake_navigation() -> void:
	if not build_grid:
		return
	_rebuild_navmesh_from_grid()


func _on_navmesh_needs_rebake() -> void:
	if not _rebake_queued:
		_rebake_queued = true
		get_tree().create_timer(0.5).timeout.connect(_do_rebake)


func _do_rebake() -> void:
	_rebake_queued = false
	rebake_navigation()
	GameBus.navmesh_rebaked.emit()


func _rebuild_navmesh_from_grid() -> void:
	var origin_x: int = int(build_grid.grid_origin.x)
	var origin_z: int = int(build_grid.grid_origin.z)
	var grid_size: int = build_grid.GRID_SIZE
	var map_cells: int = int(MAP_SIZE)

	# Shared vertex pool ensures adjacent quads share vertices → connected navmesh.
	# Key = z * 10000 + x → vertex index
	var vertex_map: Dictionary = {}
	var verts: Array[Vector3] = []
	var polys: Array[PackedInt32Array] = []

	for row in range(map_cells):
		var grid_row: int = row - origin_z
		var row_in_grid: bool = grid_row >= 0 and grid_row < grid_size

		# Merge adjacent free cells into strips for efficiency, but use shared vertices
		var strip_start: int = -1

		for col in range(map_cells):
			var occupied: bool = false
			if row_in_grid:
				var grid_col: int = col - origin_x
				if grid_col >= 0 and grid_col < grid_size:
					occupied = build_grid.get_cell_occupant(Vector2i(grid_col, grid_row)) != -1

			if not occupied:
				if strip_start == -1:
					strip_start = col
			else:
				if strip_start != -1:
					# Add per-cell quads for each cell in this strip (shared vertices)
					for cx in range(strip_start, col):
						_add_shared_quad(vertex_map, verts, polys, cx, row, cx + 1, row + 1)
					strip_start = -1

		if strip_start != -1:
			for cx in range(strip_start, map_cells):
				_add_shared_quad(vertex_map, verts, polys, cx, row, cx + 1, row + 1)

	var nav_mesh := NavigationMesh.new()
	var packed := PackedVector3Array()
	packed.resize(verts.size())
	for i in range(verts.size()):
		packed[i] = verts[i]
	nav_mesh.vertices = packed
	for p in polys:
		nav_mesh.add_polygon(p)

	navigation_region.navigation_mesh = nav_mesh


func _add_shared_quad(vertex_map: Dictionary, verts: Array[Vector3],
		polys: Array[PackedInt32Array], x0: int, z0: int, x1: int, z1: int) -> void:
	var i0: int = _get_shared_vertex(vertex_map, verts, x0, z0)
	var i1: int = _get_shared_vertex(vertex_map, verts, x1, z0)
	var i2: int = _get_shared_vertex(vertex_map, verts, x1, z1)
	var i3: int = _get_shared_vertex(vertex_map, verts, x0, z1)
	polys.append(PackedInt32Array([i0, i1, i2, i3]))


func _get_shared_vertex(vertex_map: Dictionary, verts: Array[Vector3], x: int, z: int) -> int:
	var key: int = z * 10000 + x
	if vertex_map.has(key):
		return vertex_map[key]
	var idx: int = verts.size()
	verts.append(Vector3(float(x), 0.0, float(z)))
	vertex_map[key] = idx
	return idx


func get_random_edge_position() -> Vector3:
	var edge := randi() % 4
	var pos := Vector3.ZERO
	match edge:
		0:  # North
			pos = Vector3(randf_range(0, MAP_SIZE), 0, 0)
		1:  # South
			pos = Vector3(randf_range(0, MAP_SIZE), 0, MAP_SIZE)
		2:  # East
			pos = Vector3(MAP_SIZE, 0, randf_range(0, MAP_SIZE))
		3:  # West
			pos = Vector3(0, 0, randf_range(0, MAP_SIZE))
	return pos
