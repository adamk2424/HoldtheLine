class_name EnemyVisualEnhanced
extends Node
## Enhanced enemy visual system with detailed models matching JSON descriptions
## Provides animated models with idle behaviors and visual feedback

# --- Animation Types ---
enum AnimationType {
	IDLE,
	WALK,
	ATTACK,
	DAMAGED,
	DEATH,
	SPECIAL
}

# --- Visual Enhancement Categories ---
enum EnemyCategory {
	SWARM,      # Small fast enemies (thrasher, blight_mite)
	BRUISER,    # Heavy melee (brute, gorger)
	RANGED,     # Long-range attackers (slinker, bile_spitter)
	FLYING,     # Aerial units (scrit, gloom_wing)
	SPECIAL,    # Unique mechanics (clugg, howler)
	BOSS        # Major threats (terror_bringer, behemoth, etc.)
}

## Create enhanced visual for enemy based on JSON data
static func create_enhanced_enemy_visual(enemy_id: String, enemy_data: Dictionary, base_color: Color) -> Node3D:
	match enemy_id:
		"thrasher":
			return _create_thrasher_enhanced(base_color, enemy_data)
		"brute":
			return _create_brute_enhanced(base_color, enemy_data)
		"clugg":
			return _create_clugg_enhanced(base_color, enemy_data)
		"scrit":
			return _create_scrit_enhanced(base_color, enemy_data)
		"blight_mite":
			return _create_blight_mite_enhanced(base_color, enemy_data)
		"terror_bringer":
			return _create_terror_bringer_enhanced(base_color, enemy_data)
		"polus":
			return _create_polus_enhanced(base_color, enemy_data)
		"slinker":
			return _create_slinker_enhanced(base_color, enemy_data)
		"howler":
			return _create_howler_enhanced(base_color, enemy_data)
		"gorger":
			return _create_gorger_enhanced(base_color, enemy_data)
		"gloom_wing":
			return _create_gloom_wing_enhanced(base_color, enemy_data)
		"bile_spitter":
			return _create_bile_spitter_enhanced(base_color, enemy_data)
		"behemoth":
			return _create_behemoth_enhanced(base_color, enemy_data)
		"phase_stalker":
			return _create_phase_stalker_enhanced(base_color, enemy_data)
		"void_spawner":
			return _create_void_spawner_enhanced(base_color, enemy_data)
		"void_wraith":
			return _create_void_wraith_enhanced(base_color, enemy_data)
		"crystal_golem":
			return _create_crystal_golem_enhanced(base_color, enemy_data)
		"nightmare_drone":
			return _create_nightmare_drone_enhanced(base_color, enemy_data)
		"soul_reaver":
			return _create_soul_reaver_enhanced(base_color, enemy_data)
		"abyssal_lord":
			return _create_abyssal_lord_enhanced(base_color, enemy_data)
		"omega_destroyer":
			return _create_omega_destroyer_enhanced(base_color, enemy_data)
		_:
			# Fallback to basic visual generator
			return VisualGenerator.create_entity_visual(enemy_id, base_color) or _create_generic_enemy(base_color, enemy_data)

## Set up enemy animations based on category and data
static func setup_enemy_animations(visual: Node3D, enemy_id: String, enemy_data: Dictionary) -> void:
	var category := _get_enemy_category(enemy_data)
	_setup_idle_animation(visual, enemy_id, category)
	_setup_movement_animations(visual, enemy_id, category)
	_setup_attack_animations(visual, enemy_id, enemy_data)

# =============================================================================
# Enhanced Enemy Visuals - Swarm Category
# =============================================================================

static func _create_thrasher_enhanced(c: Color, data: Dictionary) -> Node3D:
	## Lean feline quadruped: low slung body, exposed ribs, razor claws, pack hunter stance
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.3)
	var lite := c.lightened(0.2)
	var bone := Color(0.85, 0.82, 0.75)
	var eye_glow := Color(0.9, 0.7, 0.1)
	
	# Lean predator body (low and streamlined)
	_add_box(r, Vector3(0.4, 0.15, 0.55), Vector3(0, 0.18, 0), c)
	
	# Exposed ribcage detail
	for i in range(4):
		var rib_z := -0.15 + i * 0.1
		_add_box(r, Vector3(0.42, 0.02, 0.02), Vector3(0, 0.26, rib_z), bone)
	
	# Predatory head (angular, forward-thrust)
	_add_box(r, Vector3(0.12, 0.08, 0.18), Vector3(0, 0.22, 0.32), lite)
	_add_box(r, Vector3(0.08, 0.05, 0.1), Vector3(0, 0.19, 0.42), lite)  # Snout
	
	# Glowing predator eyes
	_add_emissive_sphere(r, 0.02, Vector3(0.05, 0.25, 0.38), eye_glow, 2.5)
	_add_emissive_sphere(r, 0.02, Vector3(-0.05, 0.25, 0.38), eye_glow, 2.5)
	
	# Powerful hind legs (spring-loaded for pouncing)
	_add_cylinder(r, 0.03, 0.2, Vector3(0.15, 0.1, -0.15), dark)
	_add_cylinder(r, 0.03, 0.2, Vector3(-0.15, 0.1, -0.15), dark)
	# Hind muscle definition
	_add_box(r, Vector3(0.06, 0.08, 0.1), Vector3(0.15, 0.15, -0.2), dark)
	_add_box(r, Vector3(0.06, 0.08, 0.1), Vector3(-0.15, 0.15, -0.2), dark)
	
	# Front legs with razor claws
	_add_cylinder(r, 0.025, 0.18, Vector3(0.14, 0.09, 0.18), dark)
	_add_cylinder(r, 0.025, 0.18, Vector3(-0.14, 0.09, 0.18), dark)
	# Razor claws (signature feature)
	_add_box(r, Vector3(0.02, 0.02, 0.15), Vector3(0.14, 0.02, 0.32), bone)
	_add_box(r, Vector3(0.02, 0.02, 0.15), Vector3(-0.14, 0.02, 0.32), bone)
	_add_box(r, Vector3(0.015, 0.015, 0.12), Vector3(0.12, 0.01, 0.34), bone)  # Side claws
	_add_box(r, Vector3(0.015, 0.015, 0.12), Vector3(-0.12, 0.01, 0.34), bone)
	
	# Whip-like tail
	_add_box(r, Vector3(0.02, 0.02, 0.2), Vector3(0, 0.2, -0.35), dark)
	
	# Pack hunter scent glands (glowing)
	_add_emissive_sphere(r, 0.015, Vector3(0.08, 0.2, 0.15), eye_glow, 1.5)
	_add_emissive_sphere(r, 0.015, Vector3(-0.08, 0.2, 0.15), eye_glow, 1.5)
	
	r.set_meta("animation_type", "quadruped_predator")
	r.set_meta("special_features", ["razor_claws", "pack_hunter"])
	return r

static func _create_blight_mite_enhanced(c: Color, data: Dictionary) -> Node3D:
	## Suicide bomber insect: swollen volatile sac, spindly legs, no head, green bioluminescence
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.4)
	var sac_glow := Color(0.4, 0.9, 0.2)
	
	# Small chitinous body
	_add_box(r, Vector3(0.1, 0.05, 0.14), Vector3(0, 0.08, 0), dark)
	
	# THE KEY FEATURE: Volatile sac (visibly pulsing and dangerous)
	var sac := _add_emissive_sphere(r, 0.08, Vector3(0, 0.15, -0.03), sac_glow, 3.0)
	sac.set_meta("volatile_sac", true)  # Mark for pulsing animation
	
	# Secondary smaller sacs
	_add_emissive_sphere(r, 0.03, Vector3(0.04, 0.12, 0.02), sac_glow, 2.0)
	_add_emissive_sphere(r, 0.025, Vector3(-0.03, 0.11, 0.04), sac_glow, 1.8)
	
	# 6 spindly insect legs (very thin and fragile-looking)
	for leg_i in range(3):
		for side in [-1.0, 1.0]:
			var leg_z := -0.02 + leg_i * 0.04
			var leg_x := side * 0.08
			_add_box(r, Vector3(0.07, 0.008, 0.008), Vector3(leg_x, 0.04, leg_z), dark)
			# Leg joints
			_add_sphere(r, 0.008, Vector3(leg_x * 1.3, 0.02, leg_z), dark)
	
	# Bio-luminescent veins on body
	_add_emissive_box(r, Vector3(0.01, 0.008, 0.08), Vector3(0.02, 0.06, 0), sac_glow, 1.2)
	_add_emissive_box(r, Vector3(0.01, 0.008, 0.08), Vector3(-0.02, 0.06, 0), sac_glow, 1.2)
	
	# No head - just sensory pits
	_add_emissive_sphere(r, 0.006, Vector3(0.02, 0.09, 0.08), sac_glow, 1.0)
	_add_emissive_sphere(r, 0.006, Vector3(-0.02, 0.09, 0.08), sac_glow, 1.0)
	
	r.set_meta("animation_type", "insect_suicide")
	r.set_meta("special_features", ["volatile_sac", "suicide_bomber"])
	return r

