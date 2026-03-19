class_name VfxPoolSystem
extends Node
## VfxPoolSystem - Advanced pooling system for lightweight VFX effects
## Manages multiple pools with automatic cleanup and performance optimization

# --- Pool Categories ---
enum PoolCategory {
	PROJECTILE_TRAILS,     # Fast moving projectile trails
	IMPACT_SPARKS,        # Hit effects and sparks
	EXPLOSIONS,           # Blast effects
	ENVIRONMENTAL,        # Ambient and area effects
	UI_EFFECTS,           # Interface feedback effects
	SPECIAL_EFFECTS       # Unique/boss effects
}

# --- Performance Settings ---
const MAX_TOTAL_EFFECTS := 1000
const MAX_EFFECTS_PER_CATEGORY := 200
const CLEANUP_INTERVAL := 5.0
const LOW_FPS_THRESHOLD := 40

# --- Static Instance ---
static var _instance: VfxPoolSystem = null

# --- Pool Storage ---
var _pools: Dictionary = {}
var _active_counts: Dictionary = {}
var _performance_mode: bool = false
var _cleanup_timer: Timer = null

func _ready() -> void:
	if not VfxPoolSystem._instance:
		VfxPoolSystem._instance = self
		_initialize_pools()
		_setup_cleanup_timer()
		_setup_performance_monitoring()

## Get the global VFX pool system instance
static func get_instance() -> VfxPoolSystem:
	if not VfxPoolSystem._instance:
		var system := VfxPoolSystem.new()
		system.name = "VfxPoolSystem"
		Engine.get_main_loop().current_scene.add_child(system)
	return VfxPoolSystem._instance

# =============================================================================
# Pool Management API
# =============================================================================

## Create a projectile trail effect with automatic pooling
static func create_projectile_trail(
	start_pos: Vector3,
	end_pos: Vector3,
	trail_type: String,
	color: Color = Color.CYAN,
	duration: float = 0.5
) -> void:
	var instance := get_instance()
	if instance._check_performance_limits():
		return
	
	var effect := instance._acquire_effect(PoolCategory.PROJECTILE_TRAILS, trail_type)
	if effect:
		instance._configure_projectile_trail(effect, start_pos, end_pos, color, duration)

## Create an impact effect with material-aware visuals
static func create_impact_effect(
	pos: Vector3,
	normal: Vector3,
	impact_type: String,
	material_type: String = "generic",
	intensity: float = 1.0
) -> void:
	var instance := get_instance()
	if instance._check_performance_limits():
		return
	
	var effect := instance._acquire_effect(PoolCategory.IMPACT_SPARKS, impact_type)
	if effect:
		instance._configure_impact_effect(effect, pos, normal, material_type, intensity)

## Create an explosion effect with size and type parameters
static func create_explosion(
	pos: Vector3,
	explosion_type: String = "generic",
	size: float = 1.0,
	color: Color = Color.ORANGE
) -> void:
	var instance := get_instance()
	if instance._check_performance_limits():
		return
	
	var effect := instance._acquire_effect(PoolCategory.EXPLOSIONS, explosion_type)
	if effect:
		instance._configure_explosion(effect, pos, size, color)

## Create environmental effects (smoke, fire, etc.)
static func create_environmental_effect(
	pos: Vector3,
	effect_type: String,
	duration: float = 10.0,
	intensity: float = 1.0
) -> void:
	var instance := get_instance()
	if instance._check_performance_limits():
		return
	
	var effect := instance._acquire_effect(PoolCategory.ENVIRONMENTAL, effect_type)
	if effect:
		instance._configure_environmental_effect(effect, pos, duration, intensity)

## Create UI feedback effects
static func create_ui_effect(
	pos: Vector3,
	effect_type: String,
	color: Color = Color.WHITE,
	scale: float = 1.0
) -> void:
	var instance := get_instance()
	# UI effects are always allowed (player feedback is important)
	
	var effect := instance._acquire_effect(PoolCategory.UI_EFFECTS, effect_type)
	if effect:
		instance._configure_ui_effect(effect, pos, color, scale)

## Create special effects for bosses and unique events
static func create_special_effect(
	pos: Vector3,
	effect_type: String,
	parameters: Dictionary = {}
) -> void:
	var instance := get_instance()
	# Special effects get priority
	
	var effect := instance._acquire_effect(PoolCategory.SPECIAL_EFFECTS, effect_type)
	if effect:
		instance._configure_special_effect(effect, pos, parameters)

