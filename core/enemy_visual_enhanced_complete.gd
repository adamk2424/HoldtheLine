class_name EnemyVisualEnhancedComplete
extends Node
## Complete enemy visual system with detailed models matching enemy data
## Provides highly detailed enemy models with animations and special effects

# --- Visual Categories ---
enum EnemyClass {
	SWARM_LIGHT,        # Small fast enemies - minimal detail for performance
	SWARM_HEAVY,        # Small enemies with more visual features
	BRUISER,            # Medium tanky enemies with armor detail
	SPECIALIST,         # Special ability enemies with unique visuals
	ELITE,              # High-value targets with detailed models
	BOSS,               # Major bosses with full detail and animations
	FLYING,             # Aerial units with wing/hover systems
	SIEGE              # Large siege units with complex models
}

# --- Animation States ---
enum AnimationState {
	IDLE,
	MOVING,
	ATTACKING,
	DAMAGED,
	SPECIAL_ABILITY,
	DEATH
}

# --- Effect Intensity Based on Enemy Value ---
static func _get_effect_intensity(enemy_data: Dictionary) -> float:
	var hp: float = enemy_data.get("hp", 100.0)
	var is_boss: bool = enemy_data.get("is_boss", false)
	
	if is_boss:
		return 2.0  # High intensity for bosses
	elif hp > 1000:
		return 1.5  # Elite enemies
	elif hp > 300:
		return 1.2  # Heavy enemies
	else:
		return 0.8  # Standard enemies

## Create enhanced enemy visual with full detail matching JSON data
static func create_complete_enemy_visual(enemy_id: String, enemy_data: Dictionary) -> Node3D:
	var base_color := Color.html(enemy_data.get("mesh_color", "#FFFFFF"))
	var enemy_class := _classify_enemy(enemy_data)
	var effect_intensity := _get_effect_intensity(enemy_data)
	
	match enemy_id:
		# --- Swarm Units ---
		"thrasher":
			return _create_thrasher_complete(base_color, enemy_data, effect_intensity)
		"blight_mite":
			return _create_blight_mite_complete(base_color, enemy_data, effect_intensity)
		"polus":
			return _create_polus_complete(base_color, enemy_data, effect_intensity)
			
		# --- Bruiser Units ---
		"brute":
			return _create_brute_complete(base_color, enemy_data, effect_intensity)
		"gorger":
			return _create_gorger_complete(base_color, enemy_data, effect_intensity)
			
		# --- Specialists ---
		"slinker":
			return _create_slinker_complete(base_color, enemy_data, effect_intensity)
		"howler":
			return _create_howler_complete(base_color, enemy_data, effect_intensity)
		"bile_spitter":
			return _create_bile_spitter_complete(base_color, enemy_data, effect_intensity)
			
		# --- Flying Units ---
		"scrit":
			return _create_scrit_complete(base_color, enemy_data, effect_intensity)
		"gloom_wing":
			return _create_gloom_wing_complete(base_color, enemy_data, effect_intensity)
		"nightmare_drone":
			return _create_nightmare_drone_complete(base_color, enemy_data, effect_intensity)
			
		# --- Siege Units ---
		"clugg":
			return _create_clugg_complete(base_color, enemy_data, effect_intensity)
		"crystal_golem":
			return _create_crystal_golem_complete(base_color, enemy_data, effect_intensity)
			
		# --- Elite Units ---
		"phase_stalker":
			return _create_phase_stalker_complete(base_color, enemy_data, effect_intensity)
		"void_spawner":
			return _create_void_spawner_complete(base_color, enemy_data, effect_intensity)
		"soul_reaver":
			return _create_soul_reaver_complete(base_color, enemy_data, effect_intensity)
			
		# --- Boss Units ---
		"terror_bringer":
			return _create_terror_bringer_complete(base_color, enemy_data, effect_intensity)
		"behemoth":
			return _create_behemoth_complete(base_color, enemy_data, effect_intensity)
		"abyssal_lord":
			return _create_abyssal_lord_complete(base_color, enemy_data, effect_intensity)
		"omega_destroyer":
			return _create_omega_destroyer_complete(base_color, enemy_data, effect_intensity)
			
		# --- Minions ---
		"void_wraith":
			return _create_void_wraith_complete(base_color, enemy_data, effect_intensity)
		_:
			return _create_generic_enemy_complete(enemy_id, base_color, enemy_data, effect_intensity)

# =============================================================================
# Enhanced Swarm Units
# =============================================================================

