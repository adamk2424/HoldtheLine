class_name AmbientEffectsEnhanced
extends Node
## Enhanced ambient and environmental effects system
## Creates atmospheric effects, environmental hazards, and battlefield ambience

# --- Ambient Effect Categories ---
enum AmbientType {
	ATMOSPHERIC,        # Weather, air quality, lighting
	BATTLEFIELD,        # Smoke, fire, destruction debris
	ENVIRONMENTAL,      # Natural phenomena, terrain effects
	CORRUPTION,         # Alien influence, void corruption
	ENERGY_FIELDS,      # Shield domes, barrier walls
	INDUSTRIAL          # Steam vents, electrical sparks
}

# --- Effect Persistence Levels ---
enum PersistenceLevel {
	BRIEF,              # 1-3 seconds
	SHORT,              # 5-10 seconds  
	MEDIUM,             # 30-60 seconds
	LONG,               # 2-5 minutes
	PERMANENT           # Until manually cleared
}

# --- Global Effect Registry ---
static var _active_effects: Dictionary = {}
static var _effect_id_counter: int = 0

## Create atmospheric battlefield smoke
static func create_battlefield_smoke(
	position: Vector3, 
	radius: float = 5.0, 
	intensity: float = 1.0,
	duration: float = 30.0
) -> int:
	var effect_id := _get_next_effect_id()
	var smoke := _create_smoke_effect(position, radius, intensity, duration)
	_register_effect(effect_id, smoke, AmbientType.BATTLEFIELD)
	return effect_id

## Create electrical spark shower from damaged systems
static func create_spark_shower(
	position: Vector3,
	direction: Vector3,
	intensity: float = 1.0,
	duration: float = 15.0
) -> int:
	var effect_id := _get_next_effect_id()
	var sparks := _create_electrical_sparks(position, direction, intensity, duration)
	_register_effect(effect_id, sparks, AmbientType.INDUSTRIAL)
	return effect_id

## Create fire and ember effects from damage
static func create_fire_ambience(
	position: Vector3,
	size: float = 2.0,
	intensity: float = 1.0,
	duration: float = 45.0
) -> int:
	var effect_id := _get_next_effect_id()
	var fire := _create_fire_effect(position, size, intensity, duration)
	_register_effect(effect_id, fire, AmbientType.BATTLEFIELD)
	return effect_id

## Create alien corruption tendrils and void effects
static func create_corruption_field(
	center: Vector3,
	radius: float = 8.0,
	corruption_level: float = 1.0,
	duration: float = 60.0
) -> int:
	var effect_id := _get_next_effect_id()
	var corruption := _create_corruption_effect(center, radius, corruption_level, duration)
	_register_effect(effect_id, corruption, AmbientType.CORRUPTION)
	return effect_id

## Create energy shield dome visualization
static func create_energy_dome(
	center: Vector3,
	radius: float = 10.0,
	shield_color: Color = Color(0.3, 0.6, 1.0),
	duration: float = 120.0
) -> int:
	var effect_id := _get_next_effect_id()
	var dome := _create_shield_dome(center, radius, shield_color, duration)
	_register_effect(effect_id, dome, AmbientType.ENERGY_FIELDS)
	return effect_id

## Create heat shimmer from thermal weapons
static func create_heat_shimmer(
	position: Vector3,
	area: Vector3 = Vector3(3.0, 2.0, 3.0),
	intensity: float = 1.0,
	duration: float = 20.0
) -> int:
	var effect_id := _get_next_effect_id()
	var shimmer := _create_thermal_shimmer(position, area, intensity, duration)
	_register_effect(effect_id, shimmer, AmbientType.ATMOSPHERIC)
	return effect_id

## Create acid pool environmental hazard
static func create_acid_pool(
	position: Vector3,
	radius: float = 3.0,
	damage_per_second: float = 5.0,
	duration: float = 40.0
) -> int:
	var effect_id := _get_next_effect_id()
	var acid := _create_acid_hazard(position, radius, damage_per_second, duration)
	_register_effect(effect_id, acid, AmbientType.ENVIRONMENTAL)
	return effect_id