# =============================================================================
# Performance and Optimization
# =============================================================================

## Enable performance mode (reduces effect quality for better FPS)
static func set_performance_mode(enabled: bool) -> void:
	var instance := get_instance()
	instance._performance_mode = enabled
	
	if enabled:
		print("VfxPoolSystem: Performance mode enabled - reducing effect quality")
	else:
		print("VfxPoolSystem: Performance mode disabled - full quality effects")

## Get current effect statistics
static func get_statistics() -> Dictionary:
	var instance := get_instance()
	return {
		"total_active_effects": instance._get_total_active_effects(),
		"effects_per_category": instance._active_counts.duplicate(),
		"performance_mode": instance._performance_mode,
		"pools_initialized": instance._pools.size()
	}

## Force cleanup of all inactive effects
static func cleanup_all_effects() -> void:
	var instance := get_instance()
	instance._cleanup_inactive_effects()

# =============================================================================
# Internal Pool Implementation
# =============================================================================

func _initialize_pools() -> void:
	for category in PoolCategory.values():
		_pools[category] = {}
		_active_counts[category] = 0

func _setup_cleanup_timer() -> void:
	_cleanup_timer = Timer.new()
	_cleanup_timer.wait_time = CLEANUP_INTERVAL
	_cleanup_timer.timeout.connect(_cleanup_inactive_effects)
	_cleanup_timer.autostart = true
	add_child(_cleanup_timer)

func _setup_performance_monitoring() -> void:
	# Monitor FPS and automatically enable performance mode if needed
	var performance_timer := Timer.new()
	performance_timer.wait_time = 2.0  # Check every 2 seconds
	performance_timer.timeout.connect(_monitor_performance)
	performance_timer.autostart = true
	add_child(performance_timer)

func _monitor_performance() -> void:
	var fps := Engine.get_frames_per_second()
	
	if fps < LOW_FPS_THRESHOLD and not _performance_mode:
		print("VfxPoolSystem: Low FPS detected (", fps, "), enabling performance mode")
		_performance_mode = true
	elif fps > LOW_FPS_THRESHOLD + 10 and _performance_mode:
		# Give some hysteresis before disabling performance mode
		print("VfxPoolSystem: FPS improved (", fps, "), disabling performance mode")
		_performance_mode = false

func _check_performance_limits() -> bool:
	var total_effects := _get_total_active_effects()
	
	if total_effects >= MAX_TOTAL_EFFECTS:
		return true  # Skip effect creation
	
	return false

func _get_total_active_effects() -> int:
	var total := 0
	for count in _active_counts.values():
		total += count
	return total

func _acquire_effect(category: PoolCategory, effect_type: String) -> Node3D:
	if _active_counts[category] >= MAX_EFFECTS_PER_CATEGORY:
		return null  # Category limit reached
	
	var category_pool := _pools[category]
	
	# Try to reuse an existing effect
	if category_pool.has(effect_type):
		var pool_array: Array = category_pool[effect_type]
		for i in range(pool_array.size() - 1, -1, -1):
			var effect: Node3D = pool_array[i]
			if is_instance_valid(effect) and not effect.visible:
				pool_array.remove_at(i)
				effect.visible = true
				_active_counts[category] += 1
				return effect
	
	# Create new effect
	var new_effect := _create_effect(category, effect_type)
	if new_effect:
		_active_counts[category] += 1
		get_tree().current_scene.add_child(new_effect)
	
	return new_effect

func _release_effect(effect: Node3D, category: PoolCategory, effect_type: String) -> void:
	if not is_instance_valid(effect):
		return
	
	effect.visible = false
	_active_counts[category] = max(0, _active_counts[category] - 1)
	
	# Return to pool
	var category_pool := _pools[category]
	if not category_pool.has(effect_type):
		category_pool[effect_type] = []
	
	var pool_array: Array = category_pool[effect_type]
	if pool_array.size() < 50:  # Limit pool size per effect type
		pool_array.append(effect)
	else:
		effect.queue_free()