static func _create_thrasher_complete(c: Color, data: Dictionary, intensity: float) -> Node3D:
	## Lean feline predator with pack hunter features and razor claws
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.3)
	var lite := c.lightened(0.2)
	var bone := Color(0.9, 0.85, 0.75)
	var blood := Color(0.6, 0.1, 0.1)
	var eye_glow := Color(0.9, 0.7, 0.1)
	
	# Lean predator body with muscle definition
	_add_box(r, Vector3(0.4, 0.15, 0.55), Vector3(0, 0.18, 0), c)
	
	# Exposed ribcage (shows undernourishment and savagery)
	for i in range(5):
		var rib_z := -0.18 + i * 0.09
		var rib_size := 0.02 + (abs(i - 2) * -0.005)  # Larger in middle
		_add_box(r, Vector3(rib_size, 0.08, 0.015), Vector3(0.18, 0.22, rib_z), bone)
		_add_box(r, Vector3(rib_size, 0.08, 0.015), Vector3(-0.18, 0.22, rib_z), bone)
	
	# Elongated skull with pronounced jaw
	_add_box(r, Vector3(0.16, 0.12, 0.22), Vector3(0, 0.22, 0.35), lite)
	_add_box(r, Vector3(0.14, 0.06, 0.1), Vector3(0, 0.18, 0.45), lite)  # Snout
	
	# Predatory eyes with hunt-focus glow
	_add_emissive_sphere(r, 0.025, Vector3(0.06, 0.24, 0.42), eye_glow, 2.5 * intensity)
	_add_emissive_sphere(r, 0.025, Vector3(-0.06, 0.24, 0.42), eye_glow, 2.5 * intensity)
	
	# Open jaw showing fangs
	_add_box(r, Vector3(0.12, 0.03, 0.08), Vector3(0, 0.16, 0.48), dark)  # Open mouth
	# Individual fangs
	_add_box(r, Vector3(0.015, 0.025, 0.015), Vector3(0.03, 0.155, 0.52), bone)
	_add_box(r, Vector3(0.015, 0.025, 0.015), Vector3(-0.03, 0.155, 0.52), bone)
	_add_box(r, Vector3(0.012, 0.02, 0.012), Vector3(0.05, 0.16, 0.51), bone)
	_add_box(r, Vector3(0.012, 0.02, 0.012), Vector3(-0.05, 0.16, 0.51), bone)
	
	# Powerful front legs with extended razor claws
	_add_cylinder(r, 0.03, 0.22, Vector3(0.16, 0.11, 0.18), dark)
	_add_cylinder(r, 0.03, 0.22, Vector3(-0.16, 0.11, 0.18), dark)
	
	# Extended curved claws (signature weapon)
	_add_box(r, Vector3(0.02, 0.02, 0.15), Vector3(0.16, 0.02, 0.32), bone)
	_add_box(r, Vector3(0.02, 0.02, 0.15), Vector3(-0.16, 0.02, 0.32), bone)
	# Additional claw details
	_add_box(r, Vector3(0.015, 0.015, 0.12), Vector3(0.18, 0.025, 0.3), bone)
	_add_box(r, Vector3(0.015, 0.015, 0.12), Vector3(-0.18, 0.025, 0.3), bone)
	
	# Hind legs (for pouncing power)
	_add_cylinder(r, 0.035, 0.24, Vector3(0.15, 0.12, -0.18), dark)
	_add_cylinder(r, 0.035, 0.24, Vector3(-0.15, 0.12, -0.18), dark)
	
	# Spine ridges with bone protrusions
	for i in range(4):
		var spine_z := -0.1 + i * 0.08
		var spine_height := 0.05 + abs(i - 1.5) * 0.01
		_add_box(r, Vector3(0.04, spine_height, 0.02), Vector3(0, 0.28, spine_z), bone)
	
	# Whip-like tail with barbs
	_add_box(r, Vector3(0.025, 0.025, 0.2), Vector3(0, 0.22, -0.37), dark)
	# Tail barbs
	_add_box(r, Vector3(0.01, 0.01, 0.03), Vector3(0.02, 0.23, -0.42), bone)
	_add_box(r, Vector3(0.01, 0.01, 0.03), Vector3(-0.02, 0.23, -0.42), bone)
	_add_box(r, Vector3(0.008, 0.008, 0.025), Vector3(0, 0.24, -0.46), bone)
	
	# Battle scars and blood stains (shows veteran status)
	_add_box(r, Vector3(0.02, 0.01, 0.04), Vector3(0.12, 0.19, 0.1), blood)
	_add_box(r, Vector3(0.015, 0.008, 0.03), Vector3(-0.08, 0.16, -0.05), blood)
	
	# Pack hunting communication organ (throat sac that can glow)
	_add_emissive_sphere(r, 0.02, Vector3(0, 0.16, 0.25), eye_glow.darkened(0.3), 1.0 * intensity)
	
	# Set animation metadata
	_setup_animation_nodes(r, "thrasher", data)
	
	return r

