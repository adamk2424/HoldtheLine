class_name ImpactEffectsEnhanced
extends Node
## Enhanced impact effects system for different damage types and environmental interactions
## Creates appropriate visual feedback based on weapon type, target material, and damage amount

# --- Impact Effect Categories ---
enum ImpactCategory {
	KINETIC,        # Bullets, shells, physical impacts
	EXPLOSIVE,      # Missiles, grenades, bombs
	ENERGY,         # Lasers, plasma, beams
	ELECTRIC,       # Tesla coils, lightning
	FIRE,          # Flames, incendiary
	ACID,          # Corrosive damage
	FROST,         # Ice damage
	VOID,          # Dark/corruption damage
	PIERCING,      # Railguns, spikes
	AREA           # AoE effects
}

# --- Material Types for Impact Response ---
enum MaterialType {
	ORGANIC,       # Enemy flesh, biological
	ARMOR,         # Metal plating, vehicles
	ENERGY_SHIELD, # Force fields, barriers
	STONE,         # Concrete, rock
	CRYSTAL,       # Crystal formations
	LIQUID,        # Water, acid pools
	VOID_MATTER    # Alien substances
}

# --- Static instance for global access ---
static var _instance: ImpactEffectsEnhanced = null

func _ready() -> void:
	if not ImpactEffectsEnhanced._instance:
		ImpactEffectsEnhanced._instance = self

## Get the main instance
static func get_instance() -> ImpactEffectsEnhanced:
	if not ImpactEffectsEnhanced._instance:
		var instance := ImpactEffectsEnhanced.new()
		instance.name = "ImpactEffectsEnhanced"
		Engine.get_main_loop().current_scene.add_child(instance)
		ImpactEffectsEnhanced._instance = instance
	return ImpactEffectsEnhanced._instance

# =============================================================================
# Enhanced Impact Effects API
# =============================================================================

## Create comprehensive impact effect based on damage type and target
static func create_enhanced_impact(
	pos: Vector3,
	normal: Vector3,
	damage_amount: float,
	impact_category: ImpactCategory,
	material_type: MaterialType,
	weapon_id: String = "",
	additional_data: Dictionary = {}
) -> void:
	var instance := get_instance()
	instance._create_impact_effect(pos, normal, damage_amount, impact_category, material_type, weapon_id, additional_data)

## Create weapon-specific impact based on weapon ID and target
static func create_weapon_impact(
	pos: Vector3,
	normal: Vector3,
	damage: float,
	weapon_id: String,
	target_entity: Node = null
) -> void:
	var impact_cat := _get_impact_category_for_weapon(weapon_id)
	var material := _get_material_type_for_target(target_entity)
	create_enhanced_impact(pos, normal, damage, impact_cat, material, weapon_id)

## Create environmental destruction effects
static func create_environmental_destruction(
	pos: Vector3,
	destruction_type: String,
	intensity: float = 1.0,
	radius: float = 2.0
) -> void:
	var instance := get_instance()
	instance._create_destruction_effect(pos, destruction_type, intensity, radius)

## Create chain reaction effects
static func create_chain_reaction(
	start_pos: Vector3,
	end_positions: Array[Vector3],
	reaction_type: String,
	delay_between: float = 0.2
) -> void:
	var instance := get_instance()
	instance._create_chain_effect(start_pos, end_positions, reaction_type, delay_between)

## Create persistent area effects
static func create_persistent_area_effect(
	pos: Vector3,
	effect_type: String,
	duration: float,
	radius: float,
	intensity: float = 1.0
) -> void:
	var instance := get_instance()
	instance._create_persistent_effect(pos, effect_type, duration, radius, intensity)

# =============================================================================
# Internal Impact Effect Implementation
# =============================================================================