func _create_effect(category: PoolCategory, effect_type: String) -> Node3D:
	match category:
		PoolCategory.PROJECTILE_TRAILS:
			return _create_projectile_trail_effect(effect_type)
		PoolCategory.IMPACT_SPARKS:
			return _create_impact_spark_effect(effect_type)
		PoolCategory.EXPLOSIONS:
			return _create_explosion_effect(effect_type)
		PoolCategory.ENVIRONMENTAL:
			return _create_environmental_effect_node(effect_type)
		PoolCategory.UI_EFFECTS:
			return _create_ui_effect_node(effect_type)
		PoolCategory.SPECIAL_EFFECTS:
			return _create_special_effect_node(effect_type)
		_:
			return null

# =============================================================================
# Effect Creation Functions
# =============================================================================

func _create_projectile_trail_effect(trail_type: String) -> Node3D:
	var root := Node3D.new()
	root.name = "ProjectileTrail_" + trail_type
	
	match trail_type:
		"bullet":
			_add_bullet_trail_components(root)
		"missile":
			_add_missile_trail_components(root)
		"energy":
			_add_energy_trail_components(root)
		"railgun":
			_add_railgun_trail_components(root)
		_:
			_add_generic_trail_components(root)
	
	# Add animation system
	var tween := Tween.new()
	root.add_child(tween)
	root.set_meta("tween", tween)
	root.set_meta("trail_type", trail_type)
	
	return root

func _create_impact_spark_effect(impact_type: String) -> Node3D:
	var root := Node3D.new()
	root.name = "ImpactSpark_" + impact_type
	
	match impact_type:
		"kinetic":
			_add_kinetic_impact_components(root)
		"energy":
			_add_energy_impact_components(root)
		"explosive":
			_add_explosive_impact_components(root)
		"acid":
			_add_acid_impact_components(root)
		_:
			_add_generic_impact_components(root)
	
	var tween := Tween.new()
	root.add_child(tween)
	root.set_meta("tween", tween)
	root.set_meta("impact_type", impact_type)
	
	return root

func _create_explosion_effect(explosion_type: String) -> Node3D:
	var root := Node3D.new()
	root.name = "Explosion_" + explosion_type
	
	match explosion_type:
		"missile":
			_add_missile_explosion_components(root)
		"plasma":
			_add_plasma_explosion_components(root)
		"boss_death":
			_add_boss_death_explosion_components(root)
		_:
			_add_generic_explosion_components(root)
	
	var tween := Tween.new()
	root.add_child(tween)
	root.set_meta("tween", tween)
	root.set_meta("explosion_type", explosion_type)
	
	return root

func _create_environmental_effect_node(effect_type: String) -> Node3D:
	var root := Node3D.new()
	root.name = "Environmental_" + effect_type
	
	match effect_type:
		"smoke":
			_add_smoke_components(root)
		"fire":
			_add_fire_components(root)
		"sparks":
			_add_sparks_components(root)
		_:
			_add_generic_environmental_components(root)
	
	var tween := Tween.new()
	root.add_child(tween)
	root.set_meta("tween", tween)
	root.set_meta("effect_type", effect_type)
	
	return root

func _create_ui_effect_node(effect_type: String) -> Node3D:
	var root := Node3D.new()
	root.name = "UIEffect_" + effect_type
	
	match effect_type:
		"damage_number":
			_add_damage_number_components(root)
		"pickup_flash":
			_add_pickup_flash_components(root)
		_:
			_add_generic_ui_components(root)
	
	var tween := Tween.new()
	root.add_child(tween)
	root.set_meta("tween", tween)
	root.set_meta("ui_type", effect_type)
	
	return root

func _create_special_effect_node(effect_type: String) -> Node3D:
	var root := Node3D.new()
	root.name = "SpecialEffect_" + effect_type
	
	# Special effects get more complex, longer-lasting visuals
	match effect_type:
		"boss_spawn":
			_add_boss_spawn_components(root)
		"wave_complete":
			_add_wave_complete_components(root)
		"portal":
			_add_portal_components(root)
		_:
			_add_generic_special_components(root)
	
	var tween := Tween.new()
	root.add_child(tween)
	root.set_meta("tween", tween)
	root.set_meta("special_type", effect_type)
	
	return root

# =============================================================================
# Effect Component Builders (Lightweight Visuals)
# =============================================================================

func _add_bullet_trail_components(root: Node3D) -> void:
	# Fast kinetic tracer
	var tracer := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.01
	cylinder.bottom_radius = 0.01
	cylinder.height = 1.0
	
	var material := StandardMaterial3D.new()
	material.emission_enabled = true
	material.emission = Color.YELLOW
	material.emission_energy_multiplier = 2.0
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cylinder.material = material
	
	tracer.mesh = cylinder
	tracer.name = "Tracer"
	root.add_child(tracer)