static func _create_blight_mite_complete(c: Color, data: Dictionary, intensity: float) -> Node3D:
	## Tiny living bomb with swollen volatile sac and nervous system exposure
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.4)
	var sac_glow := Color(0.5, 0.9, 0.2)
	var nerve := Color(0.3, 0.8, 0.3)
	var warning := Color(1.0, 0.8, 0.0)
	
	# Small insectoid body
	_add_box(r, Vector3(0.12, 0.06, 0.16), Vector3(0, 0.08, 0), dark)
	
	# MASSIVE volatile sac (defining feature - ready to explode)
	var sac_size := 0.09 * intensity
	_add_emissive_sphere(r, sac_size, Vector3(0, 0.17, -0.03), sac_glow, 3.0 * intensity)
	
	# Pulsing effect on the sac (shows instability)
	var sac_pulse := MeshInstance3D.new()
	sac_pulse.name = "SacPulse"
	var pulse_sphere := SphereMesh.new()
	pulse_sphere.radius = sac_size * 1.2
	pulse_sphere.height = sac_size * 2.4
	var pulse_mat := StandardMaterial3D.new()
	pulse_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pulse_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pulse_mat.albedo_color = Color(0.7, 1.0, 0.3, 0.2)
	pulse_mat.emission_enabled = true
	pulse_mat.emission = sac_glow.lightened(0.2)
	pulse_mat.emission_energy_multiplier = 1.5 * intensity
	pulse_sphere.material = pulse_mat
	sac_pulse.mesh = pulse_sphere
	sac_pulse.position = Vector3(0, 0.17, -0.03)
	r.add_child(sac_pulse)
	
	# 6 spindly legs with joints visible
	for side in [-1.0, 1.0]:
		for leg_i in range(3):
			var leg_z := -0.04 + leg_i * 0.04
			# Upper leg segment
			_add_box(r, Vector3(0.06, 0.012, 0.012), Vector3(side * 0.09, 0.08, leg_z), dark)
			# Lower leg segment (angled)
			_add_box(r, Vector3(0.05, 0.01, 0.01), Vector3(side * 0.13, 0.04, leg_z), dark)
			# Joint
			_add_sphere(r, 0.008, Vector3(side * 0.11, 0.06, leg_z), dark.darkened(0.2))
			# Claw tip
			_add_box(r, Vector3(0.008, 0.008, 0.02), Vector3(side * 0.155, 0.035, leg_z + 0.01), dark.darkened(0.3))
	
	# Exposed nervous system (shows bio-weapon nature)
	_add_emissive_box(r, Vector3(0.02, 0.01, 0.12), Vector3(0.03, 0.06, 0), nerve, 1.5 * intensity)
	_add_emissive_box(r, Vector3(0.02, 0.01, 0.12), Vector3(-0.03, 0.06, 0), nerve, 1.5 * intensity)
	# Neural connections to sac
	_add_emissive_box(r, Vector3(0.015, 0.01, 0.04), Vector3(0.02, 0.12, -0.03), nerve, 1.0 * intensity)
	_add_emissive_box(r, Vector3(0.015, 0.01, 0.04), Vector3(-0.02, 0.12, -0.03), nerve, 1.0 * intensity)
	
	# Simple sensory nubs (no real eyes)
	_add_box(r, Vector3(0.03, 0.015, 0.015), Vector3(0, 0.09, 0.08), dark)
	
	# Warning coloration patches (natural danger signals)
	_add_box(r, Vector3(0.025, 0.008, 0.025), Vector3(0.06, 0.085, 0.04), warning)
	_add_box(r, Vector3(0.025, 0.008, 0.025), Vector3(-0.06, 0.085, 0.04), warning)
	
	# Detonation trigger spines (if touched, explodes)
	_add_box(r, Vector3(0.008, 0.02, 0.008), Vector3(0.05, 0.19, -0.08), Color(1.0, 0.3, 0.3))
	_add_box(r, Vector3(0.008, 0.02, 0.008), Vector3(-0.05, 0.19, -0.08), Color(1.0, 0.3, 0.3))
	_add_box(r, Vector3(0.008, 0.02, 0.008), Vector3(0, 0.22, -0.05), Color(1.0, 0.3, 0.3))
	
	# Chemical leak marks (shows volatile nature)
	_add_emissive_sphere(r, 0.015, Vector3(0.04, 0.05, -0.04), sac_glow.darkened(0.2), 0.8)
	_add_emissive_sphere(r, 0.012, Vector3(-0.03, 0.04, 0.02), sac_glow.darkened(0.2), 0.8)
	
	# Set animation metadata for jittery movement and explosion buildup
	_setup_animation_nodes(r, "blight_mite", data)
	r.set_meta("explosion_warning_time", 2.0)  # Time before detonation
	r.set_meta("explosion_radius", 2.0)
	r.set_meta("explosion_damage", 80)
	
	return r

# =============================================================================
# Enhanced Specialist Units  
# =============================================================================

