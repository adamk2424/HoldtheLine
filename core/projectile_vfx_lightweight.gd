class_name ProjectileVfxLightweight
extends Node
## Lightweight projectile VFX system using only 2D effects and particles
## No 3D objects for maximum performance - uses sprites, quads, and particle systems

# --- Lightweight Effect Types ---
enum EffectType {
	SPRITE_TRAIL,       # 2D sprites following projectile path
	PARTICLE_STREAM,    # Particle system trail
	QUAD_FLASH,         # Billboard quad muzzle flash
	SCREEN_SPACE_LINE,  # 2D line renderer for instant hits
	ANIMATED_TEXTURE    # Animated sprite sequence
}

# --- Weapon Configuration ---
const WEAPON_CONFIGS := {
	"autocannon": {
		"muzzle_flash": {"type": EffectType.QUAD_FLASH, "color": Color(1.0, 0.8, 0.2), "size": 0.15, "duration": 0.08},
		"trail": {"type": EffectType.PARTICLE_STREAM, "color": Color(1.0, 0.9, 0.3), "particles": 20, "lifetime": 0.3},
		"impact": {"type": EffectType.SPRITE_TRAIL, "color": Color(1.0, 0.8, 0.0), "sparks": 8}
	},
	"missile_battery": {
		"muzzle_flash": {"type": EffectType.QUAD_FLASH, "color": Color(1.0, 0.6, 0.0), "size": 0.2, "duration": 0.12},
		"trail": {"type": EffectType.PARTICLE_STREAM, "color": Color(0.8, 0.8, 0.9), "particles": 50, "lifetime": 2.5},
		"impact": {"type": EffectType.ANIMATED_TEXTURE, "sequence": "explosion_small"}
	},
	"rail_gun": {
		"muzzle_flash": {"type": EffectType.SCREEN_SPACE_LINE, "color": Color(0.3, 0.8, 1.0), "width": 0.05, "duration": 0.06},
		"trail": {"type": EffectType.SCREEN_SPACE_LINE, "color": Color(0.4, 0.9, 1.0), "width": 0.03, "duration": 0.1},
		"impact": {"type": EffectType.ANIMATED_TEXTURE, "sequence": "electric_burst"}
	},
	"plasma_mortar": {
		"muzzle_flash": {"type": EffectType.QUAD_FLASH, "color": Color(0.8, 0.3, 1.0), "size": 0.25, "duration": 0.15},
		"trail": {"type": EffectType.PARTICLE_STREAM, "color": Color(0.7, 0.2, 0.9), "particles": 30, "lifetime": 1.0},
		"impact": {"type": EffectType.ANIMATED_TEXTURE, "sequence": "plasma_explosion"}
	},
	"tesla_coil": {
		"muzzle_flash": {"type": EffectType.ANIMATED_TEXTURE, "sequence": "electric_charge"},
		"trail": {"type": EffectType.SCREEN_SPACE_LINE, "color": Color(0.4, 0.8, 1.0), "width": 0.08, "zigzag": true},
		"impact": {"type": EffectType.PARTICLE_STREAM, "color": Color(0.3, 0.9, 1.0), "particles": 25, "electric": true}
	},
	"inferno_tower": {
		"muzzle_flash": {"type": EffectType.PARTICLE_STREAM, "color": Color(1.0, 0.4, 0.1), "particles": 15},
		"trail": {"type": EffectType.PARTICLE_STREAM, "color": Color(1.0, 0.5, 0.1), "particles": 40, "lifetime": 0.8},
		"impact": {"type": EffectType.PARTICLE_STREAM, "color": Color(1.0, 0.3, 0.0), "particles": 30, "fire": true}
	}
}

# --- Shared Resources ---
static var _quad_mesh: QuadMesh = null
static var _line_material: ShaderMaterial = null
static var _sprite_materials: Dictionary = {}

## Initialize lightweight VFX resources
static func initialize() -> void:
	_setup_shared_mesh()
	_setup_line_shader()
	_setup_sprite_materials()

## Create lightweight muzzle flash effect
static func create_muzzle_flash(weapon_type: String, position: Vector3, direction: Vector3) -> void:
	var config = WEAPON_CONFIGS.get(weapon_type, {})
	var flash_config = config.get("muzzle_flash", {})
	
	match flash_config.get("type", EffectType.QUAD_FLASH):
		EffectType.QUAD_FLASH:
			_create_quad_flash(position, direction, flash_config)
		EffectType.ANIMATED_TEXTURE:
			_create_animated_flash(position, direction, flash_config)
		EffectType.PARTICLE_STREAM:
			_create_particle_flash(position, direction, flash_config)
		EffectType.SCREEN_SPACE_LINE:
			_create_line_flash(position, direction, flash_config)