## Create plasma discharge ambient effect
static func create_plasma_discharge(
	position: Vector3,
	discharge_count: int = 5,
	radius: float = 4.0,
	duration: float = 25.0
) -> int:
	var effect_id := _get_next_effect_id()
	var plasma := _create_plasma_ambient(position, discharge_count, radius, duration)
	_register_effect(effect_id, plasma, AmbientType.ENERGY_FIELDS)
	return effect_id

## Create debris field from destroyed structures
static func create_debris_field(
	position: Vector3,
	debris_count: int = 15,
	spread_radius: float = 5.0,
	material_type: String = "concrete"
) -> int:
	var effect_id := _get_next_effect_id()
	var debris := _create_destruction_debris(position, debris_count, spread_radius, material_type)
	_register_effect(effect_id, debris, AmbientType.BATTLEFIELD)
	return effect_id

# =============================================================================
# Smoke Effects
# =============================================================================

static func _create_smoke_effect(position: Vector3, radius: float, intensity: float, duration: float) -> Node3D:
	var smoke_system := Node3D.new()
	smoke_system.name = "BattlefieldSmoke"
	smoke_system.position = position
	
	# Main dense smoke core
	var core_particles := GPUParticles3D.new()
	core_particles.name = "SmokeCore"
	core_particles.emitting = true
	core_particles.amount = int(50 * intensity)
	core_particles.lifetime = duration * 0.8
	core_particles.explosiveness = 0.0
	
	var core_material := ParticleProcessMaterial.new()
	core_material.direction = Vector3(0, 1, 0)
	core_material.spread = 25.0
	core_material.initial_velocity_min = 0.5
	core_material.initial_velocity_max = 2.0
	core_material.gravity = Vector3(0, -0.2, 0)  # Slight downward drift
	core_material.scale_min = radius * 0.2
	core_material.scale_max = radius * 0.8
	core_material.scale_over_velocity_min = 1.0
	core_material.scale_over_velocity_max = 1.5
	core_material.color = Color(0.3, 0.3, 0.35, 0.7)
	core_material.color_ramp = _create_smoke_gradient()
	
	core_particles.process_material = core_material
	smoke_system.add_child(core_particles)
	
	# Wispy smoke tendrils
	var wispy_particles := GPUParticles3D.new()
	wispy_particles.name = "SmokeWisps"
	wispy_particles.emitting = true
	wispy_particles.amount = int(30 * intensity)
	wispy_particles.lifetime = duration * 1.2
	wispy_particles.explosiveness = 0.0
	
	var wispy_material := ParticleProcessMaterial.new()
	wispy_material.direction = Vector3(0, 1, 0)
	wispy_material.spread = 45.0
	wispy_material.initial_velocity_min = 0.2
	wispy_material.initial_velocity_max = 1.0
	wispy_material.gravity = Vector3(0, 0.3, 0)  # Upward drift
	wispy_material.scale_min = radius * 0.1
	wispy_material.scale_max = radius * 0.5
	wispy_material.color = Color(0.4, 0.4, 0.45, 0.3)
	
	wispy_particles.process_material = wispy_material
	smoke_system.add_child(wispy_particles)
	
	# Add scene and setup cleanup
	var scene := Engine.get_main_loop().current_scene
	if scene:
		scene.add_child(smoke_system)
		
		# Gradually reduce emission over time
		var fade_time := duration * 0.3
		scene.get_tree().create_timer(duration - fade_time).timeout.connect(func():
			var tween := scene.create_tween()
			tween.set_parallel(true)
			tween.tween_method(func(amount): core_particles.amount = amount, 
				core_particles.amount, 0, fade_time)
			tween.tween_method(func(amount): wispy_particles.amount = amount,
				wispy_particles.amount, 0, fade_time)
		)
		
		# Final cleanup
		scene.get_tree().create_timer(duration + 5.0).timeout.connect(smoke_system.queue_free)
	
	return smoke_system

# =============================================================================
# Electrical Effects
# =============================================================================

