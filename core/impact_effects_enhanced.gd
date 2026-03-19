class_name ImpactEffectsEnhanced
extends Node
## Enhanced impact effects system for weapon impacts on different target types
## Creates contextually appropriate visual and audio feedback for hits

# --- Impact Types ---
enum ImpactType {
	KINETIC,        # Bullets, shells, physical projectiles
	ENERGY,         # Lasers, plasma, particle beams  
	EXPLOSIVE,      # Missiles, grenades, charges
	FLAME,          # Fire, thermite, incendiary
	ELECTRIC,       # Tesla, lightning, EMP
	ACID,           # Chemical, corrosive attacks
	BIOLOGICAL,     # Organic projectiles, spines
	PIERCING        # Railgun, armor-piercing rounds
}

# --- Target Material Types ---
enum MaterialType {
	ORGANIC,        # Flesh, biological enemies
	ARMOR,          # Metal plating, vehicles
	CONCRETE,       # Walls, buildings, structures
	CRYSTAL,        # Energy shields, crystal formations
	ENERGY,         # Force fields, plasma barriers
	GENERIC         # Unknown/mixed materials
}

## Create weapon-specific impact effect
static func create_weapon_impact(
	pos: Vector3, 
	normal: Vector3, 
	damage: float, 
	weapon_type: String, 
	target_entity: Node = null
) -> void:
	var impact_type := _get_impact_type_from_weapon(weapon_type)
	var material_type := _get_material_type_from_target(target_entity)
	
	# Create primary impact effect
	_create_primary_impact(pos, normal, impact_type, material_type, damage)
	
	# Create secondary effects based on weapon
	_create_secondary_effects(pos, normal, weapon_type, target_entity, damage)
	
	# Play appropriate audio
	_play_impact_audio(pos, impact_type, material_type, damage)

## Create enhanced projectile trail impact
static func create_projectile_trail_impact(
	start_pos: Vector3,
	end_pos: Vector3, 
	weapon_type: String,
	target_entity: Node = null
) -> void:
	var direction := (end_pos - start_pos).normalized()
	var distance := start_pos.distance_to(end_pos)
	
	# Create trail particles along path
	match weapon_type:
		"autocannon":
			_create_bullet_trail_sparks(start_pos, end_pos, 0.3)
		"missile_battery":
			_create_missile_smoke_trail(start_pos, end_pos, 1.2)
		"rail_gun":
			_create_railgun_ionization_trail(start_pos, end_pos)
		"plasma_mortar":
			_create_plasma_discharge_trail(start_pos, end_pos)
		"tesla_coil":
			_create_electric_arc_branches(start_pos, end_pos)
		"inferno_tower":
			_create_flame_stream_particles(start_pos, end_pos)

# =============================================================================
# Primary Impact Effects
# =============================================================================

static func _create_primary_impact(
	pos: Vector3, 
	normal: Vector3, 
	impact_type: ImpactType, 
	material_type: MaterialType,
	damage: float
) -> void:
	match impact_type:
		ImpactType.KINETIC:
			_create_kinetic_impact(pos, normal, material_type, damage)
		ImpactType.ENERGY:
			_create_energy_impact(pos, normal, material_type, damage)
		ImpactType.EXPLOSIVE:
			_create_explosive_impact(pos, normal, material_type, damage)
		ImpactType.FLAME:
			_create_flame_impact(pos, normal, material_type, damage)
		ImpactType.ELECTRIC:
			_create_electric_impact(pos, normal, material_type, damage)
		ImpactType.ACID:
			_create_acid_impact(pos, normal, material_type, damage)
		ImpactType.BIOLOGICAL:
			_create_biological_impact(pos, normal, material_type, damage)
		ImpactType.PIERCING:
			_create_piercing_impact(pos, normal, material_type, damage)

static func _create_kinetic_impact(pos: Vector3, normal: Vector3, material: MaterialType, damage: float) -> void:
	match material:
		MaterialType.ORGANIC:
			# Blood spurt, tissue damage
			VfxPool.play_impact_spark(pos, normal, Color(0.6, 0.1, 0.1), 1.5)
			VfxPool.play_impact_spark(pos + normal * 0.1, normal, Color(0.8, 0.2, 0.1), 1.0)
			AmbientVfx.create_blood_spatter(pos, normal, damage * 0.1)
			
		MaterialType.ARMOR:
			# Metal sparks, ricochet
			VfxPool.play_impact_spark(pos, normal, Color(1.0, 0.8, 0.2), 2.0)
			AmbientVfx.create_metal_sparks(pos, normal, 8, 0.8)
			if damage > 30:  # Heavy impacts dent armor
				AmbientVfx.create_impact_crater(pos, 0.1)
				
		MaterialType.CONCRETE:
			# Concrete dust, chips
			VfxPool.play_impact_spark(pos, normal, Color(0.7, 0.7, 0.6), 1.2)
			AmbientVfx.create_dust_cloud(pos, normal * 0.3, 0.8)
			AmbientVfx.create_concrete_chips(pos, normal, damage * 0.05)
			
		_:
			# Generic impact
			VfxPool.play_impact_spark(pos, normal, Color.ORANGE, 1.0)