static func _create_slinker_complete(c: Color, data: Dictionary, intensity: float) -> Node3D:
	## Tall hunched sniper with split skull energy cannon and digitigrade stance
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.3)
	var lite := c.lightened(0.15)
	var skin := c.darkened(0.1)
	var energy := Color(0.3, 0.9, 0.2)
	var targeting := Color(0.8, 0.2, 0.2)
	
	# Digitigrade stance legs (backward-jointed for sniper stability)
	# Upper leg (thigh)
	_add_box(r, Vector3(0.07, 0.35, 0.09), Vector3(0.12, 0.5, -0.05), dark)
	_add_box(r, Vector3(0.07, 0.35, 0.09), Vector3(-0.12, 0.5, -0.05), dark)
	
	# Knee joints (prominent, arthropod-like)
	_add_sphere(r, 0.05, Vector3(0.12, 0.32, -0.05), dark.darkened(0.2))
	_add_sphere(r, 0.05, Vector3(-0.12, 0.32, -0.05), dark.darkened(0.2))
	
	# Lower leg (angled forward for balance)
	_add_box(r, Vector3(0.06, 0.3, 0.07), Vector3(0.12, 0.16, 0.08), dark)
	_add_box(r, Vector3(0.06, 0.3, 0.07), Vector3(-0.12, 0.16, 0.08), dark)
	
	# Large splayed feet (for shooting stability)
	_add_box(r, Vector3(0.08, 0.04, 0.14), Vector3(0.12, 0.02, 0.12), dark.darkened(0.1))
	_add_box(r, Vector3(0.08, 0.04, 0.14), Vector3(-0.12, 0.02, 0.12), dark.darkened(0.1))
	
	# Hunched sniper torso (lean forward for shooting position)
	_add_box(r, Vector3(0.28, 0.32, 0.22), Vector3(0, 0.8, 0.08), skin)
	
	# Vestigial arms (minimal - weapon is built-in)
	_add_box(r, Vector3(0.05, 0.14, 0.05), Vector3(0.15, 0.72, 0.12), dark)
	_add_box(r, Vector3(0.05, 0.14, 0.05), Vector3(-0.15, 0.72, 0.12), dark)
	# Tiny manipulator hands
	_add_box(r, Vector3(0.03, 0.03, 0.06), Vector3(0.15, 0.65, 0.18), dark.darkened(0.1))
	_add_box(r, Vector3(0.03, 0.03, 0.06), Vector3(-0.15, 0.65, 0.18), dark.darkened(0.1))
	
	# Forward-angled neck (targeting posture)
	_add_cylinder(r, 0.045, 0.18, Vector3(0, 1.05, 0.12), skin)
	
	# ELONGATED SNIPER SKULL (the key feature)
	_add_box(r, Vector3(0.2, 0.22, 0.35), Vector3(0, 1.18, 0.2), lite)
	
	# Split cranium mechanism (opens to reveal energy cannon)
	var split_left := MeshInstance3D.new()
	split_left.name = "SkullLeft"
	var left_box := BoxMesh.new()
	left_box.size = Vector3(0.09, 0.06, 0.25)
	var left_mat := StandardMaterial3D.new()
	left_mat.albedo_color = lite
	left_mat.roughness = 0.8
	left_box.material = left_mat
	split_left.mesh = left_box
	split_left.position = Vector3(0.09, 1.24, 0.22)
	r.add_child(split_left)
	
	var split_right := MeshInstance3D.new()
	split_right.name = "SkullRight"
	var right_box := BoxMesh.new()
	right_box.size = Vector3(0.09, 0.06, 0.25)
	var right_mat := StandardMaterial3D.new()
	right_mat.albedo_color = lite
	right_mat.roughness = 0.8
	right_box.material = right_mat
	split_right.mesh = right_box
	split_right.position = Vector3(-0.09, 1.24, 0.22)
	r.add_child(split_right)
	
	# Energy cannon organ (visible between skull halves)
	var energy_cannon := MeshInstance3D.new()
	energy_cannon.name = "EnergyCannon"
	var cannon_cylinder := CylinderMesh.new()
	cannon_cylinder.top_radius = 0.04
	cannon_cylinder.bottom_radius = 0.06
	cannon_cylinder.height = 0.18
	var cannon_mat := StandardMaterial3D.new()
	cannon_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cannon_mat.albedo_color = energy
	cannon_mat.emission_enabled = true
	cannon_mat.emission = energy
	cannon_mat.emission_energy_multiplier = 2.5 * intensity
	cannon_cylinder.material = cannon_mat
	energy_cannon.mesh = cannon_cylinder
	energy_cannon.position = Vector3(0, 1.24, 0.25)
	energy_cannon.rotation_degrees = Vector3(0, 0, 90)
	r.add_child(energy_cannon)
	
	# Energy buildup rings around cannon
	for i in range(3):
		var ring_offset := -0.05 + i * 0.05
		_add_emissive_box(r, Vector3(0.12, 0.12, 0.02), Vector3(0, 1.24, 0.25 + ring_offset), energy, 1.5 * intensity)
	
	# Targeting sensor eyes (narrow slits, laser-focused)
	_add_emissive_box(r, Vector3(0.08, 0.02, 0.025), Vector3(0.08, 1.15, 0.37), targeting, 2.0 * intensity)
	_add_emissive_box(r, Vector3(0.08, 0.02, 0.025), Vector3(-0.08, 1.15, 0.37), targeting, 2.0 * intensity)
	
	# Targeting laser emitters
	_add_emissive_sphere(r, 0.015, Vector3(0.06, 1.15, 0.38), targeting, 3.0 * intensity)
	_add_emissive_sphere(r, 0.015, Vector3(-0.06, 1.15, 0.38), targeting, 3.0 * intensity)
	
	# Mottled camouflage skin patterns (sniper adaptation)
	_add_box(r, Vector3(0.06, 0.08, 0.05), Vector3(0.12, 0.85, 0.12), lite.darkened(0.2))
	_add_box(r, Vector3(0.05, 0.06, 0.04), Vector3(-0.10, 0.78, 0.10), lite.darkened(0.2))
	_add_box(r, Vector3(0.04, 0.05, 0.04), Vector3(0.08, 0.68, 0.06), lite.darkened(0.3))
	
	# Bio-luminescent nerve clusters (shows energy flow to weapon)
	_add_emissive_box(r, Vector3(0.015, 0.08, 0.02), Vector3(0.04, 0.95, 0.15), energy.darkened(0.3), 1.0 * intensity)
	_add_emissive_box(r, Vector3(0.015, 0.08, 0.02), Vector3(-0.04, 0.95, 0.15), energy.darkened(0.3), 1.0 * intensity)
	
	# Stabilizing spurs/claws for shooting stance
	_add_box(r, Vector3(0.012, 0.012, 0.04), Vector3(0.15, 0.01, 0.18), Color(0.7, 0.7, 0.75))
	_add_box(r, Vector3(0.012, 0.012, 0.04), Vector3(-0.15, 0.01, 0.18), Color(0.7, 0.7, 0.75))
	
	# Set animation metadata for aiming and firing sequences
	_setup_animation_nodes(r, "slinker", data)
	r.set_meta("skull_split_left", split_left.get_path())
	r.set_meta("skull_split_right", split_right.get_path())
	r.set_meta("energy_cannon", energy_cannon.get_path())
	r.set_meta("charge_time", 1.5)
	r.set_meta("targeting_range", 18.0)
	
	return r