## Create lightweight projectile trail
static func create_projectile_trail(
	weapon_type: String, 
	start_pos: Vector3, 
	end_pos: Vector3, 
	travel_time: float,
	parent: Node3D
) -> void:
	var config = WEAPON_CONFIGS.get(weapon_type, {})
	var trail_config = config.get("trail", {})
	
	match trail_config.get("type", EffectType.PARTICLE_STREAM):
		EffectType.SPRITE_TRAIL:
			_create_sprite_trail(start_pos, end_pos, travel_time, trail_config, parent)
		EffectType.PARTICLE_STREAM:
			_create_particle_trail(start_pos, end_pos, travel_time, trail_config, parent)
		EffectType.SCREEN_SPACE_LINE:
			_create_line_trail(start_pos, end_pos, travel_time, trail_config, parent)

## Create lightweight impact effect
static func create_impact_effect(weapon_type: String, position: Vector3, normal: Vector3, parent: Node3D) -> void:
	var config = WEAPON_CONFIGS.get(weapon_type, {})
	var impact_config = config.get("impact", {})
	
	match impact_config.get("type", EffectType.PARTICLE_STREAM):
		EffectType.SPRITE_TRAIL:
			_create_impact_sprites(position, normal, impact_config, parent)
		EffectType.PARTICLE_STREAM:
			_create_impact_particles(position, normal, impact_config, parent)
		EffectType.ANIMATED_TEXTURE:
			_create_impact_animation(position, normal, impact_config, parent)

# =============================================================================
# Quad Flash Effects
# =============================================================================

static func _create_quad_flash(position: Vector3, direction: Vector3, config: Dictionary) -> void:
	var scene := Engine.get_main_loop().current_scene
	if not scene:
		return
	
	var flash := MeshInstance3D.new()
	flash.name = "MuzzleFlash"
	flash.mesh = _get_quad_mesh()
	
	# Create unshaded material with emission
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = config.get("color", Color.YELLOW)
	material.emission_enabled = true
	material.emission = config.get("color", Color.YELLOW)
	material.emission_energy_multiplier = 3.0
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	
	flash.material_override = material
	flash.position = position + direction * 0.1
	
	var size = config.get("size", 0.15)
	flash.scale = Vector3(size, size, size)
	
	scene.add_child(flash)
	
	# Animate flash
	var tween := scene.create_tween()
	var duration = config.get("duration", 0.08)
	tween.set_parallel(true)
	tween.tween_property(flash, "scale", Vector3(size * 1.5, size * 1.5, size * 1.5), duration * 0.3)
	tween.tween_property(flash, "modulate:a", 0.0, duration)
	tween.tween_callback(flash.queue_free).set_delay(duration)

# =============================================================================
# Particle Stream Effects
# =============================================================================

static func _create_particle_trail(
	start_pos: Vector3, 
	end_pos: Vector3, 
	travel_time: float, 
	config: Dictionary,
	parent: Node3D
) -> void:
	var particles := GPUParticles3D.new()
	particles.name = "ProjectileTrail"
	particles.emitting = true
	particles.amount = config.get("particles", 30)
	particles.lifetime = config.get("lifetime", 0.5)
	particles.explosiveness = 0.0
	
	# Create particle material
	var material := ParticleProcessMaterial.new()
	material.direction = Vector3(0, 0, 1)
	material.spread = 5.0
	material.initial_velocity_min = 0.1
	material.initial_velocity_max = 0.3
	material.gravity = Vector3.ZERO
	material.scale_min = 0.05
	material.scale_max = 0.1
	material.color = config.get("color", Color.CYAN)
	
	# Special effects based on weapon type
	if config.has("electric"):
		material.emission = Color(0.4, 0.9, 1.0)
		material.emission_energy = 2.0
	elif config.has("fire"):
		material.gravity = Vector3(0, -0.5, 0)
		material.scale_max = 0.2
		material.color_ramp = _create_fire_gradient()
	
	particles.process_material = material
	particles.position = start_pos
	
	# Orient toward target
	particles.look_at(end_pos, Vector3.UP)
	
	parent.add_child(particles)
	
	# Move particles along trajectory
	var tween := parent.create_tween()
	tween.tween_property(particles, "position", end_pos, travel_time)
	tween.tween_callback(particles.queue_free).set_delay(particles.lifetime)

