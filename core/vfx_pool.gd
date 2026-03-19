class_name VfxPool
extends Node
## VFX Pool - Manages reusable lightweight visual effects for projectiles and impacts
## Uses particle systems and emissive spheres to create effects without complex 3D objects

# --- Static Pool Management ---
static var _pools: Dictionary = {}
static var _scene_tree: SceneTree = null

# --- Effect Types ---
enum EffectType {
	MUZZLE_FLASH,
	PROJECTILE_TRAIL,
	IMPACT_SPARK,
	EXPLOSION,
	ENERGY_CHARGE,
	BEAM_HIT,
	SMOKE_PUFF,
	FIRE_BURST
}

# --- Pool Storage ---
var _available_effects: Dictionary = {}
var _active_effects: Array[Node] = []
var _max_pool_size: int = 100
var _effect_scenes: Dictionary = {}

func _ready() -> void:
	VfxPool._scene_tree = get_tree()
	if not VfxPool._pools.has("main"):
		VfxPool._pools["main"] = self
	_initialize_effect_pools()

func _initialize_effect_pools() -> void:
	for effect_type in EffectType.values():
		_available_effects[effect_type] = []

# =============================================================================
# Public API
# =============================================================================

## Get the main VFX pool instance
static func get_main_pool() -> VfxPool:
	if VfxPool._pools.has("main"):
		return VfxPool._pools["main"]
	
	# Create main pool if it doesn't exist
	var pool := VfxPool.new()
	pool.name = "VfxPool"
	VfxPool._scene_tree.current_scene.add_child(pool)
	VfxPool._pools["main"] = pool
	return pool

## Play a muzzle flash effect at the given position
static func play_muzzle_flash(pos: Vector3, color: Color = Color.YELLOW, scale: float = 1.0, duration: float = 0.15) -> void:
	var pool := get_main_pool()
	var effect := pool._acquire_effect(EffectType.MUZZLE_FLASH, pos)
	pool._configure_muzzle_flash(effect, pos, color, scale, duration)

## Play a projectile trail effect 
static func play_projectile_trail(pos: Vector3, direction: Vector3, color: Color = Color.CYAN, length: float = 0.5) -> void:
	var pool := get_main_pool()
	var effect := pool._acquire_effect(EffectType.PROJECTILE_TRAIL, pos)
	pool._configure_projectile_trail(effect, pos, direction, color, length)

## Play an impact spark effect
static func play_impact_spark(pos: Vector3, normal: Vector3, color: Color = Color.ORANGE, intensity: float = 1.0) -> void:
	var pool := get_main_pool()
	var effect := pool._acquire_effect(EffectType.IMPACT_SPARK, pos)
	pool._configure_impact_spark(effect, pos, normal, color, intensity)

## Play an explosion effect
static func play_explosion(pos: Vector3, size: float = 1.0, color: Color = Color.RED) -> void:
	var pool := get_main_pool()
	var effect := pool._acquire_effect(EffectType.EXPLOSION, pos)
	pool._configure_explosion(effect, pos, size, color)

## Play an energy charging effect
static func play_energy_charge(pos: Vector3, target_pos: Vector3, color: Color = Color.BLUE, charge_time: float = 1.0) -> void:
	var pool := get_main_pool()
	var effect := pool._acquire_effect(EffectType.ENERGY_CHARGE, pos)
	pool._configure_energy_charge(effect, pos, target_pos, color, charge_time)

## Play a beam hit effect
static func play_beam_hit(pos: Vector3, color: Color = Color.WHITE, intensity: float = 1.0) -> void:
	var pool := get_main_pool()
	var effect := pool._acquire_effect(EffectType.BEAM_HIT, pos)
	pool._configure_beam_hit(effect, pos, color, intensity)

## Play a smoke puff effect
static func play_smoke_puff(pos: Vector3, velocity: Vector3 = Vector3.ZERO, size: float = 1.0) -> void:
	var pool := get_main_pool()
	var effect := pool._acquire_effect(EffectType.SMOKE_PUFF, pos)
	pool._configure_smoke_puff(effect, pos, velocity, size)