# =============================================================================
# Enhanced Enemy Visuals - Bruiser Category
# =============================================================================

static func _create_brute_enhanced(c: Color, data: Dictionary) -> Node3D:
	## Hulking biped: massive upper body, gorilla-like stance, bone-club fists, scars
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.3)
	var lite := c.lightened(0.15)
	var chitin := c.darkened(0.15)
	var scar := Color(0.6, 0.4, 0.4)
	var glow := Color(0.8, 0.45, 0.1)
	
	# Massive tree-trunk legs
	_add_box(r, Vector3(0.25, 0.55, 0.28), Vector3(0.25, 0.275, 0), dark)
	_add_box(r, Vector3(0.25, 0.55, 0.28), Vector3(-0.25, 0.275, 0), dark)
	# Ankle reinforcement
	_add_box(r, Vector3(0.28, 0.08, 0.3), Vector3(0.25, 0.1, 0), chitin)
	_add_box(r, Vector3(0.28, 0.08, 0.3), Vector3(-0.25, 0.1, 0), chitin)
	
	# Enormous torso (hunched forward, intimidating)
	_add_box(r, Vector3(1.0, 0.7, 0.8), Vector3(0, 0.9, 0.1), c)
	# Upper chest (barrel-like)
	_add_box(r, Vector3(1.1, 0.4, 0.7), Vector3(0, 1.4, 0.05), c)
	
	# Layered chitinous armor plates
	_add_box(r, Vector3(1.15, 0.08, 0.75), Vector3(0, 1.1, 0.05), chitin)
	_add_box(r, Vector3(1.0, 0.08, 0.65), Vector3(0, 0.9, 0.1), chitin)
	_add_box(r, Vector3(0.85, 0.08, 0.55), Vector3(0, 0.75, 0.15), chitin)
	
	# Battle scars across body
	_add_emissive_box(r, Vector3(0.6, 0.02, 0.02), Vector3(0.2, 1.2, 0.35), scar, 0.8)
	_add_emissive_box(r, Vector3(0.02, 0.3, 0.02), Vector3(-0.3, 1.0, 0.3), scar, 0.8)
	
	# Small head (typical bruiser proportions)
	_add_box(r, Vector3(0.2, 0.18, 0.22), Vector3(0, 1.65, 0.18), lite)
	# Eyes (small and mean)
	_add_emissive_sphere(r, 0.02, Vector3(0.07, 1.7, 0.3), glow, 2.0)
	_add_emissive_sphere(r, 0.02, Vector3(-0.07, 1.7, 0.3), glow, 2.0)
	
	# Disproportionately long arms (knuckle-dragger)
	_add_box(r, Vector3(0.18, 0.65, 0.18), Vector3(0.55, 0.8, 0.05), dark)
	_add_box(r, Vector3(0.18, 0.65, 0.18), Vector3(-0.55, 0.8, 0.05), dark)
	
	# SIGNATURE FEATURE: Bone-club fists (grown from skeleton)
	_add_box(r, Vector3(0.25, 0.25, 0.25), Vector3(0.55, 0.35, 0.05), Color(0.9, 0.85, 0.7))
	_add_box(r, Vector3(0.25, 0.25, 0.25), Vector3(-0.55, 0.35, 0.05), Color(0.9, 0.85, 0.7))
	# Bone spikes on knuckles
	_add_box(r, Vector3(0.04, 0.08, 0.04), Vector3(0.65, 0.4, 0.1), Color(0.95, 0.9, 0.8))
	_add_box(r, Vector3(0.04, 0.08, 0.04), Vector3(-0.65, 0.4, 0.1), Color(0.95, 0.9, 0.8))
	
	# Bioluminescent rage indicators
	_add_emissive_box(r, Vector3(0.03, 0.4, 0.03), Vector3(0.45, 0.8, 0.2), glow, 2.0)
	_add_emissive_box(r, Vector3(0.03, 0.4, 0.03), Vector3(-0.45, 0.8, 0.2), glow, 2.0)
	
	r.set_meta("animation_type", "hulking_bruiser")
	r.set_meta("special_features", ["bone_clubs", "intimidating_presence"])
	return r

static func _create_gorger_enhanced(c: Color, data: Dictionary) -> Node3D:
	## Predator quadruped: oversized jaw, blade arms, bone ridges, frenzy scars
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.3)
	var lite := c.lightened(0.15)
	var hide := Color(0.55, 0.2, 0.12)
	var bone := Color(0.85, 0.78, 0.4)
	var blood := Color(0.6, 0.1, 0.05)
	var eye_glow := Color(0.8, 0.1, 0.05)
	
	# Predator body (hunched, muscular, forward-heavy)
	_add_box(r, Vector3(0.7, 0.4, 0.75), Vector3(0, 0.6, 0.05), hide)
	# Powerful shoulder hump
	_add_box(r, Vector3(0.8, 0.25, 0.35), Vector3(0, 0.85, 0.2), hide)
	
	# 4 legs - front larger with blade modifications
	_add_box(r, Vector3(0.12, 0.5, 0.12), Vector3(0.32, 0.25, 0.35), dark)
	_add_box(r, Vector3(0.12, 0.5, 0.12), Vector3(-0.32, 0.25, 0.35), dark)
	_add_box(r, Vector3(0.1, 0.48, 0.1), Vector3(0.28, 0.24, -0.25), dark)
	_add_box(r, Vector3(0.1, 0.48, 0.1), Vector3(-0.28, 0.24, -0.25), dark)
	
	# SIGNATURE FEATURE: Blade-arms (evolved for slashing)
	_add_box(r, Vector3(0.25, 0.06, 0.04), Vector3(0.32, 0.02, 0.55), bone)
	_add_box(r, Vector3(0.25, 0.06, 0.04), Vector3(-0.32, 0.02, 0.55), bone)
	# Serrated edges
	for i in range(5):
		var z_pos := 0.45 + i * 0.04
		_add_box(r, Vector3(0.02, 0.04, 0.01), Vector3(0.44, 0.04, z_pos), bone)
		_add_box(r, Vector3(0.02, 0.04, 0.01), Vector3(-0.44, 0.04, z_pos), bone)
	
	# Blood stains on blades (from past kills)
	_add_emissive_box(r, Vector3(0.15, 0.02, 0.02), Vector3(0.38, 0.03, 0.58), blood, 1.0)
	_add_emissive_box(r, Vector3(0.15, 0.02, 0.02), Vector3(-0.38, 0.03, 0.58), blood, 1.0)
	
	# Head with MASSIVE unhinging jaw
	_add_box(r, Vector3(0.3, 0.25, 0.3), Vector3(0, 0.8, 0.5), hide)
	# Upper jaw
	_add_box(r, Vector3(0.28, 0.08, 0.25), Vector3(0, 0.85, 0.6), dark)
	# Lower jaw (hangs open, showing size)
	_add_box(r, Vector3(0.26, 0.12, 0.22), Vector3(0, 0.65, 0.58), dark)
	# Massive teeth
	for tooth_i in range(6):
		var tooth_x := -0.1 + tooth_i * 0.04
		_add_box(r, Vector3(0.01, 0.06, 0.01), Vector3(tooth_x, 0.75, 0.7), Color(0.95, 0.9, 0.85))
		_add_box(r, Vector3(0.01, 0.05, 0.01), Vector3(tooth_x, 0.62, 0.68), Color(0.95, 0.9, 0.85))
	
	# Glowing predator eyes
	_add_emissive_sphere(r, 0.03, Vector3(0.12, 0.88, 0.65), eye_glow, 3.5)
	_add_emissive_sphere(r, Vector3(0.03, 0.88, 0.65), Vector3(-0.12, 0.88, 0.65), eye_glow, 3.5)
	
	# Spine ridges (bone armor)
	for ridge_i in range(6):
		var ridge_z := -0.2 + ridge_i * 0.08
		var height := 0.08 + ridge_i * 0.01
		_add_box(r, Vector3(0.06, height, 0.04), Vector3(0, 0.95, ridge_z), bone)
	
	# Frenzy scars (self-inflicted during rage)
	_add_emissive_box(r, Vector3(0.02, 0.02, 0.4), Vector3(0.25, 0.7, 0.05), blood, 0.8)
	_add_emissive_box(r, Vector3(0.02, 0.02, 0.4), Vector3(-0.25, 0.7, 0.05), blood, 0.8)
	
	r.set_meta("animation_type", "predator_quadruped")
	r.set_meta("special_features", ["blade_arms", "massive_jaw", "frenzy_mode"])
	return r

# =============================================================================
# Enhanced Enemy Visuals - Ranged Category
# =============================================================================