static func _create_particle_flash(position: Vector3, direction: Vector3, config: Dictionary) -> void:
	var scene := Engine.get_main_loop().current_scene
	if not scene:
		return
	
	var particles := GPUParticles3D.new()
	particles.name = "MuzzleFlashParticles"
	particles.emitting = true
	particles.amount = config.get("particles", 15)
	particles.lifetime = 0.2
	particles.explosiveness = 1.0
	
	var material := ParticleProcessMaterial.new()
	material.direction = direction
	material.spread = 25.0
	material.initial_velocity_min = 2.0
	material.initial_velocity_max = 5.0
	material.gravity = Vector3.ZERO
	material.scale_min = 0.02
	material.scale_max = 0.08
	material.color = config.get("color", Color.YELLOW)
	
	particles.process_material = material
	particles.position = position
	scene.add_child(particles)
	
	# Auto cleanup
	scene.get_tree().create_timer(particles.lifetime + 0.1).timeout.connect(particles.queue_free)

static func _create_impact_particles(position: Vector3, normal: Vector3, config: Dictionary, parent: Node3D) -> void:
	var particles := GPUParticles3D.new()
	particles.name = "ImpactParticles"
	particles.emitting = true
	particles.amount = config.get("sparks", 20)
	particles.lifetime = 0.8
	particles.explosiveness = 1.0
	
	var material := ParticleProcessMaterial.new()
	material.direction = normal
	material.spread = 45.0
	material.initial_velocity_min = 1.0
	material.initial_velocity_max = 4.0
	material.gravity = Vector3(0, -9.8, 0)
	material.scale_min = 0.01
	material.scale_max = 0.05
	material.color = config.get("color", Color.ORANGE)
	
	if config.has("electric"):
		material.gravity = Vector3.ZERO
		material.color = Color(0.4, 0.9, 1.0)
		material.emission = Color(0.4, 0.9, 1.0)
		material.emission_energy = 2.0
	
	particles.process_material = material
	particles.position = position
	parent.add_child(particles)
	
	# Auto cleanup
	parent.get_tree().create_timer(particles.lifetime + 0.1).timeout.connect(particles.queue_free)

# =============================================================================
# Screen Space Line Effects
# =============================================================================

static func _create_line_trail(
	start_pos: Vector3, 
	end_pos: Vector3, 
	travel_time: float, 
	config: Dictionary,
	parent: Node3D
) -> void:
	var line := MeshInstance3D.new()
	line.name = "LineTrail"
	
	# Create cylinder mesh for line
	var cylinder := CylinderMesh.new()
	var length := start_pos.distance_to(end_pos)
	cylinder.top_radius = config.get("width", 0.03)
	cylinder.bottom_radius = config.get("width", 0.03)
	cylinder.height = length
	
	# Create line material
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = config.get("color", Color.CYAN)
	material.emission_enabled = true
	material.emission = config.get("color", Color.CYAN)
	material.emission_energy_multiplier = 2.0
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	cylinder.material = material
	line.mesh = cylinder
	
	# Position and orient line
	var midpoint := (start_pos + end_pos) / 2.0
	line.position = midpoint
	line.look_at(end_pos, Vector3.UP)
	line.rotate_object_local(Vector3.RIGHT, PI / 2.0)  # Align with direction
	
	parent.add_child(line)
	
	# Animate line fade
	var duration = max(travel_time * 0.3, 0.1)  # Line persists briefly
	var tween := parent.create_tween()
	tween.tween_property(line, "modulate:a", 0.0, duration)
	tween.tween_callback(line.queue_free)

static func _create_line_flash(position: Vector3, direction: Vector3, config: Dictionary) -> void:
	var scene := Engine.get_main_loop().current_scene
	if not scene:
		return
	
	var line := MeshInstance3D.new()
	line.name = "LineFlash"
	
	# Create short intense line
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = config.get("width", 0.05)
	cylinder.bottom_radius = 0.0  # Tapered
	cylinder.height = 0.3
	
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = config.get("color", Color.CYAN)
	material.emission_enabled = true
	material.emission = config.get("color", Color.CYAN)
	material.emission_energy_multiplier = 4.0
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	cylinder.material = material
	line.mesh = cylinder
	line.position = position
	line.look_at(position + direction, Vector3.UP)
	line.rotate_object_local(Vector3.RIGHT, PI / 2.0)
	
	scene.add_child(line)
	
	# Quick flash
	var duration = config.get("duration", 0.06)
	var tween := scene.create_tween()
	tween.tween_property(line, "modulate:a", 0.0, duration)
	tween.tween_callback(line.queue_free)