func _create_impact_effect(
	pos: Vector3,
	normal: Vector3,
	damage: float,
	impact_cat: ImpactCategory,
	material: MaterialType,
	weapon_id: String,
	additional_data: Dictionary
) -> void:
	var intensity := clampf(damage / 50.0, 0.2, 3.0)
	
	# Primary impact based on category
	match impact_cat:
		ImpactCategory.KINETIC:
			_create_kinetic_impact(pos, normal, intensity, material)
		ImpactCategory.EXPLOSIVE:
			_create_explosive_impact(pos, normal, intensity, material)
		ImpactCategory.ENERGY:
			_create_energy_impact(pos, normal, intensity, material, weapon_id)
		ImpactCategory.ELECTRIC:
			_create_electric_impact(pos, normal, intensity, material)
		ImpactCategory.FIRE:
			_create_fire_impact(pos, normal, intensity, material)
		ImpactCategory.ACID:
			_create_acid_impact(pos, normal, intensity, material)
		ImpactCategory.FROST:
			_create_frost_impact(pos, normal, intensity, material)
		ImpactCategory.VOID:
			_create_void_impact(pos, normal, intensity, material)
		ImpactCategory.PIERCING:
			_create_piercing_impact(pos, normal, intensity, material)
		ImpactCategory.AREA:
			_create_area_impact(pos, normal, intensity, material)
	
	# Secondary material-specific responses
	_create_material_response(pos, normal, material, intensity)
	
	# Weapon-specific enhancements
	if weapon_id != "":
		_create_weapon_specific_effects(pos, normal, weapon_id, intensity)

func _create_kinetic_impact(pos: Vector3, normal: Vector3, intensity: float, material: MaterialType) -> void:
	match material:
		MaterialType.ORGANIC:
			# Flesh impact with blood splatter
			VfxPool.play_impact_spark(pos, normal, Color(0.8, 0.2, 0.2), intensity)
			_create_blood_splatter(pos, normal, intensity)
		MaterialType.ARMOR:
			# Metal impact with sparks and ricochet
			VfxPool.play_impact_spark(pos, normal, Color(1.0, 0.7, 0.3), intensity)
			AmbientVfx.create_sparks_shower(pos, 1.0 + intensity, intensity * 0.6)
			_create_ricochet_sparks(pos, normal, intensity)
		MaterialType.STONE:
			# Concrete/stone impact with dust and chips
			VfxPool.play_impact_spark(pos, normal, Color(0.7, 0.7, 0.6), intensity)
			AmbientVfx.create_dust_particles(pos, 3.0 + intensity, intensity * 0.8)
			_create_stone_chips(pos, normal, intensity)
		MaterialType.ENERGY_SHIELD:
			# Shield impact with energy ripples
			_create_shield_ripple(pos, normal, intensity)
		_:
			VfxPool.play_impact_spark(pos, normal, Color.WHITE, intensity)

func _create_explosive_impact(pos: Vector3, normal: Vector3, intensity: float, material: MaterialType) -> void:
	# Core explosion
	var explosion_radius := intensity * 1.5
	VfxPool.play_explosion(pos, explosion_radius, Color.ORANGE)
	
	# Shockwave ring
	_create_shockwave_ring(pos, explosion_radius * 1.2, Color(1.0, 0.8, 0.4))
	
	# Material-specific debris
	match material:
		MaterialType.ORGANIC:
			_create_organic_debris(pos, intensity, explosion_radius)
		MaterialType.ARMOR:
			_create_metal_debris(pos, intensity, explosion_radius)
			AmbientVfx.create_sparks_shower(pos, 3.0, intensity * 1.5)
		MaterialType.STONE:
			_create_stone_debris(pos, intensity, explosion_radius)
			AmbientVfx.create_dust_particles(pos, 10.0, intensity)
		_:
			_create_generic_debris(pos, intensity, explosion_radius)
	
	# Smoke and fire
	AmbientVfx.create_battlefield_smoke(pos, 15.0 + intensity * 5.0, intensity)
	AmbientVfx.create_fire_embers(pos, 8.0, intensity * 0.7)