# =============================================================================
# Enhanced Flying Units
# =============================================================================

static func _create_gloom_wing_complete(c: Color, data: Dictionary, intensity: float) -> Node3D:
	## Massive manta ray bomber with bio-luminescent bomb sacs and trailing tentacles
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.3)
	var lite := c.lightened(0.15)
	var membrane := c.darkened(0.1)
	var bio_glow := Color(0.3, 0.8, 0.9)
	var bomb_glow := Color(0.4, 0.6, 1.0)
	var nerve_glow := Color(0.2, 0.9, 0.8)
	
	# Main body (central diamond/manta shape)
	_add_box(r, Vector3(1.6, 0.15, 1.2), Vector3(0, 0.3, 0), c)
	
	# Elevated central ridge (spine/nervous system housing)
	_add_box(r, Vector3(0.25, 0.12, 1.3), Vector3(0, 0.42, -0.05), lite)
	
	# Wing membranes (primary flight surfaces)
	# Main wing sections
	_add_box(r, Vector3(0.8, 0.08, 0.7), Vector3(1.0, 0.28, 0.05), membrane)
	_add_box(r, Vector3(0.8, 0.08, 0.7), Vector3(-1.0, 0.28, 0.05), membrane)
	
	# Wing tip extensions (for maneuverability)
	_add_box(r, Vector3(0.4, 0.06, 0.5), Vector3(1.6, 0.26, 0.1), membrane.darkened(0.1))
	_add_box(r, Vector3(0.4, 0.06, 0.5), Vector3(-1.6, 0.26, 0.1), membrane.darkened(0.1))
	
	# Wing membrane support structure (cartilage ribs)
	for rib_i in range(5):
		var rib_x := 0.3 + rib_i * 0.35
		# Right wing ribs
		_add_box(r, Vector3(0.02, 0.02, 0.6), Vector3(rib_x, 0.31, 0.05), lite.darkened(0.2))
		# Left wing ribs  
		_add_box(r, Vector3(0.02, 0.02, 0.6), Vector3(-rib_x, 0.31, 0.05), lite.darkened(0.2))
	
	# Bio-luminescent wing edge veins (navigation and threat display)
	_add_emissive_box(r, Vector3(1.5, 0.015, 0.025), Vector3(0.8, 0.29, 0.7), bio_glow, 1.5 * intensity)
	_add_emissive_box(r, Vector3(1.5, 0.015, 0.025), Vector3(-0.8, 0.29, 0.7), bio_glow, 1.5 * intensity)
	_add_emissive_box(r, Vector3(1.5, 0.015, 0.025), Vector3(0.8, 0.29, -0.6), bio_glow, 1.5 * intensity)
	_add_emissive_box(r, Vector3(1.5, 0.015, 0.025), Vector3(-0.8, 0.29, -0.6), bio_glow, 1.5 * intensity)
	
	# Central nervous system glow (shows intelligence)
	_add_emissive_box(r, Vector3(0.04, 0.02, 0.9), Vector3(0, 0.43, 0), nerve_glow, 2.0 * intensity)
	
	# Bomb sacs (the primary weapon system - pulsing with explosive bio-chemicals)
	var bomb_positions := [
		Vector3(0.3, 0.22, 0.1),
		Vector3(-0.3, 0.22, 0.1),
		Vector3(0.15, 0.22, 0.25),
		Vector3(-0.15, 0.22, 0.25),
		Vector3(0, 0.22, 0.35),
		Vector3(0, 0.22, -0.1)
	]
	
	for i in range(bomb_positions.size()):
		var pos := bomb_positions[i]
		var sac_size := 0.1 + randf_range(-0.02, 0.02)  # Slightly varied sizes
		
		var bomb_sac := MeshInstance3D.new()
		bomb_sac.name = "BombSac_" + str(i)
		var sac_sphere := SphereMesh.new()
		sac_sphere.radius = sac_size
		sac_sphere.height = sac_size * 2.0
		
		var sac_mat := StandardMaterial3D.new()
		sac_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sac_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sac_mat.albedo_color = Color(bomb_glow.r, bomb_glow.g, bomb_glow.b, 0.8)
		sac_mat.emission_enabled = true
		sac_mat.emission = bomb_glow
		sac_mat.emission_energy_multiplier = 2.0 * intensity
		
		sac_sphere.material = sac_mat
		bomb_sac.mesh = sac_sphere
		bomb_sac.position = pos
		r.add_child(bomb_sac)
		
		# Pulsing animation for each sac
		var pulse_tween := r.create_tween()
		pulse_tween.set_loops()
		var delay := i * 0.3  # Stagger the pulsing
		pulse_tween.tween_delay(delay)
		pulse_tween.tween_property(bomb_sac, "scale", Vector3(1.2, 1.2, 1.2), 0.8)
		pulse_tween.tween_property(bomb_sac, "scale", Vector3(0.9, 0.9, 0.9), 0.8)
	
	# Sensory organs (no distinct head - distributed along leading edge)
	for sensor_i in range(4):
		var sensor_x := -0.3 + sensor_i * 0.2
		_add_box(r, Vector3(0.08, 0.05, 0.03), Vector3(sensor_x, 0.34, 0.6), lite.lightened(0.1))
		# Sensor glow
		_add_emissive_sphere(r, 0.02, Vector3(sensor_x, 0.36, 0.63), bio_glow, 1.2 * intensity)
	
	# Trailing tentacle tail (for steering and defense)
	var tentacle_segments := 8
	for seg_i in range(tentacle_segments):
		var seg_z := -0.65 - seg_i * 0.08
		var seg_thickness := 0.06 - seg_i * 0.005  # Tapers toward end
		_add_box(r, Vector3(seg_thickness, seg_thickness, 0.07), Vector3(0, 0.28, seg_z), dark)
		
		# Trailing tentacle bio-luminescence
		if seg_i % 2 == 0:
			_add_emissive_sphere(r, seg_thickness * 0.8, Vector3(0, 0.28, seg_z), bio_glow.darkened(0.3), 0.8 * intensity)
	
	# Tentacle tip (sensor/manipulator)
	_add_sphere(r, 0.04, Vector3(0, 0.28, -1.3), lite.lightened(0.2))
	_add_emissive_sphere(r, 0.03, Vector3(0, 0.28, -1.3), bio_glow, 1.5 * intensity)
	
	# Wing flutter simulation points (for animation)
	var flutter_points := []
	for wing_side in [-1, 1]:
		for flutter_i in range(3):
			var flutter_x := wing_side * (0.8 + flutter_i * 0.3)
			var flutter_z := -0.2 + flutter_i * 0.2
			flutter_points.append(Vector3(flutter_x, 0.28, flutter_z))
	
	# Bio-electric discharge points (defensive capability)
	_add_emissive_sphere(r, 0.03, Vector3(1.8, 0.26, 0.1), bio_glow.lightened(0.3), 1.8 * intensity)
	_add_emissive_sphere(r, 0.03, Vector3(-1.8, 0.26, 0.1), bio_glow.lightened(0.3), 1.8 * intensity)
	
	# Set animation metadata
	_setup_animation_nodes(r, "gloom_wing", data)
	r.set_meta("bomb_sac_count", bomb_positions.size())
	r.set_meta("flutter_points", flutter_points)
	r.set_meta("tentacle_segments", tentacle_segments)
	r.set_meta("bombing_run_altitude", 3.0)
	
	return r