func _add_missile_trail_components(root: Node3D) -> void:
	# Smoke trail with multiple segments
	for i in range(5):
		var smoke := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.05 + i * 0.02
		sphere.height = sphere.radius * 2
		
		var material := StandardMaterial3D.new()
		material.albedo_color = Color.GRAY
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color.a = 0.6 - i * 0.1
		sphere.material = material
		
		smoke.mesh = sphere
		smoke.name = "Smoke" + str(i)
		smoke.position.z = -i * 0.1
		root.add_child(smoke)

func _add_energy_trail_components(root: Node3D) -> void:
	# Glowing energy beam
	var beam := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.02
	cylinder.bottom_radius = 0.02
	cylinder.height = 1.0
	
	var material := StandardMaterial3D.new()
	material.emission_enabled = true
	material.emission = Color.CYAN
	material.emission_energy_multiplier = 3.0
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cylinder.material = material
	
	beam.mesh = cylinder
	beam.name = "Beam"
	root.add_child(beam)

func _add_railgun_trail_components(root: Node3D) -> void:
	# High-energy electromagnetic trail
	var core := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.015
	cylinder.bottom_radius = 0.015
	cylinder.height = 1.0
	
	var core_material := StandardMaterial3D.new()
	core_material.emission_enabled = true
	core_material.emission = Color(0.6, 0.9, 1.0)
	core_material.emission_energy_multiplier = 4.0
	core_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cylinder.material = core_material
	
	core.mesh = cylinder
	core.name = "Core"
	root.add_child(core)
	
	# Electromagnetic field
	var field := MeshInstance3D.new()
	var field_cylinder := CylinderMesh.new()
	field_cylinder.top_radius = 0.03
	field_cylinder.bottom_radius = 0.03
	field_cylinder.height = 1.0
	
	var field_material := StandardMaterial3D.new()
	field_material.emission_enabled = true
	field_material.emission = Color(0.3, 0.6, 1.0)
	field_material.emission_energy_multiplier = 1.5
	field_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	field_material.albedo_color.a = 0.3
	field_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	field_cylinder.material = field_material
	
	field.mesh = field_cylinder
	field.name = "Field"
	root.add_child(field)

func _add_generic_trail_components(root: Node3D) -> void:
	var tracer := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.02
	cylinder.bottom_radius = 0.02
	cylinder.height = 1.0
	
	var material := StandardMaterial3D.new()
	material.emission_enabled = true
	material.emission = Color.WHITE
	material.emission_energy_multiplier = 2.0
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cylinder.material = material
	
	tracer.mesh = cylinder
	tracer.name = "Tracer"
	root.add_child(tracer)

# Add similar component builders for impacts, explosions, etc.
func _add_kinetic_impact_components(root: Node3D) -> void:
	# Sparks flying outward
	for i in range(8):
		var spark := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.01
		sphere.height = 0.02
		
		var material := StandardMaterial3D.new()
		material.emission_enabled = true
		material.emission = Color(1.0, 0.8, 0.3)
		material.emission_energy_multiplier = 3.0
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sphere.material = material
		
		spark.mesh = sphere
		spark.name = "Spark" + str(i)
		var angle := i * TAU / 8.0
		spark.position = Vector3(cos(angle) * 0.05, 0, sin(angle) * 0.05)
		root.add_child(spark)

func _add_energy_impact_components(root: Node3D) -> void:
	var flash := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.08
	sphere.height = 0.16
	
	var material := StandardMaterial3D.new()
	material.emission_enabled = true
	material.emission = Color(0.8, 0.9, 1.0)
	material.emission_energy_multiplier = 5.0
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sphere.material = material
	
	flash.mesh = sphere
	flash.name = "Flash"
	root.add_child(flash)

func _add_explosive_impact_components(root: Node3D) -> void:
	var explosion := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.15
	sphere.height = 0.3
	
	var material := StandardMaterial3D.new()
	material.emission_enabled = true
	material.emission = Color.ORANGE
	material.emission_energy_multiplier = 4.0
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sphere.material = material
	
	explosion.mesh = sphere
	explosion.name = "Explosion"
	root.add_child(explosion)