static func _create_electrical_sparks(position: Vector3, direction: Vector3, intensity: float, duration: float) -> Node3D:
	var spark_system := Node3D.new()
	spark_system.name = "ElectricalSparks"
	spark_system.position = position
	
	# Main spark shower
	var sparks := GPUParticles3D.new()
	sparks.name = "SparkShower"
	sparks.emitting = true
	sparks.amount = int(40 * intensity)
	sparks.lifetime = 1.5
	sparks.explosiveness = 0.0
	
	var spark_material := ParticleProcessMaterial.new()
	spark_material.direction = direction
	spark_material.spread = 35.0
	spark_material.initial_velocity_min = 3.0
	spark_material.initial_velocity_max = 8.0
	spark_material.gravity = Vector3(0, -9.8, 0)
	spark_material.scale_min = 0.01
	spark_material.scale_max = 0.04
	spark_material.color = Color(1.0, 0.9, 0.3, 1.0)
	spark_material.emission = Color(1.0, 0.8, 0.2)
	spark_material.emission_energy = 2.0
	
	sparks.process_material = spark_material
	spark_system.add_child(sparks)
	
	# Electrical arcs
	var arc_timer := Timer.new()
	arc_timer.name = "ArcTimer"
	arc_timer.wait_time = 0.5
	arc_timer.timeout.connect(func(): _create_electric_arc(spark_system, position, intensity))
	spark_system.add_child(arc_timer)
	arc_timer.start()
	
	# Add to scene
	var scene := Engine.get_main_loop().current_scene
	if scene:
		scene.add_child(spark_system)
		
		# Stop arc timer after duration
		scene.get_tree().create_timer(duration).timeout.connect(func():
			arc_timer.stop()
			sparks.emitting = false
		)
		
		# Cleanup after sparks finish
		scene.get_tree().create_timer(duration + sparks.lifetime).timeout.connect(spark_system.queue_free)
	
	return spark_system

static func _create_electric_arc(parent: Node3D, origin: Vector3, intensity: float) -> void:
	var arc := MeshInstance3D.new()
	arc.name = "ElectricArc"
	
	# Random arc direction
	var target_offset := Vector3(
		randf_range(-2.0, 2.0),
		randf_range(-1.0, 3.0),
		randf_range(-2.0, 2.0)
	) * intensity
	
	var start := origin
	var end := origin + target_offset
	var distance := start.distance_to(end)
	
	# Create arc mesh
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.02 * intensity
	cylinder.bottom_radius = 0.01 * intensity
	cylinder.height = distance
	
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.3, 0.8, 1.0, 0.8)
	material.emission_enabled = true
	material.emission = Color(0.4, 0.9, 1.0)
	material.emission_energy_multiplier = 3.0
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	cylinder.material = material
	arc.mesh = cylinder
	
	# Position and orient arc
	var midpoint := (start + end) / 2.0
	arc.position = midpoint
	arc.look_at(end, Vector3.UP)
	arc.rotate_object_local(Vector3.RIGHT, PI / 2.0)
	
	parent.add_child(arc)
	
	# Brief flash
	var tween := parent.create_tween()
	tween.tween_property(arc, "modulate:a", 0.0, 0.2)
	tween.tween_callback(arc.queue_free)

# =============================================================================
# Fire Effects
# =============================================================================

static func _create_fire_effect(position: Vector3, size: float, intensity: float, duration: float) -> Node3D:
	var fire_system := Node3D.new()
	fire_system.name = "FireAmbience"
	fire_system.position = position
	
	# Main fire particles
	var fire_particles := GPUParticles3D.new()
	fire_particles.name = "FireCore"
	fire_particles.emitting = true
	fire_particles.amount = int(60 * intensity)
	fire_particles.lifetime = 2.0
	fire_particles.explosiveness = 0.0
	
	var fire_material := ParticleProcessMaterial.new()
	fire_material.direction = Vector3(0, 1, 0)
	fire_material.spread = 20.0
	fire_material.initial_velocity_min = 1.0
	fire_material.initial_velocity_max = 4.0
	fire_material.gravity = Vector3(0, 2.0, 0)  # Upward convection
	fire_material.scale_min = size * 0.2
	fire_material.scale_max = size * 0.8
	fire_material.color_ramp = _create_fire_gradient()
	
	fire_particles.process_material = fire_material
	fire_system.add_child(fire_particles)
	
	# Floating ember particles
	var embers := GPUParticles3D.new()
	embers.name = "Embers"
	embers.emitting = true
	embers.amount = int(25 * intensity)
	embers.lifetime = 5.0
	embers.explosiveness = 0.0
	
	var ember_material := ParticleProcessMaterial.new()
	ember_material.direction = Vector3(0, 1, 0)
	ember_material.spread = 45.0
	ember_material.initial_velocity_min = 0.5
	ember_material.initial_velocity_max = 2.0
	ember_material.gravity = Vector3(0, 1.0, 0)
	ember_material.scale_min = 0.02
	ember_material.scale_max = 0.08
	ember_material.color = Color(1.0, 0.4, 0.0, 0.8)
	ember_material.emission = Color(1.0, 0.3, 0.0)
	ember_material.emission_energy = 1.5
	
	embers.process_material = ember_material
	fire_system.add_child(embers)
	
	# Add heat shimmer effect
	_add_heat_shimmer_to_fire(fire_system, Vector3(size, size * 2, size))
	
	# Add to scene
	var scene := Engine.get_main_loop().current_scene
	if scene:
		scene.add_child(fire_system)
		
		# Gradually reduce fire over time
		var fade_start := duration * 0.7
		scene.get_tree().create_timer(fade_start).timeout.connect(func():
			var fade_time := duration - fade_start
			var tween := scene.create_tween()
			tween.set_parallel(true)
			tween.tween_method(func(amount): fire_particles.amount = amount,
				fire_particles.amount, 0, fade_time)
			tween.tween_method(func(amount): embers.amount = amount,
				embers.amount, int(5 * intensity), fade_time)
		)
		
		scene.get_tree().create_timer(duration + 5.0).timeout.connect(fire_system.queue_free)
	
	return fire_system