# =============================================================================
# Enhanced Boss Units
# =============================================================================

static func _create_behemoth_complete(c: Color, data: Dictionary, intensity: float) -> Node3D:
	## Colossal walking fortress with ground-slam capability and intimidating presence
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.3)
	var armor := c.lightened(0.1)
	var metal := Color(0.4, 0.4, 0.5)
	var glow := Color(0.5, 0.2, 0.8)
	var eye_glow := Color(0.8, 0.1, 0.9)
	
	# MASSIVE pillar legs (mountain-like stability)
	_add_box(r, Vector3(0.8, 1.2, 0.9), Vector3(0.8, 0.6, 0), dark)
	_add_box(r, Vector3(0.8, 1.2, 0.9), Vector3(-0.8, 0.6, 0), dark)
	
	# Leg armor plating (overlapping scales)
	for plate_i in range(4):
		var plate_y := 0.2 + plate_i * 0.25
		_add_box(r, Vector3(0.85, 0.12, 0.95), Vector3(0.8, plate_y, 0), armor)
		_add_box(r, Vector3(0.85, 0.12, 0.95), Vector3(-0.8, plate_y, 0), armor)
	
	# Enormous feet with ground-slam mechanisms
	_add_box(r, Vector3(1.0, 0.2, 1.2), Vector3(0.8, 0.1, 0.05), dark.darkened(0.2))
	_add_box(r, Vector3(1.0, 0.2, 1.2), Vector3(-0.8, 0.1, 0.05), dark.darkened(0.2))
	
	# Foot slam pistons (visible shock absorbers)
	_add_cylinder(r, 0.08, 0.25, Vector3(0.8, 0.35, 0.3), metal)
	_add_cylinder(r, 0.08, 0.25, Vector3(0.8, 0.35, -0.3), metal)
	_add_cylinder(r, 0.08, 0.25, Vector3(-0.8, 0.35, 0.3), metal)
	_add_cylinder(r, 0.08, 0.25, Vector3(-0.8, 0.35, -0.3), metal)
	
	# MASSIVE torso (fortress-like)
	_add_box(r, Vector3(2.2, 1.5, 1.8), Vector3(0, 2.0, 0), c)
	
	# Fortress battlements on shoulders
	_add_box(r, Vector3(2.4, 0.5, 1.6), Vector3(0, 2.95, 0), armor)
	# Crenellations
	for crene_i in range(6):
		var crene_x := -1.0 + crene_i * 0.4
		_add_box(r, Vector3(0.15, 0.2, 0.15), Vector3(crene_x, 3.25, 0.72), armor.lightened(0.1))
		_add_box(r, Vector3(0.15, 0.2, 0.15), Vector3(crene_x, 3.25, -0.72), armor.lightened(0.1))
	
	# Layered armor plating across body (overlapping defensive scales)
	for armor_row in range(5):
		var armor_y := 1.4 + armor_row * 0.28
		var armor_width := 2.3 - armor_row * 0.05  # Tapers slightly upward
		_add_box(r, Vector3(armor_width, 0.12, 1.7), Vector3(0, armor_y, 0), armor)
		
		# Armor rivets/bolts
		for rivet_x in [-0.8, 0.0, 0.8]:
			_add_cylinder(r, 0.02, 0.03, Vector3(rivet_x, armor_y + 0.07, 0.8), metal.darkened(0.2))
			_add_cylinder(r, 0.02, 0.03, Vector3(rivet_x, armor_y + 0.07, -0.8), metal.darkened(0.2))
	
	# Head (small relative to body, set between massive shoulders)
	_add_box(r, Vector3(0.7, 0.6, 0.7), Vector3(0, 3.15, 0.35), armor)
	
	# Heavy brow plate (intimidating scowl)
	_add_box(r, Vector3(0.8, 0.18, 0.4), Vector3(0, 3.35, 0.55), armor.lightened(0.1))
	
	# Glowing eyes (malevolent intelligence)
	_add_emissive_sphere(r, 0.08, Vector3(0.2, 3.15, 0.7), eye_glow, 3.5 * intensity)
	_add_emissive_sphere(r, 0.08, Vector3(-0.2, 3.15, 0.7), eye_glow, 3.5 * intensity)
	
	# MASSIVE arms (disproportionately large for ground-slam attacks)
	_add_box(r, Vector3(0.45, 1.2, 0.45), Vector3(1.4, 2.0, 0.1), dark)
	_add_box(r, Vector3(0.45, 1.2, 0.45), Vector3(-1.4, 2.0, 0.1), dark)
	
	# Ground-slam fists (enormous, weapon-like)
	_add_box(r, Vector3(0.7, 0.6, 0.7), Vector3(1.4, 1.0, 0.15), armor)
	_add_box(r, Vector3(0.7, 0.6, 0.7), Vector3(-1.4, 1.0, 0.15), armor)
	
	# Fist spikes for devastating impacts
	_add_box(r, Vector3(0.08, 0.15, 0.08), Vector3(1.55, 1.15, 0.3), metal.lightened(0.2))
	_add_box(r, Vector3(0.08, 0.15, 0.08), Vector3(1.25, 1.15, 0.3), metal.lightened(0.2))
	_add_box(r, Vector3(0.08, 0.15, 0.08), Vector3(-1.55, 1.15, 0.3), metal.lightened(0.2))
	_add_box(r, Vector3(0.08, 0.15, 0.08), Vector3(-1.25, 1.15, 0.3), metal.lightened(0.2))
	
	# Bio-luminescent power veins (shows enormous energy)
	_add_emissive_box(r, Vector3(0.06, 1.0, 0.06), Vector3(0.7, 2.0, 0.6), glow, 2.0 * intensity)
	_add_emissive_box(r, Vector3(0.06, 1.0, 0.06), Vector3(-0.7, 2.0, 0.6), glow, 2.0 * intensity)
	_add_emissive_box(r, Vector3(1.5, 0.06, 0.06), Vector3(0, 1.8, 0.9), glow, 1.5 * intensity)
	_add_emissive_box(r, Vector3(1.5, 0.06, 0.06), Vector3(0, 2.2, 0.9), glow, 1.5 * intensity)
	
	# Shoulder spikes (intimidation and defense)
	_add_box(r, Vector3(0.2, 0.45, 0.2), Vector3(1.1, 3.2, 0.1), armor.lightened(0.2))
	_add_box(r, Vector3(0.2, 0.45, 0.2), Vector3(-1.1, 3.2, 0.1), armor.lightened(0.2))
	_add_box(r, Vector3(0.15, 0.35, 0.15), Vector3(0.8, 3.1, -0.3), armor.lightened(0.2))
	_add_box(r, Vector3(0.15, 0.35, 0.15), Vector3(-0.8, 3.1, -0.3), armor.lightened(0.2))
	
	# Ground impact glow on fists (shows slam capability)
	_add_emissive_sphere(r, 0.15, Vector3(1.4, 0.8, 0.15), glow.lightened(0.3), 2.0 * intensity)
	_add_emissive_sphere(r, 0.15, Vector3(-1.4, 0.8, 0.15), glow.lightened(0.3), 2.0 * intensity)
	
	# Boss status indicator (crown-like protrusions)
	_add_box(r, Vector3(0.12, 0.25, 0.12), Vector3(0, 3.6, 0), armor.lightened(0.3))
	_add_box(r, Vector3(0.08, 0.18, 0.08), Vector3(0.15, 3.55, 0.15), armor.lightened(0.3))
	_add_box(r, Vector3(0.08, 0.18, 0.08), Vector3(-0.15, 3.55, -0.15), armor.lightened(0.3))
	_add_emissive_sphere(r, 0.06, Vector3(0, 3.75, 0), eye_glow, 3.0 * intensity)
	
	# Set animation metadata for ground slam and intimidation
	_setup_animation_nodes(r, "behemoth", data)
	r.set_meta("ground_slam_range", 6.0)
	r.set_meta("ground_slam_damage", 80)
	r.set_meta("intimidation_radius", 8.0)
	r.set_meta("boss_tier", 2)  # Mid-tier boss
	
	return r