func _create_energy_impact(pos: Vector3, normal: Vector3, intensity: float, material: MaterialType, weapon_id: String) -> void:
	var energy_color := _get_energy_color_for_weapon(weapon_id)
	
	# Energy discharge
	VfxPool.play_beam_hit(pos, energy_color, intensity * 1.5)
	
	# Energy ripples
	_create_energy_ripples(pos, normal, energy_color, intensity)
	
	# Material interaction
	match material:
		MaterialType.ORGANIC:
			# Cauterization effect
			_create_cauterization(pos, normal, energy_color, intensity)
		MaterialType.ARMOR:
			# Metal heating and warping
			_create_metal_heating(pos, normal, intensity)
			AmbientVfx.create_heat_shimmer(pos, 8.0, intensity)
		MaterialType.ENERGY_SHIELD:
			# Shield overload
			_create_shield_overload(pos, energy_color, intensity)
		_:
			AmbientVfx.create_energy_disturbance(pos, 5.0, intensity)

func _create_electric_impact(pos: Vector3, normal: Vector3, intensity: float, material: MaterialType) -> void:
	# Main electric discharge
	VfxPool.play_beam_hit(pos, Color(0.6, 0.9, 1.0), intensity)
	AmbientVfx.create_electric_arcs(pos, 2.0 + intensity, intensity)
	
	# Chain lightning to nearby conductive objects
	_create_chain_lightning(pos, intensity)
	
	# Material-specific effects
	match material:
		MaterialType.ORGANIC:
			# Electrical burns and muscle spasms
			_create_electrical_burns(pos, normal, intensity)
		MaterialType.ARMOR:
			# EMP effect and system disruption
			_create_emp_effect(pos, intensity)
		MaterialType.ENERGY_SHIELD:
			# Shield shorting out
			_create_shield_short(pos, intensity)

func _create_fire_impact(pos: Vector3, normal: Vector3, intensity: float, material: MaterialType) -> void:
	# Fire burst
	VfxPool.play_fire_burst(pos, intensity, intensity * 1.2)
	
	# Spreading flames
	AmbientVfx.create_fire_embers(pos, 6.0 + intensity * 3.0, intensity)
	AmbientVfx.create_heat_shimmer(pos, 12.0, intensity)
	
	# Material ignition
	match material:
		MaterialType.ORGANIC:
			_create_organic_ignition(pos, normal, intensity)
		MaterialType.ARMOR:
			# Metal heating and paint burn-off
			_create_paint_burning(pos, normal, intensity)
		_:
			# Generic spreading fire
			_create_fire_spread(pos, intensity)

func _create_acid_impact(pos: Vector3, normal: Vector3, intensity: float, material: MaterialType) -> void:
	# Acid splash
	VfxPool.play_impact_spark(pos, normal, Color(0.6, 0.8, 0.2), intensity)
	
	# Corrosive eating effect
	_create_corrosion_effect(pos, normal, intensity, material)
	
	# Acid pool formation
	_create_acid_pool(pos, intensity)
	
	# Material dissolution
	match material:
		MaterialType.ORGANIC:
			_create_organic_dissolution(pos, intensity)
		MaterialType.ARMOR:
			_create_metal_corrosion(pos, intensity)
		MaterialType.STONE:
			_create_stone_erosion(pos, intensity)

func _create_frost_impact(pos: Vector3, normal: Vector3, intensity: float, material: MaterialType) -> void:
	# Frost burst
	VfxPool.play_impact_spark(pos, normal, Color(0.7, 0.9, 1.0), intensity)
	
	# Freezing effect
	_create_freezing_effect(pos, normal, intensity)
	
	# Ice crystal formation
	_create_ice_crystals(pos, intensity)

