class_name ProjectileVfxEnhanced
extends Node
## Enhanced projectile VFX system for different weapon types and projectile behaviors
## Provides lightweight visual effects without using heavy 3D objects

# --- Projectile VFX Types ---
enum ProjectileVfxType {
	BULLET_TRACER,          # Fast kinetic rounds (autocannon)
	MISSILE_TRAIL,          # Guided missiles with smoke trails
	ENERGY_BEAM,           # Instant laser/plasma beams
	RAILGUN_BOLT,          # High-energy electromagnetic projectile
	PLASMA_BOLT,           # Glowing plasma projectile
	FLAME_STREAM,          # Continuous flame projector
	ELECTRIC_ARC,          # Lightning/tesla discharge
	ACID_GLOB,             # Corrosive projectiles
	SPINE_DART,            # Biological projectiles
	ENERGY_ORB             # Slow-moving energy spheres
}

# --- Static Pool Management ---
static var _vfx_pools: Dictionary = {}
static var _scene_tree: SceneTree = null

func _ready() -> void:
	if not ProjectileVfxEnhanced._scene_tree:
		ProjectileVfxEnhanced._scene_tree = get_tree()

# =============================================================================
# Public API for Projectile VFX
# =============================================================================

## Create weapon-specific projectile VFX
static func create_projectile_vfx(
	start_pos: Vector3,
	end_pos: Vector3,
	weapon_type: String,
	travel_time: float = 1.0,
	homing: bool = false,
	target: Node = null
) -> void:
	var vfx_type := _get_vfx_type_for_weapon(weapon_type)
	match vfx_type:
		ProjectileVfxType.BULLET_TRACER:
			_create_bullet_tracer(start_pos, end_pos, travel_time)
		ProjectileVfxType.MISSILE_TRAIL:
			_create_missile_trail(start_pos, end_pos, travel_time, homing, target)
		ProjectileVfxType.ENERGY_BEAM:
			_create_energy_beam(start_pos, end_pos, weapon_type)
		ProjectileVfxType.RAILGUN_BOLT:
			_create_railgun_bolt(start_pos, end_pos, travel_time)
		ProjectileVfxType.PLASMA_BOLT:
			_create_plasma_bolt(start_pos, end_pos, travel_time)
		ProjectileVfxType.FLAME_STREAM:
			_create_flame_stream(start_pos, end_pos, travel_time)
		ProjectileVfxType.ELECTRIC_ARC:
			_create_electric_arc(start_pos, end_pos)
		ProjectileVfxType.ACID_GLOB:
			_create_acid_glob(start_pos, end_pos, travel_time)
		ProjectileVfxType.SPINE_DART:
			_create_spine_dart(start_pos, end_pos, travel_time)
		ProjectileVfxType.ENERGY_ORB:
			_create_energy_orb(start_pos, end_pos, travel_time, homing, target)

## Create enhanced muzzle flash for specific weapons
static func create_weapon_muzzle_flash(pos: Vector3, weapon_type: String, direction: Vector3 = Vector3.FORWARD) -> void:
	match weapon_type:
		"autocannon":
			VfxPool.play_muzzle_flash(pos, Color(1.0, 0.8, 0.2), 0.8, 0.08)
			# Add shell ejection sparks
			AmbientVfx.create_sparks_shower(pos + direction * 0.2, 0.5, 0.3)
		"missile_battery":
			VfxPool.play_muzzle_flash(pos, Color(1.0, 0.4, 0.0), 1.5, 0.15)
			VfxPool.play_smoke_puff(pos, direction * 0.5, 1.2)
		"rail_gun":
			# Charge-up effect followed by discharge
			VfxPool.play_energy_charge(pos, pos + direction, Color(0.3, 0.6, 1.0), 0.8)
			VfxPool.play_beam_hit(pos + direction * 0.3, Color(0.6, 0.9, 1.0), 2.0)
		"plasma_mortar":
			VfxPool.play_muzzle_flash(pos, Color(0.8, 0.2, 0.9), 2.0, 0.25)
			AmbientVfx.create_heat_shimmer(pos, 5.0, 1.0)
		"tesla_coil":
			VfxPool.play_beam_hit(pos, Color(0.4, 0.8, 1.0), 1.8)
			AmbientVfx.create_electric_arcs(pos, 1.5, 1.2)
		"inferno_tower":
			VfxPool.play_fire_burst(pos, 1.2, 1.5)
			AmbientVfx.create_fire_embers(pos, 4.0, 0.8)
		_:
			VfxPool.play_muzzle_flash(pos, Color.YELLOW, 1.0, 0.1)