# =============================================================================
# Utility Functions
# =============================================================================

static func _classify_enemy(enemy_data: Dictionary) -> EnemyClass:
	var hp: float = enemy_data.get("hp", 100.0)
	var is_boss: bool = enemy_data.get("is_boss", false)
	var flying: bool = enemy_data.get("flying", false)
	var size: String = enemy_data.get("size", "small")
	var role: String = enemy_data.get("role", "swarm")
	
	if is_boss:
		return EnemyClass.BOSS
	elif flying:
		return EnemyClass.FLYING
	elif size == "huge":
		return EnemyClass.SIEGE
	elif hp > 1000:
		return EnemyClass.ELITE
	elif role == "special":
		return EnemyClass.SPECIALIST
	elif hp > 300:
		return EnemyClass.BRUISER
	elif role == "swarm" and hp < 200:
		return EnemyClass.SWARM_LIGHT
	else:
		return EnemyClass.SWARM_HEAVY

static func _setup_animation_nodes(visual: Node3D, enemy_id: String, enemy_data: Dictionary) -> void:
	visual.set_meta("enemy_id", enemy_id)
	visual.set_meta("animation_state", AnimationState.IDLE)
	visual.set_meta("has_special_animations", true)
	
	# Store enemy-specific animation data
	match enemy_id:
		"thrasher":
			visual.set_meta("supports_pack_howl", true)
			visual.set_meta("supports_pounce_attack", true)
		"blight_mite":
			visual.set_meta("supports_explosion_buildup", true)
			visual.set_meta("supports_jittery_movement", true)
		"slinker":
			visual.set_meta("supports_skull_split", true)
			visual.set_meta("supports_energy_charge", true)
		"gloom_wing":
			visual.set_meta("supports_wing_flutter", true)
			visual.set_meta("supports_bomb_drop", true)
		"behemoth":
			visual.set_meta("supports_ground_slam", true)
			visual.set_meta("supports_intimidation", true)

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