func _create_void_impact(pos: Vector3, normal: Vector3, intensity: float, material: MaterialType) -> void:
	# Dark energy discharge
	VfxPool.play_impact_spark(pos, normal, Color(0.4, 0.2, 0.8), intensity)
	
	# Reality distortion
	_create_void_distortion(pos, intensity)
	
	# Corruption spread
	AmbientVfx.create_corruption_tendrils(pos, 15.0, intensity * 0.8)

func _create_piercing_impact(pos: Vector3, normal: Vector3, intensity: float, material: MaterialType) -> void:
	# Entry hole effect
	_create_entry_hole(pos, normal, intensity)
	
	# Material-specific piercing
	match material:
		MaterialType.ORGANIC:
			_create_penetration_wound(pos, normal, intensity)
		MaterialType.ARMOR:
			_create_armor_penetration(pos, normal, intensity)
		MaterialType.STONE:
			_create_stone_drilling(pos, normal, intensity)

func _create_area_impact(pos: Vector3, normal: Vector3, intensity: float, material: MaterialType) -> void:
	# Large area effect
	var radius := intensity * 2.0
	_create_shockwave_ring(pos, radius, Color(1.0, 0.5, 0.2))
	
	# Multiple impact points
	for i in range(int(intensity * 3)):
		var offset := Vector3(
			randf_range(-radius, radius),
			randf_range(-0.5, 0.5),
			randf_range(-radius, radius)
		)
		var impact_pos := pos + offset
		VfxPool.play_impact_spark(impact_pos, normal, Color.ORANGE, intensity * 0.5)

# =============================================================================
# Material Response Effects
# =============================================================================

func _create_material_response(pos: Vector3, normal: Vector3, material: MaterialType, intensity: float) -> void:
	match material:
		MaterialType.ORGANIC:
			if randf() < 0.3:  # 30% chance for blood
				_create_blood_splatter(pos, normal, intensity * 0.5)
		MaterialType.ARMOR:
			if randf() < 0.4:  # 40% chance for sparks
				AmbientVfx.create_sparks_shower(pos, 1.5, intensity * 0.4)
		MaterialType.STONE:
			if randf() < 0.5:  # 50% chance for dust
				AmbientVfx.create_dust_particles(pos, 5.0, intensity * 0.3)
		MaterialType.CRYSTAL:
			_create_crystal_shatter(pos, intensity)
		MaterialType.LIQUID:
			_create_liquid_splash(pos, intensity)

# =============================================================================
# Weapon-Specific Enhancement Effects
# =============================================================================

func _create_weapon_specific_effects(pos: Vector3, normal: Vector3, weapon_id: String, intensity: float) -> void:
	match weapon_id:
		"autocannon":
			# Shell casing ejection
			_create_shell_casing(pos, intensity)
		"missile_battery":
			# Delayed secondary explosions
			_create_delayed_explosions(pos, intensity)
		"rail_gun":
			# Electromagnetic afterglow
			_create_em_afterglow(pos, intensity)
		"tesla_coil":
			# Persistent electrical field
			_create_electrical_field(pos, intensity)
		"inferno_tower":
			# Lingering flames
			_create_lingering_flames(pos, intensity)

# =============================================================================
# Specialized Effect Creation Functions
# =============================================================================

func _create_blood_splatter(pos: Vector3, normal: Vector3, intensity: float) -> void:
	# Multiple blood droplets
	for i in range(int(intensity * 5)):
		var splatter_dir := normal + Vector3(
			randf_range(-0.5, 0.5),
			randf_range(-0.2, 0.5),
			randf_range(-0.5, 0.5)
		)
		var splatter_pos := pos + splatter_dir * randf_range(0.1, 0.3)
		VfxPool.play_impact_spark(splatter_pos, splatter_dir, Color(0.6, 0.1, 0.05), 0.3)