## Create impact effects based on projectile and target types
static func create_projectile_impact(
	pos: Vector3,
	projectile_type: String,
	target_type: String = "generic",
	normal: Vector3 = Vector3.UP,
	damage: float = 10.0
) -> void:
	var intensity := clampf(damage / 50.0, 0.3, 2.0)
	
	match projectile_type:
		"autocannon":
			VfxPool.play_impact_spark(pos, normal, Color(1.0, 0.7, 0.3), intensity)
			if target_type == "armor":
				AmbientVfx.create_sparks_shower(pos, 1.5, intensity * 0.5)
		"missile":
			AmbientVfx.create_area_damage_effect(pos, intensity * 2.0, "explosive")
		"railgun":
			VfxPool.play_beam_hit(pos, Color(0.8, 0.9, 1.0), intensity * 1.5)
			AmbientVfx.create_energy_disturbance(pos, 3.0, intensity)
		"plasma":
			VfxPool.play_explosion(pos, intensity, Color(0.8, 0.2, 0.9))
			AmbientVfx.create_heat_shimmer(pos, 8.0, intensity * 0.8)
		"tesla":
			VfxPool.play_beam_hit(pos, Color(0.5, 0.9, 1.0), intensity)
			AmbientVfx.create_electric_arcs(pos, 2.0, intensity)
		"flame":
			VfxPool.play_fire_burst(pos, intensity, intensity)
			AmbientVfx.create_fire_embers(pos, 6.0, intensity * 0.7)
		"acid":
			VfxPool.play_impact_spark(pos, normal, Color(0.6, 0.8, 0.2), intensity)
			AmbientVfx.create_corruption_tendrils(pos, 5.0, intensity * 0.3)
		"spine":
			VfxPool.play_impact_spark(pos, normal, Color(0.9, 0.7, 0.4), intensity * 0.7)
		_:
			VfxPool.play_impact_spark(pos, normal, Color.WHITE, intensity)

# =============================================================================
# Internal VFX Creation Functions
# =============================================================================

static func _get_vfx_type_for_weapon(weapon_type: String) -> ProjectileVfxType:
	match weapon_type:
		"autocannon":
			return ProjectileVfxType.BULLET_TRACER
		"missile_battery":
			return ProjectileVfxType.MISSILE_TRAIL
		"rail_gun":
			return ProjectileVfxType.RAILGUN_BOLT
		"plasma_mortar":
			return ProjectileVfxType.PLASMA_BOLT
		"tesla_coil":
			return ProjectileVfxType.ELECTRIC_ARC
		"inferno_tower":
			return ProjectileVfxType.FLAME_STREAM
		"enemy_projectile":
			return ProjectileVfxType.SPINE_DART
		"energy_projectile":
			return ProjectileVfxType.ENERGY_ORB
		_:
			return ProjectileVfxType.BULLET_TRACER

static func _create_bullet_tracer(start_pos: Vector3, end_pos: Vector3, travel_time: float) -> void:
	# Fast tracer line for kinetic rounds
	var tracer := _create_tracer_line(start_pos, end_pos, Color(1.0, 0.8, 0.2), 0.03)
	var tween := tracer.get_meta("tween") as Tween
	
	# Quick fade out
	tween.tween_method(_fade_tracer_material.bind(tracer), 1.0, 0.0, travel_time)
	tween.tween_callback(tracer.queue_free).set_delay(travel_time)