## Play a fire burst effect
static func play_fire_burst(pos: Vector3, size: float = 1.0, intensity: float = 1.0) -> void:
	var pool := get_main_pool()
	var effect := pool._acquire_effect(EffectType.FIRE_BURST, pos)
	pool._configure_fire_burst(effect, pos, size, intensity)

# =============================================================================
# Internal Pool Management
# =============================================================================

func _acquire_effect(effect_type: EffectType, pos: Vector3) -> Node:
	var effect: Node = null
	
	# Try to reuse an available effect
	if not _available_effects[effect_type].is_empty():
		effect = _available_effects[effect_type].pop_back()
		if is_instance_valid(effect) and effect.is_inside_tree():
			effect.global_position = pos
			effect.visible = true
			_active_effects.append(effect)
			return effect
	
	# Create new effect if pool is empty or effect is invalid
	effect = _create_effect(effect_type)
	effect.global_position = pos
	get_tree().current_scene.add_child(effect)
	_active_effects.append(effect)
	return effect

func _release_effect(effect: Node, effect_type: EffectType) -> void:
	if not is_instance_valid(effect):
		return
	
	effect.visible = false
	_active_effects.erase(effect)
	
	# Return to pool if under size limit
	if _available_effects[effect_type].size() < _max_pool_size:
		_available_effects[effect_type].append(effect)
	else:
		effect.queue_free()

func _create_effect(effect_type: EffectType) -> Node:
	match effect_type:
		EffectType.MUZZLE_FLASH:
			return _create_muzzle_flash_effect()
		EffectType.PROJECTILE_TRAIL:
			return _create_projectile_trail_effect()
		EffectType.IMPACT_SPARK:
			return _create_impact_spark_effect()
		EffectType.EXPLOSION:
			return _create_explosion_effect()
		EffectType.ENERGY_CHARGE:
			return _create_energy_charge_effect()
		EffectType.BEAM_HIT:
			return _create_beam_hit_effect()
		EffectType.SMOKE_PUFF:
			return _create_smoke_puff_effect()
		EffectType.FIRE_BURST:
			return _create_fire_burst_effect()
		_:
			push_warning("Unknown VFX effect type: " + str(effect_type))
			return _create_muzzle_flash_effect()

# =============================================================================
# Effect Creation Functions
# =============================================================================

func _create_muzzle_flash_effect() -> Node3D:
	var root := Node3D.new()
	root.name = "MuzzleFlash"
	
	# Central bright flash
	var flash_sphere := MeshInstance3D.new()
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = 0.15
	sphere_mesh.height = 0.3
	
	var material := StandardMaterial3D.new()
	material.emission_enabled = true
	material.emission = Color.YELLOW
	material.emission_energy_multiplier = 4.0
	material.albedo_color = Color.YELLOW
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sphere_mesh.material = material
	
	flash_sphere.mesh = sphere_mesh
	flash_sphere.name = "Flash"
	root.add_child(flash_sphere)
	
	# Animated glow effect using Tween
	var tween := Tween.new()
	root.add_child(tween)
	root.set_meta("tween", tween)
	
	return root

func _create_projectile_trail_effect() -> Node3D:
	var root := Node3D.new()
	root.name = "ProjectileTrail"
	
	# Simple streak using elongated quad
	var trail_quad := MeshInstance3D.new()
	var quad_mesh := QuadMesh.new()
	quad_mesh.size = Vector2(0.05, 0.5)
	
	var material := StandardMaterial3D.new()
	material.emission_enabled = true
	material.emission = Color.CYAN
	material.emission_energy_multiplier = 2.0
	material.albedo_color = Color.CYAN
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.7
	quad_mesh.material = material
	
	trail_quad.mesh = quad_mesh
	trail_quad.name = "Trail"
	root.add_child(trail_quad)
	
	var tween := Tween.new()
	root.add_child(tween)
	root.set_meta("tween", tween)
	
	return root