func _add_acid_impact_components(root: Node3D) -> void:
	var acid := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.06
	sphere.height = 0.12
	
	var material := StandardMaterial3D.new()
	material.emission_enabled = true
	material.emission = Color(0.6, 0.8, 0.2)
	material.emission_energy_multiplier = 2.5
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sphere.material = material
	
	acid.mesh = sphere
	acid.name = "Acid"
	root.add_child(acid)

func _add_generic_impact_components(root: Node3D) -> void:
	_add_kinetic_impact_components(root)  # Default to kinetic impact

# Continue with explosion, environmental, UI, and special effect components...
func _add_generic_explosion_components(root: Node3D) -> void:
	var explosion := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.2
	sphere.height = 0.4
	
	var material := StandardMaterial3D.new()
	material.emission_enabled = true
	material.emission = Color.ORANGE
	material.emission_energy_multiplier = 4.0
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sphere.material = material
	
	explosion.mesh = sphere
	explosion.name = "Explosion"
	root.add_child(explosion)

func _add_missile_explosion_components(root: Node3D) -> void:
	_add_generic_explosion_components(root)
	# Add shrapnel effects
	for i in range(12):
		var fragment := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.02, 0.02, 0.02)
		fragment.mesh = box
		fragment.name = "Fragment" + str(i)
		root.add_child(fragment)

func _add_plasma_explosion_components(root: Node3D) -> void:
	var plasma := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.25
	sphere.height = 0.5
	
	var material := StandardMaterial3D.new()
	material.emission_enabled = true
	material.emission = Color(0.8, 0.2, 0.9)
	material.emission_energy_multiplier = 5.0
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sphere.material = material
	
	plasma.mesh = sphere
	plasma.name = "Plasma"
	root.add_child(plasma)

func _add_boss_death_explosion_components(root: Node3D) -> void:
	# Massive explosion with multiple layers
	for i in range(3):
		var layer := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.3 + i * 0.15
		sphere.height = sphere.radius * 2
		
		var material := StandardMaterial3D.new()
		material.emission_enabled = true
		material.emission = Color(1.0, 0.4 - i * 0.1, 0.0)
		material.emission_energy_multiplier = 6.0 - i
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color.a = 0.8 - i * 0.2
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sphere.material = material
		
		layer.mesh = sphere
		layer.name = "Layer" + str(i)
		root.add_child(layer)

func _add_generic_environmental_components(root: Node3D) -> void:
	var ambient := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.1
	sphere.height = 0.2
	
	var material := StandardMaterial3D.new()
	material.albedo_color = Color.GRAY
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.5
	sphere.material = material
	
	ambient.mesh = sphere
	ambient.name = "Ambient"
	root.add_child(ambient)

func _add_smoke_components(root: Node3D) -> void:
	for i in range(4):
		var smoke := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.08 + i * 0.03
		sphere.height = sphere.radius * 2
		
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.4, 0.4, 0.4)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color.a = 0.6 - i * 0.1
		sphere.material = material
		
		smoke.mesh = sphere
		smoke.name = "Smoke" + str(i)
		smoke.position.y = i * 0.05
		root.add_child(smoke)

func _add_fire_components(root: Node3D) -> void:
	var fire := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.1
	sphere.height = 0.2
	
	var material := StandardMaterial3D.new()
	material.emission_enabled = true
	material.emission = Color(1.0, 0.5, 0.0)
	material.emission_energy_multiplier = 3.0
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sphere.material = material
	
	fire.mesh = sphere
	fire.name = "Fire"
	root.add_child(fire)

func _add_sparks_components(root: Node3D) -> void:
	for i in range(6):
		var spark := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.005
		sphere.height = 0.01
		
		var material := StandardMaterial3D.new()
		material.emission_enabled = true
		material.emission = Color(1.0, 0.7, 0.1)
		material.emission_energy_multiplier = 3.0
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sphere.material = material
		
		spark.mesh = sphere
		spark.name = "Spark" + str(i)
		var angle := i * TAU / 6.0
		spark.position = Vector3(cos(angle) * 0.08, 0, sin(angle) * 0.08)
		root.add_child(spark)

func _add_generic_ui_components(root: Node3D) -> void:
	var ui_element := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.05
	sphere.height = 0.1
	
	var material := StandardMaterial3D.new()
	material.emission_enabled = true
	material.emission = Color.WHITE
	material.emission_energy_multiplier = 2.0
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sphere.material = material
	
	ui_element.mesh = sphere
	ui_element.name = "UIElement"
	root.add_child(ui_element)