static func _create_missile_trail(start_pos: Vector3, end_pos: Vector3, travel_time: float, homing: bool, target: Node) -> void:
	# Smoke trail for missiles
	var trail := _create_tracer_line(start_pos, end_pos, Color(0.8, 0.8, 0.7), 0.08)
	var tween := trail.get_meta("tween") as Tween
	
	# Add periodic smoke puffs along the trail
	var smoke_count := int(travel_time * 3.0)  # 3 puffs per second
	for i in range(smoke_count):
		var delay := (i * travel_time) / smoke_count
		var lerp_factor := float(i) / smoke_count
		var smoke_pos := start_pos.lerp(end_pos, lerp_factor)
		tween.tween_callback(VfxPool.play_smoke_puff.bind(smoke_pos, Vector3.ZERO, 0.5)).set_delay(delay)
	
	tween.tween_method(_fade_tracer_material.bind(trail), 1.0, 0.0, travel_time)
	tween.tween_callback(trail.queue_free).set_delay(travel_time + 1.0)

static func _create_energy_beam(start_pos: Vector3, end_pos: Vector3, weapon_type: String) -> void:
	# Instant beam for lasers/plasma
	var beam_color := Color(0.8, 0.2, 0.9) if weapon_type == "plasma_mortar" else Color(0.3, 0.6, 1.0)
	var beam := _create_tracer_line(start_pos, end_pos, beam_color, 0.05)
	var tween := beam.get_meta("tween") as Tween
	
	# Pulse effect
	tween.tween_method(_pulse_tracer_width.bind(beam), 0.05, 0.12, 0.1)
	tween.tween_method(_pulse_tracer_width.bind(beam), 0.12, 0.05, 0.1)
	tween.tween_method(_fade_tracer_material.bind(beam), 1.0, 0.0, 0.2).set_delay(0.1)
	tween.tween_callback(beam.queue_free).set_delay(0.4)

static func _create_railgun_bolt(start_pos: Vector3, end_pos: Vector3, travel_time: float) -> void:
	# High-energy bolt with electromagnetic field
	var bolt := _create_tracer_line(start_pos, end_pos, Color(0.6, 0.9, 1.0), 0.04)
	var tween := bolt.get_meta("tween") as Tween
	
	# Add secondary energy field
	var field := _create_tracer_line(start_pos, end_pos, Color(0.3, 0.6, 1.0), 0.08)
	field.get_child(0).material_override.albedo_color.a = 0.3
	
	tween.tween_method(_fade_tracer_material.bind(bolt), 1.0, 0.0, travel_time * 0.8)
	tween.tween_method(_fade_tracer_material.bind(field), 0.3, 0.0, travel_time * 1.2)
	tween.tween_callback(bolt.queue_free).set_delay(travel_time)
	tween.tween_callback(field.queue_free).set_delay(travel_time * 1.2)

static func _create_plasma_bolt(start_pos: Vector3, end_pos: Vector3, travel_time: float) -> void:
	# Glowing plasma projectile
	var bolt := _create_tracer_line(start_pos, end_pos, Color(0.8, 0.2, 0.9), 0.06)
	var tween := bolt.get_meta("tween") as Tween
	
	# Pulsing glow effect
	tween.set_loops()
	tween.tween_method(_pulse_tracer_emission.bind(bolt), 3.0, 5.0, 0.2)
	tween.tween_method(_pulse_tracer_emission.bind(bolt), 5.0, 3.0, 0.2)
	
	# Stop pulsing and fade
	tween.tween_callback(tween.stop).set_delay(travel_time)
	tween.tween_method(_fade_tracer_material.bind(bolt), 1.0, 0.0, 0.3).set_delay(travel_time)
	tween.tween_callback(bolt.queue_free).set_delay(travel_time + 0.3)

