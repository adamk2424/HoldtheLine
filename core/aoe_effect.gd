class_name AoEEffect
extends Node3D
## AoE Effect - Deals damage to all entities in radius, then disappears.

var damage: float = 0.0
var radius: float = 4.0
var source: Node = null
var target_type: String = "enemy"
var duration: float = 0.5  # Visual duration before cleanup
var _has_dealt_damage: bool = false


func _ready() -> void:
	# Create visual ring
	var mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = 0.2
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.5, 0.0, 0.5)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.5, 0.0)
	mat.emission_energy_multiplier = 3.0
	cyl.material = mat
	mesh.mesh = cyl
	mesh.position.y = 0.1
	add_child(mesh)


func setup(p_damage: float, p_radius: float, p_source: Node = null, p_target_type: String = "enemy") -> void:
	damage = p_damage
	radius = p_radius
	source = p_source
	target_type = p_target_type


func _process(delta: float) -> void:
	if not _has_dealt_damage:
		_deal_area_damage()
		_has_dealt_damage = true

	duration -= delta
	if duration <= 0.0:
		queue_free()


func _deal_area_damage() -> void:
	var targets: Array = EntityRegistry.get_in_range(global_position, target_type, radius)
	for target: Node in targets:
		if not is_instance_valid(target):
			continue
		var health: HealthComponent = null
		if target is EntityBase:
			health = target.health_component
		if health:
			health.take_damage(damage, source)