# =============================================================================
# Corruption Effects
# =============================================================================

static func _create_corruption_effect(center: Vector3, radius: float, corruption_level: float, duration: float) -> Node3D:
	var corruption_system := Node3D.new()
	corruption_system.name = "CorruptionField"
	corruption_system.position = center
	
	# Dark energy tendrils
	var tendrils := Node3D.new()
	tendrils.name = "VoidTendrils"
	corruption_system.add_child(tendrils)
	
	var tendril_count := int(8 * corruption_level)
	for i in range(tendril_count):
		var tendril := MeshInstance3D.new()
		tendril.name = "Tendril_" + str(i)
		
		# Create undulating tendril shape
		var capsule := CapsuleMesh.new()
		capsule.radius = 0.1 * corruption_level
		capsule.height = radius * 0.8
		
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color = Color(0.3, 0.1, 0.5, 0.6)
		material.emission_enabled = true
		material.emission = Color(0.4, 0.0, 0.8)
		material.emission_energy_multiplier = 1.5
		
		capsule.material = material
		tendril.mesh = capsule
		
		# Position at circle edge
		var angle := (i / float(tendril_count)) * TAU
		tendril.position = Vector3(
			cos(angle) * radius * 0.5,
			0.0,
			sin(angle) * radius * 0.5
		)
		tendril.rotation_degrees = Vector3(90, angle * 180 / PI, 0)
		
		tendrils.add_child(tendril)
		
		# Undulating animation
		var tween := corruption_system.create_tween()
		tween.set_loops()
		tween.tween_property(tendril, "position:y", radius * 0.3, 2.0 + randf() * 2.0)
		tween.tween_property(tendril, "position:y", -radius * 0.1, 2.0 + randf() * 2.0)
	
	# Corruption particles
	var void_particles := GPUParticles3D.new()
	void_particles.name = "VoidParticles"
	void_particles.emitting = true
	void_particles.amount = int(40 * corruption_level)
	void_particles.lifetime = 8.0
	void_particles.explosiveness = 0.0
	
	var void_material := ParticleProcessMaterial.new()
	void_material.direction = Vector3(0, 1, 0)
	void_material.spread = 15.0
	void_material.initial_velocity_min = 0.2
	void_material.initial_velocity_max = 1.0
	void_material.gravity = Vector3.ZERO
	void_material.scale_min = 0.05
	void_material.scale_max = 0.2
	void_material.color = Color(0.2, 0.0, 0.4, 0.7)
	void_material.emission = Color(0.3, 0.0, 0.6)
	void_material.emission_energy = 2.0
	
	void_particles.process_material = void_material
	corruption_system.add_child(void_particles)
	
	# Add to scene
	var scene := Engine.get_main_loop().current_scene
	if scene:
		scene.add_child(corruption_system)
		scene.get_tree().create_timer(duration).timeout.connect(func():
			# Fade out effect
			var fade_tween := scene.create_tween()
			fade_tween.tween_property(corruption_system, "modulate:a", 0.0, 3.0)
			fade_tween.tween_callback(corruption_system.queue_free)
		)
	
	return corruption_system