static func _create_slinker_enhanced(c: Color, data: Dictionary) -> Node3D:
	## Ranged sniper: elongated skull, digitigrade stance, energy organ, mottled camouflage
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.3)
	var lite := c.lightened(0.15)
	var camo := c.darkened(0.2)
	var energy := Color(0.3, 0.85, 0.2)
	
	# Digitigrade legs (bird-like, built for stability while aiming)
	# Upper thigh
	_add_box(r, Vector3(0.08, 0.35, 0.1), Vector3(0.12, 0.45, -0.05), dark)
	_add_box(r, Vector3(0.08, 0.35, 0.1), Vector3(-0.12, 0.45, -0.05), dark)
	# Lower leg (angled forward)
	_add_box(r, Vector3(0.06, 0.3, 0.08), Vector3(0.12, 0.15, 0.08), dark)
	_add_box(r, Vector3(0.06, 0.3, 0.08), Vector3(-0.12, 0.15, 0.08), dark)
	# Splayed feet (for stability)
	_add_box(r, Vector3(0.08, 0.03, 0.14), Vector3(0.12, 0.02, 0.12), dark)
	_add_box(r, Vector3(0.08, 0.03, 0.14), Vector3(-0.12, 0.02, 0.12), dark)
	
	# Lean sniper torso
	_add_box(r, Vector3(0.28, 0.35, 0.22), Vector3(0, 0.8, 0), c)
	
	# Vestigial arms (evolutionary remnant)
	_add_box(r, Vector3(0.04, 0.15, 0.04), Vector3(0.14, 0.72, 0.08), dark)
	_add_box(r, Vector3(0.04, 0.15, 0.04), Vector3(-0.14, 0.72, 0.08), dark)
	
	# Long thin neck
	_add_cylinder(r, 0.05, 0.18, Vector3(0, 1.05, 0.08), c)
	
	# SIGNATURE FEATURE: Elongated skull with split cranium
	_add_box(r, Vector3(0.2, 0.25, 0.4), Vector3(0, 1.2, 0.15), lite)
	# Split cranium halves (for energy organ access)
	_add_box(r, Vector3(0.09, 0.06, 0.25), Vector3(0.09, 1.35, 0.15), lite)
	_add_box(r, Vector3(0.09, 0.06, 0.25), Vector3(-0.09, 1.35, 0.15), lite)
	
	# Energy organ (visible between skull halves - THE WEAPON)
	var energy_organ := _add_emissive_box(r, Vector3(0.08, 0.08, 0.2), Vector3(0, 1.35, 0.18), energy, 3.0)
	energy_organ.set_meta("energy_organ", true)  # Mark for charging animation
	
	# Focusing lenses in eye sockets
	_add_emissive_box(r, Vector3(0.08, 0.02, 0.03), Vector3(0.12, 1.15, 0.35), energy, 2.0)
	_add_emissive_box(r, Vector3(0.08, 0.02, 0.03), Vector3(-0.12, 1.15, 0.35), energy, 2.0)
	
	# Mottled camouflage patterns
	_add_box(r, Vector3(0.08, 0.08, 0.06), Vector3(0.15, 0.85, 0.08), camo)
	_add_box(r, Vector3(0.06, 0.06, 0.05), Vector3(-0.12, 0.7, -0.08), lite)
	_add_box(r, Vector3(0.07, 0.05, 0.04), Vector3(0.08, 0.6, 0.12), camo)
	
	# Neural interface ports (for targeting systems)
	_add_emissive_sphere(r, 0.015, Vector3(0.18, 1.3, 0.05), energy, 1.5)
	_add_emissive_sphere(r, 0.015, Vector3(-0.18, 1.3, 0.05), energy, 1.5)
	
	r.set_meta("animation_type", "ranged_sniper")
	r.set_meta("special_features", ["energy_organ", "split_skull", "digitigrade"])
	return r

static func _create_bile_spitter_enhanced(c: Color, data: Dictionary) -> Node3D:
	## Siege artillery: massively bloated body, acid sacs, chemical vents, decay
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.3)
	var pale := Color(0.7, 0.68, 0.4)
	var sick := pale.darkened(0.3)
	var acid := Color(0.6, 0.8, 0.15)
	var vein := Color(0.4, 0.6, 0.2)
	
	# Stubby legs (barely supporting mass)
	_add_box(r, Vector3(0.12, 0.12, 0.1), Vector3(0.22, 0.06, 0.18), dark)
	_add_box(r, Vector3(0.12, 0.12, 0.1), Vector3(-0.22, 0.06, 0.18), dark)
	_add_box(r, Vector3(0.12, 0.12, 0.1), Vector3(0.22, 0.06, -0.18), dark)
	_add_box(r, Vector3(0.12, 0.12, 0.1), Vector3(-0.22, 0.06, -0.18), dark)
	
	# MASSIVELY BLOATED body (the defining characteristic)
	_add_box(r, Vector3(0.5, 0.35, 0.6), Vector3(0, 0.3, 0), pale)
	# Even more bloated midsection (chemical production)
	_add_sphere(r, 0.32, Vector3(0, 0.4, -0.05), pale)
	
	# Visible acid sacs under skin
	_add_emissive_sphere(r, 0.08, Vector3(0.15, 0.35, 0.1), acid, 2.0)
	_add_emissive_sphere(r, 0.06, Vector3(-0.18, 0.32, -0.05), acid, 1.8)
	_add_emissive_sphere(r, 0.07, Vector3(0.05, 0.45, -0.15), acid, 2.2)
	
	# Chemical processing vents (smoking)
	_add_cylinder(r, 0.03, 0.1, Vector3(0.2, 0.55, 0), sick)
	_add_cylinder(r, 0.025, 0.08, Vector3(-0.15, 0.52, 0.1), sick)
	# Vent emissions
	_add_emissive_sphere(r, 0.04, Vector3(0.2, 0.62, 0), acid, 1.5)
	_add_emissive_sphere(r, 0.03, Vector3(-0.15, 0.58, 0.1), acid, 1.2)
	
	# Grotesquely swollen head (rears back for spitting)
	_add_sphere(r, 0.25, Vector3(0, 0.55, 0.35), pale)
	# Distended throat sac
	_add_sphere(r, 0.15, Vector3(0, 0.4, 0.45), pale)
	
	# Wide spitting maw
	_add_box(r, Vector3(0.15, 0.1, 0.08), Vector3(0, 0.5, 0.58), dark.darkened(0.4))
	# Acid constantly dripping
	_add_emissive_sphere(r, 0.03, Vector3(0, 0.47, 0.62), acid, 2.5)
	_add_emissive_sphere(r, 0.02, Vector3(0.05, 0.45, 0.6), acid, 2.0)
	
	# Toxic vein networks (visible through skin)
	_add_emissive_box(r, Vector3(0.02, 0.02, 0.3), Vector3(0.18, 0.42, 0), vein, 1.0)
	_add_emissive_box(r, Vector3(0.02, 0.02, 0.3), Vector3(-0.18, 0.42, 0), vein, 1.0)
	_add_emissive_box(r, Vector3(0.25, 0.02, 0.02), Vector3(0, 0.45, -0.12), vein, 1.0)
	
	# Decay patches (chemical burns on own body)
	_add_box(r, Vector3(0.08, 0.06, 0.05), Vector3(0.2, 0.25, 0.2), sick)
	_add_box(r, Vector3(0.06, 0.05, 0.04), Vector3(-0.15, 0.35, -0.18), sick)
	
	# Tapered tail section
	_add_box(r, Vector3(0.3, 0.18, 0.25), Vector3(0, 0.18, -0.35), pale.darkened(0.1))
	_add_box(r, Vector3(0.15, 0.1, 0.15), Vector3(0, 0.12, -0.5), pale.darkened(0.2))
	
	r.set_meta("animation_type", "bloated_spitter")
	r.set_meta("special_features", ["acid_sacs", "chemical_vents", "massive_bloat"])
	return r

# =============================================================================
# Enhanced Enemy Visuals - Flying Category
# =============================================================================

