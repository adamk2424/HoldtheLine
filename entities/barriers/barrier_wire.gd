class_name BarrierWire
extends BarrierBase
## BarrierWire - Concertina Wire barrier.
## A low-profile razor wire trap that damages and slows enemies occupying the cell.
## Uses an Area3D to detect enemies standing in the wire.
## - Contact damage: 10 HP/sec
## - Slow: 60% while inside (persistent, removed on exit)
## Lowest HP of all barriers, no armor.

# Effect parameters (loaded from data specials)
var contact_damage_per_second: float = 10.0
var slow_percent: float = 0.6

# Area3D for detecting enemies
var effect_area: Area3D = null

# Track enemies currently in the wire
var _enemies_inside: Array = []

# Damage tick timer
var _damage_tick_timer: float = 0.0
const DAMAGE_TICK_INTERVAL: float = 0.5

# Active slow debuff ids, keyed by enemy instance id for cleanup
var _active_slow_ids: Dictionary = {}  # { int (enemy instance id) : String (debuff_id) }

# Connector meshes for visual connection between adjacent wire segments
var _connector_meshes: Dictionary = {}


func _ready() -> void:
	super._ready()
	add_to_group("wire")


func initialize(p_entity_id: String, p_entity_type: String, p_data: Dictionary = {}) -> void:
	super.initialize(p_entity_id, p_entity_type, p_data)

	# Parse specials from data
	var specials: Array = data.get("specials", [])
	for special: Dictionary in specials:
		var stype: String = special.get("type", "")
		var params: Dictionary = special.get("params", {})
		match stype:
			"contact_damage":
				contact_damage_per_second = float(params.get("damage_per_second", 10))
			"slow":
				slow_percent = float(params.get("slow_percent", 60)) / 100.0

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


## Create an Area3D with a CollisionShape3D matching the cell footprint.
## The wire is low (mesh_scale y = 0.3) so the detection volume is also low.
func _setup_effect_area() -> void:
	effect_area = Area3D.new()
	effect_area.name = "EffectArea"
	effect_area.collision_layer = 0
	effect_area.collision_mask = 2  # Enemy layer
	effect_area.monitoring = true
	effect_area.monitorable = false

	var shape := CollisionShape3D.new()
	shape.name = "EffectShape"
	var box := BoxShape3D.new()
	box.size = Vector3(BuildGrid.CELL_SIZE, 1.5, BuildGrid.CELL_SIZE)
	shape.shape = box
	shape.position = Vector3(0.0, 0.75, 0.0)

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
	_remove_slow_from_enemy(body)


## Apply a persistent slow debuff while the enemy is inside the wire.
## Uses a very long duration; it will be explicitly removed on exit.
func _apply_slow_to_enemy(enemy: Node3D) -> void:
	if not is_instance_valid(enemy):
		return

	var enemy_base: EntityBase = enemy as EntityBase
	var debuff_id: String = "wire_slow_%d" % get_instance_id()

	if enemy_base and enemy_base.buff_debuff_component:
		enemy_base.buff_debuff_component.apply_debuff(
			debuff_id,
			"slow",
			slow_percent,
			999.0,  # Effectively permanent until removed
			self
		)
		_active_slow_ids[enemy.get_instance_id()] = debuff_id
	elif enemy_base and enemy_base.movement_component:
		# Fallback: direct speed modification
		enemy_base.movement_component.speed_multiplier = max(
			0.1,
			enemy_base.movement_component.speed_multiplier - slow_percent
		)
		_active_slow_ids[enemy.get_instance_id()] = ""