# =============================================================================
# Sprite Trail Effects
# =============================================================================

static func _create_sprite_trail(
	start_pos: Vector3, 
	end_pos: Vector3, 
	travel_time: float, 
	config: Dictionary,
	parent: Node3D
) -> void:
	var sprite_count := 8
	var direction := (end_pos - start_pos).normalized()
	var distance := start_pos.distance_to(end_pos)
	var step := distance / float(sprite_count)
	
	for i in range(sprite_count):
		var sprite := MeshInstance3D.new()
		sprite.name = "TrailSprite_" + str(i)
		sprite.mesh = _get_quad_mesh()
		
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color = config.get("color", Color.YELLOW)
		material.emission_enabled = true
		material.emission = config.get("color", Color.YELLOW)
		material.emission_energy_multiplier = 1.5
		material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		
		sprite.material_override = material
		sprite.position = start_pos + direction * (step * float(i))
		sprite.scale = Vector3(0.05, 0.05, 0.05)
		
		parent.add_child(sprite)
		
		# Animate sprite movement and fade
		var delay := (travel_time / float(sprite_count)) * float(i)
		var lifetime := 0.3
		
		var tween := parent.create_tween()
		tween.tween_delay(delay)
		tween.set_parallel(true)
		tween.tween_property(sprite, "position", end_pos, travel_time - delay)
		tween.tween_property(sprite, "modulate:a", 0.0, lifetime).set_delay(travel_time - delay)
		tween.tween_callback(sprite.queue_free).set_delay(travel_time - delay + lifetime)

static func _create_impact_sprites(position: Vector3, normal: Vector3, config: Dictionary, parent: Node3D) -> void:
	var spark_count := config.get("sparks", 8)
	
	for i in range(spark_count):
		var sprite := MeshInstance3D.new()
		sprite.name = "ImpactSpark_" + str(i)
		sprite.mesh = _get_quad_mesh()
		
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color = config.get("color", Color.ORANGE)
		material.emission_enabled = true
		material.emission = config.get("color", Color.ORANGE)
		material.emission_energy_multiplier = 2.0
		material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		
		sprite.material_override = material
		sprite.position = position
		sprite.scale = Vector3(0.03, 0.03, 0.03)
		
		parent.add_child(sprite)
		
		# Random spark direction influenced by surface normal
		var random_dir := Vector3(
			randf_range(-1.0, 1.0),
			randf_range(0.0, 1.0),
			randf_range(-1.0, 1.0)
		).normalized()
		random_dir = (normal + random_dir).normalized()
		
		var distance := randf_range(0.3, 0.8)
		var target_pos := position + random_dir * distance
		
		# Animate spark arc
		var tween := parent.create_tween()
		tween.set_parallel(true)
		tween.tween_property(sprite, "position", target_pos, 0.4)
		tween.tween_property(sprite, "scale", Vector3.ZERO, 0.4)
		tween.tween_property(sprite, "modulate:a", 0.0, 0.4)
		tween.tween_callback(sprite.queue_free)

# =============================================================================
# Animated Texture Effects
# =============================================================================

static func _create_animated_flash(position: Vector3, direction: Vector3, config: Dictionary) -> void:
	# Placeholder for animated texture sequences
	# Would use AnimationPlayer with texture changes for complex sequences
	_create_quad_flash(position, direction, config)  # Fallback to quad flash

static func _create_impact_animation(position: Vector3, normal: Vector3, config: Dictionary, parent: Node3D) -> void:
	var sequence := config.get("sequence", "explosion_small")
	
	match sequence:
		"explosion_small":
			_create_explosion_sprites(position, normal, 0.5, parent)
		"electric_burst":
			_create_electric_burst_sprites(position, normal, parent)
		"plasma_explosion":
			_create_plasma_explosion_sprites(position, normal, parent)
		_:
			_create_explosion_sprites(position, normal, 0.3, parent)