static func _create_flame_stream(start_pos: Vector3, end_pos: Vector3, travel_time: float) -> void:
	# Continuous flame stream
	var flame_count := int((end_pos - start_pos).length() * 5.0)  # 5 flames per unit
	var direction := (end_pos - start_pos).normalized()
	var distance := (end_pos - start_pos).length()
	
	for i in range(flame_count):
		var t := float(i) / flame_count
		var pos := start_pos + direction * distance * t
		var delay := travel_time * t * 0.3  # Flames start quickly
		
		if ProjectileVfxEnhanced._scene_tree:
			var timer := Timer.new()
			timer.wait_time = delay
			timer.one_shot = true
			timer.timeout.connect(VfxPool.play_fire_burst.bind(pos, 0.3, 1.0))
			timer.timeout.connect(timer.queue_free)
			ProjectileVfxEnhanced._scene_tree.current_scene.add_child(timer)
			timer.start()

static func _create_electric_arc(start_pos: Vector3, end_pos: Vector3) -> void:
	# Instant electrical discharge with branching
	var main_arc := _create_tracer_line(start_pos, end_pos, Color(0.5, 0.9, 1.0), 0.03)
	var tween := main_arc.get_meta("tween") as Tween
	
	# Add branching arcs
	var mid_point := start_pos.lerp(end_pos, 0.5)
	var branch_end1 := mid_point + Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * 0.8
	var branch_end2 := mid_point + Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * 0.6
	
	var branch1 := _create_tracer_line(mid_point, branch_end1, Color(0.4, 0.8, 1.0), 0.02)
	var branch2 := _create_tracer_line(mid_point, branch_end2, Color(0.4, 0.8, 1.0), 0.02)
	
	# Quick flash and fade
	tween.tween_method(_fade_tracer_material.bind(main_arc), 1.0, 0.0, 0.15)
	tween.tween_method(_fade_tracer_material.bind(branch1), 1.0, 0.0, 0.1).set_delay(0.05)
	tween.tween_method(_fade_tracer_material.bind(branch2), 1.0, 0.0, 0.1).set_delay(0.08)
	tween.tween_callback(main_arc.queue_free).set_delay(0.2)
	tween.tween_callback(branch1.queue_free).set_delay(0.2)
	tween.tween_callback(branch2.queue_free).set_delay(0.2)

static func _create_acid_glob(start_pos: Vector3, end_pos: Vector3, travel_time: float) -> void:
	# Corrosive projectile with dripping effect
	var glob := _create_tracer_line(start_pos, end_pos, Color(0.6, 0.8, 0.2), 0.05)
	var tween := glob.get_meta("tween") as Tween
	
	# Add dripping particles along path
	var drip_count := int(travel_time * 4.0)
	for i in range(drip_count):
		var delay := (i * travel_time) / drip_count
		var lerp_factor := float(i) / drip_count
		var drip_pos := start_pos.lerp(end_pos, lerp_factor)
		var fall_pos := drip_pos + Vector3(randf_range(-0.2, 0.2), -randf_range(0.5, 1.5), randf_range(-0.2, 0.2))
		
		tween.tween_callback(VfxPool.play_impact_spark.bind(fall_pos, Vector3.DOWN, Color(0.6, 0.8, 0.2), 0.3)).set_delay(delay)
	
	tween.tween_method(_fade_tracer_material.bind(glob), 1.0, 0.0, travel_time * 0.8)
	tween.tween_callback(glob.queue_free).set_delay(travel_time)

static func _create_spine_dart(start_pos: Vector3, end_pos: Vector3, travel_time: float) -> void:
	# Biological projectile
	var dart := _create_tracer_line(start_pos, end_pos, Color(0.9, 0.7, 0.4), 0.02)
	var tween := dart.get_meta("tween") as Tween
	
	tween.tween_method(_fade_tracer_material.bind(dart), 1.0, 0.0, travel_time)
	tween.tween_callback(dart.queue_free).set_delay(travel_time)