# =============================================================================
# Energy Field Effects
# =============================================================================

static func _create_shield_dome(center: Vector3, radius: float, shield_color: Color, duration: float) -> Node3D:
	var dome_system := Node3D.new()
	dome_system.name = "EnergyDome"
	dome_system.position = center
	
	# Main dome sphere
	var dome := MeshInstance3D.new()
	dome.name = "DomeMesh"
	
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(shield_color.r, shield_color.g, shield_color.b, 0.15)
	material.emission_enabled = true
	material.emission = shield_color
	material.emission_energy_multiplier = 0.8
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED
	
	sphere.material = material
	dome.mesh = sphere
	dome_system.add_child(dome)
	
	# Energy field particles
	var field_particles := GPUParticles3D.new()
	field_particles.name = "FieldParticles"
	field_particles.emitting = true
	field_particles.amount = 30
	field_particles.lifetime = 3.0
	field_particles.explosiveness = 0.0
	
	var field_material := ParticleProcessMaterial.new()
	field_material.direction = Vector3(0, 1, 0)
	field_material.spread = 90.0
	field_material.initial_velocity_min = radius * 0.1
	field_material.initial_velocity_max = radius * 0.3
	field_material.gravity = Vector3.ZERO
	field_material.scale_min = 0.02
	field_material.scale_max = 0.08
	field_material.color = shield_color
	field_material.emission = shield_color
	field_material.emission_energy = 1.5
	
	field_particles.process_material = field_material
	dome_system.add_child(field_particles)
	
	# Dome pulsing animation
	var pulse_tween := dome_system.create_tween()
	pulse_tween.set_loops()
	pulse_tween.tween_property(dome, "scale", Vector3(1.05, 1.05, 1.05), 2.0)
	pulse_tween.tween_property(dome, "scale", Vector3(0.98, 0.98, 0.98), 2.0)
	
	# Add to scene
	var scene := Engine.get_main_loop().current_scene
	if scene:
		scene.add_child(dome_system)
		if duration > 0:
			scene.get_tree().create_timer(duration).timeout.connect(func():
				pulse_tween.kill()
				var fade_tween := scene.create_tween()
				fade_tween.tween_property(dome_system, "modulate:a", 0.0, 2.0)
				fade_tween.tween_callback(dome_system.queue_free)
			)
	
	return dome_system

# =============================================================================
# Environmental Hazard Effects
# =============================================================================