static func _create_explosion_sprites(position: Vector3, normal: Vector3, size: float, parent: Node3D) -> void:
	var explosion := MeshInstance3D.new()
	explosion.name = "ExplosionSprite"
	explosion.mesh = _get_quad_mesh()
	
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(1.0, 0.6, 0.2)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.5, 0.1)
	material.emission_energy_multiplier = 3.0
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	
	explosion.material_override = material
	explosion.position = position + normal * 0.1
	explosion.scale = Vector3(size * 0.3, size * 0.3, size * 0.3)
	
	parent.add_child(explosion)
	
	# Animate explosion
	var tween := parent.create_tween()
	tween.set_parallel(true)
	tween.tween_property(explosion, "scale", Vector3(size, size, size), 0.2)
	tween.tween_property(explosion, "modulate:a", 0.0, 0.3).set_delay(0.1)
	tween.tween_callback(explosion.queue_free)

static func _create_electric_burst_sprites(position: Vector3, normal: Vector3, parent: Node3D) -> void:
	# Multiple electric arcs
	for i in range(6):
		var arc := MeshInstance3D.new()
		arc.name = "ElectricArc_" + str(i)
		arc.mesh = _get_quad_mesh()
		
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color = Color(0.4, 0.9, 1.0)
		material.emission_enabled = true
		material.emission = Color(0.3, 0.8, 1.0)
		material.emission_energy_multiplier = 2.5
		material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		
		arc.material_override = material
		arc.position = position
		arc.scale = Vector3(0.02, 0.4, 0.02)
		
		# Random rotation
		arc.rotation_degrees = Vector3(
			randf_range(0, 360),
			randf_range(0, 360),
			randf_range(0, 360)
		)
		
		parent.add_child(arc)
		
		# Quick flash and fade
		var tween := parent.create_tween()
		tween.tween_property(arc, "modulate:a", 0.0, 0.15)
		tween.tween_callback(arc.queue_free)

static func _create_plasma_explosion_sprites(position: Vector3, normal: Vector3, parent: Node3D) -> void:
	var plasma_burst := MeshInstance3D.new()
	plasma_burst.name = "PlasmaExplosion"
	plasma_burst.mesh = _get_quad_mesh()
	
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.8, 0.3, 1.0)
	material.emission_enabled = true
	material.emission = Color(0.7, 0.2, 0.9)
	material.emission_energy_multiplier = 3.5
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	
	plasma_burst.material_override = material
	plasma_burst.position = position + normal * 0.15
	plasma_burst.scale = Vector3(0.2, 0.2, 0.2)
	
	parent.add_child(plasma_burst)
	
	# Plasma expansion and fade
	var tween := parent.create_tween()
	tween.set_parallel(true)
	tween.tween_property(plasma_burst, "scale", Vector3(0.8, 0.8, 0.8), 0.3)
	tween.tween_property(plasma_burst, "modulate:a", 0.0, 0.4).set_delay(0.2)
	tween.tween_callback(plasma_burst.queue_free)

# =============================================================================
# Utility Functions
# =============================================================================

static func _get_quad_mesh() -> QuadMesh:
	if not _quad_mesh:
		_quad_mesh = QuadMesh.new()
		_quad_mesh.size = Vector2(1.0, 1.0)
	return _quad_mesh

static func _setup_shared_mesh() -> void:
	_quad_mesh = QuadMesh.new()
	_quad_mesh.size = Vector2(1.0, 1.0)

static func _setup_line_shader() -> void:
	# Placeholder for custom line shader
	pass

static func _setup_sprite_materials() -> void:
	# Pre-create common materials for better performance
	pass

static func _create_fire_gradient() -> Gradient:
	var gradient := Gradient.new()
	gradient.add_point(0.0, Color(1.0, 0.8, 0.2))
	gradient.add_point(0.5, Color(1.0, 0.4, 0.1))
	gradient.add_point(1.0, Color(0.3, 0.1, 0.0))
	return gradient

## Cleanup all active lightweight effects
static func cleanup_effects() -> void:
	var scene := Engine.get_main_loop().current_scene
	if not scene:
		return
	
	# Find and remove all lightweight effects
	for child in scene.get_children():
		if child.name.begins_with("MuzzleFlash") or child.name.begins_with("ProjectileTrail") or child.name.begins_with("ImpactParticles"):
			child.queue_free()

## Get effect count for performance monitoring
static func get_active_effect_count() -> int:
	var scene := Engine.get_main_loop().current_scene
	if not scene:
		return 0
	
	var count := 0
	for child in scene.get_children():
		if child.name.contains("Flash") or child.name.contains("Trail") or child.name.contains("Impact"):
			count += 1
	
	return count