static func _create_energy_orb(start_pos: Vector3, end_pos: Vector3, travel_time: float, homing: bool, target: Node) -> void:
	# Slow-moving energy sphere
	var orb := _create_energy_sphere(start_pos, Color(0.4, 0.6, 1.0), 0.08)
	var tween := orb.get_meta("tween") as Tween
	
	# Move orb to target with slight curve if homing
	if homing and is_instance_valid(target):
		var curve_point := start_pos.lerp(end_pos, 0.5) + Vector3(randf_range(-2, 2), randf_range(1, 3), randf_range(-2, 2))
		tween.tween_property(orb, "global_position", curve_point, travel_time * 0.5)
		tween.tween_property(orb, "global_position", end_pos, travel_time * 0.5)
	else:
		tween.tween_property(orb, "global_position", end_pos, travel_time)
	
	# Pulsing glow during flight
	tween.parallel().tween_method(_pulse_sphere_emission.bind(orb), 2.0, 4.0, travel_time * 0.5)
	tween.parallel().tween_method(_pulse_sphere_emission.bind(orb), 4.0, 2.0, travel_time * 0.5).set_delay(travel_time * 0.5)
	
	tween.tween_callback(orb.queue_free).set_delay(travel_time)

# =============================================================================
# Helper Functions for VFX Creation
# =============================================================================

static func _create_tracer_line(start_pos: Vector3, end_pos: Vector3, color: Color, width: float) -> Node3D:
	var root := Node3D.new()
	root.name = "TracerLine"
	root.global_position = start_pos
	
	var line := MeshInstance3D.new()
	var cylinder_mesh := CylinderMesh.new()
	var distance := start_pos.distance_to(end_pos)
	cylinder_mesh.top_radius = width
	cylinder_mesh.bottom_radius = width
	cylinder_mesh.height = distance
	
	var material := StandardMaterial3D.new()
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 3.0
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cylinder_mesh.material = material
	
	line.mesh = cylinder_mesh
	line.name = "Line"
	
	# Orient towards target
	root.look_at(end_pos, Vector3.UP)
	line.position.z = distance * 0.5
	
	root.add_child(line)
	
	var tween := Tween.new()
	root.add_child(tween)
	root.set_meta("tween", tween)
	
	if ProjectileVfxEnhanced._scene_tree:
		ProjectileVfxEnhanced._scene_tree.current_scene.add_child(root)
	
	return root

static func _create_energy_sphere(pos: Vector3, color: Color, radius: float) -> Node3D:
	var root := Node3D.new()
	root.name = "EnergySphere"
	root.global_position = pos
	
	var sphere := MeshInstance3D.new()
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = radius
	sphere_mesh.height = radius * 2.0
	
	var material := StandardMaterial3D.new()
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 2.0
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.8
	sphere_mesh.material = material
	
	sphere.mesh = sphere_mesh
	sphere.name = "Sphere"
	root.add_child(sphere)
	
	var tween := Tween.new()
	root.add_child(tween)
	root.set_meta("tween", tween)
	
	if ProjectileVfxEnhanced._scene_tree:
		ProjectileVfxEnhanced._scene_tree.current_scene.add_child(root)
	
	return root

# =============================================================================
# Animation Helper Functions
# =============================================================================

static func _fade_tracer_material(tracer: Node3D, alpha: float) -> void:
	var line := tracer.get_node("Line") as MeshInstance3D
	if line and line.material_override:
		line.material_override.albedo_color.a = alpha

static func _pulse_tracer_width(tracer: Node3D, width: float) -> void:
	var line := tracer.get_node("Line") as MeshInstance3D
	if line and line.mesh is CylinderMesh:
		var mesh := line.mesh as CylinderMesh
		mesh.top_radius = width
		mesh.bottom_radius = width

static func _pulse_tracer_emission(tracer: Node3D, energy: float) -> void:
	var line := tracer.get_node("Line") as MeshInstance3D
	if line and line.material_override:
		line.material_override.emission_energy_multiplier = energy

static func _pulse_sphere_emission(sphere: Node3D, energy: float) -> void:
	var sphere_mesh := sphere.get_node("Sphere") as MeshInstance3D
	if sphere_mesh and sphere_mesh.material_override:
		sphere_mesh.material_override.emission_energy_multiplier = energy