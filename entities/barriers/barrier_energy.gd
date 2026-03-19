class_name BarrierEnergy
extends BarrierBase
## BarrierEnergy - Energy Barrier.
## A semi-transparent blue energy field that slows and damages enemies passing through.
## Uses an Area3D child to detect overlapping enemies.
## - Slow: 40% for 2 seconds (applied as debuff via BuffDebuffComponent, or direct speed mod)
## - Damage: 5 HP/sec to all enemies inside the field
## Lower HP than the reinforced wall and no armor.

# Effect parameters (loaded from data specials)
var slow_percent: float = 0.4
var slow_duration: float = 2.0
var damage_per_second: float = 5.0

# Area3D for detecting enemies
var effect_area: Area3D = null

# Track enemies inside the field for per-second damage ticking
var _enemies_inside: Array = []  # Array of Node references

# Damage tick timer
var _damage_tick_timer: float = 0.0
const DAMAGE_TICK_INTERVAL: float = 0.5  # Apply damage every 0.5s (in proportion)

# Connector meshes for energy barrier connections (visual bridging)
var _connector_meshes: Dictionary = {}


func _ready() -> void:
	super._ready()
	add_to_group("energy_barrier")


func initialize(p_entity_id: String, p_entity_type: String, p_data: Dictionary = {}) -> void:
	super.initialize(p_entity_id, p_entity_type, p_data)

	# Parse specials from data
	var specials: Array = data.get("specials", [])
	for special: Dictionary in specials:
		var stype: String = special.get("type", "")
		var params: Dictionary = special.get("params", {})
		match stype:
			"slow_field":
				slow_percent = float(params.get("slow_percent", 40)) / 100.0
				slow_duration = float(params.get("duration", 2.0))
			"damage_field":
				damage_per_second = float(params.get("damage_per_second", 5))

	# Override the default visual to be semi-transparent blue
	_apply_transparent_material()

	# Create the Area3D for enemy detection
	_setup_effect_area()


func _process(delta: float) -> void:
	super._process(delta)

	if not is_built:
		return

	# Damage tick
	_damage_tick_timer += delta
	if _damage_tick_timer >= DAMAGE_TICK_INTERVAL:
		_damage_tick_timer -= DAMAGE_TICK_INTERVAL
		_apply_damage_tick()


## Override EntityBase._setup_visual so we can modify transparency after creation.
func _apply_transparent_material() -> void:
	if not visual_node:
		return
	var mesh_inst: MeshInstance3D = visual_node as MeshInstance3D
	if not mesh_inst or not mesh_inst.mesh:
		return
	var mat := mesh_inst.mesh.material as StandardMaterial3D
	if not mat:
		mat = StandardMaterial3D.new()
		mesh_inst.mesh.material = mat
	mat.albedo_color = Color(0.27, 0.53, 1.0, 0.45)  # Semi-transparent blue
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.5, 1.0)
	mat.emission_energy_multiplier = 0.6


## Create an Area3D with a CollisionShape3D matching the cell size for enemy detection.
func _setup_effect_area() -> void:
	effect_area = Area3D.new()
	effect_area.name = "EffectArea"
	effect_area.collision_layer = 0
	# Monitor layer where enemies exist (assuming enemies are on layer 2 / bit 1)
	effect_area.collision_mask = 2
	effect_area.monitoring = true
	effect_area.monitorable = false

	var shape := CollisionShape3D.new()
	shape.name = "EffectShape"
	var box := BoxShape3D.new()
	# Match the cell size with some vertical extent
	box.size = Vector3(BuildGrid.CELL_SIZE, 3.0, BuildGrid.CELL_SIZE)
	shape.shape = box
	shape.position = Vector3(0.0, 1.5, 0.0)

	effect_area.add_child(shape)
	add_child(effect_area)

	effect_area.body_entered.connect(_on_body_entered)
	effect_area.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	if not is_built:
		return
	if not body.is_in_group("enemy"):
		return
	if body not in _enemies_inside:
		_enemies_inside.append(body)
		_apply_slow_to_enemy(body)


func _on_body_exited(body: Node3D) -> void:
	_enemies_inside.erase(body)