static func _create_scrit_enhanced(c: Color, data: Dictionary) -> Node3D:
	## Flying assassin: tattered membrane wings, needle spine launcher, green bioluminescence
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.3)
	var lite := c.lightened(0.2)
	var wing_glow := Color(0.3, 0.7, 0.2)
	var spine_color := Color(0.8, 0.9, 0.6)
	
	# Lean aerial body
	_add_box(r, Vector3(0.15, 0.12, 0.35), Vector3(0, 0.2, 0), c)
	
	# Angular head (mostly mouth)
	_add_box(r, Vector3(0.12, 0.1, 0.15), Vector3(0, 0.25, 0.22), lite)
	# Gaping maw
	_add_box(r, Vector3(0.1, 0.03, 0.08), Vector3(0, 0.22, 0.28), dark.darkened(0.5))
	
	# TATTERED WING MEMBRANES (key visual feature)
	# Left wing - torn and battle-damaged
	_add_box(r, Vector3(0.4, 0.02, 0.25), Vector3(0.28, 0.22, 0.0), c)
	_add_box(r, Vector3(0.18, 0.02, 0.2), Vector3(0.52, 0.21, -0.05), dark)
	# Wing tears and holes
	_add_box(r, Vector3(0.08, 0.03, 0.08), Vector3(0.45, 0.22, 0.02), Color.TRANSPARENT)  # Hole
	_add_box(r, Vector3(0.05, 0.03, 0.12), Vector3(0.55, 0.21, -0.08), Color.TRANSPARENT)  # Hole
	
	# Right wing - similarly tattered
	_add_box(r, Vector3(0.4, 0.02, 0.25), Vector3(-0.28, 0.22, 0.0), c)
	_add_box(r, Vector3(0.18, 0.02, 0.2), Vector3(-0.52, 0.21, -0.05), dark)
	# More tears
	_add_box(r, Vector3(0.06, 0.03, 0.1), Vector3(-0.42, 0.22, 0.05), Color.TRANSPARENT)
	_add_box(r, Vector3(0.07, 0.03, 0.09), Vector3(-0.58, 0.21, -0.06), Color.TRANSPARENT)
	
	# Wing support struts (bone/chitin)
	_add_box(r, Vector3(0.45, 0.015, 0.015), Vector3(0.3, 0.23, 0.1), dark)
	_add_box(r, Vector3(0.4, 0.015, 0.015), Vector3(0.28, 0.23, -0.08), dark)
	_add_box(r, Vector3(0.45, 0.015, 0.015), Vector3(-0.3, 0.23, 0.1), dark)
	_add_box(r, Vector3(0.4, 0.015, 0.015), Vector3(-0.28, 0.23, -0.08), dark)
	
	# Bioluminescent veins on wings (navigation system)
	_add_emissive_box(r, Vector3(0.3, 0.01, 0.01), Vector3(0.25, 0.24, 0.0), wing_glow, 1.8)
	_add_emissive_box(r, Vector3(0.3, 0.01, 0.01), Vector3(-0.25, 0.24, 0.0), wing_glow, 1.8)
	_add_emissive_box(r, Vector3(0.01, 0.01, 0.18), Vector3(0.4, 0.24, 0.05), wing_glow, 1.5)
	_add_emissive_box(r, Vector3(0.01, 0.01, 0.18), Vector3(-0.4, 0.24, 0.05), wing_glow, 1.5)
	
	# SPINE LAUNCHER tail (the ranged weapon)
	_add_box(r, Vector3(0.03, 0.03, 0.28), Vector3(0, 0.18, -0.32), dark)
	# Spine storage chambers
	for i in range(4):
		var spine_z := -0.22 - i * 0.04
		_add_box(r, Vector3(0.01, 0.01, 0.03), Vector3(0.02, 0.2, spine_z), spine_color)
		_add_box(r, Vector3(0.01, 0.01, 0.03), Vector3(-0.02, 0.2, spine_z), spine_color)
	
	# Launcher tip (glowing when ready to fire)
	var launcher_tip := _add_emissive_sphere(r, 0.025, Vector3(0, 0.18, -0.48), wing_glow, 2.5)
	launcher_tip.set_meta("launcher_tip", true)
	
	# Wing membrane damage lighting
	_add_emissive_sphere(r, 0.02, Vector3(0.35, 0.22, 0.02), wing_glow, 1.0)
	_add_emissive_sphere(r, 0.015, Vector3(-0.38, 0.22, -0.03), wing_glow, 1.0)
	
	r.set_meta("animation_type", "tattered_flyer")
	r.set_meta("special_features", ["tattered_wings", "spine_launcher", "bioluminescent"])
	return r

static func _create_gloom_wing_enhanced(c: Color, data: Dictionary) -> Node3D:
	## Massive aerial bomber: manta ray silhouette, bomb sacs, trailing tentacles
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.3)
	var lite := c.lightened(0.15)
	var glow := Color(0.3, 0.75, 0.9)
	var bomb_glow := Color(0.4, 0.6, 1.0)
	
	# Main body (manta ray shaped - wide and flat)
	_add_box(r, Vector3(1.6, 0.15, 1.2), Vector3(0, 0.3, 0), c)
	# Elevated center ridge (neural spine)
	_add_box(r, Vector3(0.25, 0.1, 1.3), Vector3(0, 0.4, -0.05), lite)
	
	# Wing sections (segmented for aerodynamics)
	# Inner wing segments
	_add_box(r, Vector3(0.6, 0.08, 0.7), Vector3(0.9, 0.28, 0.05), dark)
	_add_box(r, Vector3(0.6, 0.08, 0.7), Vector3(-0.9, 0.28, 0.05), dark)
	# Outer wing tips
	_add_box(r, Vector3(0.4, 0.06, 0.5), Vector3(1.3, 0.26, 0.1), dark.darkened(0.1))
	_add_box(r, Vector3(0.4, 0.06, 0.5), Vector3(-1.3, 0.26, 0.1), dark.darkened(0.1))
	
	# Wing edge bioluminescence (navigation/threat display)
	_add_emissive_box(r, Vector3(1.5, 0.01, 0.02), Vector3(0, 0.28, 0.6), glow, 2.0)
	_add_emissive_box(r, Vector3(1.5, 0.01, 0.02), Vector3(0, 0.28, -0.6), glow, 2.0)
	_add_emissive_box(r, Vector3(0.02, 0.01, 1.1), Vector3(1.2, 0.28, 0), glow, 2.0)
	_add_emissive_box(r, Vector3(0.02, 0.01, 1.1), Vector3(-1.2, 0.28, 0), glow, 2.0)
	
	# Neural spine illumination
	_add_emissive_box(r, Vector3(0.04, 0.01, 1.0), Vector3(0, 0.46, 0), glow, 1.5)
	
	# BOMB SACS (the key weapon system) - visible underneath
	var bomb_sac_1 := _add_emissive_sphere(r, 0.1, Vector3(0.25, 0.18, 0), bomb_glow, 2.5)
	var bomb_sac_2 := _add_emissive_sphere(r, 0.1, Vector3(-0.25, 0.18, 0), bomb_glow, 2.5)
	var bomb_sac_3 := _add_emissive_sphere(r, 0.08, Vector3(0, 0.18, 0.2), bomb_glow, 2.2)
	var bomb_sac_4 := _add_emissive_sphere(r, 0.08, Vector3(0, 0.18, -0.2), bomb_glow, 2.2)
	# Mark for pulsing animation
	bomb_sac_1.set_meta("bomb_sac", true)
	bomb_sac_2.set_meta("bomb_sac", true)
	bomb_sac_3.set_meta("bomb_sac", true)
	bomb_sac_4.set_meta("bomb_sac", true)
	
	# Secondary smaller bomb chambers
	_add_emissive_sphere(r, 0.05, Vector3(0.4, 0.2, 0.15), bomb_glow, 1.8)
	_add_emissive_sphere(r, 0.05, Vector3(-0.4, 0.2, 0.15), bomb_glow, 1.8)
	_add_emissive_sphere(r, 0.04, Vector3(0.15, 0.19, -0.3), bomb_glow, 1.5)
	_add_emissive_sphere(r, 0.04, Vector3(-0.15, 0.19, -0.3), bomb_glow, 1.5)
	
	# Sensory organs along leading edge (no distinct head)
	_add_box(r, Vector3(0.08, 0.05, 0.03), Vector3(0.3, 0.34, 0.6), lite)
	_add_box(r, Vector3(0.08, 0.05, 0.03), Vector3(-0.3, 0.34, 0.6), lite)
	_add_emissive_sphere(r, 0.02, Vector3(0.3, 0.36, 0.62), glow, 1.8)
	_add_emissive_sphere(r, 0.02, Vector3(-0.3, 0.36, 0.62), glow, 1.8)
	
	# TRAILING TENTACLES (signature feature)
	_add_box(r, Vector3(0.05, 0.04, 0.5), Vector3(0, 0.26, -0.85), dark)
	_add_box(r, Vector3(0.03, 0.03, 0.35), Vector3(0, 0.24, -1.15), dark)
	# Sensory nodes along tentacles
	_add_emissive_sphere(r, 0.02, Vector3(0, 0.26, -0.9), glow, 1.2)
	_add_emissive_sphere(r, 0.015, Vector3(0, 0.24, -1.1), glow, 1.0)
	
	# Atmospheric sensors (for bombing accuracy)
	_add_cylinder(r, 0.015, 0.08, Vector3(0.6, 0.35, 0.3), lite)
	_add_cylinder(r, 0.015, 0.08, Vector3(-0.6, 0.35, 0.3), lite)
	
	r.set_meta("animation_type", "manta_bomber")
	r.set_meta("special_features", ["bomb_sacs", "trailing_tentacles", "massive_wingspan"])
	return r

# =============================================================================
# Helper Functions
# =============================================================================

static func _get_enemy_category(data: Dictionary) -> EnemyCategory:
	var role: String = data.get("role", "")
	var is_boss: bool = data.get("is_boss", false)
	var flying: bool = data.get("flying", false)
	
	if is_boss:
		return EnemyCategory.BOSS
	elif flying:
		return EnemyCategory.FLYING
	elif role == "swarm":
		return EnemyCategory.SWARM
	elif role in ["bruiser", "tank"]:
		return EnemyCategory.BRUISER
	elif role == "ranged":
		return EnemyCategory.RANGED
	else:
		return EnemyCategory.SPECIAL