func _create_ricochet_sparks(pos: Vector3, normal: Vector3, intensity: float) -> void:
	# Sparks flying off in ricochet directions
	var ricochet_dir := normal.reflect(Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)))
	for i in range(int(intensity * 3)):
		var spark_dir := ricochet_dir + Vector3(
			randf_range(-0.3, 0.3),
			randf_range(-0.3, 0.3),
			randf_range(-0.3, 0.3)
		)
		var spark_pos := pos + spark_dir * randf_range(0.2, 0.8)
		VfxPool.play_impact_spark(spark_pos, spark_dir, Color(1.0, 0.7, 0.1), 0.4)

func _create_stone_chips(pos: Vector3, normal: Vector3, intensity: float) -> void:
	# Stone chips and fragments
	for i in range(int(intensity * 4)):
		var chip_dir := normal + Vector3(
			randf_range(-0.8, 0.8),
			randf_range(0.0, 1.0),
			randf_range(-0.8, 0.8)
		)
		var chip_pos := pos + chip_dir * randf_range(0.1, 0.5)
		VfxPool.play_impact_spark(chip_pos, chip_dir, Color(0.6, 0.6, 0.5), 0.2)

func _create_shockwave_ring(pos: Vector3, radius: float, color: Color) -> void:
	# Expanding shockwave ring effect
	var ring := Node3D.new()
	ring.name = "ShockwaveRing"
	ring.global_position = pos
	
	var ring_mesh := MeshInstance3D.new()
	var quad_mesh := QuadMesh.new()
	quad_mesh.size = Vector2(radius * 2.0, 0.1)
	
	var material := StandardMaterial3D.new()
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 2.0
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	quad_mesh.material = material
	
	ring_mesh.mesh = quad_mesh
	ring_mesh.rotation.x = -PI/2  # Lay flat
	ring.add_child(ring_mesh)
	
	if Engine.get_main_loop():
		Engine.get_main_loop().current_scene.add_child(ring)
		
		var tween := Tween.new()
		ring.add_child(tween)
		
		# Expand and fade
		tween.parallel().tween_property(ring_mesh, "scale", Vector3(2.0, 1.0, 2.0), 0.5)
		tween.parallel().tween_method(_fade_material.bind(material), 1.0, 0.0, 0.5)
		tween.tween_callback(ring.queue_free).set_delay(0.5)

func _create_shield_ripple(pos: Vector3, normal: Vector3, intensity: float) -> void:
	# Energy shield ripple effect
	VfxPool.play_beam_hit(pos, Color(0.3, 0.8, 1.0), intensity)
	AmbientVfx.create_energy_disturbance(pos, 3.0, intensity * 0.8)
	
	# Hexagonal ripple pattern
	_create_hex_ripple(pos, intensity)

func _create_energy_ripples(pos: Vector3, normal: Vector3, color: Color, intensity: float) -> void:
	# Concentric energy ripples
	for i in range(3):
		var delay := i * 0.1
		var ripple_radius := (i + 1) * intensity * 0.5
		_create_delayed_energy_ring(pos, color, ripple_radius, delay)

func _create_chain_lightning(pos: Vector3, intensity: float) -> void:
	# Find nearby metallic objects and create arcs
	# Simplified: create random arc patterns
	for i in range(int(intensity * 2)):
		var arc_end := pos + Vector3(
			randf_range(-2.0, 2.0),
			randf_range(-1.0, 2.0),
			randf_range(-2.0, 2.0)
		)
		_create_lightning_arc(pos, arc_end, Color(0.7, 0.9, 1.0))

func _create_corrosion_effect(pos: Vector3, normal: Vector3, intensity: float, material: MaterialType) -> void:
	# Acid eating through material
	AmbientVfx.create_corruption_tendrils(pos, 8.0, intensity * 0.5)
	
	# Bubbling and hissing
	for i in range(int(intensity * 3)):
		var bubble_pos := pos + Vector3(
			randf_range(-0.2, 0.2),
			randf_range(0.0, 0.1),
			randf_range(-0.2, 0.2)
		)
		VfxPool.play_impact_spark(bubble_pos, Vector3.UP, Color(0.6, 0.8, 0.2), 0.3)