static func _create_energy_impact(pos: Vector3, normal: Vector3, material: MaterialType, damage: float) -> void:
	match material:
		MaterialType.ORGANIC:
			# Energy burn, cauterization
			VfxPool.play_beam_hit(pos, Color(0.8, 0.9, 1.0), 2.0)
			AmbientVfx.create_energy_burn(pos, damage * 0.08)
			VfxPool.play_smoke_puff(pos, normal * 0.2, 0.5)
			
		MaterialType.ARMOR:
			# Metal heating, energy dispersion
			VfxPool.play_beam_hit(pos, Color(1.0, 0.6, 0.2), 2.5)
			AmbientVfx.create_heat_shimmer(pos, 2.0, 1.5)
			if damage > 50:  # High energy melts through
				AmbientVfx.create_molten_metal(pos, normal)
				
		MaterialType.ENERGY:
			# Energy-on-energy interference
			VfxPool.play_beam_hit(pos, Color(0.8, 0.4, 1.0), 3.0)
			AmbientVfx.create_energy_interference(pos, 1.5)
			
		_:
			VfxPool.play_beam_hit(pos, Color(0.6, 0.8, 1.0), 1.5)

static func _create_explosive_impact(pos: Vector3, normal: Vector3, material: MaterialType, damage: float) -> void:
	var explosion_size := damage * 0.02
	
	# Primary explosion
	VfxPool.play_explosion(pos, explosion_size, Color(1.0, 0.4, 0.0))
	
	match material:
		MaterialType.ORGANIC:
			# Devastating organic damage
			AmbientVfx.create_gore_explosion(pos, explosion_size)
			VfxPool.play_fire_burst(pos, explosion_size * 0.8, 1.5)
			
		MaterialType.ARMOR:
			# Metal fragmentation
			AmbientVfx.create_shrapnel_burst(pos, normal, 12, explosion_size)
			VfxPool.play_fire_burst(pos, explosion_size, 2.0)
			
		MaterialType.CONCRETE:
			# Structural damage
			AmbientVfx.create_debris_explosion(pos, explosion_size)
			AmbientVfx.create_dust_cloud(pos, Vector3.UP, explosion_size)
			
		_:
			VfxPool.play_fire_burst(pos, explosion_size, 1.0)

static func _create_flame_impact(pos: Vector3, normal: Vector3, material: MaterialType, damage: float) -> void:
	VfxPool.play_fire_burst(pos, damage * 0.03, 2.0)
	
	match material:
		MaterialType.ORGANIC:
			# Organic burning
			AmbientVfx.create_burning_flesh(pos, damage * 0.05)
			VfxPool.play_smoke_puff(pos, normal * 0.3, 1.0)
			
		MaterialType.ARMOR:
			# Metal heating and warping
			AmbientVfx.create_metal_heating(pos, damage * 0.04)
			AmbientVfx.create_heat_shimmer(pos, 3.0, 2.0)
			
		_:
			AmbientVfx.create_fire_spread(pos, normal, damage * 0.02)

static func _create_electric_impact(pos: Vector3, normal: Vector3, material: MaterialType, damage: float) -> void:
	VfxPool.play_beam_hit(pos, Color(0.4, 0.8, 1.0), 2.5)
	
	match material:
		MaterialType.ORGANIC:
			# Neural disruption
			AmbientVfx.create_electric_nervous_system(pos, damage * 0.1)
			
		MaterialType.ARMOR:
			# Electrical arcing across metal
			AmbientVfx.create_electric_arcs(pos, 1.5, 2.0)
			AmbientVfx.create_emp_pulse(pos, damage * 0.05)
			
		MaterialType.ENERGY:
			# Energy field disruption
			AmbientVfx.create_energy_field_collapse(pos, damage * 0.08)
			
		_:
			AmbientVfx.create_electric_arcs(pos, 1.0, 1.5)

static func _create_acid_impact(pos: Vector3, normal: Vector3, material: MaterialType, damage: float) -> void:
	VfxPool.play_impact_spark(pos, normal, Color(0.6, 0.8, 0.2), 1.5)
	
	match material:
		MaterialType.ORGANIC:
			# Tissue dissolution
			AmbientVfx.create_acid_dissolution(pos, damage * 0.06)
			VfxPool.play_smoke_puff(pos, normal * 0.2, 0.8)
			
		MaterialType.ARMOR:
			# Metal corrosion
			AmbientVfx.create_metal_corrosion(pos, damage * 0.04)
			AmbientVfx.create_acid_smoke(pos, 1.5)
			
		_:
			AmbientVfx.create_acid_pool(pos, damage * 0.03)