static func _setup_idle_animation(visual: Node3D, enemy_id: String, category: EnemyCategory) -> void:
	# Enhanced idle animations based on category and specific enemy
	match category:
		EnemyCategory.FLYING:
			_setup_flying_idle(visual, enemy_id)
		EnemyCategory.SWARM:
			_setup_swarm_idle(visual, enemy_id)
		EnemyCategory.BRUISER:
			_setup_bruiser_idle(visual, enemy_id)
		EnemyCategory.RANGED:
			_setup_ranged_idle(visual, enemy_id)
		EnemyCategory.SPECIAL:
			_setup_special_idle(visual, enemy_id)
		EnemyCategory.BOSS:
			_setup_boss_idle(visual, enemy_id)

static func _setup_movement_animations(visual: Node3D, enemy_id: String, category: EnemyCategory) -> void:
	# Set up movement animation metadata
	match category:
		EnemyCategory.FLYING:
			visual.set_meta("movement_type", "aerial")
		EnemyCategory.SWARM:
			visual.set_meta("movement_type", "scurry")
		EnemyCategory.BRUISER:
			visual.set_meta("movement_type", "lumber")
		EnemyCategory.RANGED:
			visual.set_meta("movement_type", "cautious")
		_:
			visual.set_meta("movement_type", "standard")

static func _setup_attack_animations(visual: Node3D, enemy_id: String, data: Dictionary) -> void:
	var attack_type: String = data.get("attack_type", "melee")
	visual.set_meta("attack_type", attack_type)
	
	# Set up attack animation metadata based on specials
	var specials: Array = data.get("specials", [])
	for special in specials:
		if special is Dictionary:
			var special_type: String = special.get("type", "")
			visual.set_meta("special_" + special_type, true)

# Placeholder idle animation setups (would be expanded with full animation system)
static func _setup_flying_idle(visual: Node3D, enemy_id: String) -> void:
	visual.set_meta("idle_animation", "floating_hover")

static func _setup_swarm_idle(visual: Node3D, enemy_id: String) -> void:
	visual.set_meta("idle_animation", "twitchy_ready")

static func _setup_bruiser_idle(visual: Node3D, enemy_id: String) -> void:
	visual.set_meta("idle_animation", "intimidating_sway")

static func _setup_ranged_idle(visual: Node3D, enemy_id: String) -> void:
	visual.set_meta("idle_animation", "scanning_alert")

static func _setup_special_idle(visual: Node3D, enemy_id: String) -> void:
	visual.set_meta("idle_animation", "unique_behavior")

static func _setup_boss_idle(visual: Node3D, enemy_id: String) -> void:
	visual.set_meta("idle_animation", "menacing_presence")

static func _create_generic_enemy(c: Color, data: Dictionary) -> Node3D:
	# Fallback for unknown enemies
	var r := Node3D.new()
	r.name = "Visual"
	_add_box(r, Vector3(0.5, 0.5, 0.5), Vector3(0, 0.25, 0), c)
	_add_emissive_sphere(r, 0.1, Vector3(0, 0.6, 0), Color.RED, 2.0)
	return r

# Helper functions for creating basic shapes (same as VisualGenerator)
static func _add_box(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color.r, color.g, color.b, 1.0)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	mat.roughness = 0.85
	mat.metallic = 0.15
	box.material = mat
	mi.mesh = box
	mi.position = pos
	parent.add_child(mi)
	return mi