func _create_acid_pool(pos: Vector3, intensity: float) -> void:
	# Persistent acid pool
	var pool_radius := intensity * 0.5
	create_persistent_area_effect(pos, "acid_pool", 10.0, pool_radius, intensity)

# =============================================================================
# Destruction and Environmental Effects
# =============================================================================

func _create_destruction_effect(pos: Vector3, destruction_type: String, intensity: float, radius: float) -> void:
	match destruction_type:
		"building_collapse":
			_create_building_collapse(pos, intensity, radius)
		"ground_crater":
			_create_ground_crater(pos, intensity, radius)
		"structural_damage":
			_create_structural_damage(pos, intensity, radius)
		"environmental_fire":
			_create_environmental_fire(pos, intensity, radius)

func _create_building_collapse(pos: Vector3, intensity: float, radius: float) -> void:
	# Large explosion with debris
	VfxPool.play_explosion(pos, radius, Color(0.8, 0.5, 0.2))
	AmbientVfx.create_battlefield_smoke(pos, 30.0, intensity * 1.5)
	AmbientVfx.create_dust_particles(pos, 25.0, intensity)
	
	# Falling debris
	for i in range(int(intensity * 8)):
		var debris_pos := pos + Vector3(
			randf_range(-radius, radius),
			randf_range(2.0, 5.0),
			randf_range(-radius, radius)
		)
		_create_falling_debris(debris_pos, pos)

func _create_ground_crater(pos: Vector3, intensity: float, radius: float) -> void:
	# Ground impact crater
	_create_shockwave_ring(pos, radius * 1.5, Color(0.6, 0.4, 0.2))
	AmbientVfx.create_dust_particles(pos, 20.0, intensity)
	
	# Dirt and rock spray
	for i in range(int(intensity * 6)):
		var spray_dir := Vector3(
			randf_range(-1, 1),
			randf_range(0.5, 1.5),
			randf_range(-1, 1)
		).normalized()
		var spray_pos := pos + spray_dir * randf_range(radius * 0.5, radius * 1.2)
		VfxPool.play_impact_spark(spray_pos, spray_dir, Color(0.4, 0.3, 0.2), 0.5)

# =============================================================================
# Chain and Persistent Effects
# =============================================================================

func _create_chain_effect(start_pos: Vector3, end_positions: Array[Vector3], reaction_type: String, delay: float) -> void:
	for i in range(end_positions.size()):
		var timer := Timer.new()
		timer.wait_time = delay * i
		timer.one_shot = true
		timer.timeout.connect(_trigger_chain_effect.bind(end_positions[i], reaction_type))
		timer.timeout.connect(timer.queue_free)
		add_child(timer)
		timer.start()

func _trigger_chain_effect(pos: Vector3, reaction_type: String) -> void:
	match reaction_type:
		"explosion_chain":
			VfxPool.play_explosion(pos, 1.0, Color.ORANGE)
			AmbientVfx.create_battlefield_smoke(pos, 5.0, 0.8)
		"electric_chain":
			VfxPool.play_beam_hit(pos, Color(0.6, 0.9, 1.0), 1.0)
			AmbientVfx.create_electric_arcs(pos, 2.0, 1.0)

func _create_persistent_effect(pos: Vector3, effect_type: String, duration: float, radius: float, intensity: float) -> void:
	# Create persistent area effect that lasts over time
	var effect_data := {
		"position": pos,
		"type": effect_type,
		"duration": duration,
		"radius": radius,
		"intensity": intensity,
		"start_time": Time.get_ticks_msec() / 1000.0
	}
	
	# Start the persistent effect
	_start_persistent_effect(effect_data)