static func _create_acid_hazard(position: Vector3, radius: float, dps: float, duration: float) -> Node3D:
	var acid_system := Node3D.new()
	acid_system.name = "AcidPool"
	acid_system.position = position
	
	# Acid pool base
	var pool := MeshInstance3D.new()
	pool.name = "AcidBase"
	
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius * 0.8
	cylinder.height = 0.05
	
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.5, 0.9, 0.3, 0.8)
	material.emission_enabled = true
	material.emission = Color(0.4, 0.8, 0.2)
	material.emission_energy_multiplier = 1.0
	
	cylinder.material = material
	pool.mesh = cylinder
	pool.position.y = -0.025
	acid_system.add_child(pool)
	
	# Acid bubbles
	var bubbles := GPUParticles3D.new()
	bubbles.name = "AcidBubbles"
	bubbles.emitting = true
	bubbles.amount = int(15 * (radius / 2.0))
	bubbles.lifetime = 2.0
	bubbles.explosiveness = 0.0
	
	var bubble_material := ParticleProcessMaterial.new()
	bubble_material.direction = Vector3(0, 1, 0)
	bubble_material.spread = 10.0
	bubble_material.initial_velocity_min = 0.3
	bubble_material.initial_velocity_max = 1.0
	bubble_material.gravity = Vector3(0, -0.5, 0)
	bubble_material.scale_min = 0.03
	bubble_material.scale_max = 0.1
	bubble_material.color = Color(0.6, 1.0, 0.4, 0.6)
	
	bubbles.process_material = bubble_material
	acid_system.add_child(bubbles)
	
	# Corrosive vapor
	var vapor := GPUParticles3D.new()
	vapor.name = "CorrosiveVapor"
	vapor.emitting = true
	vapor.amount = int(8 * (radius / 2.0))
	vapor.lifetime = 4.0
	vapor.explosiveness = 0.0
	
	var vapor_material := ParticleProcessMaterial.new()
	vapor_material.direction = Vector3(0, 1, 0)
	vapor_material.spread = 25.0
	vapor_material.initial_velocity_min = 0.2
	vapor_material.initial_velocity_max = 0.8
	vapor_material.gravity = Vector3(0, 0.1, 0)
	vapor_material.scale_min = radius * 0.3
	vapor_material.scale_max = radius * 0.8
	vapor_material.color = Color(0.4, 0.8, 0.2, 0.3)
	
	vapor.process_material = vapor_material
	acid_system.add_child(vapor)
	
	# Damage area (for game logic to hook into)
	var damage_area := Area3D.new()
	damage_area.name = "DamageArea"
	var collision_shape := CollisionShape3D.new()
	var cylinder_shape := CylinderShape3D.new()
	cylinder_shape.height = 2.0
	cylinder_shape.top_radius = radius
	cylinder_shape.bottom_radius = radius
	collision_shape.shape = cylinder_shape
	damage_area.add_child(collision_shape)
	acid_system.add_child(damage_area)
	
	# Store damage data for game systems
	acid_system.set_meta("damage_per_second", dps)
	acid_system.set_meta("hazard_type", "acid")
	acid_system.set_meta("radius", radius)
	
	# Add to scene
	var scene := Engine.get_main_loop().current_scene
	if scene:
		scene.add_child(acid_system)
		scene.get_tree().create_timer(duration).timeout.connect(func():
			# Fade effect
			var fade_tween := scene.create_tween()
			fade_tween.set_parallel(true)
			fade_tween.tween_property(pool, "modulate:a", 0.0, 3.0)
			fade_tween.tween_property(bubbles, "modulate:a", 0.0, 3.0)
			fade_tween.tween_property(vapor, "modulate:a", 0.0, 3.0)
			fade_tween.tween_callback(acid_system.queue_free).set_delay(3.0)
		)
	
	return acid_system

# =============================================================================
# Utility Functions
# =============================================================================

static func _add_heat_shimmer_to_fire(parent: Node3D, area: Vector3) -> void:
	# Placeholder - would use shader effects for heat distortion
	# For now, add subtle particle shimmer
	var shimmer := GPUParticles3D.new()
	shimmer.name = "HeatShimmer"
	shimmer.emitting = true
	shimmer.amount = 10
	shimmer.lifetime = 1.5
	shimmer.explosiveness = 0.0
	
	var shimmer_material := ParticleProcessMaterial.new()
	shimmer_material.direction = Vector3(0, 1, 0)
	shimmer_material.spread = 15.0
	shimmer_material.initial_velocity_min = 0.8
	shimmer_material.initial_velocity_max = 2.0
	shimmer_material.gravity = Vector3(0, 2.0, 0)
	shimmer_material.scale_min = area.x * 0.8
	shimmer_material.scale_max = area.x * 1.2
	shimmer_material.color = Color(1.0, 1.0, 1.0, 0.1)
	
	shimmer.process_material = shimmer_material
	parent.add_child(shimmer)

static func _create_thermal_shimmer(position: Vector3, area: Vector3, intensity: float, duration: float) -> Node3D:
	var shimmer_system := Node3D.new()
	shimmer_system.name = "ThermalShimmer"
	shimmer_system.position = position
	
	# Heat distortion particles
	var particles := GPUParticles3D.new()
	particles.name = "ShimmerParticles"
	particles.emitting = true
	particles.amount = int(15 * intensity)
	particles.lifetime = 3.0
	particles.explosiveness = 0.0
	
	var material := ParticleProcessMaterial.new()
	material.direction = Vector3(0, 1, 0)
	material.spread = 20.0
	material.initial_velocity_min = 0.5
	material.initial_velocity_max = 1.5
	material.gravity = Vector3(0, 1.0, 0)
	material.scale_min = area.x * 0.5
	material.scale_max = area.x * 1.0
	material.color = Color(1.0, 1.0, 1.0, 0.15)
	
	particles.process_material = material
	shimmer_system.add_child(particles)
	
	# Add to scene with cleanup
	var scene := Engine.get_main_loop().current_scene
	if scene:
		scene.add_child(shimmer_system)
		scene.get_tree().create_timer(duration).timeout.connect(func():
			particles.emitting = false
		)
		scene.get_tree().create_timer(duration + particles.lifetime).timeout.connect(shimmer_system.queue_free)
	
	return shimmer_system