## Remove the slow debuff when the enemy exits the wire.
func _remove_slow_from_enemy(enemy: Node3D) -> void:
	if not is_instance_valid(enemy):
		_active_slow_ids.erase(enemy.get_instance_id() if is_instance_valid(enemy) else 0)
		return

	var eid: int = enemy.get_instance_id()
	if not _active_slow_ids.has(eid):
		return

	var debuff_id: String = _active_slow_ids[eid]
	var enemy_base: EntityBase = enemy as EntityBase

	if debuff_id != "" and enemy_base and enemy_base.buff_debuff_component:
		enemy_base.buff_debuff_component.remove_debuff(debuff_id)
	elif enemy_base and enemy_base.movement_component:
		enemy_base.movement_component.speed_multiplier = min(
			2.0,
			enemy_base.movement_component.speed_multiplier + slow_percent
		)

	_active_slow_ids.erase(eid)


## Apply proportional damage to all enemies currently in the wire.
func _apply_damage_tick() -> void:
	var damage_this_tick: float = contact_damage_per_second * DAMAGE_TICK_INTERVAL
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
		_active_slow_ids.erase(dead.get_instance_id() if is_instance_valid(dead) else 0)


# ---------------------------------------------------------------------------
# Clean up active slows when the wire is destroyed
# ---------------------------------------------------------------------------

func die(killer: Node = null) -> void:
	# Remove slow debuffs from all enemies still inside
	for enemy: Node in _enemies_inside:
		_remove_slow_from_enemy(enemy as Node3D)
	_enemies_inside.clear()
	_active_slow_ids.clear()
	super.die(killer)


# ---------------------------------------------------------------------------
# Connection visuals (wire segments connecting)
# ---------------------------------------------------------------------------

func _update_connection_visual() -> void:
	for dir: Vector2i in _connector_meshes.keys():
		if not connected_neighbors.has(dir):
			var mesh: MeshInstance3D = _connector_meshes[dir]
			if is_instance_valid(mesh):
				mesh.queue_free()
			_connector_meshes.erase(dir)

	for dir: Vector2i in connected_neighbors:
		if _connector_meshes.has(dir):
			continue
		_create_connector(dir)


func _create_connector(dir: Vector2i) -> void:
	var mesh_scale: Array = data.get("mesh_scale", [1.0, 0.3, 1.0])
	var wire_height: float = float(mesh_scale[1]) if mesh_scale.size() >= 2 else 0.3
	var wire_width_x: float = float(mesh_scale[0]) if mesh_scale.size() >= 1 else 1.0
	var wire_width_z: float = float(mesh_scale[2]) if mesh_scale.size() >= 3 else 1.0

	var connector := MeshInstance3D.new()
	connector.name = "Connector_%d_%d" % [dir.x, dir.y]

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.html(data.get("mesh_color", "#AAAAAA"))
	mat.albedo_color.a = 1.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	mat.roughness = 0.9
	mat.metallic = 0.1

	var is_diagonal: bool = dir.x != 0 and dir.y != 0
	var box := BoxMesh.new()

	if is_diagonal:
		var cell: float = BuildGrid.CELL_SIZE
		var thickness: float = min(wire_width_x, wire_width_z) * 0.85
		var diag_length: float = sqrt(2.0) * cell
		box.size = Vector3(diag_length, wire_height, thickness)
		box.material = mat
		connector.mesh = box
		connector.position = Vector3(
			float(dir.x) * cell / 2.0,
			wire_height / 2.0,
			float(dir.y) * cell / 2.0
		)
		connector.rotation.y = -atan2(float(dir.y), float(dir.x))
	elif dir.x != 0:
		var gap: float = BuildGrid.CELL_SIZE - wire_width_x
		if gap <= 0.0:
			return
		box.size = Vector3(gap, wire_height, wire_width_z)
		box.material = mat
		connector.mesh = box
		connector.position = Vector3(dir.x * (wire_width_x / 2.0 + gap / 2.0), wire_height / 2.0, 0.0)
	else:
		var gap: float = BuildGrid.CELL_SIZE - wire_width_z
		if gap <= 0.0:
			return
		box.size = Vector3(wire_width_x, wire_height, gap)
		box.material = mat
		connector.mesh = box
		connector.position = Vector3(0.0, wire_height / 2.0, dir.y * (wire_width_z / 2.0 + gap / 2.0))

	add_child(connector)
	_connector_meshes[dir] = connector