# Placeholder implementations for remaining enemies (would follow similar detailed patterns)
static func _create_generic_enemy_complete(enemy_id: String, base_color: Color, enemy_data: Dictionary, intensity: float) -> Node3D:
	# Fallback to existing system for unimplemented enemies
	return VisualGenerator.create_entity_visual(enemy_id, base_color) or _create_basic_placeholder(base_color, enemy_data)

static func _create_basic_placeholder(base_color: Color, enemy_data: Dictionary) -> Node3D:
	var r := Node3D.new()
	r.name = "Visual"
	
	var size_scale: Vector3 = Vector3(1.0, 1.0, 1.0)
	if enemy_data.has("mesh_scale"):
		var scale_data = enemy_data["mesh_scale"]
		if scale_data is Array and scale_data.size() >= 3:
			size_scale = Vector3(scale_data[0], scale_data[1], scale_data[2])
	
	_add_box(r, size_scale, Vector3(0, size_scale.y / 2.0, 0), base_color)
	return r

# Additional enemy implementations would follow here...
static func _create_polus_complete(c: Color, data: Dictionary, intensity: float) -> Node3D:
	# Implementation placeholder - would be detailed like above examples
	return _create_generic_enemy_complete("polus", c, data, intensity)

static func _create_brute_complete(c: Color, data: Dictionary, intensity: float) -> Node3D:
	# Implementation placeholder  
	return _create_generic_enemy_complete("brute", c, data, intensity)

static func _create_gorger_complete(c: Color, data: Dictionary, intensity: float) -> Node3D:
	# Implementation placeholder
	return _create_generic_enemy_complete("gorger", c, data, intensity)

static func _create_howler_complete(c: Color, data: Dictionary, intensity: float) -> Node3D:
	# Implementation placeholder
	return _create_generic_enemy_complete("howler", c, data, intensity)

static func _create_bile_spitter_complete(c: Color, data: Dictionary, intensity: float) -> Node3D:
	# Implementation placeholder
	return _create_generic_enemy_complete("bile_spitter", c, data, intensity)

static func _create_scrit_complete(c: Color, data: Dictionary, intensity: float) -> Node3D:
	# Implementation placeholder
	return _create_generic_enemy_complete("scrit", c, data, intensity)

static func _create_nightmare_drone_complete(c: Color, data: Dictionary, intensity: float) -> Node3D:
	# Implementation placeholder
	return _create_generic_enemy_complete("nightmare_drone", c, data, intensity)

static func _create_clugg_complete(c: Color, data: Dictionary, intensity: float) -> Node3D:
	# Implementation placeholder
	return _create_generic_enemy_complete("clugg", c, data, intensity)

static func _create_crystal_golem_complete(c: Color, data: Dictionary, intensity: float) -> Node3D:
	# Implementation placeholder
	return _create_generic_enemy_complete("crystal_golem", c, data, intensity)

static func _create_phase_stalker_complete(c: Color, data: Dictionary, intensity: float) -> Node3D:
	# Implementation placeholder
	return _create_generic_enemy_complete("phase_stalker", c, data, intensity)

static func _create_void_spawner_complete(c: Color, data: Dictionary, intensity: float) -> Node3D:
	# Implementation placeholder
	return _create_generic_enemy_complete("void_spawner", c, data, intensity)

static func _create_soul_reaver_complete(c: Color, data: Dictionary, intensity: float) -> Node3D:
	# Implementation placeholder
	return _create_generic_enemy_complete("soul_reaver", c, data, intensity)

static func _create_terror_bringer_complete(c: Color, data: Dictionary, intensity: float) -> Node3D:
	# Implementation placeholder
	return _create_generic_enemy_complete("terror_bringer", c, data, intensity)

static func _create_abyssal_lord_complete(c: Color, data: Dictionary, intensity: float) -> Node3D:
	# Implementation placeholder
	return _create_generic_enemy_complete("abyssal_lord", c, data, intensity)

static func _create_omega_destroyer_complete(c: Color, data: Dictionary, intensity: float) -> Node3D:
	# Implementation placeholder
	return _create_generic_enemy_complete("omega_destroyer", c, data, intensity)

static func _create_void_wraith_complete(c: Color, data: Dictionary, intensity: float) -> Node3D:
	# Implementation placeholder
	return _create_generic_enemy_complete("void_wraith", c, data, intensity)