func _add_damage_number_components(root: Node3D) -> void:
	# Placeholder for damage number - would be replaced with actual text in full implementation
	var number := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.03
	sphere.height = 0.06
	
	var material := StandardMaterial3D.new()
	material.emission_enabled = true
	material.emission = Color.RED
	material.emission_energy_multiplier = 2.5
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sphere.material = material
	
	number.mesh = sphere
	number.name = "DamageNumber"
	root.add_child(number)

func _add_pickup_flash_components(root: Node3D) -> void:
	var flash := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.1
	sphere.height = 0.2
	
	var material := StandardMaterial3D.new()
	material.emission_enabled = true
	material.emission = Color.YELLOW
	material.emission_energy_multiplier = 4.0
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sphere.material = material
	
	flash.mesh = sphere
	flash.name = "Flash"
	root.add_child(flash)

func _add_generic_special_components(root: Node3D) -> void:
	var special := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.2
	sphere.height = 0.4
	
	var material := StandardMaterial3D.new()
	material.emission_enabled = true
	material.emission = Color(0.5, 0.2, 1.0)
	material.emission_energy_multiplier = 4.0
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sphere.material = material
	
	special.mesh = sphere
	special.name = "Special"
	root.add_child(special)

func _add_boss_spawn_components(root: Node3D) -> void:
	# Dramatic entrance effect
	var portal := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 1.0
	cylinder.bottom_radius = 1.0
	cylinder.height = 0.1
	
	var material := StandardMaterial3D.new()
	material.emission_enabled = true
	material.emission = Color(0.8, 0.1, 0.1)
	material.emission_energy_multiplier = 5.0
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cylinder.material = material
	
	portal.mesh = cylinder
	portal.name = "Portal"
	root.add_child(portal)

func _add_wave_complete_components(root: Node3D) -> void:
	var celebration := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	
	var material := StandardMaterial3D.new()
	material.emission_enabled = true
	material.emission = Color.GREEN
	material.emission_energy_multiplier = 3.0
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sphere.material = material
	
	celebration.mesh = sphere
	celebration.name = "Celebration"
	root.add_child(celebration)

func _add_portal_components(root: Node3D) -> void:
	# Swirling portal effect
	var portal_ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.3
	torus.outer_radius = 0.5
	
	var material := StandardMaterial3D.new()
	material.emission_enabled = true
	material.emission = Color(0.4, 0.2, 0.8)
	material.emission_energy_multiplier = 4.0
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	torus.material = material
	
	portal_ring.mesh = torus
	portal_ring.name = "PortalRing"
	root.add_child(portal_ring)

# =============================================================================
# Effect Configuration Functions
# =============================================================================

func _configure_projectile_trail(effect: Node3D, start_pos: Vector3, end_pos: Vector3, color: Color, duration: float) -> void:
	effect.global_position = start_pos
	var direction := end_pos - start_pos
	var distance := direction.length()
	
	if distance > 0:
		effect.look_at(end_pos, Vector3.UP)
	
	# Configure trail length and appearance
	var tracer := effect.get_node_or_null("Tracer") as MeshInstance3D
	if tracer and tracer.mesh is CylinderMesh:
		var mesh := tracer.mesh as CylinderMesh
		mesh.height = distance
		tracer.position.z = distance * 0.5
		
		var material := mesh.material as StandardMaterial3D
		if material:
			material.emission = color
			material.albedo_color = color
	
	# Animate the trail
	var tween := effect.get_meta("tween") as Tween
	if tween:
		tween.kill()
		tween.tween_method(_fade_trail_material.bind(effect), 1.0, 0.0, duration)
		tween.tween_callback(_release_effect.bind(effect, PoolCategory.PROJECTILE_TRAILS, effect.get_meta("trail_type", "generic"))).set_delay(duration)

func _configure_impact_effect(effect: Node3D, pos: Vector3, normal: Vector3, material_type: String, intensity: float) -> void:
	effect.global_position = pos
	
	# Adjust effect based on material
	var color_modifier := _get_material_color_modifier(material_type)
	_apply_color_to_effect(effect, color_modifier, intensity)
	
	# Animate sparks or impact
	var tween := effect.get_meta("tween") as Tween
	if tween:
		tween.kill()
		_animate_impact_sparks(effect, normal, tween)
		tween.tween_callback(_release_effect.bind(effect, PoolCategory.IMPACT_SPARKS, effect.get_meta("impact_type", "generic"))).set_delay(0.3)