func _create_impact_spark_effect() -> Node3D:
	var root := Node3D.new()
	root.name = "ImpactSpark"
	
	# Multiple small spark particles
	for i in range(6):
		var spark := MeshInstance3D.new()
		var spark_mesh := SphereMesh.new()
		spark_mesh.radius = 0.02
		spark_mesh.height = 0.04
		
		var material := StandardMaterial3D.new()
		material.emission_enabled = true
		material.emission = Color.ORANGE
		material.emission_energy_multiplier = 3.0
		material.albedo_color = Color.ORANGE
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		spark_mesh.material = material
		
		spark.mesh = spark_mesh
		spark.name = "Spark" + str(i)
		
		# Random position offset
		spark.position = Vector3(
			randf_range(-0.1, 0.1),
			randf_range(-0.1, 0.1),
			randf_range(-0.1, 0.1)
		)
		
		root.add_child(spark)
	
	var tween := Tween.new()
	root.add_child(tween)
	root.set_meta("tween", tween)
	
	return root

func _create_explosion_effect() -> Node3D:
	var root := Node3D.new()
	root.name = "Explosion"
	
	# Central explosion sphere
	var explosion_sphere := MeshInstance3D.new()
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = 0.3
	sphere_mesh.height = 0.6
	
	var material := StandardMaterial3D.new()
	material.emission_enabled = true
	material.emission = Color.RED
	material.emission_energy_multiplier = 5.0
	material.albedo_color = Color.RED
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sphere_mesh.material = material
	
	explosion_sphere.mesh = sphere_mesh
	explosion_sphere.name = "Explosion"
	root.add_child(explosion_sphere)
	
	# Secondary flash ring
	var ring_quad := MeshInstance3D.new()
	var quad_mesh := QuadMesh.new()
	quad_mesh.size = Vector2(1.0, 0.1)
	
	var ring_material := StandardMaterial3D.new()
	ring_material.emission_enabled = true
	ring_material.emission = Color.ORANGE
	ring_material.emission_energy_multiplier = 3.0
	ring_material.albedo_color = Color.ORANGE
	ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	quad_mesh.material = ring_material
	
	ring_quad.mesh = quad_mesh
	ring_quad.name = "Ring"
	ring_quad.rotation.z = randf() * TAU  # Random rotation
	root.add_child(ring_quad)
	
	var tween := Tween.new()
	root.add_child(tween)
	root.set_meta("tween", tween)
	
	return root

func _create_energy_charge_effect() -> Node3D:
	var root := Node3D.new()
	root.name = "EnergyCharge"
	
	# Pulsing energy sphere
	var charge_sphere := MeshInstance3D.new()
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = 0.1
	sphere_mesh.height = 0.2
	
	var material := StandardMaterial3D.new()
	material.emission_enabled = true
	material.emission = Color.BLUE
	material.emission_energy_multiplier = 3.0
	material.albedo_color = Color.BLUE
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sphere_mesh.material = material
	
	charge_sphere.mesh = sphere_mesh
	charge_sphere.name = "Charge"
	root.add_child(charge_sphere)
	
	var tween := Tween.new()
	root.add_child(tween)
	root.set_meta("tween", tween)
	
	return root

func _create_beam_hit_effect() -> Node3D:
	var root := Node3D.new()
	root.name = "BeamHit"
	
	# Bright point flash
	var hit_sphere := MeshInstance3D.new()
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = 0.08
	sphere_mesh.height = 0.16
	
	var material := StandardMaterial3D.new()
	material.emission_enabled = true
	material.emission = Color.WHITE
	material.emission_energy_multiplier = 6.0
	material.albedo_color = Color.WHITE
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sphere_mesh.material = material
	
	hit_sphere.mesh = sphere_mesh
	hit_sphere.name = "Hit"
	root.add_child(hit_sphere)
	
	var tween := Tween.new()
	root.add_child(tween)
	root.set_meta("tween", tween)
	
	return root