static func _create_plasma_ambient(position: Vector3, discharge_count: int, radius: float, duration: float) -> Node3D:
	var plasma_system := Node3D.new()
	plasma_system.name = "PlasmaDischarge"
	plasma_system.position = position
	
	# Plasma field base
	var field := MeshInstance3D.new()
	field.name = "PlasmaField"
	
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.7, 0.2, 1.0, 0.2)
	material.emission_enabled = true
	material.emission = Color(0.8, 0.3, 1.0)
	material.emission_energy_multiplier = 1.2
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	sphere.material = material
	field.mesh = sphere
	plasma_system.add_child(field)
	
	# Random discharge timer
	var discharge_timer := Timer.new()
	discharge_timer.name = "DischargeTimer"
	discharge_timer.wait_time = 2.0
	discharge_timer.timeout.connect(func(): _create_plasma_bolt(plasma_system, radius))
	plasma_system.add_child(discharge_timer)
	discharge_timer.start()
	
	# Add to scene
	var scene := Engine.get_main_loop().current_scene
	if scene:
		scene.add_child(plasma_system)
		scene.get_tree().create_timer(duration).timeout.connect(func():
			discharge_timer.stop()
			var fade_tween := scene.create_tween()
			fade_tween.tween_property(plasma_system, "modulate:a", 0.0, 2.0)
			fade_tween.tween_callback(plasma_system.queue_free)
		)
	
	return plasma_system

static func _create_plasma_bolt(parent: Node3D, max_radius: float) -> void:
	var bolt := MeshInstance3D.new()
	bolt.name = "PlasmaBolt"
	
	var start := Vector3.ZERO
	var end := Vector3(
		randf_range(-max_radius, max_radius),
		randf_range(-max_radius * 0.5, max_radius * 0.5),
		randf_range(-max_radius, max_radius)
	)
	var distance := start.distance_to(end)
	
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.03
	cylinder.bottom_radius = 0.01
	cylinder.height = distance
	
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.8, 0.4, 1.0, 0.9)
	material.emission_enabled = true
	material.emission = Color(0.9, 0.5, 1.0)
	material.emission_energy_multiplier = 3.0
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	cylinder.material = material
	bolt.mesh = cylinder
	
	var midpoint := (start + end) / 2.0
	bolt.position = midpoint
	bolt.look_at(end, Vector3.UP)
	bolt.rotate_object_local(Vector3.RIGHT, PI / 2.0)
	
	parent.add_child(bolt)
	
	# Quick flash
	var tween := parent.create_tween()
	tween.tween_property(bolt, "modulate:a", 0.0, 0.3)
	tween.tween_callback(bolt.queue_free)

static func _create_destruction_debris(position: Vector3, debris_count: int, spread_radius: float, material_type: String) -> Node3D:
	var debris_system := Node3D.new()
	debris_system.name = "DestructionDebris"
	debris_system.position = position
	
	var debris_color: Color
	var debris_size_range: Vector2
	
	match material_type:
		"concrete":
			debris_color = Color(0.7, 0.7, 0.75)
			debris_size_range = Vector2(0.1, 0.4)
		"metal":
			debris_color = Color(0.6, 0.6, 0.7)
			debris_size_range = Vector2(0.05, 0.3)
		"crystal":
			debris_color = Color(0.8, 0.9, 1.0)
			debris_size_range = Vector2(0.08, 0.25)
		_:
			debris_color = Color(0.5, 0.5, 0.5)
			debris_size_range = Vector2(0.1, 0.3)
	
	for i in range(debris_count):
		var debris := MeshInstance3D.new()
		debris.name = "Debris_" + str(i)
		
		var size := randf_range(debris_size_range.x, debris_size_range.y)
		var box := BoxMesh.new()
		box.size = Vector3(size, size * randf_range(0.5, 1.5), size * randf_range(0.7, 1.3))
		
		var material := StandardMaterial3D.new()
		material.albedo_color = debris_color.lerp(Color.BLACK, randf_range(0.0, 0.3))
		material.roughness = 0.9
		material.metallic = 0.1 if material_type != "metal" else 0.7
		
		box.material = material
		debris.mesh = box
		
		# Random position within spread radius
		var angle := randf() * TAU
		var distance := randf_range(0.0, spread_radius)
		debris.position = Vector3(
			cos(angle) * distance,
			randf_range(0.0, 1.0),
			sin(angle) * distance
		)
		
		# Random rotation
		debris.rotation_degrees = Vector3(
			randf_range(0, 360),
			randf_range(0, 360),
			randf_range(0, 360)
		)
		
		debris_system.add_child(debris)
	
	# Add to scene - debris is permanent unless manually cleaned
	var scene := Engine.get_main_loop().current_scene
	if scene:
		scene.add_child(debris_system)
	
	return debris_system