## Apply the slow debuff to an enemy that enters the barrier.
func _apply_slow_to_enemy(enemy: Node3D) -> void:
	if not is_instance_valid(enemy):
		return

	# Try via BuffDebuffComponent first
	var enemy_base: EntityBase = enemy as EntityBase
	if enemy_base and enemy_base.buff_debuff_component:
		var debuff_id: String = "energy_barrier_slow_%d" % get_instance_id()
		enemy_base.buff_debuff_component.apply_debuff(
			debuff_id,
			"slow",
			slow_percent,
			slow_duration,
			self
		)
	elif enemy_base and enemy_base.movement_component:
		# Fallback: direct speed modification
		enemy_base.movement_component.speed_multiplier = max(
			0.1,
			enemy_base.movement_component.speed_multiplier - slow_percent
		)
		# Schedule restoration via a timer
		var restore_timer := get_tree().create_timer(slow_duration)
		restore_timer.timeout.connect(
			func() -> void:
				if is_instance_valid(enemy_base) and enemy_base.movement_component:
					enemy_base.movement_component.speed_multiplier = min(
						2.0,
						enemy_base.movement_component.speed_multiplier + slow_percent
					)
		)


## Apply proportional damage to all enemies currently inside the field.
func _apply_damage_tick() -> void:
	var damage_this_tick: float = damage_per_second * DAMAGE_TICK_INTERVAL
	var to_remove: Array = []

	for enemy: Node in _enemies_inside:
		if not is_instance_valid(enemy) or not enemy.is_inside_tree():
			to_remove.append(enemy)
			continue

		var enemy_base: EntityBase = enemy as EntityBase
		if enemy_base and enemy_base.health_component:
			enemy_base.health_component.take_damage(damage_this_tick, self)

	for dead: Node in to_remove:
		_enemies_inside.erase(dead)


# ---------------------------------------------------------------------------
# Connection visuals (energy barriers connecting to each other)
# ---------------------------------------------------------------------------

func _update_connection_visual() -> void:
	# Remove stale connectors
	for dir: Vector2i in _connector_meshes.keys():
		if not connected_neighbors.has(dir):
			var mesh: MeshInstance3D = _connector_meshes[dir]
			if is_instance_valid(mesh):
				mesh.queue_free()
			_connector_meshes.erase(dir)

	# Add connectors where neighbors exist
	for dir: Vector2i in connected_neighbors:
		if _connector_meshes.has(dir):
			continue
		_create_connector(dir)


func _create_connector(dir: Vector2i) -> void:
	var mesh_scale: Array = data.get("mesh_scale", [1.0, 2.0, 0.2])
	var barrier_height: float = float(mesh_scale[1]) if mesh_scale.size() >= 2 else 2.0
	var wall_width_x: float = float(mesh_scale[0]) if mesh_scale.size() >= 1 else 1.0
	var wall_width_z: float = float(mesh_scale[2]) if mesh_scale.size() >= 3 else 0.2

	var connector := MeshInstance3D.new()
	connector.name = "Connector_%d_%d" % [dir.x, dir.y]

	# Semi-transparent blue material matching the barrier
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.27, 0.53, 1.0, 0.45)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.5, 1.0)
	mat.emission_energy_multiplier = 0.6

	var is_diagonal: bool = dir.x != 0 and dir.y != 0
	var box := BoxMesh.new()

	if is_diagonal:
		var cell: float = BuildGrid.CELL_SIZE
		var thickness: float = min(wall_width_x, wall_width_z) * 0.85
		var diag_length: float = sqrt(2.0) * cell
		box.size = Vector3(diag_length, barrier_height, thickness)
		box.material = mat
		connector.mesh = box
		connector.position = Vector3(
			float(dir.x) * cell / 2.0,
			barrier_height / 2.0,
			float(dir.y) * cell / 2.0
		)
		connector.rotation.y = -atan2(float(dir.y), float(dir.x))
	elif dir.x != 0:
		var gap: float = BuildGrid.CELL_SIZE - wall_width_x
		if gap <= 0.0:
			return
		box.size = Vector3(gap, barrier_height, wall_width_z)
		box.material = mat
		connector.mesh = box
		connector.position = Vector3(dir.x * (wall_width_x / 2.0 + gap / 2.0), barrier_height / 2.0, 0.0)
	else:
		var gap: float = max(BuildGrid.CELL_SIZE - wall_width_z, 0.01)
		box.size = Vector3(wall_width_x, barrier_height, gap)
		box.material = mat
		connector.mesh = box
		connector.position = Vector3(0.0, barrier_height / 2.0, dir.y * (wall_width_z / 2.0 + gap / 2.0))

	add_child(connector)
	_connector_meshes[dir] = connector