func _create_smoke_puff_effect() -> Node3D:
	var root := Node3D.new()
	root.name = "SmokePuff"
	
	# Multiple small smoke spheres
	for i in range(4):
		var smoke := MeshInstance3D.new()
		var sphere_mesh := SphereMesh.new()
		sphere_mesh.radius = 0.05 + i * 0.02
		sphere_mesh.height = sphere_mesh.radius * 2.0
		
		var material := StandardMaterial3D.new()
		material.albedo_color = Color.GRAY
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color.a = 0.5 - i * 0.1
		sphere_mesh.material = material
		
		smoke.mesh = sphere_mesh
		smoke.name = "Smoke" + str(i)
		
		# Offset positions for volume
		smoke.position = Vector3(
			randf_range(-0.05, 0.05),
			i * 0.03,
			randf_range(-0.05, 0.05)
		)
		
		root.add_child(smoke)
	
	var tween := Tween.new()
	root.add_child(tween)
	root.set_meta("tween", tween)
	
	return root

func _create_fire_burst_effect() -> Node3D:
	var root := Node3D.new()
	root.name = "FireBurst"
	
	# Central fire core
	var fire_sphere := MeshInstance3D.new()
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = 0.12
	sphere_mesh.height = 0.24
	
	var material := StandardMaterial3D.new()
	material.emission_enabled = true
	material.emission = Color(1.0, 0.4, 0.0)  # Orange fire
	material.emission_energy_multiplier = 4.0
	material.albedo_color = Color(1.0, 0.4, 0.0)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sphere_mesh.material = material
	
	fire_sphere.mesh = sphere_mesh
	fire_sphere.name = "Fire"
	root.add_child(fire_sphere)
	
	# Flickering flames around edges
	for i in range(8):
		var flame := MeshInstance3D.new()
		var flame_mesh := QuadMesh.new()
		flame_mesh.size = Vector2(0.02, 0.08)
		
		var flame_material := StandardMaterial3D.new()
		flame_material.emission_enabled = true
		flame_material.emission = Color(1.0, 0.6, 0.0)
		flame_material.emission_energy_multiplier = 2.0
		flame_material.albedo_color = Color(1.0, 0.6, 0.0)
		flame_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		flame_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		flame_material.albedo_color.a = 0.8
		flame_mesh.material = flame_material
		
		flame.mesh = flame_mesh
		flame.name = "Flame" + str(i)
		
		# Position flames in circle around core
		var angle := i * TAU / 8.0
		flame.position = Vector3(
			cos(angle) * 0.15,
			randf_range(0.0, 0.05),
			sin(angle) * 0.15
		)
		flame.look_at(root.global_position + Vector3.UP, Vector3.UP)
		
		root.add_child(flame)
	
	var tween := Tween.new()
	root.add_child(tween)
	root.set_meta("tween", tween)
	
	return root

# =============================================================================
# Effect Configuration Functions
# =============================================================================

func _configure_muzzle_flash(effect: Node, pos: Vector3, color: Color, scale: float, duration: float) -> void:
	var flash := effect.get_node("Flash") as MeshInstance3D
	var tween := effect.get_meta("tween") as Tween
	
	# Set color and scale
	var material := flash.mesh.material as StandardMaterial3D
	material.emission = color
	material.albedo_color = color
	flash.scale = Vector3.ONE * scale
	flash.material_override = material
	
	# Animate flash
	tween.kill()
	material.albedo_color.a = 1.0
	flash.visible = true
	
	tween.tween_method(_fade_material.bind(material), 1.0, 0.0, duration)
	tween.tween_callback(_release_effect.bind(effect, EffectType.MUZZLE_FLASH)).set_delay(duration)

func _configure_projectile_trail(effect: Node, pos: Vector3, direction: Vector3, color: Color, length: float) -> void:
	var trail := effect.get_node("Trail") as MeshInstance3D
	var tween := effect.get_meta("tween") as Tween
	
	# Orient trail along direction
	if direction.length() > 0:
		trail.look_at(pos + direction, Vector3.UP)
	
	# Set color and length
	var material := trail.mesh.material as StandardMaterial3D
	material.emission = color
	material.albedo_color = color
	var quad_mesh := trail.mesh as QuadMesh
	quad_mesh.size.y = length
	trail.material_override = material
	
	# Animate trail fade
	tween.kill()
	material.albedo_color.a = 0.7
	trail.visible = true
	
	tween.tween_method(_fade_material.bind(material), 0.7, 0.0, 0.3)
	tween.tween_callback(_release_effect.bind(effect, EffectType.PROJECTILE_TRAIL)).set_delay(0.3)