static func _create_biological_impact(pos: Vector3, normal: Vector3, material: MaterialType, damage: float) -> void:
	VfxPool.play_impact_spark(pos, normal, Color(0.8, 0.7, 0.4), 1.0)
	
	match material:
		MaterialType.ORGANIC:
			# Spine penetration, bio-toxins
			AmbientVfx.create_toxin_injection(pos, damage * 0.05)
			
		MaterialType.ARMOR:
			# Spine shattering on hard surfaces
			AmbientVfx.create_bone_fragments(pos, normal, 6)
			
		_:
			AmbientVfx.create_organic_splatter(pos, normal, damage * 0.02)

static func _create_piercing_impact(pos: Vector3, normal: Vector3, material: MaterialType, damage: float) -> void:
	match material:
		MaterialType.ORGANIC:
			# Clean through-and-through wounds
			VfxPool.play_beam_hit(pos, Color(0.8, 0.2, 0.2), 1.5)
			AmbientVfx.create_entry_wound(pos, normal, damage * 0.03)
			
		MaterialType.ARMOR:
			# Armor penetration, molten edges
			VfxPool.play_beam_hit(pos, Color(1.0, 0.8, 0.4), 2.0)
			AmbientVfx.create_penetration_hole(pos, normal, damage * 0.02)
			AmbientVfx.create_molten_metal(pos, -normal)  # Exit spray
			
		_:
			VfxPool.play_beam_hit(pos, Color(0.6, 0.9, 1.0), 1.8)

# =============================================================================
# Secondary Effects
# =============================================================================

static func _create_secondary_effects(
	pos: Vector3, 
	normal: Vector3, 
	weapon_type: String, 
	target_entity: Node, 
	damage: float
) -> void:
	match weapon_type:
		"autocannon":
			# Shell casing ejection
			AmbientVfx.create_shell_casing(pos + normal * -0.5, Vector3(randf_range(-1,1), randf_range(0.5,1), randf_range(-1,1)))
			
		"missile_battery": 
			# Explosive fragmentation
			if damage > 40:
				AmbientVfx.create_shrapnel_burst(pos, normal, 8, 0.8)
				
		"rail_gun":
			# Electromagnetic pulse
			AmbientVfx.create_emp_pulse(pos, 2.0)
			
		"plasma_mortar":
			# Plasma residue
			AmbientVfx.create_plasma_residue(pos, 1.5, 3.0)
			
		"tesla_coil":
			# Chain lightning to nearby targets
			if target_entity and is_instance_valid(target_entity):
				AmbientVfx.create_chain_lightning(pos, target_entity, 5.0)
				
		"inferno_tower":
			# Lingering flames
			AmbientVfx.create_fire_spread(pos, normal, 1.2)

# =============================================================================
# Trail Effects
# =============================================================================

static func _create_bullet_trail_sparks(start: Vector3, end: Vector3, duration: float) -> void:
	var distance := start.distance_to(end)
	var direction := (end - start).normalized()
	var spark_count := int(distance * 3.0)
	
	for i in range(spark_count):
		var t := float(i) / spark_count
		var pos := start.lerp(end, t)
		var delay := duration * t * 0.1  # Sparks appear quickly after bullet
		
		_delayed_spark(pos + Vector3(randf_range(-0.1, 0.1), randf_range(-0.1, 0.1), randf_range(-0.1, 0.1)), 
					   Color(1.0, 0.8, 0.3), delay)

static func _create_missile_smoke_trail(start: Vector3, end: Vector3, duration: float) -> void:
	var smoke_count := int((end - start).length() * 2.0)
	
	for i in range(smoke_count):
		var t := float(i) / smoke_count
		var pos := start.lerp(end, t)
		var delay := duration * t * 0.3
		
		_delayed_smoke(pos, Vector3.UP * 0.1, delay, 0.8)

static func _create_railgun_ionization_trail(start: Vector3, end: Vector3) -> void:
	var segment_count := 8
	
	for i in range(segment_count):
		var t := float(i) / segment_count
		var pos := start.lerp(end, t)
		
		VfxPool.play_beam_hit(pos, Color(0.4, 0.8, 1.0), 1.5)

static func _create_plasma_discharge_trail(start: Vector3, end: Vector3) -> void:
	var discharge_count := 6
	
	for i in range(discharge_count):
		var t := float(i) / discharge_count  
		var pos := start.lerp(end, t)
		
		VfxPool.play_energy_charge(pos, pos + Vector3.UP * 0.2, Color(0.8, 0.2, 0.9), 0.3)