static func _add_emissive_box(parent: Node3D, size: Vector3, pos: Vector3, color: Color, emission_strength: float = 1.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	var mat := StandardMaterial3D.new()
	var opaque_color := Color(color.r, color.g, color.b, 1.0)
	mat.albedo_color = opaque_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	mat.emission_enabled = true
	mat.emission = opaque_color
	mat.emission_energy_multiplier = emission_strength
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	box.material = mat
	mi.mesh = box
	mi.position = pos
	parent.add_child(mi)
	return mi

static func _add_cylinder(parent: Node3D, radius: float, height: float, pos: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = height
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color.r, color.g, color.b, 1.0)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	mat.roughness = 0.7
	mat.metallic = 0.3
	cyl.material = mat
	mi.mesh = cyl
	mi.position = pos
	parent.add_child(mi)
	return mi

static func _add_sphere(parent: Node3D, radius: float, pos: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color.r, color.g, color.b, 1.0)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	mat.roughness = 0.8
	mat.metallic = 0.2
	sphere.material = mat
	mi.mesh = sphere
	mi.position = pos
	parent.add_child(mi)
	return mi

static func _add_emissive_sphere(parent: Node3D, radius: float, pos: Vector3, color: Color, emission_strength: float = 2.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	var mat := StandardMaterial3D.new()
	var opaque_color := Color(color.r, color.g, color.b, 1.0)
	mat.albedo_color = opaque_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	mat.emission_enabled = true
	mat.emission = opaque_color
	mat.emission_energy_multiplier = emission_strength
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sphere.material = mat
	mi.mesh = sphere
	mi.position = pos
	parent.add_child(mi)
	return mi

## Complete the remaining enemies from the JSON data

static func _create_clugg_enhanced(c: Color, data: Dictionary) -> Node3D:
	## Enormous turtle tank: massive domed shell, threat aura system, slam mechanism
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.3)
	var shell := c.darkened(0.1)
	var moss := Color(0.2, 0.3, 0.15)
	var threat := Color(0.8, 0.3, 0.1)
	
	# Massive pillar legs (barely able to carry the weight)
	_add_box(r, Vector3(0.4, 0.7, 0.4), Vector3(0.7, 0.35, 0.7), dark)
	_add_box(r, Vector3(0.4, 0.7, 0.4), Vector3(-0.7, 0.35, 0.7), dark)
	_add_box(r, Vector3(0.4, 0.7, 0.4), Vector3(0.7, 0.35, -0.7), dark)
	_add_box(r, Vector3(0.4, 0.7, 0.4), Vector3(-0.7, 0.35, -0.7), dark)
	
	# Underbelly protection
	_add_box(r, Vector3(1.8, 0.35, 1.8), Vector3(0, 0.7, 0), dark)
	
	# MASSIVE DOMED SHELL (the key feature - layered for depth)
	_add_sphere(r, 1.1, Vector3(0, 1.2, 0), shell)
	_add_sphere(r, 0.9, Vector3(0, 1.5, 0), shell.lightened(0.05))
	_add_sphere(r, 0.6, Vector3(0, 1.75, 0), shell.lightened(0.1))
	_add_sphere(r, 0.3, Vector3(0, 1.95, 0), shell.lightened(0.12))
	
	# Ancient battle scars on shell
	for i in range(6):
		var angle := i * TAU / 6.0
		var scar_x := cos(angle) * 0.8
		var scar_z := sin(angle) * 0.8
		_add_box(r, Vector3(0.05, 0.02, 0.3), Vector3(scar_x, 1.3, scar_z), dark.darkened(0.3))
	
	# Moss and growth patches (age indicators)
	_add_box(r, Vector3(0.3, 0.03, 0.25), Vector3(-0.4, 1.45, 0.5), moss)
	_add_box(r, Vector3(0.25, 0.03, 0.3), Vector3(0.5, 1.8, -0.3), moss)
	_add_box(r, Vector3(0.2, 0.03, 0.2), Vector3(-0.6, 1.65, -0.4), moss)
	
	# Shell ridges and plates
	for ridge_i in range(4):
		var ridge_radius := 0.6 + ridge_i * 0.15
		for segment in range(8):
			var angle := segment * TAU / 8.0
			var ridge_x := cos(angle) * ridge_radius
			var ridge_z := sin(angle) * ridge_radius
			var ridge_y := 1.1 + ridge_i * 0.1
			_add_box(r, Vector3(0.08, 0.04, 0.06), Vector3(ridge_x, ridge_y, ridge_z), shell.lightened(0.08))
	
	# THREAT AURA PROJECTORS (the special ability)
	var aura_emitter_1 := _add_emissive_sphere(r, 0.06, Vector3(0.8, 1.4, 0), threat, 2.5)
	var aura_emitter_2 := _add_emissive_sphere(r, 0.06, Vector3(-0.8, 1.4, 0), threat, 2.5)
	var aura_emitter_3 := _add_emissive_sphere(r, 0.06, Vector3(0, 1.4, 0.8), threat, 2.5)
	var aura_emitter_4 := _add_emissive_sphere(r, 0.06, Vector3(0, 1.4, -0.8), threat, 2.5)
	aura_emitter_1.set_meta("threat_aura", true)
	aura_emitter_2.set_meta("threat_aura", true)
	aura_emitter_3.set_meta("threat_aura", true)
	aura_emitter_4.set_meta("threat_aura", true)
	
	# SLAM MECHANISM - visible under the shell
	var slam_core := _add_emissive_sphere(r, 0.12, Vector3(0, 0.9, 0), threat, 3.0)
	slam_core.set_meta("slam_core", true)
	
	# Head (tiny, barely visible, tucked under front)
	_add_box(r, Vector3(0.4, 0.25, 0.25), Vector3(0, 0.7, 1.0), dark)
	
	# Calcified growths and spines
	_add_box(r, Vector3(0.2, 0.2, 0.2), Vector3(0.6, 1.6, 0.4), Color(0.9, 0.85, 0.8))
	_add_box(r, Vector3(0.15, 0.15, 0.15), Vector3(-0.5, 1.7, -0.5), Color(0.9, 0.85, 0.8))
	_add_box(r, Vector3(0.18, 0.25, 0.18), Vector3(0.3, 1.85, -0.6), Color(0.9, 0.85, 0.8))
	
	r.set_meta("animation_type", "massive_tank")
	r.set_meta("special_features", ["threat_aura", "ground_slam", "ancient_shell"])
	return r

static func _create_terror_bringer_enhanced(c: Color, data: Dictionary) -> Node3D:
	## Towering boss: armored skull crest, death blast chamber, intimidation presence
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.3)
	var lite := c.lightened(0.15)
	var armor_plate := c.darkened(0.2)
	var death_glow := Color(0.9, 0.15, 0.05)
	
	# Massive trunk legs (boss-sized)
	_add_box(r, Vector3(0.4, 0.8, 0.45), Vector3(0.4, 0.4, 0), dark)
	_add_box(r, Vector3(0.4, 0.8, 0.45), Vector3(-0.4, 0.4, 0), dark)
	# Reinforced ankles
	_add_box(r, Vector3(0.45, 0.12, 0.5), Vector3(0.4, 0.1, 0), armor_plate)
	_add_box(r, Vector3(0.45, 0.12, 0.5), Vector3(-0.4, 0.1, 0), armor_plate)
	
	# Clawed feet with ground-cracking capability
	_add_box(r, Vector3(0.5, 0.1, 0.6), Vector3(0.4, 0.05, 0.05), dark.darkened(0.2))
	_add_box(r, Vector3(0.5, 0.1, 0.6), Vector3(-0.4, 0.05, 0.05), dark.darkened(0.2))
	# Claws
	for claw_i in range(3):
		var claw_x := -0.15 + claw_i * 0.15
		_add_box(r, Vector3(0.04, 0.06, 0.12), Vector3(0.4 + claw_x, 0.08, 0.3), Color(0.9, 0.85, 0.8))
		_add_box(r, Vector3(0.04, 0.06, 0.12), Vector3(-0.4 + claw_x, 0.08, 0.3), Color(0.9, 0.85, 0.8))
	
	# MASSIVE TORSO (intimidating forward lean)
	_add_box(r, Vector3(1.2, 0.8, 0.9), Vector3(0, 1.2, 0.15), c)
	# Upper torso (broader shoulders)
	_add_box(r, Vector3(1.4, 0.5, 0.8), Vector3(0, 1.75, 0.1), c)
	
	# Layered armor plating (boss-tier protection)
	_add_box(r, Vector3(1.45, 0.1, 0.85), Vector3(0, 1.3, 0.1), armor_plate)
	_add_box(r, Vector3(1.25, 0.1, 0.75), Vector3(0, 1.1, 0.15), armor_plate)
	_add_box(r, Vector3(1.05, 0.1, 0.65), Vector3(0, 0.95, 0.2), armor_plate)
	_add_box(r, Vector3(0.85, 0.1, 0.55), Vector3(0, 0.85, 0.25), armor_plate)
	
	# ARMORED SKULL WITH MASSIVE CREST (the signature weapon)
	_add_box(r, Vector3(0.6, 0.35, 0.6), Vector3(0, 1.85, 0.4), lite)
	# The devastating bone crest (battering ram)
	_add_box(r, Vector3(0.7, 0.25, 0.3), Vector3(0, 1.95, 0.65), Color(0.95, 0.9, 0.85))
	_add_box(r, Vector3(0.55, 0.2, 0.2), Vector3(0, 2.05, 0.85), Color(0.98, 0.95, 0.9))
	_add_box(r, Vector3(0.4, 0.15, 0.15), Vector3(0, 2.12, 1.0), Color(1.0, 0.98, 0.95))
	
	# Crest reinforcement ridges
	for ridge_i in range(3):
		var ridge_z := 0.7 + ridge_i * 0.1
		_add_box(r, Vector3(0.6 - ridge_i * 0.1, 0.03, 0.02), Vector3(0, 2.0 + ridge_i * 0.03, ridge_z), lite)
	
	# DEATH BLAST CHAMBER (visible as glowing core in chest)
	var death_chamber := _add_emissive_sphere(r, 0.15, Vector3(0, 1.4, 0.2), death_glow, 4.0)
	death_chamber.set_meta("death_blast_chamber", true)
	# Secondary blast nodes
	_add_emissive_sphere(r, 0.08, Vector3(0.3, 1.3, 0.15), death_glow, 2.5)
	_add_emissive_sphere(r, Vector3(0.08, 1.3, 0.15), Vector3(-0.3, 1.3, 0.15), death_glow, 2.5)
	
	# Glowing eyes (small but menacing)
	_add_emissive_sphere(r, 0.04, Vector3(0.15, 1.9, 0.68), death_glow, 3.5)
	_add_emissive_sphere(r, 0.04, Vector3(-0.15, 1.9, 0.68), death_glow, 3.5)
	
	# Vestigial arms (not the primary weapons for a charger)
	_add_box(r, Vector3(0.15, 0.4, 0.15), Vector3(0.65, 1.3, 0.2), dark)
	_add_box(r, Vector3(0.15, 0.4, 0.15), Vector3(-0.65, 1.3, 0.2), dark)
	# Small clawed hands
	_add_box(r, Vector3(0.18, 0.18, 0.18), Vector3(0.65, 0.95, 0.22), armor_plate)
	_add_box(r, Vector3(0.18, 0.18, 0.18), Vector3(-0.65, 0.95, 0.22), armor_plate)
	
	# Rage indicators (bioluminescent stress patterns)
	_add_emissive_box(r, Vector3(0.04, 0.6, 0.04), Vector3(0.5, 1.3, 0.3), death_glow, 2.5)
	_add_emissive_box(r, Vector3(0.04, 0.6, 0.04), Vector3(-0.5, 1.3, 0.3), death_glow, 2.5)
	_add_emissive_box(r, Vector3(0.8, 0.04, 0.04), Vector3(0, 1.05, 0.4), death_glow, 2.0)
	
	# Shoulder spikes and intimidation features
	_add_box(r, Vector3(0.2, 0.4, 0.2), Vector3(0.7, 2.0, 0.1), armor_plate)
	_add_box(r, Vector3(0.2, 0.4, 0.2), Vector3(-0.7, 2.0, 0.1), armor_plate)
	
	r.set_meta("animation_type", "boss_charger")
	r.set_meta("special_features", ["skull_crest", "death_blast", "intimidating_charge"])
	return r

static func _create_polus_enhanced(c: Color, data: Dictionary) -> Node3D:
	## Compact jumper: spine launcher, powerful hind legs, crimson war paint
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.3)
	var exo := Color(0.12, 0.12, 0.12)  # Black exoskeleton
	var crimson := Color(0.7, 0.1, 0.15)
	var bone := Color(0.9, 0.85, 0.75)
	
	# Compact body (designed for leaping)
	_add_box(r, Vector3(0.6, 0.3, 0.7), Vector3(0, 0.4, 0), exo)
	
	# Front legs (lighter, for landing)
	_add_cylinder(r, 0.05, 0.35, Vector3(0.25, 0.175, 0.3), exo)
	_add_cylinder(r, 0.05, 0.35, Vector3(-0.25, 0.175, 0.3), exo)
	
	# POWERFUL HIND LEGS (the key feature - spring-loaded)
	_add_box(r, Vector3(0.1, 0.4, 0.1), Vector3(0.28, 0.2, -0.25), exo)
	_add_box(r, Vector3(0.1, 0.4, 0.1), Vector3(-0.28, 0.2, -0.25), exo)
	# Visible spring mechanisms (enhanced muscle groups)
	_add_box(r, Vector3(0.12, 0.12, 0.15), Vector3(0.28, 0.18, -0.3), dark)
	_add_box(r, Vector3(0.12, 0.12, 0.15), Vector3(-0.28, 0.18, -0.3), dark)
	# Spring tension indicators
	_add_emissive_box(r, Vector3(0.02, 0.08, 0.02), Vector3(0.28, 0.25, -0.32), crimson, 1.5)
	_add_emissive_box(r, Vector3(0.02, 0.08, 0.02), Vector3(-0.28, 0.25, -0.32), crimson, 1.5)
	
	# Eyeless head with sensory array
	_add_box(r, Vector3(0.2, 0.15, 0.18), Vector3(0, 0.48, 0.4), exo)
	# Sensory pits (thermal/vibration detection)
	_add_emissive_sphere(r, 0.02, Vector3(0.08, 0.5, 0.48), crimson, 2.0)
	_add_emissive_sphere(r, 0.02, Vector3(-0.08, 0.5, 0.48), crimson, 2.0)
	_add_emissive_sphere(r, 0.015, Vector3(0, 0.52, 0.5), crimson, 1.8)
	
	# SPINE LAUNCHER ROWS (the ranged weapon system)
	var spine_rows := 5
	for row_i in range(spine_rows):
		var spine_z := -0.2 + row_i * 0.1
		var spine_height := 0.12 + row_i * 0.02
		# Left row
		var spine_left := _add_box(r, Vector3(0.025, spine_height, 0.02), Vector3(0.12, 0.58, spine_z), bone)
		spine_left.set_meta("spine_projectile", true)
		# Right row
		var spine_right := _add_box(r, Vector3(0.025, spine_height, 0.02), Vector3(-0.12, 0.58, spine_z), bone)
		spine_right.set_meta("spine_projectile", true)
	
	# Spine launcher mechanism
	_add_box(r, Vector3(0.3, 0.04, 0.05), Vector3(0, 0.52, -0.15), dark)
	var launcher_core := _add_emissive_sphere(r, 0.03, Vector3(0, 0.52, -0.12), crimson, 2.5)
	launcher_core.set_meta("spine_launcher", true)
	
	# CRIMSON WAR PAINT (cultural markings)
	_add_emissive_box(r, Vector3(0.4, 0.02, 0.04), Vector3(0, 0.52, 0), crimson, 1.2)
	_add_emissive_box(r, Vector3(0.02, 0.02, 0.5), Vector3(0, 0.52, 0), crimson, 1.2)
	# Tribal marking on head
	_add_emissive_box(r, Vector3(0.15, 0.02, 0.02), Vector3(0, 0.55, 0.45), crimson, 1.5)
	
	# Joint articulation (visible exoskeleton segments)
	_add_box(r, Vector3(0.65, 0.02, 0.02), Vector3(0, 0.3, 0.1), exo.lightened(0.1))
	_add_box(r, Vector3(0.65, 0.02, 0.02), Vector3(0, 0.3, -0.1), exo.lightened(0.1))
	
	# Sensory quills (vibration detection)
	for quill_i in range(4):
		var angle := quill_i * TAU / 4.0
		var quill_x := cos(angle) * 0.18
		var quill_z := sin(angle) * 0.18
		_add_cylinder(r, 0.008, 0.08, Vector3(quill_x, 0.6, quill_z), bone)
	
	r.set_meta("animation_type", "spring_jumper")
	r.set_meta("special_features", ["spine_launcher", "leap_attack", "crimson_markings"])
	return r