func _start_persistent_effect(effect_data: Dictionary) -> void:
	var effect_type: String = effect_data["type"]
	var pos: Vector3 = effect_data["position"]
	var intensity: float = effect_data["intensity"]
	
	match effect_type:
		"acid_pool":
			_start_acid_pool_effect(effect_data)
		"fire_spread":
			_start_fire_spread_effect(effect_data)
		"electric_field":
			_start_electric_field_effect(effect_data)
		"toxic_cloud":
			_start_toxic_cloud_effect(effect_data)

func _start_acid_pool_effect(effect_data: Dictionary) -> void:
	var pos: Vector3 = effect_data["position"]
	var intensity: float = effect_data["intensity"]
	
	# Periodic bubbling
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(_acid_pool_tick.bind(pos, intensity))
	add_child(timer)
	timer.start()
	
	# Auto-cleanup after duration
	var cleanup_timer := Timer.new()
	cleanup_timer.wait_time = effect_data["duration"]
	cleanup_timer.one_shot = true
	cleanup_timer.timeout.connect(timer.queue_free)
	cleanup_timer.timeout.connect(cleanup_timer.queue_free)
	add_child(cleanup_timer)
	cleanup_timer.start()

func _acid_pool_tick(pos: Vector3, intensity: float) -> void:
	VfxPool.play_impact_spark(
		pos + Vector3(randf_range(-0.3, 0.3), 0.05, randf_range(-0.3, 0.3)),
		Vector3.UP,
		Color(0.6, 0.8, 0.2),
		intensity * 0.3
	)

# =============================================================================
# Helper Functions and Utilities
# =============================================================================

static func _get_impact_category_for_weapon(weapon_id: String) -> ImpactCategory:
	match weapon_id:
		"autocannon":
			return ImpactCategory.KINETIC
		"missile_battery":
			return ImpactCategory.EXPLOSIVE
		"rail_gun":
			return ImpactCategory.PIERCING
		"plasma_mortar":
			return ImpactCategory.ENERGY
		"tesla_coil":
			return ImpactCategory.ELECTRIC
		"inferno_tower":
			return ImpactCategory.FIRE
		_:
			return ImpactCategory.KINETIC

static func _get_material_type_for_target(target: Node) -> MaterialType:
	if not is_instance_valid(target):
		return MaterialType.ORGANIC
	
	if target.has_method("get_material_type"):
		var material_name: String = target.get_material_type()
		match material_name:
			"organic", "flesh", "biological":
				return MaterialType.ORGANIC
			"metal", "armor", "steel":
				return MaterialType.ARMOR
			"energy", "shield", "barrier":
				return MaterialType.ENERGY_SHIELD
			"stone", "concrete", "rock":
				return MaterialType.STONE
			"crystal":
				return MaterialType.CRYSTAL
			"liquid", "water":
				return MaterialType.LIQUID
			"void", "corruption":
				return MaterialType.VOID_MATTER
	
	# Fallback based on entity type
	if target.is_in_group("enemy"):
		return MaterialType.ORGANIC
	elif target.is_in_group("tower") or target.is_in_group("building"):
		return MaterialType.ARMOR
	else:
		return MaterialType.ORGANIC

func _get_energy_color_for_weapon(weapon_id: String) -> Color:
	match weapon_id:
		"rail_gun":
			return Color(0.3, 0.6, 1.0)
		"plasma_mortar":
			return Color(0.8, 0.2, 0.9)
		"tesla_coil":
			return Color(0.5, 0.9, 1.0)
		_:
			return Color(0.6, 0.8, 1.0)

func _fade_material(material: StandardMaterial3D, alpha: float) -> void:
	if material:
		material.albedo_color.a = alpha

# Placeholder functions for complex effects (would be expanded with full implementation)
func _create_hex_ripple(pos: Vector3, intensity: float) -> void:
	# Hexagonal energy pattern
	VfxPool.play_beam_hit(pos, Color(0.3, 0.8, 1.0), intensity)