func _configure_explosion(effect: Node3D, pos: Vector3, size: float, color: Color) -> void:
	effect.global_position = pos
	effect.scale = Vector3.ZERO
	
	var explosion_node := effect.get_node_or_null("Explosion") as MeshInstance3D
	if explosion_node and explosion_node.mesh.material:
		var material := explosion_node.mesh.material as StandardMaterial3D
		material.emission = color
		material.albedo_color = color
	
	var tween := effect.get_meta("tween") as Tween
	if tween:
		tween.kill()
		tween.tween_property(effect, "scale", Vector3.ONE * size, 0.2)
		tween.tween_method(_fade_explosion_material.bind(effect), 1.0, 0.0, 0.5).set_delay(0.1)
		tween.tween_callback(_release_effect.bind(effect, PoolCategory.EXPLOSIONS, effect.get_meta("explosion_type", "generic"))).set_delay(0.7)

func _configure_environmental_effect(effect: Node3D, pos: Vector3, duration: float, intensity: float) -> void:
	effect.global_position = pos
	effect.scale = Vector3.ONE * intensity
	
	var tween := effect.get_meta("tween") as Tween
	if tween:
		tween.kill()
		# Environmental effects last longer and fade slowly
		tween.tween_method(_fade_environmental_material.bind(effect), 1.0, 0.0, duration)
		tween.tween_callback(_release_effect.bind(effect, PoolCategory.ENVIRONMENTAL, effect.get_meta("effect_type", "generic"))).set_delay(duration)

func _configure_ui_effect(effect: Node3D, pos: Vector3, color: Color, scale: float) -> void:
	effect.global_position = pos
	effect.scale = Vector3.ONE * scale
	
	var ui_element := effect.get_node_or_null("UIElement") as MeshInstance3D
	if ui_element and ui_element.mesh.material:
		var material := ui_element.mesh.material as StandardMaterial3D
		material.emission = color
		material.albedo_color = color
	
	var tween := effect.get_meta("tween") as Tween
	if tween:
		tween.kill()
		# UI effects are quick and snappy
		tween.tween_property(effect, "scale", Vector3.ONE * scale * 1.2, 0.1)
		tween.tween_property(effect, "scale", Vector3.ONE * scale * 0.8, 0.1)
		tween.tween_method(_fade_ui_material.bind(effect), 1.0, 0.0, 0.3)
		tween.tween_callback(_release_effect.bind(effect, PoolCategory.UI_EFFECTS, effect.get_meta("ui_type", "generic"))).set_delay(0.5)

func _configure_special_effect(effect: Node3D, pos: Vector3, parameters: Dictionary) -> void:
	effect.global_position = pos
	
	var special_type: String = effect.get_meta("special_type", "generic")
	var duration: float = parameters.get("duration", 3.0)
	var size: float = parameters.get("size", 1.0)
	var color: Color = parameters.get("color", Color.WHITE)
	
	effect.scale = Vector3.ONE * size
	
	var tween := effect.get_meta("tween") as Tween
	if tween:
		tween.kill()
		
		# Special effects get unique animations based on type
		match special_type:
			"boss_spawn":
				_animate_boss_spawn(effect, tween, duration)
			"wave_complete":
				_animate_wave_complete(effect, tween, duration)
			"portal":
				_animate_portal(effect, tween, duration)
			_:
				_animate_generic_special(effect, tween, duration)
		
		tween.tween_callback(_release_effect.bind(effect, PoolCategory.SPECIAL_EFFECTS, special_type)).set_delay(duration)

# =============================================================================
# Animation Helper Functions
# =============================================================================

func _fade_trail_material(effect: Node3D, alpha: float) -> void:
	var tracer := effect.get_node_or_null("Tracer") as MeshInstance3D
	if tracer and tracer.mesh.material:
		var material := tracer.mesh.material as StandardMaterial3D
		material.albedo_color.a = alpha
		if material.emission_enabled:
			material.emission_energy_multiplier = material.emission_energy_multiplier * alpha

func _fade_explosion_material(effect: Node3D, alpha: float) -> void:
	var explosion := effect.get_node_or_null("Explosion") as MeshInstance3D
	if explosion and explosion.mesh.material:
		var material := explosion.mesh.material as StandardMaterial3D
		material.albedo_color.a = alpha