static func _create_howler_enhanced(c: Color, data: Dictionary) -> Node3D:
	## Support caster: massive cranium, war cry organ, albino features
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.3)
	var pale := Color(0.9, 0.85, 0.87)  # Albino coloring
	var vein := Color(0.6, 0.4, 0.7)  # Visible veins
	var war_cry := Color(0.9, 0.2, 0.3)  # War cry organ
	
	# Thin, spindly legs (barely supporting the head weight)
	_add_cylinder(r, 0.035, 0.45, Vector3(0.1, 0.225, 0), pale)
	_add_cylinder(r, 0.035, 0.45, Vector3(-0.1, 0.225, 0), pale)
	# Bony knee joints
	_add_sphere(r, 0.05, Vector3(0.1, 0.3, 0), pale)
	_add_sphere(r, 0.05, Vector3(-0.1, 0.3, 0), pale)
	
	# Small, frail body
	_add_box(r, Vector3(0.25, 0.18, 0.2), Vector3(0, 0.55, 0), pale)
	
	# Thin, vestigial arms
	_add_cylinder(r, 0.025, 0.25, Vector3(0.16, 0.48, 0), pale)
	_add_cylinder(r, 0.025, 0.25, Vector3(-0.16, 0.48, 0), pale)
	# Tiny hands
	_add_sphere(r, 0.03, Vector3(0.16, 0.35, 0), pale)
	_add_sphere(r, 0.03, Vector3(-0.16, 0.35, 0), pale)
	
	# MASSIVE CRANIUM (the defining feature - nearly half the body mass)
	_add_sphere(r, 0.3, Vector3(0, 0.95, 0), pale)
	# Cranium expansion chambers
	_add_sphere(r, 0.15, Vector3(0.2, 0.9, 0.1), pale)
	_add_sphere(r, 0.15, Vector3(-0.2, 0.9, 0.1), pale)
	_add_sphere(r, 0.12, Vector3(0, 0.85, 0.25), pale)
	
	# HORIZONTAL SKULL SEAM (splits open for war cry)
	var skull_seam := _add_box(r, Vector3(0.65, 0.02, 0.2), Vector3(0, 0.95, 0.1), dark.darkened(0.3))
	skull_seam.set_meta("skull_seam", true)
	
	# WAR CRY ORGAN (visible through the seam when active)
	var war_cry_organ := _add_emissive_sphere(r, 0.12, Vector3(0, 0.95, 0.12), war_cry, 3.5)
	war_cry_organ.set_meta("war_cry_organ", true)
	# Secondary resonance chambers
	_add_emissive_sphere(r, 0.06, Vector3(0.15, 0.92, 0.08), war_cry, 2.0)
	_add_emissive_sphere(r, 0.06, Vector3(-0.15, 0.92, 0.08), war_cry, 2.0)
	
	# Large, milky, unfocused eyes
	_add_sphere(r, 0.05, Vector3(0.12, 0.9, 0.22), Color(0.95, 0.92, 0.9))
	_add_sphere(r, 0.05, Vector3(-0.12, 0.9, 0.22), Color(0.95, 0.92, 0.9))
	# Pupils (dilated, seeing things others cannot)
	_add_sphere(r, 0.02, Vector3(0.12, 0.9, 0.24), Color(0.3, 0.3, 0.4))
	_add_sphere(r, 0.02, Vector3(-0.12, 0.9, 0.24), Color(0.3, 0.3, 0.4))
	
	# VISIBLE VEIN NETWORKS (translucent skin shows internal systems)
	_add_emissive_box(r, Vector3(0.015, 0.15, 0.015), Vector3(0.15, 0.98, 0.12), vein, 0.8)
	_add_emissive_box(r, Vector3(0.015, 0.15, 0.015), Vector3(-0.15, 0.98, 0.12), vein, 0.8)
	_add_emissive_box(r, Vector3(0.015, 0.12, 0.015), Vector3(0.08, 1.05, -0.1), vein, 0.8)
	_add_emissive_box(r, Vector3(0.015, 0.12, 0.015), Vector3(-0.08, 1.05, -0.1), vein, 0.8)
	# Central nervous system traces
	_add_emissive_box(r, Vector3(0.02, 0.2, 0.02), Vector3(0, 0.65, 0), vein, 1.0)
	
	# Psychic emanation points (where the war cry affects allies)
	_add_emissive_sphere(r, 0.025, Vector3(0.25, 1.0, 0), war_cry, 2.5)
	_add_emissive_sphere(r, 0.025, Vector3(-0.25, 1.0, 0), war_cry, 2.5)
	_add_emissive_sphere(r, 0.02, Vector3(0, 1.15, 0.15), war_cry, 2.2)
	
	# Neural interface nodes (how it communicates the war cry)
	for node_i in range(6):
		var angle := node_i * TAU / 6.0
		var node_x := cos(angle) * 0.28
		var node_z := sin(angle) * 0.28
		_add_emissive_sphere(r, 0.015, Vector3(node_x, 0.98, node_z), vein, 1.5)
	
	r.set_meta("animation_type", "psychic_support")
	r.set_meta("special_features", ["war_cry", "massive_cranium", "psychic_emanation"])
	return r