func _create_delayed_energy_ring(pos: Vector3, color: Color, radius: float, delay: float) -> void:
	var timer := Timer.new()
	timer.wait_time = delay
	timer.one_shot = true
	timer.timeout.connect(_create_shockwave_ring.bind(pos, radius, color))
	timer.timeout.connect(timer.queue_free)
	add_child(timer)
	timer.start()

func _create_lightning_arc(start: Vector3, end: Vector3, color: Color) -> void:
	# Lightning bolt between points
	VfxPool.play_beam_hit(start, color, 1.0)
	VfxPool.play_beam_hit(end, color, 0.8)

func _create_falling_debris(start_pos: Vector3, target_pos: Vector3) -> void:
	# Debris falling animation
	VfxPool.play_impact_spark(target_pos, Vector3.UP, Color(0.5, 0.4, 0.3), 0.8)

# Additional placeholder functions for all the specialized effects...
func _create_cauterization(pos: Vector3, normal: Vector3, color: Color, intensity: float) -> void: pass
func _create_metal_heating(pos: Vector3, normal: Vector3, intensity: float) -> void: pass
func _create_shield_overload(pos: Vector3, color: Color, intensity: float) -> void: pass
func _create_electrical_burns(pos: Vector3, normal: Vector3, intensity: float) -> void: pass
func _create_emp_effect(pos: Vector3, intensity: float) -> void: pass
func _create_shield_short(pos: Vector3, intensity: float) -> void: pass
func _create_organic_ignition(pos: Vector3, normal: Vector3, intensity: float) -> void: pass
func _create_paint_burning(pos: Vector3, normal: Vector3, intensity: float) -> void: pass
func _create_fire_spread(pos: Vector3, intensity: float) -> void: pass
func _create_organic_dissolution(pos: Vector3, intensity: float) -> void: pass
func _create_metal_corrosion(pos: Vector3, intensity: float) -> void: pass
func _create_stone_erosion(pos: Vector3, intensity: float) -> void: pass
func _create_freezing_effect(pos: Vector3, normal: Vector3, intensity: float) -> void: pass
func _create_ice_crystals(pos: Vector3, intensity: float) -> void: pass
func _create_void_distortion(pos: Vector3, intensity: float) -> void: pass
func _create_entry_hole(pos: Vector3, normal: Vector3, intensity: float) -> void: pass
func _create_penetration_wound(pos: Vector3, normal: Vector3, intensity: float) -> void: pass
func _create_armor_penetration(pos: Vector3, normal: Vector3, intensity: float) -> void: pass
func _create_stone_drilling(pos: Vector3, normal: Vector3, intensity: float) -> void: pass
func _create_organic_debris(pos: Vector3, intensity: float, radius: float) -> void: pass
func _create_metal_debris(pos: Vector3, intensity: float, radius: float) -> void: pass
func _create_stone_debris(pos: Vector3, intensity: float, radius: float) -> void: pass
func _create_generic_debris(pos: Vector3, intensity: float, radius: float) -> void: pass
func _create_crystal_shatter(pos: Vector3, intensity: float) -> void: pass
func _create_liquid_splash(pos: Vector3, intensity: float) -> void: pass
func _create_shell_casing(pos: Vector3, intensity: float) -> void: pass
func _create_delayed_explosions(pos: Vector3, intensity: float) -> void: pass
func _create_em_afterglow(pos: Vector3, intensity: float) -> void: pass
func _create_electrical_field(pos: Vector3, intensity: float) -> void: pass
func _create_lingering_flames(pos: Vector3, intensity: float) -> void: pass
func _create_structural_damage(pos: Vector3, intensity: float, radius: float) -> void: pass
func _create_environmental_fire(pos: Vector3, intensity: float, radius: float) -> void: pass
func _start_fire_spread_effect(effect_data: Dictionary) -> void: pass
func _start_electric_field_effect(effect_data: Dictionary) -> void: pass
func _start_toxic_cloud_effect(effect_data: Dictionary) -> void: pass