func _fade_environmental_material(effect: Node3D, alpha: float) -> void:
	for child in effect.get_children():
		if child is MeshInstance3D:
			var mesh_inst := child as MeshInstance3D
			if mesh_inst.mesh and mesh_inst.mesh.material:
				var material := mesh_inst.mesh.material as StandardMaterial3D
				material.albedo_color.a = alpha * 0.5  # Environmental effects are more subtle

func _fade_ui_material(effect: Node3D, alpha: float) -> void:
	var ui_element := effect.get_node_or_null("UIElement") as MeshInstance3D
	if ui_element and ui_element.mesh.material:
		var material := ui_element.mesh.material as StandardMaterial3D
		material.albedo_color.a = alpha

func _animate_impact_sparks(effect: Node3D, normal: Vector3, tween: Tween) -> void:
	# Animate sparks flying away from impact
	for child in effect.get_children():
		if child.name.begins_with("Spark"):
			var spark := child as MeshInstance3D
			var direction := (spark.position + normal).normalized()
			var end_pos := spark.position + direction * 0.2
			tween.parallel().tween_property(spark, "position", end_pos, 0.2)

func _animate_boss_spawn(effect: Node3D, tween: Tween, duration: float) -> void:
	var portal := effect.get_node_or_null("Portal") as MeshInstance3D
	if portal:
		tween.set_loops()
		tween.tween_property(portal, "rotation_degrees:y", 360, 1.0)

func _animate_wave_complete(effect: Node3D, tween: Tween, duration: float) -> void:
	var celebration := effect.get_node_or_null("Celebration") as MeshInstance3D
	if celebration:
		tween.tween_property(effect, "scale", Vector3.ONE * 2.0, duration * 0.5)
		tween.tween_property(effect, "scale", Vector3.ZERO, duration * 0.5)

func _animate_portal(effect: Node3D, tween: Tween, duration: float) -> void:
	var portal_ring := effect.get_node_or_null("PortalRing") as MeshInstance3D
	if portal_ring:
		tween.set_loops()
		tween.tween_property(portal_ring, "rotation_degrees:y", 360, 2.0)

func _animate_generic_special(effect: Node3D, tween: Tween, duration: float) -> void:
	tween.tween_method(_fade_ui_material.bind(effect), 1.0, 0.0, duration)

func _get_material_color_modifier(material_type: String) -> Color:
	match material_type:
		"organic":
			return Color(0.8, 0.3, 0.2)  # Reddish for blood/flesh
		"armor":
			return Color(1.0, 0.8, 0.3)  # Yellowish sparks for metal
		"concrete":
			return Color(0.7, 0.7, 0.6)  # Grayish dust
		"energy":
			return Color(0.3, 0.8, 1.0)  # Blue energy discharge
		_:
			return Color.WHITE

func _apply_color_to_effect(effect: Node3D, color: Color, intensity: float) -> void:
	for child in effect.get_children():
		if child is MeshInstance3D:
			var mesh_inst := child as MeshInstance3D
			if mesh_inst.mesh and mesh_inst.mesh.material:
				var material := mesh_inst.mesh.material as StandardMaterial3D
				material.emission = color
				material.albedo_color = color
				if material.emission_enabled:
					material.emission_energy_multiplier = material.emission_energy_multiplier * intensity

# =============================================================================
# Cleanup Functions
# =============================================================================

func _cleanup_inactive_effects() -> void:
	var cleaned := 0
	
	for category in _pools:
		var category_pool: Dictionary = _pools[category]
		for effect_type in category_pool:
			var pool_array: Array = category_pool[effect_type]
			for i in range(pool_array.size() - 1, -1, -1):
				var effect: Node3D = pool_array[i]
				if not is_instance_valid(effect):
					pool_array.remove_at(i)
					cleaned += 1
	
	if cleaned > 0:
		print("VfxPoolSystem: Cleaned up ", cleaned, " invalid effects")

func _exit_tree() -> void:
	# Clean up all effects
	for category in _pools:
		var category_pool: Dictionary = _pools[category]
		for effect_type in category_pool:
			var pool_array: Array = category_pool[effect_type]
			for effect in pool_array:
				if is_instance_valid(effect):
					effect.queue_free()
	
	_pools.clear()
	_active_counts.clear()
	
	if VfxPoolSystem._instance == self:
		VfxPoolSystem._instance = null