func _configure_impact_spark(effect: Node, pos: Vector3, normal: Vector3, color: Color, intensity: float) -> void:
	var tween := effect.get_meta("tween") as Tween
	
	# Set spark colors and animate
	for i in range(6):
		var spark := effect.get_node("Spark" + str(i)) as MeshInstance3D
		var material := spark.mesh.material as StandardMaterial3D
		material.emission = color
		material.albedo_color = color
		material.emission_energy_multiplier = 3.0 * intensity
		spark.material_override = material
		spark.visible = true
	
	tween.kill()
	
	# Animate sparks flying away from impact point
	for i in range(6):
		var spark := effect.get_node("Spark" + str(i)) as MeshInstance3D
		var direction := (normal + Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1))).normalized()
		var end_pos := spark.position + direction * 0.3
		
		tween.parallel().tween_property(spark, "position", end_pos, 0.2)
		tween.parallel().tween_method(_fade_material.bind(spark.mesh.material), 1.0, 0.0, 0.2)
	
	tween.tween_callback(_release_effect.bind(effect, EffectType.IMPACT_SPARK)).set_delay(0.2)

func _configure_explosion(effect: Node, pos: Vector3, size: float, color: Color) -> void:
	var explosion := effect.get_node("Explosion") as MeshInstance3D
	var ring := effect.get_node("Ring") as MeshInstance3D
	var tween := effect.get_meta("tween") as Tween
	
	# Set colors and initial scale
	var exp_material := explosion.mesh.material as StandardMaterial3D
	exp_material.emission = color
	exp_material.albedo_color = color
	explosion.material_override = exp_material
	
	var ring_material := ring.mesh.material as StandardMaterial3D
	ring_material.emission = color.lightened(0.2)
	ring_material.albedo_color = color.lightened(0.2)
	ring.material_override = ring_material
	
	explosion.scale = Vector3.ZERO
	ring.scale = Vector3.ZERO
	explosion.visible = true
	ring.visible = true
	
	tween.kill()
	
	# Animate explosion growth and fade
	tween.parallel().tween_property(explosion, "scale", Vector3.ONE * size, 0.1)
	tween.parallel().tween_property(ring, "scale", Vector3.ONE * size * 1.5, 0.15)
	tween.parallel().tween_method(_fade_material.bind(exp_material), 1.0, 0.0, 0.4).set_delay(0.1)
	tween.parallel().tween_method(_fade_material.bind(ring_material), 1.0, 0.0, 0.3).set_delay(0.15)
	
	tween.tween_callback(_release_effect.bind(effect, EffectType.EXPLOSION)).set_delay(0.5)

func _configure_energy_charge(effect: Node, pos: Vector3, target_pos: Vector3, color: Color, charge_time: float) -> void:
	var charge := effect.get_node("Charge") as MeshInstance3D
	var tween := effect.get_meta("tween") as Tween
	
	# Set color
	var material := charge.mesh.material as StandardMaterial3D
	material.emission = color
	material.albedo_color = color
	charge.material_override = material
	
	charge.scale = Vector3.ZERO
	charge.visible = true
	
	tween.kill()
	
	# Animate charge building up
	tween.tween_property(charge, "scale", Vector3.ONE * 1.5, charge_time * 0.8)
	tween.tween_method(_pulse_scale.bind(charge), 1.5, 2.0, charge_time * 0.2).set_delay(charge_time * 0.8)
	tween.tween_callback(_release_effect.bind(effect, EffectType.ENERGY_CHARGE)).set_delay(charge_time)