static func _create_electric_arc_branches(start: Vector3, end: Vector3) -> void:
	var branch_count := 4
	var midpoint := start.lerp(end, 0.5)
	
	# Main arc
	VfxPool.play_beam_hit(midpoint, Color(0.5, 0.9, 1.0), 2.0)
	
	# Branching arcs
	for i in range(branch_count):
		var offset := Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * 0.5
		var branch_end := midpoint + offset
		VfxPool.play_beam_hit(branch_end, Color(0.4, 0.8, 1.0), 1.2)

static func _create_flame_stream_particles(start: Vector3, end: Vector3) -> void:
	var flame_count := int((end - start).length() * 4.0)
	
	for i in range(flame_count):
		var t := float(i) / flame_count
		var pos := start.lerp(end, t)
		var offset := Vector3(randf_range(-0.2, 0.2), randf_range(-0.1, 0.2), randf_range(-0.2, 0.2))
		
		VfxPool.play_fire_burst(pos + offset, 0.3, 1.5)

# =============================================================================
# Helper Functions
# =============================================================================

static func _get_impact_type_from_weapon(weapon_type: String) -> ImpactType:
	match weapon_type:
		"autocannon":
			return ImpactType.KINETIC
		"missile_battery":
			return ImpactType.EXPLOSIVE
		"rail_gun":
			return ImpactType.PIERCING
		"plasma_mortar":
			return ImpactType.ENERGY
		"tesla_coil":
			return ImpactType.ELECTRIC
		"inferno_tower":
			return ImpactType.FLAME
		"enemy_projectile":
			return ImpactType.BIOLOGICAL
		"acid_glob":
			return ImpactType.ACID
		_:
			return ImpactType.KINETIC

static func _get_material_type_from_target(target: Node) -> MaterialType:
	if not is_instance_valid(target):
		return MaterialType.GENERIC
		
	if target.is_in_group("enemy"):
		return MaterialType.ORGANIC
	elif target.is_in_group("tower"):
		return MaterialType.ARMOR
	elif target.is_in_group("building") or target.is_in_group("barrier"):
		return MaterialType.CONCRETE
	elif target.has_meta("material_type"):
		var material: String = target.get_meta("material_type")
		match material:
			"organic": return MaterialType.ORGANIC
			"armor": return MaterialType.ARMOR
			"concrete": return MaterialType.CONCRETE
			"crystal": return MaterialType.CRYSTAL
			"energy": return MaterialType.ENERGY
			_: return MaterialType.GENERIC
	else:
		return MaterialType.GENERIC

static func _play_impact_audio(pos: Vector3, impact_type: ImpactType, material_type: MaterialType, damage: float) -> void:
	var audio_name := ""
	
	match impact_type:
		ImpactType.KINETIC:
			match material_type:
				MaterialType.ORGANIC:
					audio_name = "impact.flesh"
				MaterialType.ARMOR:
					audio_name = "impact.metal"
				MaterialType.CONCRETE:
					audio_name = "impact.concrete"
				_:
					audio_name = "impact.generic"
		ImpactType.ENERGY:
			audio_name = "impact.energy"
		ImpactType.EXPLOSIVE:
			audio_name = "impact.explosion"
		ImpactType.ELECTRIC:
			audio_name = "impact.electric"
		_:
			audio_name = "impact.generic"
	
	if audio_name != "":
		GameBus.audio_play_3d.emit(audio_name, pos)

# Delayed effect helpers for timed trail particles
static func _delayed_spark(pos: Vector3, color: Color, delay: float) -> void:
	if delay <= 0:
		VfxPool.play_impact_spark(pos, Vector3.UP, color, 0.8)
		return
	
	var timer := Timer.new()
	timer.wait_time = delay
	timer.one_shot = true
	timer.timeout.connect(VfxPool.play_impact_spark.bind(pos, Vector3.UP, color, 0.8))
	timer.timeout.connect(timer.queue_free)
	
	if Engine.get_main_loop() is SceneTree:
		var scene_tree := Engine.get_main_loop() as SceneTree
		scene_tree.current_scene.add_child(timer)
		timer.start()

static func _delayed_smoke(pos: Vector3, velocity: Vector3, delay: float, size: float) -> void:
	if delay <= 0:
		VfxPool.play_smoke_puff(pos, velocity, size)
		return
		
	var timer := Timer.new()
	timer.wait_time = delay
	timer.one_shot = true
	timer.timeout.connect(VfxPool.play_smoke_puff.bind(pos, velocity, size))
	timer.timeout.connect(timer.queue_free)
	
	if Engine.get_main_loop() is SceneTree:
		var scene_tree := Engine.get_main_loop() as SceneTree
		scene_tree.current_scene.add_child(timer)
		timer.start()