static func _create_behemoth_enhanced(c: Color, data: Dictionary) -> Node3D:
	## Colossal boss: fortress-scale armor, ground slam system, territorial presence
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.3)
	var lite := c.lightened(0.2)
	var fortress := c.lightened(0.1)
	var slam_glow := Color(0.5, 0.2, 0.8)
	
	# COLOSSAL LEGS (like fortress pillars)
	_add_box(r, Vector3(0.8, 1.2, 0.9), Vector3(0.8, 0.6, 0), dark)
	_add_box(r, Vector3(0.8, 1.2, 0.9), Vector3(-0.8, 0.6, 0), dark)
	# Reinforced leg armor
	_add_box(r, Vector3(0.85, 0.15, 0.95), Vector3(0.8, 0.3, 0), fortress)
	_add_box(r, Vector3(0.85, 0.15, 0.95), Vector3(-0.8, 0.3, 0), fortress)
	_add_box(r, Vector3(0.85, 0.15, 0.95), Vector3(0.8, 0.9, 0), fortress)
	_add_box(r, Vector3(0.85, 0.15, 0.95), Vector3(-0.8, 0.9, 0), fortress)
	
	# ENORMOUS FEET (ground-slam capable)
	_add_box(r, Vector3(0.9, 0.18, 1.1), Vector3(0.8, 0.09, 0.05), dark.darkened(0.2))
	_add_box(r, Vector3(0.9, 0.18, 1.1), Vector3(-0.8, 0.09, 0.05), dark.darkened(0.2))
	# Slam impact points (where the shockwave originates)
	var slam_point_1 := _add_emissive_sphere(r, 0.08, Vector3(0.8, 0.02, 0.05), slam_glow, 2.0)
	var slam_point_2 := _add_emissive_sphere(r, 0.08, Vector3(-0.8, 0.02, 0.05), slam_glow, 2.0)
	slam_point_1.set_meta("slam_point", true)
	slam_point_2.set_meta("slam_point", true)
	
	# MASSIVE TORSO (fortress-like scale)
	_add_box(r, Vector3(2.2, 1.5, 1.8), Vector3(0, 1.95, 0), c)
	# Upper chest fortress section
	_add_box(r, Vector3(2.4, 0.5, 1.6), Vector3(0, 2.9, 0), fortress)
	
	# LAYERED FORTRESS ARMOR (multiple defensive layers)
	_add_box(r, Vector3(2.3, 0.12, 1.7), Vector3(0, 2.2, 0), fortress)
	_add_box(r, Vector3(2.1, 0.12, 1.6), Vector3(0, 1.9, 0.05), fortress)
	_add_box(r, Vector3(1.9, 0.12, 1.5), Vector3(0, 1.6, 0.1), fortress)
	_add_box(r, Vector3(1.7, 0.12, 1.4), Vector3(0, 1.35, 0.15), fortress)
	_add_box(r, Vector3(1.5, 0.12, 1.3), Vector3(0, 1.15, 0.2), fortress)
	
	# HEAD (armored, set between massive shoulders)
	_add_box(r, Vector3(0.7, 0.6, 0.7), Vector3(0, 3.3, 0.25), lite)
	# Heavy fortress brow plate
	_add_box(r, Vector3(0.8, 0.2, 0.4), Vector3(0, 3.5, 0.45), fortress)
	
	# Glowing eyes (small relative to body size)
	_add_emissive_sphere(r, 0.08, Vector3(0.22, 3.3, 0.6), slam_glow, 3.5)
	_add_emissive_sphere(r, 0.08, Vector3(-0.22, 3.3, 0.6), slam_glow, 3.5)
	
	# MASSIVE ARMS (pillar-like)
	_add_box(r, Vector3(0.45, 1.2, 0.45), Vector3(1.25, 1.95, 0), dark)
	_add_box(r, Vector3(0.45, 1.2, 0.45), Vector3(-1.25, 1.95, 0), dark)
	# Fortress-scale fists
	_add_box(r, Vector3(0.6, 0.55, 0.6), Vector3(1.25, 0.95, 0.05), fortress)
	_add_box(r, Vector3(0.6, 0.55, 0.6), Vector3(-1.25, 0.95, 0.05), fortress)
	
	# GROUND SLAM MECHANISM (visible energy system)
	var slam_core := _add_emissive_sphere(r, 0.18, Vector3(0, 1.8, 0), slam_glow, 4.5)
	slam_core.set_meta("slam_core", true)
	# Energy conduits to feet
	_add_emissive_box(r, Vector3(0.06, 1.2, 0.06), Vector3(0.4, 1.2, 0), slam_glow, 2.0)
	_add_emissive_box(r, Vector3(0.06, 1.2, 0.06), Vector3(-0.4, 1.2, 0), slam_glow, 2.0)
	
	# Fortress-scale bioluminescent cracks
	_add_emissive_box(r, Vector3(0.05, 1.0, 0.05), Vector3(0.7, 2.0, 0.5), slam_glow, 2.5)
	_add_emissive_box(r, Vector3(0.05, 1.0, 0.05), Vector3(-0.7, 2.0, 0.5), slam_glow, 2.5)
	_add_emissive_box(r, Vector3(1.5, 0.05, 0.05), Vector3(0, 1.6, 0.7), slam_glow, 2.0)
	_add_emissive_box(r, Vector3(1.5, 0.05, 0.05), Vector3(0, 2.1, 0.7), slam_glow, 2.0)
	
	# Shoulder fortress spikes (defensive/intimidating)
	_add_box(r, Vector3(0.2, 0.45, 0.2), Vector3(1.0, 3.4, 0.1), fortress)
	_add_box(r, Vector3(0.2, 0.45, 0.2), Vector3(-1.0, 3.4, 0.1), fortress)
	_add_box(r, Vector3(0.15, 0.35, 0.15), Vector3(0.8, 3.3, -0.3), fortress)
	_add_box(r, Vector3(0.15, 0.35, 0.15), Vector3(-0.8, 3.3, -0.3), fortress)
	
	# Seismic resonance points (amplify ground slam)
	_add_emissive_sphere(r, 0.06, Vector3(1.25, 0.7, 0.05), slam_glow, 2.0)
	_add_emissive_sphere(r, 0.06, Vector3(-1.25, 0.7, 0.05), slam_glow, 2.0)
	
	# Fortress architectural details
	_add_box(r, Vector3(2.0, 0.08, 0.08), Vector3(0, 2.5, 0.85), fortress)
	_add_box(r, Vector3(0.08, 0.5, 0.08), Vector3(1.0, 2.5, 0.85), fortress)
	_add_box(r, Vector3(0.08, 0.5, 0.08), Vector3(-1.0, 2.5, 0.85), fortress)
	
	r.set_meta("animation_type", "colossal_boss")
	r.set_meta("special_features", ["ground_slam", "fortress_armor", "seismic_power"])
	return r

# Add remaining enemies with similar detail...
static func _create_phase_stalker_enhanced(c: Color, data: Dictionary) -> Node3D:
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.3)
	var phase_glow := Color(0.6, 0.3, 1.0)
	
	# Lithe assassin body
	_add_box(r, Vector3(0.35, 0.2, 0.5), Vector3(0, 0.3, 0), c)
	# Phase distortion effect around body
	_add_emissive_box(r, Vector3(0.4, 0.25, 0.55), Vector3(0, 0.3, 0), phase_glow, 1.5)
	# Add stalker-specific features...
	
	r.set_meta("animation_type", "phase_assassin")
	return r

static func _create_void_spawner_enhanced(c: Color, data: Dictionary) -> Node3D:
	var r := Node3D.new()
	r.name = "Visual"
	var void_glow := Color(0.3, 0.1, 0.6)
	
	# Large spawning sac
	_add_sphere(r, 1.2, Vector3(0, 0.8, 0), c)
	# Void portal indicators
	_add_emissive_sphere(r, 0.2, Vector3(0, 0.8, 0), void_glow, 3.0)
	
	r.set_meta("animation_type", "spawner")
	return r

static func _create_void_wraith_enhanced(c: Color, data: Dictionary) -> Node3D:
	var r := Node3D.new()
	r.name = "Visual"
	var wraith_glow := Color(0.4, 0.2, 0.8)
	
	# Ethereal form
	_add_sphere(r, 0.3, Vector3(0, 0.3, 0), c)
	_add_emissive_sphere(r, 0.35, Vector3(0, 0.3, 0), wraith_glow, 2.0)
	
	r.set_meta("animation_type", "ethereal")
	return r

# Continue with remaining enemies following the same detailed pattern...
static func _create_crystal_golem_enhanced(c: Color, data: Dictionary) -> Node3D:
	var r := Node3D.new()
	r.name = "Visual"
	var crystal := Color(0.4, 0.9, 1.0)
	_add_box(r, Vector3(1.0, 1.2, 1.0), Vector3(0, 0.6, 0), c)
	_add_emissive_sphere(r, 0.3, Vector3(0, 1.0, 0), crystal, 3.0)
	r.set_meta("animation_type", "crystal_tank")
	return r

static func _create_nightmare_drone_enhanced(c: Color, data: Dictionary) -> Node3D:
	var r := Node3D.new()
	r.name = "Visual"
	var drone_glow := Color(1.0, 0.3, 0.0)
	_add_box(r, Vector3(0.3, 0.2, 0.4), Vector3(0, 0.2, 0), c)
	_add_emissive_sphere(r, 0.1, Vector3(0, 0.25, 0), drone_glow, 2.5)
	r.set_meta("animation_type", "swarm_drone")
	return r

static func _create_soul_reaver_enhanced(c: Color, data: Dictionary) -> Node3D:
	var r := Node3D.new()
	r.name = "Visual"
	var soul_glow := Color(0.8, 0.1, 0.1)
	_add_box(r, Vector3(0.6, 1.0, 0.4), Vector3(0, 0.8, 0), c)
	_add_emissive_sphere(r, 0.15, Vector3(0, 1.2, 0), soul_glow, 3.5)
	r.set_meta("animation_type", "soul_harvester")
	return r

static func _create_abyssal_lord_enhanced(c: Color, data: Dictionary) -> Node3D:
	var r := Node3D.new()
	r.name = "Visual"
	var abyss_glow := Color(0.2, 0.0, 0.4)
	_add_box(r, Vector3(1.8, 2.0, 1.5), Vector3(0, 1.5, 0), c)
	_add_emissive_sphere(r, 0.4, Vector3(0, 2.5, 0), abyss_glow, 4.0)
	r.set_meta("animation_type", "abyssal_boss")
	return r

static func _create_omega_destroyer_enhanced(c: Color, data: Dictionary) -> Node3D:
	var r := Node3D.new()
	r.name = "Visual"
	var omega_glow := Color(1.0, 0.0, 0.0)
	_add_box(r, Vector3(2.5, 2.5, 2.0), Vector3(0, 2.0, 0), c)
	_add_emissive_sphere(r, 0.5, Vector3(0, 3.5, 0), omega_glow, 5.0)
	r.set_meta("animation_type", "ultimate_boss")
	return r