# =============================================================================
# Gradient Creation Utilities
# =============================================================================

static func _create_smoke_gradient() -> Gradient:
	var gradient := Gradient.new()
	gradient.add_point(0.0, Color(0.4, 0.4, 0.45, 0.8))
	gradient.add_point(0.3, Color(0.3, 0.3, 0.35, 0.6))
	gradient.add_point(0.7, Color(0.2, 0.2, 0.25, 0.3))
	gradient.add_point(1.0, Color(0.1, 0.1, 0.15, 0.0))
	return gradient

static func _create_fire_gradient() -> Gradient:
	var gradient := Gradient.new()
	gradient.add_point(0.0, Color(1.0, 0.9, 0.2, 1.0))
	gradient.add_point(0.3, Color(1.0, 0.5, 0.1, 0.9))
	gradient.add_point(0.6, Color(0.8, 0.2, 0.0, 0.7))
	gradient.add_point(1.0, Color(0.2, 0.0, 0.0, 0.0))
	return gradient

# =============================================================================
# Effect Management
# =============================================================================

static func _get_next_effect_id() -> int:
	_effect_id_counter += 1
	return _effect_id_counter

static func _register_effect(effect_id: int, effect_node: Node3D, effect_type: AmbientType) -> void:
	_active_effects[effect_id] = {
		"node": effect_node,
		"type": effect_type,
		"created_time": Time.get_ticks_msec()
	}

## Remove specific effect by ID
static func remove_effect(effect_id: int) -> bool:
	if not _active_effects.has(effect_id):
		return false
	
	var effect_data = _active_effects[effect_id]
	var node = effect_data.get("node")
	if node and is_instance_valid(node):
		node.queue_free()
	
	_active_effects.erase(effect_id)
	return true

## Clear all effects of specific type
static func clear_effects_by_type(effect_type: AmbientType) -> int:
	var cleared_count := 0
	var to_remove: Array = []
	
	for effect_id in _active_effects:
		var effect_data = _active_effects[effect_id]
		if effect_data.get("type") == effect_type:
			var node = effect_data.get("node")
			if node and is_instance_valid(node):
				node.queue_free()
			to_remove.append(effect_id)
			cleared_count += 1
	
	for id in to_remove:
		_active_effects.erase(id)
	
	return cleared_count

## Get statistics about active ambient effects
static func get_ambient_effect_stats() -> Dictionary:
	var stats := {}
	var total_active := 0
	
	# Count by type
	for type in AmbientType.values():
		stats[AmbientType.keys()[type]] = 0
	
	for effect_id in _active_effects:
		var effect_data = _active_effects[effect_id]
		if is_instance_valid(effect_data.get("node")):
			var type_name = AmbientType.keys()[effect_data.get("type")]
			stats[type_name] += 1
			total_active += 1
	
	stats["TOTAL_ACTIVE"] = total_active
	stats["TOTAL_REGISTERED"] = _active_effects.size()
	
	return stats

## Cleanup invalid effects
static func cleanup_invalid_effects() -> void:
	var to_remove: Array = []
	
	for effect_id in _active_effects:
		var effect_data = _active_effects[effect_id]
		var node = effect_data.get("node")
		if not node or not is_instance_valid(node):
			to_remove.append(effect_id)
	
	for id in to_remove:
		_active_effects.erase(id)