func _configure_beam_hit(effect: Node, pos: Vector3, color: Color, intensity: float) -> void:
	var hit := effect.get_node("Hit") as MeshInstance3D
	var tween := effect.get_meta("tween") as Tween
	
	# Set color and intensity
	var material := hit.mesh.material as StandardMaterial3D
	material.emission = color
	material.albedo_color = color
	material.emission_energy_multiplier = 6.0 * intensity
	hit.material_override = material
	
	hit.scale = Vector3.ONE * 2.0
	hit.visible = true
	
	tween.kill()
	
	# Quick bright flash
	tween.parallel().tween_property(hit, "scale", Vector3.ONE * 0.5, 0.1)
	tween.parallel().tween_method(_fade_material.bind(material), 1.0, 0.0, 0.1)
	
	tween.tween_callback(_release_effect.bind(effect, EffectType.BEAM_HIT)).set_delay(0.1)

func _configure_smoke_puff(effect: Node, pos: Vector3, velocity: Vector3, size: float) -> void:
	var tween := effect.get_meta("tween") as Tween
	
	# Animate smoke dissipating
	for i in range(4):
		var smoke := effect.get_node("Smoke" + str(i)) as MeshInstance3D
		smoke.scale = Vector3.ONE * size
		smoke.visible = true
		
		# Drift upward with random movement
		var drift := velocity + Vector3(randf_range(-0.1, 0.1), 0.2, randf_range(-0.1, 0.1))
		var end_pos := smoke.position + drift * 0.5
		
		tween.parallel().tween_property(smoke, "position", end_pos, 1.0)
		tween.parallel().tween_property(smoke, "scale", Vector3.ONE * size * 1.5, 1.0)
		tween.parallel().tween_method(_fade_material.bind(smoke.mesh.material), 0.5, 0.0, 1.0)
	
	tween.tween_callback(_release_effect.bind(effect, EffectType.SMOKE_PUFF)).set_delay(1.0)

func _configure_fire_burst(effect: Node, pos: Vector3, size: float, intensity: float) -> void:
	var fire := effect.get_node("Fire") as MeshInstance3D
	var tween := effect.get_meta("tween") as Tween
	
	# Set initial state
	fire.scale = Vector3.ZERO
	fire.visible = true
	
	# Configure flame color based on intensity
	var fire_material := fire.mesh.material as StandardMaterial3D
	fire_material.emission_energy_multiplier = 4.0 * intensity
	fire.material_override = fire_material
	
	# Make flames visible and animate
	for i in range(8):
		var flame := effect.get_node("Flame" + str(i)) as MeshInstance3D
		flame.visible = true
		flame.scale = Vector3.ONE * size
	
	tween.kill()
	
	# Animate fire burst
	tween.parallel().tween_property(fire, "scale", Vector3.ONE * size, 0.2)
	tween.parallel().tween_method(_fade_material.bind(fire_material), 1.0, 0.0, 0.6).set_delay(0.2)
	
	# Animate individual flames
	for i in range(8):
		var flame := effect.get_node("Flame" + str(i)) as MeshInstance3D
		var material := flame.mesh.material as StandardMaterial3D
		tween.parallel().tween_method(_fade_material.bind(material), 0.8, 0.0, 0.5).set_delay(0.1)
	
	tween.tween_callback(_release_effect.bind(effect, EffectType.FIRE_BURST)).set_delay(0.8)

# =============================================================================
# Animation Helper Functions
# =============================================================================

func _fade_material(material: StandardMaterial3D, alpha: float) -> void:
	material.albedo_color.a = alpha
	if material.emission_enabled:
		var emission_alpha := alpha
		material.emission_energy_multiplier = material.emission_energy_multiplier * emission_alpha

func _pulse_scale(node: Node3D, scale: float) -> void:
	node.scale = Vector3.ONE * scale

# =============================================================================
# Cleanup
# =============================================================================

func _exit_tree() -> void:
	# Clean up active effects
	for effect in _active_effects:
		if is_instance_valid(effect):
			effect.queue_free()
	
	# Clean up pooled effects
	for effect_type in _available_effects:
		for effect in _available_effects[effect_type]:
			if is_instance_valid(effect):
				effect.queue_free()
	
	_active_effects.clear()
	_available_effects.clear()
	
	if VfxPool._pools.has("main") and VfxPool._pools["main"] == self:
		VfxPool._pools.erase("main")