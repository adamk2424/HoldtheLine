class_name Projectile
extends Node3D
## Projectile - Travels toward a target and deals damage on hit.
## Uses object pooling and a shared material to minimize allocations and draw calls.

# --- Shared resources (created once, reused by all projectiles) ---
static var _shared_mesh: SphereMesh = null
static var _shared_material: StandardMaterial3D = null

# --- Object pool ---
static var _pool: Array[Projectile] = []

var target: Node = null
var damage: float = 0.0
var armor_pierce: float = 0.0
var source: Node = null
var speed: float = 30.0
var homing: bool = true
var _target_last_pos: Vector3 = Vector3.ZERO
var _lifetime: float = 5.0
var _active: bool = false


# =============================================================================
# Pool API
# =============================================================================

static func _ensure_shared_resources() -> void:
	if _shared_material:
		return
	_shared_material = StandardMaterial3D.new()
	_shared_material.albedo_color = Color.YELLOW
	_shared_material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	_shared_material.emission_enabled = true
	_shared_material.emission = Color.YELLOW
	_shared_material.emission_energy_multiplier = 2.0
	_shared_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	_shared_mesh = SphereMesh.new()
	_shared_mesh.radius = 0.15
	_shared_mesh.height = 0.3
	_shared_mesh.material = _shared_material


static func acquire(parent: Node) -> Projectile:
	## Get a projectile from the pool (or create one). Already in the scene tree.
	_ensure_shared_resources()

	# Try to reuse a pooled projectile
	while not _pool.is_empty():
		var proj: Projectile = _pool.pop_back()
		if is_instance_valid(proj) and proj.is_inside_tree():
			proj._activate()
			return proj

	# Pool empty or all stale — create a new one
	var proj := Projectile.new()
	var mi := MeshInstance3D.new()
	mi.mesh = _shared_mesh
	mi.name = "Mesh"
	proj.add_child(mi)
	parent.add_child(proj)
	proj._activate()
	return proj


func release() -> void:
	## Return this projectile to the pool for reuse.
	_deactivate()
	_pool.append(self)


func _activate() -> void:
	_active = true
	visible = true
	set_process(true)
	target = null
	damage = 0.0
	armor_pierce = 0.0
	source = null
	_target_last_pos = Vector3.ZERO
	_lifetime = 5.0


func _deactivate() -> void:
	_active = false
	visible = false
	set_process(false)


# =============================================================================
# Runtime
# =============================================================================

func _ready() -> void:
	# Visual is created by acquire(), not _ready().
	# Disable processing until activated.
	set_process(false)


func setup(p_target: Node, p_damage: float, p_armor_pierce: float = 0.0, p_source: Node = null) -> void:
	target = p_target
	damage = p_damage
	armor_pierce = p_armor_pierce
	source = p_source
	if target and is_instance_valid(target):
		_target_last_pos = target.global_position


func _process(delta: float) -> void:
	if not _active:
		return

	_lifetime -= delta
	if _lifetime <= 0.0:
		release()
		return

	var target_pos: Vector3
	if homing and target and is_instance_valid(target) and target.is_inside_tree():
		target_pos = target.global_position + Vector3(0, 0.5, 0)
		_target_last_pos = target_pos
	else:
		target_pos = _target_last_pos

	var direction := global_position.direction_to(target_pos)
	global_position += direction * speed * delta

	# Check hit
	if global_position.distance_to(target_pos) < 1.0:
		_hit()


func _hit() -> void:
	if target and is_instance_valid(target):
		var health: HealthComponent = null
		if target is EntityBase:
			health = target.health_component
		else:
			for child in target.get_children():
				if child is HealthComponent:
					health = child
					break
		if health:
			var valid_source: Node = source if is_instance_valid(source) else null
			if armor_pierce > 0.0:
				var orig_armor: float = health.current_armor
				health.current_armor = max(0.0, health.current_armor - armor_pierce)
				health.take_damage(damage, valid_source)
				health.current_armor = orig_armor
			else:
				health.take_damage(damage, valid_source)

	GameBus.audio_play_3d.emit("projectile.impact", global_position)
	release()
