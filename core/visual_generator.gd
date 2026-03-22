extends Node
## VisualGenerator - Creates code-generated 3D placeholder meshes.
## Used as an autoload-style utility. Access via: VisualGenerator.create_mesh(...)
## Since it's in core/, it's accessed as a class rather than autoload.

class_name VisualGenerator


static func create_mesh(shape: String, color_hex: String, scale_array: Variant = [1.0, 1.0, 1.0]) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "Visual"

	var mesh: Mesh
	match shape:
		"box":
			var box := BoxMesh.new()
			box.size = _parse_scale(scale_array)
			mesh = box
		"sphere":
			var sphere := SphereMesh.new()
			var s := _parse_scale(scale_array)
			sphere.radius = s.x / 2.0
			sphere.height = s.y
			mesh = sphere
		"cylinder":
			var cyl := CylinderMesh.new()
			var s := _parse_scale(scale_array)
			cyl.top_radius = s.x / 2.0
			cyl.bottom_radius = s.x / 2.0
			cyl.height = s.y
			mesh = cyl
		"capsule":
			var cap := CapsuleMesh.new()
			var s := _parse_scale(scale_array)
			cap.radius = s.x / 2.0
			cap.height = s.y
			mesh = cap
		_:
			var box := BoxMesh.new()
			box.size = _parse_scale(scale_array)
			mesh = box

	# Apply material with color - explicitly opaque
	var material := StandardMaterial3D.new()
	material.albedo_color = Color.html(color_hex)
	material.albedo_color.a = 1.0
	material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	material.roughness = 0.8
	material.metallic = 0.2
	mesh.material = material

	mesh_instance.mesh = mesh

	# Offset so the bottom sits on ground (y=0)
	var s := _parse_scale(scale_array)
	mesh_instance.position.y = s.y / 2.0

	return mesh_instance


static func create_health_bar(width: float = 1.0, is_enemy: bool = false) -> Node3D:
	var bar_root := Node3D.new()
	bar_root.name = "HealthBar"

	var bar_height := 0.06
	var bar_depth := 0.02

	# Background bar (dark gray)
	var bg := MeshInstance3D.new()
	var bg_mesh := QuadMesh.new()
	bg_mesh.size = Vector2(width, bar_height)
	var bg_mat := StandardMaterial3D.new()
	bg_mat.albedo_color = Color(0.15, 0.15, 0.15, 1.0)
	bg_mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	bg_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bg_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	bg_mesh.material = bg_mat
	bg.mesh = bg_mesh
	bg.name = "Background"
	bg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	bar_root.add_child(bg)

	# Foreground bar (green for allies, red for enemies)
	var fg := MeshInstance3D.new()
	var fg_mesh := QuadMesh.new()
	fg_mesh.size = Vector2(width, bar_height)
	var fg_mat := StandardMaterial3D.new()
	fg_mat.albedo_color = Color.RED if is_enemy else Color.GREEN
	fg_mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	fg_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fg_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	fg_mesh.material = fg_mat
	fg.mesh = fg_mesh
	fg.name = "Foreground"
	fg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Offset slightly forward to prevent z-fighting
	fg.position.z = bar_depth
	bar_root.add_child(fg)

	# Start hidden; shown when entity takes damage
	bar_root.visible = false

	return bar_root


static func update_health_bar(bar: Node3D, percent: float, width: float = 1.0) -> void:
	var fg := bar.get_node_or_null("Foreground") as MeshInstance3D
	if fg:
		var clamped := clampf(percent, 0.0, 1.0)
		fg.scale.x = clamped
		fg.position.x = -(width * (1.0 - clamped)) / 2.0


## Dispatch: returns a tier-specific visual for towers with sequential upgrades.
## tier 0 = base, tier 1 = tier 2 upgrade, tier 2 = tier 3 upgrade.
static func create_entity_visual_tier(entity_id: String, base_color: Color, tier: int) -> Node3D:
	if tier <= 0:
		return create_entity_visual(entity_id, base_color)
	# For towers without dedicated tier models, brighten color per tier and use base model
	var c: Color = base_color
	match entity_id:
		"autocannon":
			if tier == 1: return _create_autocannon_t2(c)
			if tier == 2: return _create_autocannon_t3(c)
		"missile_battery":
			if tier == 1: return _create_missile_battery_t2(c)
			if tier == 2: return _create_missile_battery_t3(c)
		"rail_gun":
			if tier == 1: return _create_rail_gun_t2(c)
			if tier == 2: return _create_rail_gun_t3(c)
		"plasma_mortar":
			if tier == 1: return _create_plasma_mortar_t2(c)
			if tier == 2: return _create_plasma_mortar_t3(c)
		"tesla_coil":
			if tier == 1: return _create_tesla_coil_t2(c)
			if tier == 2: return _create_tesla_coil_t3(c)
		"inferno_tower":
			if tier == 1: return _create_inferno_tower_t2(c)
			if tier == 2: return _create_inferno_tower_t3(c)
		"repair_tower":
			if tier == 1: return _create_repair_tower_t2(c)
			if tier == 2: return _create_repair_tower_t3(c)
		"war_beacon":
			if tier == 1: return _create_war_beacon_t2(c)
			if tier == 2: return _create_war_beacon_t3(c)
		"targeting_array":
			if tier == 1: return _create_targeting_array_t2(c)
			if tier == 2: return _create_targeting_array_t3(c)
		"shield_pylon":
			if tier == 1: return _create_shield_pylon_t2(c)
			if tier == 2: return _create_shield_pylon_t3(c)
		"leach_tower":
			if tier == 1: return _create_leach_tower_t2(c)
			if tier == 2: return _create_leach_tower_t3(c)
		"thermal_siphon":
			if tier == 1: return _create_thermal_siphon_t2(c)
			if tier == 2: return _create_thermal_siphon_t3(c)
		"solar_array":
			if tier == 1: return _create_solar_array_t2(c)
			if tier == 2: return _create_solar_array_t3(c)
		"recycler":
			if tier == 1: return _create_recycler_t2(c)
			if tier == 2: return _create_recycler_t3(c)
	return create_entity_visual(entity_id, base_color)


## Dispatch: returns a detailed procedural visual for known entity IDs, or null.
static func create_entity_visual(entity_id: String, base_color: Color) -> Node3D:
	match entity_id:
		"autocannon": return _create_autocannon(base_color)
		"missile_battery": return _create_missile_battery(base_color)
		"rail_gun": return _create_rail_gun(base_color)
		"plasma_mortar": return _create_plasma_mortar(base_color)
		"tesla_coil": return _create_tesla_coil(base_color)
		"inferno_tower": return _create_inferno_tower(base_color)
		"repair_tower": return _create_repair_tower(base_color)
		"war_beacon": return _create_war_beacon(base_color)
		"targeting_array": return _create_targeting_array(base_color)
		"shield_pylon": return _create_shield_pylon(base_color)
		"leach_tower": return _create_leach_tower(base_color)
		"thermal_siphon": return _create_thermal_siphon(base_color)
		"solar_array": return _create_solar_array(base_color)
		"recycler": return _create_recycler(base_color)
		"drone_printer": return _create_drone_printer(base_color)
		"mech_bay": return _create_mech_bay(base_color)
		"war_factory": return _create_war_factory(base_color)
		"barracks": return _create_barracks(base_color)
		"warehouse": return _create_warehouse(base_color)
		"office": return _create_office(base_color)
		"depot": return _create_depot(base_color)
		"container": return _create_container(base_color)
		# --- Enemy models ---
		"thrasher": return _create_thrasher(base_color)
		"brute": return _create_brute(base_color)
		"clugg": return _create_clugg(base_color)
		"scrit": return _create_scrit(base_color)
		"blight_mite": return _create_blight_mite(base_color)
		"terror_bringer": return _create_terror_bringer(base_color)
		"polus": return _create_polus(base_color)
		"slinker": return _create_slinker(base_color)
		"howler": return _create_howler(base_color)
		"gorger": return _create_gorger(base_color)
		"gloom_wing": return _create_gloom_wing(base_color)
		"bile_spitter": return _create_bile_spitter(base_color)
		"behemoth": return _create_behemoth(base_color)
		_: return null


# =============================================================================
# TOWER PEDESTAL - Elevates turrets above walls
# =============================================================================
const TOWER_PILLAR_HEIGHT: float = 2.5  # Tall enough to see over walls

static func _add_tower_pedestal(parent: Node3D, pillar_w: float, platform_w: float, c: Color) -> float:
	## Adds a reinforced pillar and returns the Y of the platform top.
	var dark := c.darkened(0.4)
	var h := TOWER_PILLAR_HEIGHT
	# Ground footing
	_add_box(parent, Vector3(platform_w + 0.1, 0.15, platform_w + 0.1), Vector3(0, 0.075, 0), dark)
	# Pillar shaft
	_add_box(parent, Vector3(pillar_w, h, pillar_w), Vector3(0, 0.15 + h / 2.0, 0), dark.lightened(0.1))
	# Cross braces at mid-height
	_add_box(parent, Vector3(platform_w, 0.06, 0.06), Vector3(0, 0.15 + h * 0.35, 0), dark)
	_add_box(parent, Vector3(0.06, 0.06, platform_w), Vector3(0, 0.15 + h * 0.35, 0), dark)
	# Top platform
	var top_y: float = 0.15 + h
	_add_box(parent, Vector3(platform_w, 0.12, platform_w), Vector3(0, top_y + 0.06, 0), dark.lightened(0.15))
	return top_y + 0.12


# =============================================================================
# OFFENSIVE TOWERS
# =============================================================================

static func _create_autocannon(c: Color) -> Node3D:
	## Military turret on pillar: rotating drum + twin barrels with animation hooks
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.3)
	var lite := c.lightened(0.2)
	var h := _add_tower_pedestal(r, 0.3, 0.6, c)
	
	# Turret base (stationary)
	_add_box(r, Vector3(0.5, 0.25, 0.5), Vector3(0, h + 0.125, 0), c)
	
	# Rotating turret body (this will rotate to track targets)
	var turret_body := Node3D.new()
	turret_body.name = "TurretBody"
	turret_body.position = Vector3(0, h + 0.25, 0)
	r.add_child(turret_body)
	
	# Upper turret housing
	_add_box(turret_body, Vector3(0.45, 0.35, 0.45), Vector3(0, 0.175, 0), c)
	
	# Barrel assembly (this will elevate up/down)
	var barrel_assembly := Node3D.new()
	barrel_assembly.name = "BarrelAssembly"
	barrel_assembly.position = Vector3(0, 0.25, 0.1)
	turret_body.add_child(barrel_assembly)
	
	# Barrel mount
	_add_box(barrel_assembly, Vector3(0.25, 0.2, 0.15), Vector3(0, 0.0, 0.22), lite)
	
	# Twin rotating barrels (will spin during firing)
	var barrel_spinner := Node3D.new()
	barrel_spinner.name = "BarrelSpinner"
	barrel_spinner.position = Vector3(0, 0.0, 0.4)
	barrel_assembly.add_child(barrel_spinner)
	
	_add_box(barrel_spinner, Vector3(0.06, 0.06, 0.5), Vector3(-0.08, 0.0, 0.25), lite)
	_add_box(barrel_spinner, Vector3(0.06, 0.06, 0.5), Vector3(0.08, 0.0, 0.25), lite)
	
	# Barrel rifling details (visual enhancement)
	_add_cylinder(barrel_spinner, 0.025, 0.5, Vector3(-0.08, 0.0, 0.25), lite.lightened(0.1))
	_add_cylinder(barrel_spinner, 0.025, 0.5, Vector3(0.08, 0.0, 0.25), lite.lightened(0.1))
	
	# Muzzle flash attachment points
	_add_muzzle_sphere(barrel_spinner, 0.04, Vector3(-0.08, 0.0, 0.5), Color(1.0, 0.8, 0.2), 2.0)
	_add_muzzle_sphere(barrel_spinner, 0.04, Vector3(0.08, 0.0, 0.5), Color(1.0, 0.8, 0.2), 2.0)
	
	# Brass ejection ports (animation markers)
	_add_box(turret_body, Vector3(0.04, 0.02, 0.06), Vector3(0.22, 0.15, 0.1), dark)
	_add_box(turret_body, Vector3(0.04, 0.02, 0.06), Vector3(-0.22, 0.15, 0.1), dark)
	
	# Ammo feed system
	_add_box(turret_body, Vector3(0.18, 0.15, 0.18), Vector3(-0.25, 0.0, -0.15), dark)
	_add_cylinder(turret_body, 0.03, 0.2, Vector3(-0.15, 0.1, 0.05), dark.darkened(0.2))  # Ammo belt feed
	
	# Heat vents for sustained fire
	_add_emissive_box(turret_body, Vector3(0.02, 0.08, 0.02), Vector3(0.15, 0.25, 0.2), Color(0.8, 0.4, 0.1), 1.0)
	_add_emissive_box(turret_body, Vector3(0.02, 0.08, 0.02), Vector3(-0.15, 0.25, 0.2), Color(0.8, 0.4, 0.1), 1.0)
	
	# Targeting laser mount point
	_add_cylinder(turret_body, 0.015, 0.08, Vector3(0, 0.35, 0.2), Color(0.7, 0.1, 0.1))
	
	# Animation metadata for future use
	r.set_meta("turret_body_node", turret_body.get_path())
	r.set_meta("barrel_assembly_node", barrel_assembly.get_path())
	r.set_meta("barrel_spinner_node", barrel_spinner.get_path())
	r.set_meta("supports_rotation", true)
	r.set_meta("supports_elevation", true)
	r.set_meta("supports_barrel_spin", true)
	r.set_meta("muzzle_flash_points", [
		Vector3(-0.08, h + 0.25, 0.5),
		Vector3(0.08, h + 0.25, 0.5)
	])
	r.set_meta("brass_ejection_points", [
		Vector3(0.22, h + 0.15, 0.1),
		Vector3(-0.22, h + 0.15, 0.1)
	])
	
	return r


static func _create_missile_battery(c: Color) -> Node3D:
	## Missile launcher on pillar: 4 launch tubes with reload system and guidance radar
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.3)
	var lite := c.lightened(0.2)
	var h := _add_tower_pedestal(r, 0.35, 0.7, c)
	
	# Launcher base housing
	_add_box(r, Vector3(0.7, 0.4, 0.7), Vector3(0, h + 0.2, 0), c)
	
	# Rotating launcher assembly (for target tracking)
	var launcher_assembly := Node3D.new()
	launcher_assembly.name = "LauncherAssembly"
	launcher_assembly.position = Vector3(0, h + 0.4, 0)
	r.add_child(launcher_assembly)
	
	# 4 missile tubes with individual missile visibility
	var tube_positions := [Vector3(-0.13, 0.175, -0.13), Vector3(0.13, 0.175, -0.13), 
						Vector3(-0.13, 0.175, 0.13), Vector3(0.13, 0.175, 0.13)]
	
	for i in range(4):
		var tube_pos: Vector3 = tube_positions[i]
		# Tube housing
		_add_cylinder(launcher_assembly, 0.07, 0.35, tube_pos, dark)
		
		# Missile inside tube (will be hidden/shown during reload)
		var missile := Node3D.new()
		missile.name = "Missile_" + str(i)
		missile.position = tube_pos + Vector3(0, 0.1, 0)
		launcher_assembly.add_child(missile)
		
		# Missile body
		_add_cylinder(missile, 0.04, 0.25, Vector3(0, 0, 0), Color(0.6, 0.6, 0.7))
		# Missile warhead (red tip)
		_add_cylinder(missile, 0.035, 0.08, Vector3(0, 0.16, 0), Color(0.8, 0.2, 0.1))
		# Guidance fins
		_add_box(missile, Vector3(0.08, 0.02, 0.02), Vector3(0, -0.08, 0), Color(0.4, 0.4, 0.5))
		_add_box(missile, Vector3(0.02, 0.02, 0.08), Vector3(0, -0.08, 0), Color(0.4, 0.4, 0.5))
		
		# Launch sequence marker (glows when ready to fire)
		_add_muzzle_sphere(launcher_assembly, 0.05, tube_pos + Vector3(0, 0.35, 0), Color(0.9, 0.5, 0.1), 1.5)
	
	# Reload mechanism (visible robotic arm)
	var reload_arm := Node3D.new()
	reload_arm.name = "ReloadArm"
	reload_arm.position = Vector3(0.25, 0.15, -0.25)
	launcher_assembly.add_child(reload_arm)
	
	_add_box(reload_arm, Vector3(0.04, 0.04, 0.15), Vector3(0, 0, 0), lite)
	_add_cylinder(reload_arm, 0.02, 0.08, Vector3(0, 0, 0.12), lite.lightened(0.1))
	
	# Missile storage magazine
	_add_box(launcher_assembly, Vector3(0.25, 0.2, 0.15), Vector3(-0.35, -0.1, -0.25), dark)
	_add_emissive_sphere(launcher_assembly, 0.02, Vector3(-0.35, 0.05, -0.25), Color(0.2, 1.0, 0.2), 2.0)  # Ready indicator
	
	# Guidance radar system (rotating dish)
	var radar_system := Node3D.new()
	radar_system.name = "RadarSystem"
	radar_system.position = Vector3(0, 0.15, -0.3)
	launcher_assembly.add_child(radar_system)
	
	_add_cylinder(radar_system, 0.12, 0.03, Vector3(0, 0, 0), lite)
	_add_cylinder(radar_system, 0.02, 0.15, Vector3(0, -0.075, 0), lite.darkened(0.1))
	# Radar sweep indicator
	_add_emissive_box(radar_system, Vector3(0.15, 0.01, 0.02), Vector3(0, 0.02, 0), Color(0.2, 0.8, 0.2), 2.0)
	
	# Status lights around base
	_add_emissive_sphere(launcher_assembly, 0.03, Vector3(0.3, -0.15, 0.3), Color(0.2, 1.0, 0.2), 2.0)
	_add_emissive_sphere(launcher_assembly, 0.03, Vector3(-0.3, -0.15, 0.3), Color(0.2, 1.0, 0.2), 2.0)
	
	# Exhaust vents for smoke trails
	for i in range(4):
		var vent_pos: Vector3 = tube_positions[i] + Vector3(0, 0.4, 0)
		_add_cylinder(launcher_assembly, 0.02, 0.05, vent_pos, dark.darkened(0.3))
	
	# Animation metadata
	r.set_meta("launcher_assembly_node", launcher_assembly.get_path())
	r.set_meta("radar_system_node", radar_system.get_path())
	r.set_meta("reload_arm_node", reload_arm.get_path())
	r.set_meta("missile_count", 4)
	r.set_meta("supports_rotation", true)
	r.set_meta("supports_missile_visibility", true)
	r.set_meta("supports_radar_sweep", true)
	r.set_meta("missile_launch_points", [
		Vector3(-0.13, h + 0.425, -0.13) + Vector3(0, 0.35, 0),
		Vector3(0.13, h + 0.425, -0.13) + Vector3(0, 0.35, 0),
		Vector3(-0.13, h + 0.425, 0.13) + Vector3(0, 0.35, 0),
		Vector3(0.13, h + 0.425, 0.13) + Vector3(0, 0.35, 0)
	])
	r.set_meta("exhaust_trail_points", [
		Vector3(-0.13, h + 0.8, -0.13),
		Vector3(0.13, h + 0.8, -0.13),
		Vector3(-0.13, h + 0.8, 0.13),
		Vector3(0.13, h + 0.8, 0.13)
	])
	
	return r


static func _create_autocannon_t2(c: Color) -> Node3D:
	## Tier 2 autocannon: heavier turret body, quad barrels, armored shield
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.25)
	var lite := c.lightened(0.25)
	var accent := Color(0.4, 0.7, 0.3)
	var h := _add_tower_pedestal(r, 0.35, 0.7, c)
	# Wider armored turret body
	_add_box(r, Vector3(0.65, 0.5, 0.55), Vector3(0, h + 0.25, 0), c)
	# Armored front shield plate
	_add_box(r, Vector3(0.7, 0.4, 0.08), Vector3(0, h + 0.3, 0.3), dark)
	# Barrel mount housing
	_add_box(r, Vector3(0.35, 0.25, 0.2), Vector3(0, h + 0.38, 0.38), lite)
	# Quad barrels (thicker)
	_add_box(r, Vector3(0.07, 0.07, 0.7), Vector3(-0.1, h + 0.42, 0.7), lite)
	_add_box(r, Vector3(0.07, 0.07, 0.7), Vector3(0.1, h + 0.42, 0.7), lite)
	_add_box(r, Vector3(0.07, 0.07, 0.7), Vector3(-0.1, h + 0.32, 0.7), lite)
	_add_box(r, Vector3(0.07, 0.07, 0.7), Vector3(0.1, h + 0.32, 0.7), lite)
	# Side ammo hoppers
	_add_box(r, Vector3(0.22, 0.2, 0.22), Vector3(-0.38, h + 0.2, 0), dark)
	_add_box(r, Vector3(0.22, 0.2, 0.22), Vector3(0.38, h + 0.2, 0), dark)
	# Tier 2 accent stripe
	_add_emissive_box(r, Vector3(0.66, 0.04, 0.56), Vector3(0, h + 0.51, 0), accent, 1.5)
	# Muzzle flash tips
	_add_muzzle_sphere(r, 0.05, Vector3(-0.1, h + 0.42, 1.05), Color(1.0, 0.8, 0.2), 2.5)
	_add_muzzle_sphere(r, 0.05, Vector3(0.1, h + 0.42, 1.05), Color(1.0, 0.8, 0.2), 2.5)
	_add_muzzle_sphere(r, 0.05, Vector3(-0.1, h + 0.32, 1.05), Color(1.0, 0.8, 0.2), 2.5)
	_add_muzzle_sphere(r, 0.05, Vector3(0.1, h + 0.32, 1.05), Color(1.0, 0.8, 0.2), 2.5)
	return r


static func _create_autocannon_t3(c: Color) -> Node3D:
	## Tier 3 autocannon: fortress turret, rotary gatling, heavy armor, glowing power core
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.2)
	var lite := c.lightened(0.3)
	var accent := Color(1.0, 0.6, 0.1)
	var h := _add_tower_pedestal(r, 0.4, 0.8, c)
	# Heavy armored turret base
	_add_box(r, Vector3(0.8, 0.35, 0.7), Vector3(0, h + 0.175, 0), dark)
	# Upper turret housing
	_add_box(r, Vector3(0.7, 0.4, 0.6), Vector3(0, h + 0.55, 0.05), c)
	# Heavy front armor plate
	_add_box(r, Vector3(0.75, 0.5, 0.1), Vector3(0, h + 0.45, 0.35), dark)
	# Rotary barrel assembly housing
	_add_cylinder(r, 0.18, 0.3, Vector3(0, h + 0.5, 0.5), lite)
	# 6 rotary barrels
	for angle_i in range(6):
		var angle: float = angle_i * TAU / 6.0
		var bx: float = cos(angle) * 0.1
		var by: float = sin(angle) * 0.1
		_add_box(r, Vector3(0.05, 0.05, 0.9), Vector3(bx, h + 0.5 + by, 0.9), lite)
	# Side armor plates
	_add_box(r, Vector3(0.1, 0.35, 0.5), Vector3(-0.45, h + 0.35, 0), dark)
	_add_box(r, Vector3(0.1, 0.35, 0.5), Vector3(0.45, h + 0.35, 0), dark)
	# Rear ammo drum
	_add_cylinder(r, 0.2, 0.3, Vector3(0, h + 0.3, -0.3), dark)
	# Power core glow
	_add_emissive_sphere(r, 0.1, Vector3(0, h + 0.55, -0.15), accent, 3.0)
	# Tier 3 accent stripes
	_add_emissive_box(r, Vector3(0.81, 0.04, 0.71), Vector3(0, h + 0.36, 0), accent, 2.0)
	_add_emissive_box(r, Vector3(0.71, 0.04, 0.61), Vector3(0, h + 0.76, 0.05), accent, 2.0)
	# Muzzle glow ring
	_add_muzzle_sphere(r, 0.12, Vector3(0, h + 0.5, 1.35), Color(1.0, 0.7, 0.1), 4.0)
	return r


static func _create_missile_battery_t2(c: Color) -> Node3D:
	## Tier 2 missile battery: 6 launch tubes, larger housing, tracking radar, armor plating
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.25)
	var lite := c.lightened(0.2)
	var accent := Color(0.3, 0.5, 0.8)
	var h := _add_tower_pedestal(r, 0.4, 0.75, c)
	# Wider launcher housing
	_add_box(r, Vector3(0.85, 0.45, 0.8), Vector3(0, h + 0.225, 0), c)
	# 6 missile tubes (2x3 grid)
	for tx in [-0.18, 0.0, 0.18]:
		for tz in [-0.13, 0.13]:
			_add_cylinder(r, 0.08, 0.4, Vector3(tx, h + 0.625, tz), c.darkened(0.15))
	# Tube openings (emissive)
	for tx in [-0.18, 0.0, 0.18]:
		for tz in [-0.13, 0.13]:
			_add_muzzle_sphere(r, 0.06, Vector3(tx, h + 0.82, tz), Color(0.9, 0.5, 0.1), 1.8)
	# Side armor plating
	_add_box(r, Vector3(0.08, 0.4, 0.6), Vector3(-0.46, h + 0.22, 0), dark)
	_add_box(r, Vector3(0.08, 0.4, 0.6), Vector3(0.46, h + 0.22, 0), dark)
	# Larger tracking radar on back
	_add_cylinder(r, 0.18, 0.04, Vector3(0, h + 0.6, -0.35), lite)
	_add_cylinder(r, 0.03, 0.2, Vector3(0, h + 0.5, -0.35), lite)
	# Tier 2 accent stripe
	_add_emissive_box(r, Vector3(0.86, 0.04, 0.81), Vector3(0, h + 0.46, 0), accent, 1.5)
	return r


static func _create_missile_battery_t3(c: Color) -> Node3D:
	## Tier 3 missile battery: 8 heavy tubes, fortress housing, dual radar, glowing reactor
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.2)
	var lite := c.lightened(0.25)
	var accent := Color(1.0, 0.4, 0.2)
	var h := _add_tower_pedestal(r, 0.45, 0.85, c)
	# Heavy armored base
	_add_box(r, Vector3(0.95, 0.3, 0.9), Vector3(0, h + 0.15, 0), dark)
	# Upper launcher housing
	_add_box(r, Vector3(0.9, 0.5, 0.85), Vector3(0, h + 0.55, 0), c)
	# 8 heavy missile tubes (2x4 grid)
	for tx in [-0.22, -0.07, 0.07, 0.22]:
		for tz in [-0.15, 0.15]:
			_add_cylinder(r, 0.09, 0.45, Vector3(tx, h + 0.725, tz), c.darkened(0.1))
	# Heavy tube openings (emissive)
	for tx in [-0.22, -0.07, 0.07, 0.22]:
		for tz in [-0.15, 0.15]:
			_add_muzzle_sphere(r, 0.07, Vector3(tx, h + 0.95, tz), accent, 2.0)
	# Thick side armor
	_add_box(r, Vector3(0.12, 0.5, 0.7), Vector3(-0.52, h + 0.4, 0), dark)
	_add_box(r, Vector3(0.12, 0.5, 0.7), Vector3(0.52, h + 0.4, 0), dark)
	# Dual tracking radar
	_add_cylinder(r, 0.15, 0.04, Vector3(-0.2, h + 0.85, -0.38), lite)
	_add_cylinder(r, 0.03, 0.15, Vector3(-0.2, h + 0.75, -0.38), lite)
	_add_cylinder(r, 0.15, 0.04, Vector3(0.2, h + 0.85, -0.38), lite)
	_add_cylinder(r, 0.03, 0.15, Vector3(0.2, h + 0.75, -0.38), lite)
	# Rear reactor core
	_add_emissive_sphere(r, 0.14, Vector3(0, h + 0.45, -0.4), accent, 3.5)
	# Tier 3 accent stripes
	_add_emissive_box(r, Vector3(0.96, 0.04, 0.91), Vector3(0, h + 0.31, 0), accent, 2.0)
	_add_emissive_box(r, Vector3(0.91, 0.04, 0.86), Vector3(0, h + 0.81, 0), accent, 2.0)
	return r


static func _create_rail_gun(c: Color) -> Node3D:
	## Sleek sniper on pillar: energy conduit system with charging effects and recoil mechanics
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.3)
	var lite := c.lightened(0.2)
	var energy_blue := Color(0.3, 0.6, 1.0)
	var h := _add_tower_pedestal(r, 0.25, 0.5, c)
	
	# Support spine with energy conduit housing
	_add_box(r, Vector3(0.15, 1.2, 0.15), Vector3(0, h + 0.6, 0), c)
	
	# Energy conduit system (glows during charge-up)
	var conduit_system := Node3D.new()
	conduit_system.name = "ConduitSystem"
	conduit_system.position = Vector3(0, h, 0)
	r.add_child(conduit_system)
	
	# Main energy conduits running up the spine
	_add_emissive_box(conduit_system, Vector3(0.02, 1.15, 0.02), Vector3(0.04, 0.625, 0.04), energy_blue, 1.0)
	_add_emissive_box(conduit_system, Vector3(0.02, 1.15, 0.02), Vector3(-0.04, 0.625, 0.04), energy_blue, 1.0)
	_add_emissive_box(conduit_system, Vector3(0.02, 1.15, 0.02), Vector3(0.04, 0.625, -0.04), energy_blue, 1.0)
	_add_emissive_box(conduit_system, Vector3(0.02, 1.15, 0.02), Vector3(-0.04, 0.625, -0.04), energy_blue, 1.0)
	
	# Barrel assembly (will recoil backward on firing)
	var barrel_assembly := Node3D.new()
	barrel_assembly.name = "BarrelAssembly"
	barrel_assembly.position = Vector3(0, h + 1.1, 0)
	r.add_child(barrel_assembly)
	
	# Main barrel housing
	_add_box(barrel_assembly, Vector3(0.1, 0.1, 1.0), Vector3(0, 0, 0.5), lite)
	
	# Energy acceleration coils (charge up sequentially)
	var coil_positions := [0.15, 0.4, 0.65, 0.9]
	for i in range(coil_positions.size()):
		var z_pos: float = coil_positions[i]
		var coil := Node3D.new()
		coil.name = "AcceleratorCoil_" + str(i)
		coil.position = Vector3(0, 0, z_pos)
		barrel_assembly.add_child(coil)
		
		_add_emissive_box(coil, Vector3(0.16, 0.16, 0.03), Vector3(0, 0, 0), energy_blue, 1.5)
		# Inner energy ring
		_add_emissive_box(coil, Vector3(0.08, 0.08, 0.02), Vector3(0, 0, 0.01), energy_blue.lightened(0.3), 2.0)
	
	# Muzzle tip with focusing elements
	_add_cylinder(barrel_assembly, 0.04, 0.08, Vector3(0, 0, 1.04), lite.lightened(0.2))
	_add_muzzle_sphere(barrel_assembly, 0.06, Vector3(0, 0, 1.08), energy_blue.lightened(0.5), 3.0)
	
	# Recoil dampener system
	var recoil_dampener := Node3D.new()
	recoil_dampener.name = "RecoilDampener"
	recoil_dampener.position = Vector3(0, h + 0.8, -0.1)
	r.add_child(recoil_dampener)
	
	_add_cylinder(recoil_dampener, 0.04, 0.2, Vector3(0, 0, 0), dark.darkened(0.2))
	_add_cylinder(recoil_dampener, 0.06, 0.05, Vector3(0, 0.1, 0), dark)
	
	# Capacitor bank (stores energy for shots)
	var capacitor_bank := Node3D.new()
	capacitor_bank.name = "CapacitorBank"
	capacitor_bank.position = Vector3(0, h + 0.3, -0.2)
	r.add_child(capacitor_bank)
	
	_add_box(capacitor_bank, Vector3(0.2, 0.15, 0.12), Vector3(0, 0, 0), dark)
	_add_emissive_sphere(capacitor_bank, 0.03, Vector3(0.08, 0.08, 0.06), energy_blue, 2.0)
	_add_emissive_sphere(capacitor_bank, 0.03, Vector3(-0.08, 0.08, 0.06), energy_blue, 2.0)
	
	# Energy transfer relays
	_add_emissive_box(conduit_system, Vector3(0.04, 0.02, 0.08), Vector3(0, 0.35, -0.1), energy_blue, 1.5)
	_add_emissive_box(conduit_system, Vector3(0.04, 0.02, 0.08), Vector3(0, 0.6, 0), energy_blue, 1.5)
	_add_emissive_box(conduit_system, Vector3(0.04, 0.02, 0.08), Vector3(0, 0.9, 0.1), energy_blue, 1.5)
	
	# Stabilizer fins with micro-adjusters
	_add_box(r, Vector3(0.4, 0.06, 0.06), Vector3(0, h + 0.15, 0), dark)
	_add_box(r, Vector3(0.06, 0.06, 0.4), Vector3(0, h + 0.15, 0), dark)
	_add_cylinder(r, 0.01, 0.04, Vector3(0.2, h + 0.18, 0), lite)
	_add_cylinder(r, 0.01, 0.04, Vector3(-0.2, h + 0.18, 0), lite)
	
	# Targeting computer housing
	_add_box(r, Vector3(0.12, 0.08, 0.08), Vector3(-0.1, h + 0.9, -0.08), dark.lightened(0.1))
	_add_emissive_sphere(r, 0.02, Vector3(-0.1, h + 0.94, -0.04), Color(0.8, 0.2, 0.2), 2.0)  # Targeting laser
	
	# Animation metadata
	r.set_meta("conduit_system_node", conduit_system.get_path())
	r.set_meta("barrel_assembly_node", barrel_assembly.get_path())
	r.set_meta("recoil_dampener_node", recoil_dampener.get_path())
	r.set_meta("capacitor_bank_node", capacitor_bank.get_path())
	r.set_meta("coil_count", coil_positions.size())
	r.set_meta("supports_energy_charging", true)
	r.set_meta("supports_recoil", true)
	r.set_meta("supports_sequential_coil_activation", true)
	r.set_meta("energy_beam_origin", Vector3(0, h + 1.1, 1.08))
	r.set_meta("recoil_distance", -0.15)  # Distance barrel moves back during recoil
	r.set_meta("charge_duration", 1.5)    # Time to fully charge before firing
	
	return r


static func _create_plasma_mortar(c: Color) -> Node3D:
	## Heavy weapon (2x2) on pillar: mortar body + angled tube + glowing core
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.3)
	var h := _add_tower_pedestal(r, 0.5, 0.9, c)
	# Mortar body (lower section wider)
	_add_cylinder(r, 0.4, 0.35, Vector3(0, h + 0.175, 0), c)
	# Upper section (narrower)
	_add_cylinder(r, 0.3, 0.25, Vector3(0, h + 0.475, 0), c.lightened(0.1))
	# Mortar tube
	_add_cylinder(r, 0.15, 0.4, Vector3(0.1, h + 0.8, 0.1), c.darkened(0.1))
	# Plasma core glow
	_add_muzzle_sphere(r, 0.12, Vector3(0.1, h + 1.0, 0.1), Color(0.8, 0.2, 0.9), 3.0)
	# Side heat vents
	_add_box(r, Vector3(0.6, 0.06, 0.08), Vector3(0, h + 0.25, 0.35), dark)
	_add_box(r, Vector3(0.6, 0.06, 0.08), Vector3(0, h + 0.25, -0.35), dark)
	# Armored plates
	_add_box(r, Vector3(0.08, 0.3, 0.5), Vector3(0.42, h + 0.2, 0), dark)
	_add_box(r, Vector3(0.08, 0.3, 0.5), Vector3(-0.42, h + 0.2, 0), dark)
	return r


static func _create_tesla_coil(c: Color) -> Node3D:
	## Electric pylon on pillar: shaft + stacked coil rings + glowing top sphere
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.3)
	var glow := Color(0.3, 0.7, 1.0)
	var h := _add_tower_pedestal(r, 0.22, 0.45, c)
	# Central pylon
	_add_cylinder(r, 0.05, 1.8, Vector3(0, h + 0.9, 0), c)
	# Coil rings (4 stacked, getting smaller toward top)
	for i in range(4):
		var y_pos: float = h + 0.4 + i * 0.4
		var ring_r: float = 0.18 - i * 0.025
		_add_emissive_box(r, Vector3(ring_r * 2, 0.04, ring_r * 2),
			Vector3(0, y_pos, 0), glow, 1.5 + i * 0.3)
	# Top sphere (main discharge point)
	_add_muzzle_sphere(r, 0.14, Vector3(0, h + 1.9, 0), glow, 4.0)
	# Support struts
	_add_box(r, Vector3(0.03, 0.4, 0.03), Vector3(0.12, h + 0.3, 0.12), dark)
	_add_box(r, Vector3(0.03, 0.4, 0.03), Vector3(-0.12, h + 0.3, -0.12), dark)
	return r


static func _create_inferno_tower(c: Color) -> Node3D:
	## Fire tower on pillar: tapered body + heat vents + glowing red nozzle
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.3)
	var flame := Color(1.0, 0.4, 0.1)
	var h := _add_tower_pedestal(r, 0.3, 0.6, c)
	# Lower body (wider)
	_add_box(r, Vector3(0.5, 0.5, 0.5), Vector3(0, h + 0.25, 0), c)
	# Upper body (narrower, tapered look)
	_add_box(r, Vector3(0.35, 0.6, 0.35), Vector3(0, h + 0.8, 0), c.lightened(0.1))
	# Heat vents on 4 sides
	for vx in [-0.28, 0.28]:
		_add_emissive_box(r, Vector3(0.04, 0.15, 0.2), Vector3(vx, h + 0.4, 0), flame, 1.0)
	for vz in [-0.28, 0.28]:
		_add_emissive_box(r, Vector3(0.2, 0.15, 0.04), Vector3(0, h + 0.4, vz), flame, 1.0)
	# Flame nozzle at top
	_add_cylinder(r, 0.1, 0.15, Vector3(0, h + 1.18, 0), dark)
	# Glowing flame tip
	_add_muzzle_sphere(r, 0.1, Vector3(0, h + 1.3, 0), flame, 4.0)
	return r


# =============================================================================
# SUPPORT TOWERS
# =============================================================================

static func _create_repair_tower(c: Color) -> Node3D:
	## Medical station on pillar: body + green cross symbol on top
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.3)
	var heal_glow := Color(0.2, 1.0, 0.3)
	var h := _add_tower_pedestal(r, 0.25, 0.55, c)
	# Body
	_add_cylinder(r, 0.25, 0.5, Vector3(0, h + 0.25, 0), c)
	# Top platform
	_add_cylinder(r, 0.3, 0.08, Vector3(0, h + 0.54, 0), c.lightened(0.1))
	# Cross symbol (two intersecting bars)
	_add_emissive_box(r, Vector3(0.35, 0.06, 0.1), Vector3(0, h + 0.62, 0), heal_glow, 2.5)
	_add_emissive_box(r, Vector3(0.1, 0.06, 0.35), Vector3(0, h + 0.62, 0), heal_glow, 2.5)
	# Vertical cross piece
	_add_emissive_box(r, Vector3(0.1, 0.25, 0.06), Vector3(0, h + 0.78, 0), heal_glow, 2.0)
	# Small antenna
	_add_cylinder(r, 0.015, 0.25, Vector3(0.15, h + 0.72, 0), dark)
	return r


static func _create_war_beacon(c: Color) -> Node3D:
	## Signal tower on pillar: tall mast + antenna dish + red pulse light
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.3)
	var pulse := Color(1.0, 0.2, 0.2)
	var h := _add_tower_pedestal(r, 0.22, 0.45, c)
	# Support legs (4 struts above platform)
	_add_box(r, Vector3(0.04, 0.5, 0.04), Vector3(0.1, h + 0.25, 0.1), c)
	_add_box(r, Vector3(0.04, 0.5, 0.04), Vector3(-0.1, h + 0.25, 0.1), c)
	_add_box(r, Vector3(0.04, 0.5, 0.04), Vector3(0.1, h + 0.25, -0.1), c)
	_add_box(r, Vector3(0.04, 0.5, 0.04), Vector3(-0.1, h + 0.25, -0.1), c)
	# Central mast
	_add_cylinder(r, 0.03, 1.2, Vector3(0, h + 0.5 + 0.6, 0), c.lightened(0.1))
	# Signal dish at top
	_add_cylinder(r, 0.18, 0.04, Vector3(0, h + 1.35, 0), c.lightened(0.2))
	# Pulse light
	_add_emissive_sphere(r, 0.08, Vector3(0, h + 1.45, 0), pulse, 4.0)
	# Secondary light lower
	_add_emissive_sphere(r, 0.04, Vector3(0, h + 0.8, 0.06), pulse, 2.0)
	return r


static func _create_targeting_array(c: Color) -> Node3D:
	## Radar on pillar: column + large radar dish + scanner lights
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.3)
	var scan := Color(0.3, 0.6, 1.0)
	var h := _add_tower_pedestal(r, 0.22, 0.5, c)
	# Support column
	_add_box(r, Vector3(0.12, 1.2, 0.12), Vector3(0, h + 0.6, 0), c)
	# Dish mount
	_add_box(r, Vector3(0.2, 0.1, 0.2), Vector3(0, h + 1.25, 0), c.lightened(0.1))
	# Radar dish (large flat disc)
	_add_cylinder(r, 0.28, 0.05, Vector3(0, h + 1.35, 0.08), c.lightened(0.2))
	# Scanner receiver (small rod on dish)
	_add_cylinder(r, 0.015, 0.2, Vector3(0, h + 1.48, 0.08), c.lightened(0.1))
	# Sensor lights
	_add_emissive_sphere(r, 0.04, Vector3(0, h + 1.58, 0.08), scan, 3.0)
	_add_emissive_sphere(r, 0.03, Vector3(0.12, h + 1.25, 0), scan, 2.0)
	_add_emissive_sphere(r, 0.03, Vector3(-0.12, h + 1.25, 0), scan, 2.0)
	return r


static func _create_shield_pylon(c: Color) -> Node3D:
	## Energy projector on pillar: tapered pylon + crystal prism + purple glow
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.3)
	var shield_glow := Color(0.4, 0.3, 1.0)
	var h := _add_tower_pedestal(r, 0.28, 0.55, c)
	# Pylon body (3 stacked sections getting narrower)
	_add_box(r, Vector3(0.42, 0.35, 0.42), Vector3(0, h + 0.175, 0), c)
	_add_box(r, Vector3(0.32, 0.3, 0.32), Vector3(0, h + 0.5, 0), c.lightened(0.05))
	_add_box(r, Vector3(0.22, 0.25, 0.22), Vector3(0, h + 0.775, 0), c.lightened(0.1))
	# Crystal prism at top
	_add_emissive_box(r, Vector3(0.18, 0.3, 0.18), Vector3(0, h + 1.05, 0), shield_glow, 3.0)
	# Energy field lines
	_add_emissive_box(r, Vector3(0.44, 0.03, 0.03), Vector3(0, h + 0.3, 0.22), shield_glow, 1.5)
	_add_emissive_box(r, Vector3(0.44, 0.03, 0.03), Vector3(0, h + 0.3, -0.22), shield_glow, 1.5)
	_add_emissive_box(r, Vector3(0.03, 0.03, 0.44), Vector3(0.22, h + 0.3, 0), shield_glow, 1.5)
	_add_emissive_box(r, Vector3(0.03, 0.03, 0.44), Vector3(-0.22, h + 0.3, 0), shield_glow, 1.5)
	return r


# =============================================================================
# RESOURCE TOWERS
# =============================================================================

static func _create_leach_tower(c: Color) -> Node3D:
	## Harvester on pillar: body + collection arm + green beam emitter
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.3)
	var harvest := Color(0.1, 0.9, 0.2)
	var h := _add_tower_pedestal(r, 0.22, 0.45, c)
	# Body
	_add_cylinder(r, 0.15, 0.7, Vector3(0, h + 0.35, 0), c)
	# Collection arm (extends outward)
	_add_box(r, Vector3(0.08, 0.08, 0.5), Vector3(0, h + 0.75, 0.3), c.lightened(0.1))
	# Scoop/funnel at arm end
	_add_box(r, Vector3(0.2, 0.15, 0.12), Vector3(0, h + 0.7, 0.55), c.lightened(0.15))
	# Beam emitter glow
	_add_emissive_sphere(r, 0.07, Vector3(0, h + 0.68, 0.62), harvest, 3.0)
	# Collection tank
	_add_cylinder(r, 0.2, 0.2, Vector3(0, h + 0.1, 0), dark)
	# Status light
	_add_emissive_sphere(r, 0.04, Vector3(0, h + 0.8, 0), harvest, 2.0)
	return r


static func _create_thermal_siphon(c: Color) -> Node3D:
	## Energy collector on pillar: body + heat pipes + cyan collector dish
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.3)
	var energy := Color(0.2, 0.8, 1.0)
	var h := _add_tower_pedestal(r, 0.25, 0.5, c)
	# Body
	_add_cylinder(r, 0.18, 0.6, Vector3(0, h + 0.3, 0), c)
	# Heat pipes (3 thin tubes extending upward)
	_add_cylinder(r, 0.025, 0.45, Vector3(0.15, h + 0.6, 0), c.lightened(0.1))
	_add_cylinder(r, 0.025, 0.45, Vector3(-0.08, h + 0.6, 0.12), c.lightened(0.1))
	_add_cylinder(r, 0.025, 0.45, Vector3(-0.08, h + 0.6, -0.12), c.lightened(0.1))
	# Collector dish at top
	_add_cylinder(r, 0.22, 0.04, Vector3(0, h + 0.85, 0), c.lightened(0.2))
	# Energy glow in dish
	_add_emissive_sphere(r, 0.1, Vector3(0, h + 0.9, 0), energy, 3.5)
	# Thermal vents
	_add_emissive_box(r, Vector3(0.03, 0.2, 0.04), Vector3(0.19, h + 0.35, 0), energy, 1.0)
	_add_emissive_box(r, Vector3(0.04, 0.2, 0.03), Vector3(0, h + 0.35, 0.19), energy, 1.0)
	return r


# =============================================================================
# TIER 2/3 VISUALS - REMAINING TOWERS
# =============================================================================

# --- Rail Gun Tiers ---
static func _create_rail_gun_t2(c: Color) -> Node3D:
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.25)
	var lite := c.lightened(0.25)
	var accent := Color(0.3, 0.5, 0.9)
	var h := _add_tower_pedestal(r, 0.3, 0.6, c)
	_add_box(r, Vector3(0.2, 1.4, 0.2), Vector3(0, h + 0.7, 0), c)
	# Dual barrel housing
	_add_box(r, Vector3(0.14, 0.14, 1.2), Vector3(0, h + 1.3, 0.6), lite)
	_add_box(r, Vector3(0.08, 0.08, 1.2), Vector3(0, h + 1.15, 0.6), lite)
	# 4 coil rings
	for i in range(4):
		var z_pos: float = 0.15 + i * 0.28
		_add_emissive_box(r, Vector3(0.2, 0.2, 0.03), Vector3(0, h + 1.25, z_pos), accent, 2.0)
	# Side stabilizer fins (larger)
	_add_box(r, Vector3(0.5, 0.08, 0.08), Vector3(0, h + 0.2, 0), dark)
	_add_box(r, Vector3(0.08, 0.08, 0.5), Vector3(0, h + 0.2, 0), dark)
	_add_muzzle_sphere(r, 0.08, Vector3(0, h + 1.25, 1.2), accent, 4.0)
	_add_emissive_box(r, Vector3(0.21, 0.04, 0.21), Vector3(0, h + 1.42, 0), accent, 1.5)
	return r

static func _create_rail_gun_t3(c: Color) -> Node3D:
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.2)
	var lite := c.lightened(0.3)
	var accent := Color(0.6, 0.3, 1.0)
	var h := _add_tower_pedestal(r, 0.35, 0.7, c)
	# Heavy support spine
	_add_box(r, Vector3(0.25, 1.6, 0.25), Vector3(0, h + 0.8, 0), c)
	# Armored barrel shroud
	_add_box(r, Vector3(0.18, 0.18, 1.5), Vector3(0, h + 1.5, 0.75), lite)
	# 5 accelerator coil rings
	for i in range(5):
		var z_pos: float = 0.1 + i * 0.3
		_add_emissive_box(r, Vector3(0.24, 0.24, 0.04), Vector3(0, h + 1.5, z_pos), accent, 2.5)
	# Side armor + capacitor banks
	_add_box(r, Vector3(0.12, 0.5, 0.4), Vector3(-0.22, h + 0.8, 0), dark)
	_add_box(r, Vector3(0.12, 0.5, 0.4), Vector3(0.22, h + 0.8, 0), dark)
	_add_emissive_sphere(r, 0.06, Vector3(-0.22, h + 1.1, 0), accent, 2.0)
	_add_emissive_sphere(r, 0.06, Vector3(0.22, h + 1.1, 0), accent, 2.0)
	# Large muzzle glow
	_add_muzzle_sphere(r, 0.12, Vector3(0, h + 1.5, 1.5), accent, 5.0)
	_add_emissive_box(r, Vector3(0.26, 0.04, 0.26), Vector3(0, h + 1.62, 0), accent, 2.0)
	_add_emissive_box(r, Vector3(0.26, 0.04, 0.26), Vector3(0, h + 0.05, 0), accent, 2.0)
	return r

# --- Plasma Mortar Tiers ---
static func _create_plasma_mortar_t2(c: Color) -> Node3D:
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.25)
	var accent := Color(0.7, 0.2, 0.9)
	var h := _add_tower_pedestal(r, 0.55, 0.95, c)
	_add_cylinder(r, 0.45, 0.4, Vector3(0, h + 0.2, 0), c)
	_add_cylinder(r, 0.35, 0.3, Vector3(0, h + 0.55, 0), c.lightened(0.1))
	# Dual mortar tubes
	_add_cylinder(r, 0.14, 0.45, Vector3(0.15, h + 0.85, 0.1), c.darkened(0.1))
	_add_cylinder(r, 0.14, 0.45, Vector3(-0.15, h + 0.85, 0.1), c.darkened(0.1))
	_add_muzzle_sphere(r, 0.11, Vector3(0.15, h + 1.08, 0.1), accent, 3.0)
	_add_muzzle_sphere(r, 0.11, Vector3(-0.15, h + 1.08, 0.1), accent, 3.0)
	# Heavier armor plates
	_add_box(r, Vector3(0.1, 0.35, 0.6), Vector3(0.48, h + 0.25, 0), dark)
	_add_box(r, Vector3(0.1, 0.35, 0.6), Vector3(-0.48, h + 0.25, 0), dark)
	_add_box(r, Vector3(0.7, 0.06, 0.1), Vector3(0, h + 0.3, 0.4), dark)
	_add_box(r, Vector3(0.7, 0.06, 0.1), Vector3(0, h + 0.3, -0.4), dark)
	_add_emissive_box(r, Vector3(0.46, 0.04, 0.46), Vector3(0, h + 0.41, 0), accent, 1.5)
	return r

static func _create_plasma_mortar_t3(c: Color) -> Node3D:
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.2)
	var accent := Color(1.0, 0.3, 0.8)
	var h := _add_tower_pedestal(r, 0.6, 1.0, c)
	# Heavy base
	_add_cylinder(r, 0.5, 0.45, Vector3(0, h + 0.225, 0), dark)
	_add_cylinder(r, 0.4, 0.35, Vector3(0, h + 0.625, 0), c)
	# Triple mortar tubes
	_add_cylinder(r, 0.13, 0.5, Vector3(0.18, h + 0.95, 0.1), c.darkened(0.1))
	_add_cylinder(r, 0.13, 0.5, Vector3(-0.18, h + 0.95, 0.1), c.darkened(0.1))
	_add_cylinder(r, 0.15, 0.55, Vector3(0, h + 1.0, 0.15), c.darkened(0.1))
	for pos in [Vector3(0.18, h + 1.2, 0.1), Vector3(-0.18, h + 1.2, 0.1), Vector3(0, h + 1.28, 0.15)]:
		_add_muzzle_sphere(r, 0.12, pos, accent, 3.5)
	# Reactor core
	_add_emissive_sphere(r, 0.15, Vector3(0, h + 0.5, -0.25), accent, 4.0)
	# Heavy armor
	_add_box(r, Vector3(0.12, 0.4, 0.7), Vector3(0.52, h + 0.3, 0), dark)
	_add_box(r, Vector3(0.12, 0.4, 0.7), Vector3(-0.52, h + 0.3, 0), dark)
	_add_emissive_box(r, Vector3(0.51, 0.04, 0.51), Vector3(0, h + 0.46, 0), accent, 2.0)
	_add_emissive_box(r, Vector3(0.41, 0.04, 0.41), Vector3(0, h + 0.81, 0), accent, 2.0)
	return r

# --- Tesla Coil Tiers ---
static func _create_tesla_coil_t2(c: Color) -> Node3D:
	var r := Node3D.new()
	r.name = "Visual"
	var accent := Color(0.4, 0.6, 1.0)
	var h := _add_tower_pedestal(r, 0.3, 0.55, c)
	# Thicker shaft
	_add_cylinder(r, 0.1, 1.8, Vector3(0, h + 0.9, 0), c)
	# 4 coil rings (larger)
	for i in range(4):
		var y_pos: float = h + 0.4 + i * 0.4
		_add_emissive_box(r, Vector3(0.28, 0.06, 0.28), Vector3(0, y_pos, 0), accent, 2.0)
	# Dual top spheres
	_add_muzzle_sphere(r, 0.16, Vector3(0, h + 1.9, 0), accent, 4.0)
	_add_muzzle_sphere(r, 0.08, Vector3(0.15, h + 1.7, 0), accent, 2.5)
	_add_muzzle_sphere(r, 0.08, Vector3(-0.15, h + 1.7, 0), accent, 2.5)
	# Side capacitors
	_add_box(r, Vector3(0.08, 0.3, 0.08), Vector3(0.2, h + 0.5, 0), c.darkened(0.2))
	_add_box(r, Vector3(0.08, 0.3, 0.08), Vector3(-0.2, h + 0.5, 0), c.darkened(0.2))
	_add_emissive_box(r, Vector3(0.3, 0.04, 0.3), Vector3(0, h + 1.82, 0), accent, 1.5)
	return r

static func _create_tesla_coil_t3(c: Color) -> Node3D:
	var r := Node3D.new()
	r.name = "Visual"
	var accent := Color(0.6, 0.4, 1.0)
	var h := _add_tower_pedestal(r, 0.35, 0.65, c)
	# Heavy shaft with armor
	_add_cylinder(r, 0.12, 2.0, Vector3(0, h + 1.0, 0), c)
	_add_box(r, Vector3(0.3, 0.4, 0.3), Vector3(0, h + 0.2, 0), c.darkened(0.2))
	# 5 large coil rings
	for i in range(5):
		var y_pos: float = h + 0.5 + i * 0.35
		_add_emissive_box(r, Vector3(0.35, 0.07, 0.35), Vector3(0, y_pos, 0), accent, 2.5)
	# Tesla sphere (larger, brighter)
	_add_muzzle_sphere(r, 0.22, Vector3(0, h + 2.15, 0), accent, 5.0)
	# 3 orbiting sub-nodes
	for angle_i in range(3):
		var angle: float = angle_i * TAU / 3.0
		var ox: float = cos(angle) * 0.2
		var oz: float = sin(angle) * 0.2
		_add_muzzle_sphere(r, 0.07, Vector3(ox, h + 1.95, oz), accent, 3.0)
	# Side pylons
	_add_box(r, Vector3(0.1, 0.6, 0.1), Vector3(0.25, h + 0.6, 0), c.darkened(0.15))
	_add_box(r, Vector3(0.1, 0.6, 0.1), Vector3(-0.25, h + 0.6, 0), c.darkened(0.15))
	_add_emissive_sphere(r, 0.05, Vector3(0.25, h + 0.95, 0), accent, 2.0)
	_add_emissive_sphere(r, 0.05, Vector3(-0.25, h + 0.95, 0), accent, 2.0)
	_add_emissive_box(r, Vector3(0.36, 0.04, 0.36), Vector3(0, h + 2.22, 0), accent, 2.0)
	_add_emissive_box(r, Vector3(0.36, 0.04, 0.36), Vector3(0, h + 0.05, 0), accent, 2.0)
	return r

# --- Inferno Tower Tiers ---
static func _create_inferno_tower_t2(c: Color) -> Node3D:
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.25)
	var flame := Color(1.0, 0.4, 0.1)
	var h := _add_tower_pedestal(r, 0.3, 0.65, c)
	# Wider body
	_add_cylinder(r, 0.2, 1.2, Vector3(0, h + 0.6, 0), c)
	# Heat vents (4 sides)
	for pos in [Vector3(0.22, h + 0.5, 0), Vector3(-0.22, h + 0.5, 0), Vector3(0, h + 0.5, 0.22), Vector3(0, h + 0.5, -0.22)]:
		_add_emissive_box(r, Vector3(0.04, 0.3, 0.04), pos, flame, 2.0)
	# Dual lens assembly
	_add_cylinder(r, 0.1, 0.3, Vector3(0.08, h + 1.25, 0.15), c.lightened(0.1))
	_add_cylinder(r, 0.1, 0.3, Vector3(-0.08, h + 1.25, 0.15), c.lightened(0.1))
	_add_muzzle_sphere(r, 0.08, Vector3(0.08, h + 1.4, 0.15), flame, 4.0)
	_add_muzzle_sphere(r, 0.08, Vector3(-0.08, h + 1.4, 0.15), flame, 4.0)
	# Heat core
	_add_emissive_sphere(r, 0.1, Vector3(0, h + 0.8, 0), flame, 2.5)
	_add_emissive_box(r, Vector3(0.25, 0.04, 0.25), Vector3(0, h + 1.22, 0), flame, 1.5)
	return r

static func _create_inferno_tower_t3(c: Color) -> Node3D:
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.2)
	var flame := Color(1.0, 0.3, 0.05)
	var h := _add_tower_pedestal(r, 0.35, 0.75, c)
	# Heavy armored body
	_add_cylinder(r, 0.25, 0.5, Vector3(0, h + 0.25, 0), dark)
	_add_cylinder(r, 0.2, 1.0, Vector3(0, h + 0.75, 0), c)
	# 6 heat vents around body
	for angle_i in range(6):
		var angle: float = angle_i * TAU / 6.0
		var vx: float = cos(angle) * 0.26
		var vz: float = sin(angle) * 0.26
		_add_emissive_box(r, Vector3(0.04, 0.35, 0.04), Vector3(vx, h + 0.6, vz), flame, 2.5)
	# Triple lens cannon
	_add_cylinder(r, 0.08, 0.35, Vector3(0, h + 1.35, 0.18), c.lightened(0.15))
	_add_cylinder(r, 0.06, 0.35, Vector3(0.1, h + 1.3, 0.15), c.lightened(0.1))
	_add_cylinder(r, 0.06, 0.35, Vector3(-0.1, h + 1.3, 0.15), c.lightened(0.1))
	_add_muzzle_sphere(r, 0.1, Vector3(0, h + 1.55, 0.18), flame, 5.0)
	_add_muzzle_sphere(r, 0.06, Vector3(0.1, h + 1.5, 0.15), flame, 3.0)
	_add_muzzle_sphere(r, 0.06, Vector3(-0.1, h + 1.5, 0.15), flame, 3.0)
	# Reactor core
	_add_emissive_sphere(r, 0.14, Vector3(0, h + 0.5, 0), flame, 3.5)
	_add_emissive_box(r, Vector3(0.3, 0.04, 0.3), Vector3(0, h + 1.26, 0), flame, 2.0)
	_add_emissive_box(r, Vector3(0.3, 0.04, 0.3), Vector3(0, h + 0.05, 0), flame, 2.0)
	return r

# --- Repair Tower Tiers ---
static func _create_repair_tower_t2(c: Color) -> Node3D:
	var r := Node3D.new()
	r.name = "Visual"
	var accent := Color(0.2, 1.0, 0.3)
	var h := _add_tower_pedestal(r, 0.3, 0.6, c)
	_add_cylinder(r, 0.18, 0.8, Vector3(0, h + 0.4, 0), c)
	# Wider dish
	_add_cylinder(r, 0.3, 0.06, Vector3(0, h + 0.85, 0), c.lightened(0.2))
	_add_emissive_sphere(r, 0.12, Vector3(0, h + 0.92, 0), accent, 3.0)
	# 4 nanite emitters
	for pos in [Vector3(0.25, h + 0.7, 0), Vector3(-0.25, h + 0.7, 0), Vector3(0, h + 0.7, 0.25), Vector3(0, h + 0.7, -0.25)]:
		_add_emissive_sphere(r, 0.05, pos, accent, 2.0)
	_add_emissive_box(r, Vector3(0.22, 0.04, 0.22), Vector3(0, h + 0.82, 0), accent, 1.5)
	return r

static func _create_repair_tower_t3(c: Color) -> Node3D:
	var r := Node3D.new()
	r.name = "Visual"
	var accent := Color(0.1, 1.0, 0.5)
	var h := _add_tower_pedestal(r, 0.35, 0.7, c)
	_add_cylinder(r, 0.22, 1.0, Vector3(0, h + 0.5, 0), c)
	# Large dish with ring
	_add_cylinder(r, 0.38, 0.07, Vector3(0, h + 1.05, 0), c.lightened(0.2))
	_add_emissive_sphere(r, 0.16, Vector3(0, h + 1.15, 0), accent, 4.0)
	# Orbiting nanite projectors
	for angle_i in range(6):
		var angle: float = angle_i * TAU / 6.0
		var ox: float = cos(angle) * 0.3
		var oz: float = sin(angle) * 0.3
		_add_emissive_sphere(r, 0.05, Vector3(ox, h + 0.9, oz), accent, 2.5)
	_add_emissive_box(r, Vector3(0.3, 0.04, 0.3), Vector3(0, h + 1.08, 0), accent, 2.0)
	_add_emissive_box(r, Vector3(0.3, 0.04, 0.3), Vector3(0, h + 0.05, 0), accent, 2.0)
	return r

# --- War Beacon Tiers ---
static func _create_war_beacon_t2(c: Color) -> Node3D:
	var r := Node3D.new()
	r.name = "Visual"
	var accent := Color(1.0, 0.3, 0.2)
	var h := _add_tower_pedestal(r, 0.3, 0.6, c)
	_add_box(r, Vector3(0.25, 1.4, 0.25), Vector3(0, h + 0.7, 0), c)
	# Larger pulsing sphere
	_add_emissive_sphere(r, 0.18, Vector3(0, h + 1.5, 0), accent, 4.0)
	# Cross arms with emitters
	_add_box(r, Vector3(0.5, 0.06, 0.06), Vector3(0, h + 1.2, 0), c.darkened(0.2))
	_add_box(r, Vector3(0.06, 0.06, 0.5), Vector3(0, h + 1.2, 0), c.darkened(0.2))
	for pos in [Vector3(0.25, h + 1.2, 0), Vector3(-0.25, h + 1.2, 0), Vector3(0, h + 1.2, 0.25), Vector3(0, h + 1.2, -0.25)]:
		_add_emissive_sphere(r, 0.04, pos, accent, 2.5)
	_add_emissive_box(r, Vector3(0.26, 0.04, 0.26), Vector3(0, h + 1.42, 0), accent, 1.5)
	return r

static func _create_war_beacon_t3(c: Color) -> Node3D:
	var r := Node3D.new()
	r.name = "Visual"
	var accent := Color(1.0, 0.2, 0.1)
	var h := _add_tower_pedestal(r, 0.35, 0.7, c)
	_add_box(r, Vector3(0.3, 1.6, 0.3), Vector3(0, h + 0.8, 0), c)
	# Large beacon sphere
	_add_emissive_sphere(r, 0.24, Vector3(0, h + 1.75, 0), accent, 5.0)
	# Dual cross arms
	_add_box(r, Vector3(0.6, 0.08, 0.08), Vector3(0, h + 1.0, 0), c.darkened(0.15))
	_add_box(r, Vector3(0.08, 0.08, 0.6), Vector3(0, h + 1.0, 0), c.darkened(0.15))
	_add_box(r, Vector3(0.5, 0.06, 0.06), Vector3(0, h + 1.4, 0), c.darkened(0.2))
	_add_box(r, Vector3(0.06, 0.06, 0.5), Vector3(0, h + 1.4, 0), c.darkened(0.2))
	for pos in [Vector3(0.3, h + 1.0, 0), Vector3(-0.3, h + 1.0, 0), Vector3(0, h + 1.0, 0.3), Vector3(0, h + 1.0, -0.3)]:
		_add_emissive_sphere(r, 0.05, pos, accent, 3.0)
	_add_emissive_box(r, Vector3(0.31, 0.04, 0.31), Vector3(0, h + 1.62, 0), accent, 2.0)
	_add_emissive_box(r, Vector3(0.31, 0.04, 0.31), Vector3(0, h + 0.05, 0), accent, 2.0)
	return r

# --- Targeting Array Tiers ---
static func _create_targeting_array_t2(c: Color) -> Node3D:
	var r := Node3D.new()
	r.name = "Visual"
	var accent := Color(0.2, 0.7, 1.0)
	var h := _add_tower_pedestal(r, 0.3, 0.6, c)
	_add_box(r, Vector3(0.2, 1.4, 0.2), Vector3(0, h + 0.7, 0), c)
	# Larger radar dish
	_add_cylinder(r, 0.28, 0.04, Vector3(0, h + 1.45, 0.1), c.lightened(0.2))
	_add_cylinder(r, 0.03, 0.2, Vector3(0, h + 1.35, 0.1), c.lightened(0.1))
	_add_emissive_sphere(r, 0.1, Vector3(0, h + 1.5, 0.1), accent, 3.0)
	# Side scanner arms
	_add_box(r, Vector3(0.4, 0.04, 0.04), Vector3(0, h + 1.1, 0), c.darkened(0.2))
	_add_emissive_sphere(r, 0.04, Vector3(0.2, h + 1.1, 0), accent, 2.0)
	_add_emissive_sphere(r, 0.04, Vector3(-0.2, h + 1.1, 0), accent, 2.0)
	_add_emissive_box(r, Vector3(0.22, 0.04, 0.22), Vector3(0, h + 1.42, 0), accent, 1.5)
	return r

static func _create_targeting_array_t3(c: Color) -> Node3D:
	var r := Node3D.new()
	r.name = "Visual"
	var accent := Color(0.1, 0.8, 1.0)
	var h := _add_tower_pedestal(r, 0.35, 0.7, c)
	_add_box(r, Vector3(0.25, 1.6, 0.25), Vector3(0, h + 0.8, 0), c)
	# Dual radar dishes
	_add_cylinder(r, 0.24, 0.04, Vector3(0.12, h + 1.6, 0.12), c.lightened(0.2))
	_add_cylinder(r, 0.24, 0.04, Vector3(-0.12, h + 1.6, -0.08), c.lightened(0.2))
	_add_cylinder(r, 0.03, 0.15, Vector3(0.12, h + 1.52, 0.12), c.lightened(0.1))
	_add_cylinder(r, 0.03, 0.15, Vector3(-0.12, h + 1.52, -0.08), c.lightened(0.1))
	_add_emissive_sphere(r, 0.08, Vector3(0.12, h + 1.66, 0.12), accent, 3.5)
	_add_emissive_sphere(r, 0.08, Vector3(-0.12, h + 1.66, -0.08), accent, 3.5)
	# Cross scanner arms
	_add_box(r, Vector3(0.5, 0.05, 0.05), Vector3(0, h + 1.2, 0), c.darkened(0.15))
	_add_box(r, Vector3(0.05, 0.05, 0.5), Vector3(0, h + 1.2, 0), c.darkened(0.15))
	for pos in [Vector3(0.25, h + 1.2, 0), Vector3(-0.25, h + 1.2, 0), Vector3(0, h + 1.2, 0.25), Vector3(0, h + 1.2, -0.25)]:
		_add_emissive_sphere(r, 0.04, pos, accent, 2.5)
	_add_emissive_box(r, Vector3(0.26, 0.04, 0.26), Vector3(0, h + 1.62, 0), accent, 2.0)
	_add_emissive_box(r, Vector3(0.26, 0.04, 0.26), Vector3(0, h + 0.05, 0), accent, 2.0)
	return r

# --- Shield Pylon Tiers ---
static func _create_shield_pylon_t2(c: Color) -> Node3D:
	var r := Node3D.new()
	r.name = "Visual"
	var accent := Color(0.4, 0.4, 1.0)
	var h := _add_tower_pedestal(r, 0.3, 0.65, c)
	_add_cylinder(r, 0.15, 1.2, Vector3(0, h + 0.6, 0), c)
	# Wider shield emitter ring
	_add_emissive_box(r, Vector3(0.45, 0.08, 0.45), Vector3(0, h + 1.25, 0), accent, 2.0)
	_add_emissive_sphere(r, 0.14, Vector3(0, h + 1.4, 0), accent, 3.5)
	# 4 support struts
	for pos in [Vector3(0.18, h + 0.8, 0), Vector3(-0.18, h + 0.8, 0), Vector3(0, h + 0.8, 0.18), Vector3(0, h + 0.8, -0.18)]:
		_add_box(r, Vector3(0.06, 0.5, 0.06), pos, c.darkened(0.2))
	_add_emissive_box(r, Vector3(0.2, 0.04, 0.2), Vector3(0, h + 1.35, 0), accent, 1.5)
	return r

static func _create_shield_pylon_t3(c: Color) -> Node3D:
	var r := Node3D.new()
	r.name = "Visual"
	var accent := Color(0.5, 0.4, 1.0)
	var h := _add_tower_pedestal(r, 0.35, 0.75, c)
	_add_cylinder(r, 0.18, 1.4, Vector3(0, h + 0.7, 0), c)
	_add_box(r, Vector3(0.35, 0.3, 0.35), Vector3(0, h + 0.15, 0), c.darkened(0.2))
	# Dual emitter rings
	_add_emissive_box(r, Vector3(0.5, 0.08, 0.5), Vector3(0, h + 1.1, 0), accent, 2.0)
	_add_emissive_box(r, Vector3(0.4, 0.06, 0.4), Vector3(0, h + 1.45, 0), accent, 2.5)
	_add_emissive_sphere(r, 0.18, Vector3(0, h + 1.6, 0), accent, 4.5)
	# 6 support struts
	for angle_i in range(6):
		var angle: float = angle_i * TAU / 6.0
		var sx: float = cos(angle) * 0.22
		var sz: float = sin(angle) * 0.22
		_add_box(r, Vector3(0.05, 0.6, 0.05), Vector3(sx, h + 0.7, sz), c.darkened(0.15))
	_add_emissive_box(r, Vector3(0.3, 0.04, 0.3), Vector3(0, h + 1.55, 0), accent, 2.0)
	_add_emissive_box(r, Vector3(0.3, 0.04, 0.3), Vector3(0, h + 0.05, 0), accent, 2.0)
	return r

# --- Leach Tower Tiers ---
static func _create_leach_tower_t2(c: Color) -> Node3D:
	var r := Node3D.new()
	r.name = "Visual"
	var accent := Color(0.3, 0.9, 0.2)
	var h := _add_tower_pedestal(r, 0.3, 0.6, c)
	_add_cylinder(r, 0.18, 1.0, Vector3(0, h + 0.5, 0), c)
	# Wider claw assembly
	_add_box(r, Vector3(0.35, 0.08, 0.35), Vector3(0, h + 1.05, 0), c.lightened(0.1))
	# 4 claws
	for pos in [Vector3(0.15, h + 1.15, 0.15), Vector3(-0.15, h + 1.15, 0.15), Vector3(0.15, h + 1.15, -0.15), Vector3(-0.15, h + 1.15, -0.15)]:
		_add_box(r, Vector3(0.04, 0.2, 0.04), pos, c.lightened(0.2))
	_add_emissive_sphere(r, 0.1, Vector3(0, h + 1.1, 0), accent, 3.0)
	_add_emissive_box(r, Vector3(0.2, 0.04, 0.2), Vector3(0, h + 1.02, 0), accent, 1.5)
	return r

static func _create_leach_tower_t3(c: Color) -> Node3D:
	var r := Node3D.new()
	r.name = "Visual"
	var accent := Color(0.2, 1.0, 0.3)
	var h := _add_tower_pedestal(r, 0.35, 0.7, c)
	_add_cylinder(r, 0.22, 1.2, Vector3(0, h + 0.6, 0), c)
	# Heavy claw ring
	_add_box(r, Vector3(0.45, 0.1, 0.45), Vector3(0, h + 1.25, 0), c.lightened(0.1))
	# 6 claws
	for angle_i in range(6):
		var angle: float = angle_i * TAU / 6.0
		var cx: float = cos(angle) * 0.2
		var cz: float = sin(angle) * 0.2
		_add_box(r, Vector3(0.04, 0.25, 0.04), Vector3(cx, h + 1.38, cz), c.lightened(0.2))
	_add_emissive_sphere(r, 0.14, Vector3(0, h + 1.3, 0), accent, 4.0)
	# Processing tanks
	_add_cylinder(r, 0.08, 0.3, Vector3(0.2, h + 0.3, 0), c.darkened(0.2))
	_add_cylinder(r, 0.08, 0.3, Vector3(-0.2, h + 0.3, 0), c.darkened(0.2))
	_add_emissive_box(r, Vector3(0.26, 0.04, 0.26), Vector3(0, h + 1.22, 0), accent, 2.0)
	_add_emissive_box(r, Vector3(0.26, 0.04, 0.26), Vector3(0, h + 0.05, 0), accent, 2.0)
	return r

# --- Thermal Siphon Tiers ---
static func _create_thermal_siphon_t2(c: Color) -> Node3D:
	var r := Node3D.new()
	r.name = "Visual"
	var energy := Color(0.2, 0.9, 1.0)
	var h := _add_tower_pedestal(r, 0.3, 0.6, c)
	_add_cylinder(r, 0.22, 0.7, Vector3(0, h + 0.35, 0), c)
	# 4 heat pipes
	for pos in [Vector3(0.16, h + 0.7, 0), Vector3(-0.16, h + 0.7, 0), Vector3(0, h + 0.7, 0.16), Vector3(0, h + 0.7, -0.16)]:
		_add_cylinder(r, 0.03, 0.5, pos, c.lightened(0.1))
	# Larger collector dish
	_add_cylinder(r, 0.28, 0.05, Vector3(0, h + 0.98, 0), c.lightened(0.2))
	_add_emissive_sphere(r, 0.12, Vector3(0, h + 1.05, 0), energy, 4.0)
	# More thermal vents
	for angle_i in range(4):
		var angle: float = angle_i * TAU / 4.0
		var vx: float = cos(angle) * 0.24
		var vz: float = sin(angle) * 0.24
		_add_emissive_box(r, Vector3(0.04, 0.25, 0.04), Vector3(vx, h + 0.4, vz), energy, 1.5)
	_add_emissive_box(r, Vector3(0.24, 0.04, 0.24), Vector3(0, h + 0.93, 0), energy, 1.5)
	return r

static func _create_thermal_siphon_t3(c: Color) -> Node3D:
	var r := Node3D.new()
	r.name = "Visual"
	var energy := Color(0.1, 1.0, 1.0)
	var h := _add_tower_pedestal(r, 0.35, 0.7, c)
	_add_cylinder(r, 0.25, 0.8, Vector3(0, h + 0.4, 0), c)
	# 6 heat pipes
	for angle_i in range(6):
		var angle: float = angle_i * TAU / 6.0
		var px: float = cos(angle) * 0.2
		var pz: float = sin(angle) * 0.2
		_add_cylinder(r, 0.03, 0.55, Vector3(px, h + 0.75, pz), c.lightened(0.1))
	# Large collector + focusing ring
	_add_cylinder(r, 0.35, 0.06, Vector3(0, h + 1.08, 0), c.lightened(0.2))
	_add_emissive_sphere(r, 0.16, Vector3(0, h + 1.18, 0), energy, 5.0)
	# Thermal vents (6)
	for angle_i in range(6):
		var angle: float = angle_i * TAU / 6.0
		var vx: float = cos(angle) * 0.28
		var vz: float = sin(angle) * 0.28
		_add_emissive_box(r, Vector3(0.04, 0.3, 0.04), Vector3(vx, h + 0.45, vz), energy, 2.0)
	_add_emissive_box(r, Vector3(0.3, 0.04, 0.3), Vector3(0, h + 1.05, 0), energy, 2.0)
	_add_emissive_box(r, Vector3(0.3, 0.04, 0.3), Vector3(0, h + 0.05, 0), energy, 2.0)
	return r

static func _create_solar_array(c: Color) -> Node3D:
	## Solar Array (2x2): Low profile solar farm with tracking panels and power conduits
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.3)
	var accent := Color(1.0, 0.8, 0.1)
	# Low flat structure - no pedestal
	# Base platform
	_add_box(r, Vector3(1.8, 0.1, 1.8), Vector3(0, 0.05, 0), dark)
	# 4 solar panels
	for pos in [Vector3(-0.45, 0.3, -0.45), Vector3(0.45, 0.3, -0.45), Vector3(-0.45, 0.3, 0.45), Vector3(0.45, 0.3, 0.45)]:
		_add_box(r, Vector3(0.8, 0.03, 0.8), pos, c)
		_add_emissive_box(r, Vector3(0.7, 0.01, 0.7), Vector3(pos.x, pos.y + 0.02, pos.z), accent, 0.8)
	# Central power hub
	_add_box(r, Vector3(0.3, 0.25, 0.3), Vector3(0, 0.225, 0), c.lightened(0.1))
	_add_emissive_sphere(r, 0.08, Vector3(0, 0.35, 0), accent, 2.5)
	return r


# --- Solar Array Tiers ---
static func _create_solar_array_t2(c: Color) -> Node3D:
	var r := Node3D.new()
	r.name = "Visual"
	var accent := Color(1.0, 0.85, 0.1)
	# Low flat structure - no pedestal
	# Base platform
	_add_box(r, Vector3(2.2, 0.15, 2.2), Vector3(0, 0.075, 0), c.darkened(0.3))
	# 4 solar panels (angled)
	for pos in [Vector3(-0.55, 0.4, -0.55), Vector3(0.55, 0.4, -0.55), Vector3(-0.55, 0.4, 0.55), Vector3(0.55, 0.4, 0.55)]:
		_add_box(r, Vector3(0.9, 0.04, 0.9), pos, c)
		_add_emissive_box(r, Vector3(0.8, 0.02, 0.8), Vector3(pos.x, pos.y + 0.03, pos.z), accent, 1.0)
	# Central power hub
	_add_box(r, Vector3(0.4, 0.3, 0.4), Vector3(0, 0.3, 0), c.lightened(0.1))
	_add_emissive_sphere(r, 0.1, Vector3(0, 0.5, 0), accent, 3.0)
	return r

static func _create_solar_array_t3(c: Color) -> Node3D:
	var r := Node3D.new()
	r.name = "Visual"
	var accent := Color(1.0, 0.9, 0.2)
	# Base platform
	_add_box(r, Vector3(2.4, 0.2, 2.4), Vector3(0, 0.1, 0), c.darkened(0.25))
	# 4 large panels with supports
	for pos in [Vector3(-0.6, 0.5, -0.6), Vector3(0.6, 0.5, -0.6), Vector3(-0.6, 0.5, 0.6), Vector3(0.6, 0.5, 0.6)]:
		_add_box(r, Vector3(0.06, 0.35, 0.06), Vector3(pos.x, 0.25, pos.z), c.darkened(0.2))
		_add_box(r, Vector3(1.0, 0.05, 1.0), pos, c)
		_add_emissive_box(r, Vector3(0.9, 0.02, 0.9), Vector3(pos.x, pos.y + 0.04, pos.z), accent, 1.5)
	# Heavy central hub
	_add_box(r, Vector3(0.5, 0.4, 0.5), Vector3(0, 0.4, 0), c.lightened(0.1))
	_add_emissive_sphere(r, 0.14, Vector3(0, 0.65, 0), accent, 4.0)
	# Capacitor banks
	_add_box(r, Vector3(0.15, 0.25, 0.15), Vector3(0.3, 0.25, 0), c.darkened(0.15))
	_add_box(r, Vector3(0.15, 0.25, 0.15), Vector3(-0.3, 0.25, 0), c.darkened(0.15))
	_add_emissive_box(r, Vector3(0.51, 0.04, 0.51), Vector3(0, 0.61, 0), accent, 2.0)
	_add_emissive_box(r, Vector3(0.51, 0.04, 0.51), Vector3(0, 0.21, 0), accent, 2.0)
	return r


# --- Recycler (4x4 material generator) ---

static func _create_recycler(c: Color) -> Node3D:
	## Recycler (4x4): industrial material processor with conveyor and hopper
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.3)
	var accent := Color(0.3, 0.9, 0.3)
	# Foundation platform
	_add_box(r, Vector3(3.6, 0.2, 3.6), Vector3(0, 0.1, 0), dark)
	# Main processing building
	_add_box(r, Vector3(2.4, 1.0, 2.4), Vector3(0, 0.7, 0), c)
	# Roof
	_add_box(r, Vector3(2.5, 0.08, 2.5), Vector3(0, 1.24, 0), dark)
	# Hopper (intake funnel on top)
	_add_box(r, Vector3(1.2, 0.5, 1.2), Vector3(0, 1.53, 0), dark)
	_add_box(r, Vector3(1.4, 0.08, 1.4), Vector3(0, 1.82, 0), c.lightened(0.1))
	# Conveyor belts on sides
	_add_box(r, Vector3(3.2, 0.1, 0.5), Vector3(0, 0.25, 1.3), dark)
	_add_box(r, Vector3(3.2, 0.1, 0.5), Vector3(0, 0.25, -1.3), dark)
	# Output chute
	_add_box(r, Vector3(0.6, 0.4, 0.8), Vector3(1.3, 0.4, 0), dark)
	# Status lights
	_add_emissive_sphere(r, 0.06, Vector3(1.2, 1.0, 1.2), accent, 2.0)
	_add_emissive_sphere(r, 0.06, Vector3(-1.2, 1.0, 1.2), accent, 2.0)
	# Processing glow inside hopper
	_add_emissive_sphere(r, 0.15, Vector3(0, 1.5, 0), accent, 2.5)
	return r


static func _create_recycler_t2(c: Color) -> Node3D:
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.3)
	var accent := Color(0.4, 1.0, 0.4)
	# Foundation platform (same footprint as T1)
	_add_box(r, Vector3(3.6, 0.25, 3.6), Vector3(0, 0.125, 0), dark)
	# Main processing building (taller, same width)
	_add_box(r, Vector3(2.4, 1.3, 2.4), Vector3(0, 0.9, 0), c)
	# Roof
	_add_box(r, Vector3(2.5, 0.1, 2.5), Vector3(0, 1.6, 0), dark)
	# Dual hoppers
	_add_box(r, Vector3(0.9, 0.5, 0.9), Vector3(-0.5, 1.85, 0), dark)
	_add_box(r, Vector3(0.9, 0.5, 0.9), Vector3(0.5, 1.85, 0), dark)
	_add_box(r, Vector3(1.0, 0.08, 1.0), Vector3(-0.5, 2.14, 0), c.lightened(0.1))
	_add_box(r, Vector3(1.0, 0.08, 1.0), Vector3(0.5, 2.14, 0), c.lightened(0.1))
	# Conveyor belts (same footprint as T1)
	_add_box(r, Vector3(3.2, 0.12, 0.5), Vector3(0, 0.3, 1.3), dark)
	_add_box(r, Vector3(3.2, 0.12, 0.5), Vector3(0, 0.3, -1.3), dark)
	# Output chutes (both sides)
	_add_box(r, Vector3(0.6, 0.5, 0.8), Vector3(1.3, 0.5, 0), dark)
	_add_box(r, Vector3(0.6, 0.5, 0.8), Vector3(-1.3, 0.5, 0), dark)
	# Status lights (all 4 corners)
	_add_emissive_sphere(r, 0.07, Vector3(1.2, 1.3, 1.2), accent, 2.5)
	_add_emissive_sphere(r, 0.07, Vector3(-1.2, 1.3, 1.2), accent, 2.5)
	_add_emissive_sphere(r, 0.07, Vector3(1.2, 1.3, -1.2), accent, 2.5)
	_add_emissive_sphere(r, 0.07, Vector3(-1.2, 1.3, -1.2), accent, 2.5)
	# Processing glow
	_add_emissive_sphere(r, 0.18, Vector3(-0.5, 1.8, 0), accent, 3.0)
	_add_emissive_sphere(r, 0.18, Vector3(0.5, 1.8, 0), accent, 3.0)
	return r


static func _create_recycler_t3(c: Color) -> Node3D:
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.25)
	var accent := Color(0.5, 1.0, 0.5)
	# Foundation platform (same footprint as T1)
	_add_box(r, Vector3(3.6, 0.3, 3.6), Vector3(0, 0.15, 0), dark)
	# Main processing building (tallest, same width)
	_add_box(r, Vector3(2.4, 1.6, 2.4), Vector3(0, 1.1, 0), c)
	# Roof
	_add_box(r, Vector3(2.5, 0.12, 2.5), Vector3(0, 1.96, 0), dark)
	# Large central hopper
	_add_box(r, Vector3(1.2, 0.6, 1.2), Vector3(0, 2.26, 0), dark)
	_add_box(r, Vector3(1.4, 0.1, 1.4), Vector3(0, 2.61, 0), c.lightened(0.1))
	# Conveyor belts (same footprint as T1)
	_add_box(r, Vector3(3.2, 0.15, 0.5), Vector3(0, 0.35, 1.3), dark)
	_add_box(r, Vector3(3.2, 0.15, 0.5), Vector3(0, 0.35, -1.3), dark)
	# Heavy output chutes
	_add_box(r, Vector3(0.6, 0.6, 0.8), Vector3(1.3, 0.6, 0), dark)
	_add_box(r, Vector3(0.6, 0.6, 0.8), Vector3(-1.3, 0.6, 0), dark)
	# Exhaust stacks
	_add_cylinder(r, 0.08, 0.5, Vector3(1.0, 2.21, 1.0), dark)
	_add_cylinder(r, 0.08, 0.5, Vector3(-1.0, 2.21, -1.0), dark)
	# Corner status lights
	_add_emissive_sphere(r, 0.08, Vector3(1.2, 1.7, 1.2), accent, 3.0)
	_add_emissive_sphere(r, 0.08, Vector3(-1.2, 1.7, 1.2), accent, 3.0)
	_add_emissive_sphere(r, 0.08, Vector3(1.2, 1.7, -1.2), accent, 3.0)
	_add_emissive_sphere(r, 0.08, Vector3(-1.2, 1.7, -1.2), accent, 3.0)
	# Processing glow
	_add_emissive_sphere(r, 0.25, Vector3(0, 2.2, 0), accent, 4.0)
	# Capacitor banks on sides
	_add_box(r, Vector3(0.2, 0.4, 0.2), Vector3(1.0, 0.5, 1.0), c.darkened(0.15))
	_add_box(r, Vector3(0.2, 0.4, 0.2), Vector3(-1.0, 0.5, -1.0), c.darkened(0.15))
	_add_emissive_box(r, Vector3(2.41, 0.04, 2.41), Vector3(0, 1.0, 0), accent, 1.5)
	return r


# =============================================================================
# PRODUCTION BUILDINGS
# =============================================================================

static func _create_drone_printer(c: Color) -> Node3D:
	## Drone factory (2x2): Enhanced compact industrial fabrication unit with landing pad, robotic arms, green status lights
	## Based on design: "Compact industrial fabrication unit with a flat top landing pad where drones are assembled 
	## and launched. Robotic arms visible through transparent panels assembling components. Green status lights along 
	## the base. Drones lift off from the top pad when production completes. Antenna array on one side for drone 
	## command signals. Military grey with green accent lighting. Hums with a soft mechanical whir when active."
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.3)
	var lite := c.lightened(0.15)
	var green := Color(0.2, 1.0, 0.3)  # Green accent lighting
	var military_grey := Color(0.25, 0.25, 0.25)
	
	# Foundation
	_add_box(r, Vector3(1.8, 0.15, 1.8), Vector3(0, 0.075, 0), dark)
	
	# Main building (compact industrial unit) - military grey as specified
	_add_box(r, Vector3(1.5, 0.7, 1.5), Vector3(0, 0.525, 0), military_grey)
	
	# Reinforced corners and structural details
	for corner_x in [-0.7, 0.7]:
		for corner_z in [-0.7, 0.7]:
			_add_box(r, Vector3(0.08, 0.75, 0.08), Vector3(corner_x, 0.525, corner_z), dark)
	
	# Top landing pad (flat fabrication surface) where drones launch
	_add_box(r, Vector3(1.6, 0.05, 1.6), Vector3(0, 0.925, 0), lite)
	_add_box(r, Vector3(1.2, 0.02, 1.2), Vector3(0, 0.96, 0), green.darkened(0.4))  # Landing grid
	
	# Landing pad grid markings for drone assembly positioning
	for i in range(4):
		var offset: float = -0.45 + i * 0.3
		_add_emissive_box(r, Vector3(1.0, 0.005, 0.02), Vector3(0, 0.965, offset), green, 0.8)
		_add_emissive_box(r, Vector3(0.02, 0.005, 1.0), Vector3(offset, 0.965, 0), green, 0.8)
	
	# Transparent panels showing robotic arms inside assembling components
	_add_emissive_box(r, Vector3(0.6, 0.3, 0.04), Vector3(0, 0.65, 0.76), Color(0.4, 0.8, 0.9), 0.8)
	_add_emissive_box(r, Vector3(0.6, 0.3, 0.04), Vector3(0, 0.65, -0.76), Color(0.4, 0.8, 0.9), 0.8)
	_add_emissive_box(r, Vector3(0.04, 0.3, 0.6), Vector3(0.76, 0.65, 0), Color(0.4, 0.8, 0.9), 0.8)
	_add_emissive_box(r, Vector3(0.04, 0.3, 0.6), Vector3(-0.76, 0.65, 0), Color(0.4, 0.8, 0.9), 0.8)
	
	# Panel frame details
	_add_box(r, Vector3(0.65, 0.04, 0.04), Vector3(0, 0.5, 0.78), dark)
	_add_box(r, Vector3(0.65, 0.04, 0.04), Vector3(0, 0.8, 0.78), dark)
	_add_box(r, Vector3(0.04, 0.04, 0.65), Vector3(0.78, 0.5, 0), dark)
	_add_box(r, Vector3(0.04, 0.04, 0.65), Vector3(0.78, 0.8, 0), dark)
	
	# Robotic arms visible through panels (with articulated joints for assembly)
	var arm_1 := Node3D.new()
	arm_1.name = "RoboticArm1"
	arm_1.position = Vector3(0.2, 0.6, 0.4)
	r.add_child(arm_1)
	_add_box(arm_1, Vector3(0.06, 0.2, 0.06), Vector3(0, 0, 0), lite)  # Base joint
	_add_box(arm_1, Vector3(0.15, 0.04, 0.04), Vector3(0.075, 0.1, 0.02), lite)  # Upper arm
	_add_cylinder(arm_1, 0.02, 0.08, Vector3(0.15, 0.1, 0.02), lite.lightened(0.1))  # End effector
	_add_emissive_sphere(arm_1, 0.015, Vector3(0.15, 0.14, 0.02), Color(0.9, 0.5, 0.2), 1.0)  # Work light
	
	var arm_2 := Node3D.new()
	arm_2.name = "RoboticArm2"
	arm_2.position = Vector3(-0.2, 0.6, 0.4)
	r.add_child(arm_2)
	_add_box(arm_2, Vector3(0.06, 0.2, 0.06), Vector3(0, 0, 0), lite)
	_add_box(arm_2, Vector3(0.15, 0.04, 0.04), Vector3(-0.075, 0.1, 0.02), lite)
	_add_cylinder(arm_2, 0.02, 0.08, Vector3(-0.15, 0.1, 0.02), lite.lightened(0.1))
	_add_emissive_sphere(arm_2, 0.015, Vector3(-0.15, 0.14, 0.02), Color(0.9, 0.5, 0.2), 1.0)
	
	# Antenna array on one side for drone command signals (as specified)
	var antenna_base := Node3D.new()
	antenna_base.name = "AntennaArray"
	antenna_base.position = Vector3(0.6, 1.0, 0.6)
	r.add_child(antenna_base)
	
	_add_cylinder(antenna_base, 0.04, 0.1, Vector3(0, 0.05, 0), dark)  # Base mount
	_add_cylinder(antenna_base, 0.02, 0.25, Vector3(0, 0.175, 0), lite)  # Main mast
	_add_cylinder(antenna_base, 0.015, 0.2, Vector3(-0.1, 0.15, 0.1), lite)  # Side antenna
	_add_cylinder(antenna_base, 0.015, 0.18, Vector3(0.1, 0.14, -0.1), lite)  # Side antenna
	
	# Communication dishes on antennas
	_add_box(antenna_base, Vector3(0.08, 0.08, 0.02), Vector3(0, 0.3, 0), lite)
	_add_box(antenna_base, Vector3(0.06, 0.06, 0.015), Vector3(-0.1, 0.26, 0.1), lite.lightened(0.05))
	_add_box(antenna_base, Vector3(0.06, 0.06, 0.015), Vector3(0.1, 0.25, -0.1), lite.lightened(0.05))
	
	# Antenna signal indicators
	_add_emissive_sphere(antenna_base, 0.02, Vector3(0, 0.32, 0), green, 2.0)
	_add_emissive_sphere(antenna_base, 0.015, Vector3(-0.1, 0.28, 0.1), green, 1.5)
	_add_emissive_sphere(antenna_base, 0.015, Vector3(0.1, 0.27, -0.1), green, 1.5)
	
	# Green status lights along base (as specified)
	_add_emissive_sphere(r, 0.03, Vector3(0.6, 0.3, 0.6), green, 2.0)
	_add_emissive_sphere(r, 0.03, Vector3(-0.6, 0.3, 0.6), green, 2.0)
	_add_emissive_sphere(r, 0.03, Vector3(0.6, 0.3, -0.6), green, 2.0)
	_add_emissive_sphere(r, 0.03, Vector3(-0.6, 0.3, -0.6), green, 2.0)
	
	# Additional status indicators on corners
	_add_emissive_box(r, Vector3(0.08, 0.03, 0.08), Vector3(0.7, 0.42, 0.7), green, 1.5)
	_add_emissive_box(r, Vector3(0.08, 0.03, 0.08), Vector3(-0.7, 0.42, 0.7), green, 1.5)
	_add_emissive_box(r, Vector3(0.08, 0.03, 0.08), Vector3(0.7, 0.42, -0.7), green, 1.5)
	_add_emissive_box(r, Vector3(0.08, 0.03, 0.08), Vector3(-0.7, 0.42, -0.7), green, 1.5)
	
	# Green accent lighting strips (as specified)
	_add_emissive_box(r, Vector3(1.5, 0.02, 0.04), Vector3(0, 0.25, 0.76), green, 1.5)
	_add_emissive_box(r, Vector3(0.04, 0.02, 1.5), Vector3(0.76, 0.25, 0), green, 1.5)
	_add_emissive_box(r, Vector3(1.5, 0.02, 0.04), Vector3(0, 0.25, -0.76), green, 1.5)
	_add_emissive_box(r, Vector3(0.04, 0.02, 1.5), Vector3(-0.76, 0.25, 0), green, 1.5)
	
	# Landing pad edge lights for guidance
	for i in range(8):
		var angle: float = i * TAU / 8.0
		var lx: float = cos(angle) * 0.65
		var lz: float = sin(angle) * 0.65
		_add_emissive_sphere(r, 0.02, Vector3(lx, 0.97, lz), green, 1.8)
	
	# Drone components being assembled on platform
	_add_box(r, Vector3(0.15, 0.03, 0.1), Vector3(0.2, 0.98, 0.15), lite.lightened(0.2))  # Hull piece
	_add_box(r, Vector3(0.1, 0.02, 0.08), Vector3(-0.18, 0.975, -0.12), Color(0.6, 0.6, 0.7))  # Rotor assembly
	_add_sphere(r, 0.03, Vector3(0.05, 1.0, -0.2), green)  # Control core
	
	# Assembly/fabrication work lights and heat signatures
	_add_emissive_sphere(r, 0.02, Vector3(0.15, 0.985, 0.12), Color(1.0, 0.6, 0.2), 1.2)
	_add_emissive_sphere(r, 0.015, Vector3(-0.12, 0.985, -0.08), Color(0.8, 0.4, 1.0), 0.8)
	
	# Internal machinery glimpsed through panels
	_add_box(r, Vector3(0.25, 0.15, 0.25), Vector3(0, 0.4, 0), dark.lightened(0.2))  # Central processor
	_add_emissive_sphere(r, 0.05, Vector3(0, 0.48, 0), green, 1.5)  # Core status
	
	# Ventilation grilles
	for i in range(3):
		var vent_y: float = 0.35 + i * 0.15
		_add_box(r, Vector3(0.8, 0.02, 0.04), Vector3(0, vent_y, -0.78), dark)
		_add_box(r, Vector3(0.04, 0.02, 0.8), Vector3(-0.78, vent_y, 0), dark)
	
	# Enhanced visual details for Task 1A - Advanced Building Atmospherics
	# Add fabrication work lights that pulse during assembly
	for i in range(6):
		var angle: float = i * TAU / 6.0
		var lx: float = cos(angle) * 0.4
		var lz: float = sin(angle) * 0.4
		_add_emissive_sphere(r, 0.015, Vector3(lx, 0.6, lz), Color(0.4, 0.8, 1.0), 1.2)
	
	# Assembly precision guides (high-tech fabrication details)
	_add_emissive_box(r, Vector3(0.8, 0.02, 0.02), Vector3(0, 0.97, 0.6), green, 2.0)
	_add_emissive_box(r, Vector3(0.02, 0.02, 0.8), Vector3(0.6, 0.97, 0), green, 2.0)
	_add_emissive_box(r, Vector3(0.8, 0.02, 0.02), Vector3(0, 0.97, -0.6), green, 2.0)
	_add_emissive_box(r, Vector3(0.02, 0.02, 0.8), Vector3(-0.6, 0.97, 0), green, 2.0)
	
	# Task 1A: Enhanced atmospheric lighting and environmental details
	# Add dynamic holographic build indicators above landing pad
	_add_emissive_box(r, Vector3(0.6, 0.01, 0.6), Vector3(0, 1.02, 0), green.lightened(0.3), 1.0)
	_add_emissive_box(r, Vector3(0.4, 0.01, 0.4), Vector3(0, 1.04, 0), green.lightened(0.5), 0.8)
	
	# Add industrial safety marking strips
	for strip_i in range(4):
		var strip_angle: float = strip_i * TAU / 4.0
		var strip_x: float = cos(strip_angle) * 0.8
		var strip_z: float = sin(strip_angle) * 0.8
		_add_emissive_box(r, Vector3(0.08, 0.02, 0.02), Vector3(strip_x, 0.15, strip_z), Color(1.0, 0.5, 0.0), 1.5)
	
	# Power distribution nodes with circuit patterns
	_add_emissive_box(r, Vector3(0.04, 0.12, 0.04), Vector3(0.7, 0.45, 0.7), green, 2.2)
	_add_emissive_box(r, Vector3(0.04, 0.12, 0.04), Vector3(-0.7, 0.45, -0.7), green, 2.2)
	
	# Environmental atmosphere enhancers
	_add_emissive_sphere(r, 0.01, Vector3(0.4, 0.8, 0.4), Color(0.6, 1.0, 0.8), 0.8)  # Air quality sensor
	_add_emissive_sphere(r, 0.01, Vector3(-0.4, 0.8, -0.4), Color(1.0, 0.6, 0.2), 0.8)  # Temperature sensor
	
	# Store animation nodes for future use
	r.set_meta("robotic_arm1_node", arm_1.get_path())
	r.set_meta("robotic_arm2_node", arm_2.get_path())
	r.set_meta("antenna_array_node", antenna_base.get_path())
	r.set_meta("supports_arm_animation", true)
	r.set_meta("supports_antenna_rotation", true)
	r.set_meta("supports_assembly_glow", true)
	r.set_meta("production_type", "drone")
	r.set_meta("assembly_points", [
		Vector3(0.2, 0.98, 0.15),   # Drone assembly point 1
		Vector3(-0.18, 0.975, -0.12), # Drone assembly point 2
		Vector3(0.05, 1.0, -0.2)    # Control core assembly
	])
	
	return r


static func _create_mech_bay(c: Color) -> Node3D:
	## Heavy factory (3x2): Large industrial hangar with bay door, assembly gantries, blue status lights
	## Based on design: "Large industrial hangar-style building with a wide bay door that opens to deploy finished mechs. 
	## Interior shows assembly gantries, welding sparks, and mech frames in various stages of completion. Heavy reinforced 
	## walls with external armor plating. Blue operational status lights. Smoke and steam vent from exhaust ports during 
	## production. Dark steel construction with blue accent lighting matching Sentinel visors."
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.3)
	var lite := c.lightened(0.15)
	var dark_steel := Color(0.2, 0.2, 0.25)  # Dark steel construction as specified
	var blue := Color(0.2, 0.4, 1.0)  # Blue accent lighting matching Sentinel visors
	
	# Foundation (reinforced)
	_add_box(r, Vector3(2.8, 0.25, 1.8), Vector3(0, 0.125, 0), dark_steel)
	
	# Main hangar building (heavy reinforced walls)
	_add_box(r, Vector3(2.5, 1.3, 1.5), Vector3(0, 0.9, 0), dark_steel)
	
	# External armor plating with rivets
	_add_box(r, Vector3(0.08, 1.0, 1.4), Vector3(1.29, 0.75, 0), dark_steel.darkened(0.2))
	_add_box(r, Vector3(0.08, 1.0, 1.4), Vector3(-1.29, 0.75, 0), dark_steel.darkened(0.2))
	_add_box(r, Vector3(2.4, 0.08, 1.4), Vector3(0, 1.55, 0), dark_steel.darkened(0.2))
	
	# Rivets on armor plating
	for i in range(5):
		var y_pos: float = 0.4 + i * 0.25
		_add_cylinder(r, 0.02, 0.02, Vector3(1.32, y_pos, 0.5), dark_steel.darkened(0.3))
		_add_cylinder(r, 0.02, 0.02, Vector3(-1.32, y_pos, 0.5), dark_steel.darkened(0.3))
		_add_cylinder(r, 0.02, 0.02, Vector3(1.32, y_pos, -0.5), dark_steel.darkened(0.3))
		_add_cylinder(r, 0.02, 0.02, Vector3(-1.32, y_pos, -0.5), dark_steel.darkened(0.3))
	
	# Wide bay door (open, showing interior)
	_add_box(r, Vector3(1.8, 1.1, 0.08), Vector3(0, 0.8, 0.76), Color(0.1, 0.1, 0.1))
	
	# Bay door tracks and mechanisms
	_add_box(r, Vector3(0.06, 1.1, 0.06), Vector3(-0.92, 0.8, 0.78), dark_steel)
	_add_box(r, Vector3(0.06, 1.1, 0.06), Vector3(0.92, 0.8, 0.78), dark_steel)
	_add_box(r, Vector3(1.9, 0.04, 0.04), Vector3(0, 1.36, 0.78), dark_steel)
	
	# Assembly gantries visible inside (more detailed)
	var gantry_system := Node3D.new()
	gantry_system.name = "GantrySystem"
	gantry_system.position = Vector3(0, 0, 0.5)
	r.add_child(gantry_system)
	
	_add_box(gantry_system, Vector3(0.06, 0.8, 0.06), Vector3(0.4, 0.7, 0), lite)
	_add_box(gantry_system, Vector3(0.06, 0.8, 0.06), Vector3(-0.4, 0.7, 0), lite)
	_add_box(gantry_system, Vector3(0.8, 0.06, 0.06), Vector3(0, 1.1, 0), lite)
	
	# Cross braces for stability
	_add_box(gantry_system, Vector3(0.04, 0.04, 0.8), Vector3(0.4, 1.05, 0), lite.darkened(0.1))
	_add_box(gantry_system, Vector3(0.04, 0.04, 0.8), Vector3(-0.4, 1.05, 0), lite.darkened(0.1))
	
	# Moveable welding arms
	var welding_arm_1 := Node3D.new()
	welding_arm_1.name = "WeldingArm1"
	welding_arm_1.position = Vector3(0.3, 0.8, 0)
	gantry_system.add_child(welding_arm_1)
	_add_box(welding_arm_1, Vector3(0.04, 0.3, 0.04), Vector3(0, 0, 0), blue.darkened(0.3))
	_add_box(welding_arm_1, Vector3(0.2, 0.04, 0.04), Vector3(-0.1, -0.15, 0), blue.darkened(0.3))
	
	var welding_arm_2 := Node3D.new()
	welding_arm_2.name = "WeldingArm2"
	welding_arm_2.position = Vector3(-0.3, 0.6, 0)
	gantry_system.add_child(welding_arm_2)
	_add_box(welding_arm_2, Vector3(0.04, 0.3, 0.04), Vector3(0, 0, 0), blue.darkened(0.3))
	_add_box(welding_arm_2, Vector3(0.15, 0.04, 0.04), Vector3(0.08, -0.15, 0), blue.darkened(0.3))
	
	# Welding sparks effect points (emissive spots for animation)
	_add_emissive_sphere(welding_arm_1, 0.03, Vector3(-0.2, -0.15, 0), Color(1.0, 0.8, 0.4), 2.0)
	_add_emissive_sphere(welding_arm_2, 0.03, Vector3(0.15, -0.15, 0), Color(1.0, 0.8, 0.4), 2.0)
	
	# Additional sparks around mech frames
	_add_emissive_sphere(r, 0.02, Vector3(0.5, 0.65, 0.4), Color(0.8, 0.9, 1.0), 1.5)
	_add_emissive_sphere(r, 0.025, Vector3(-0.5, 0.55, 0.35), Color(1.0, 0.7, 0.3), 1.8)
	
	# Mech frames in various stages (more detailed)
	# Sentinel frame under construction
	var mech_frame_1 := Node3D.new()
	mech_frame_1.name = "SentinelFrame"
	mech_frame_1.position = Vector3(0.5, 0.5, 0.3)
	r.add_child(mech_frame_1)
	_add_box(mech_frame_1, Vector3(0.3, 0.5, 0.2), Vector3(0, 0, 0), dark_steel.lightened(0.1))
	_add_box(mech_frame_1, Vector3(0.08, 0.3, 0.08), Vector3(0.15, 0.1, 0), dark_steel.lightened(0.05))  # Arm
	_add_box(mech_frame_1, Vector3(0.08, 0.3, 0.08), Vector3(-0.15, 0.1, 0), dark_steel.lightened(0.05))  # Arm
	_add_emissive_sphere(mech_frame_1, 0.03, Vector3(0, 0.2, 0.1), blue, 1.5)  # Optic system
	
	# Juggernaut frame (partially assembled)
	var mech_frame_2 := Node3D.new()
	mech_frame_2.name = "JuggernautFrame"
	mech_frame_2.position = Vector3(-0.5, 0.45, 0.3)
	r.add_child(mech_frame_2)
	_add_box(mech_frame_2, Vector3(0.25, 0.4, 0.18), Vector3(0, 0, 0), dark_steel.lightened(0.1))
	_add_box(mech_frame_2, Vector3(0.1, 0.25, 0.1), Vector3(0.12, 0.075, 0), dark_steel.lightened(0.05))
	_add_box(mech_frame_2, Vector3(0.1, 0.25, 0.1), Vector3(-0.12, 0.075, 0), dark_steel.lightened(0.05))
	
	# Heavy door frame
	_add_box(r, Vector3(1.9, 0.08, 0.1), Vector3(0, 1.37, 0.76), dark_steel)
	_add_box(r, Vector3(0.08, 1.1, 0.1), Vector3(-0.95, 0.8, 0.76), dark_steel)
	_add_box(r, Vector3(0.08, 1.1, 0.1), Vector3(0.95, 0.8, 0.76), dark_steel)
	
	# Heavy crane arm with lifting capability
	var crane_system := Node3D.new()
	crane_system.name = "CraneSystem"
	crane_system.position = Vector3(0.8, 1.9, 0)
	r.add_child(crane_system)
	_add_box(crane_system, Vector3(0.12, 0.7, 0.12), Vector3(0, 0, 0), dark_steel)
	_add_box(crane_system, Vector3(1.0, 0.08, 0.08), Vector3(0, 0.35, 0.4), dark_steel)
	_add_box(crane_system, Vector3(0.06, 0.15, 0.06), Vector3(0.5, 0.28, 0.4), lite)  # Hook
	_add_cylinder(crane_system, 0.01, 0.25, Vector3(0.5, 0.1, 0.4), dark_steel.darkened(0.3))  # Cable
	
	# Exhaust ports with steam/smoke
	_add_cylinder(r, 0.12, 0.5, Vector3(-0.8, 1.9, -0.5), dark_steel)
	_add_cylinder(r, 0.1, 0.5, Vector3(-1.0, 1.9, -0.3), dark_steel)
	_add_emissive_sphere(r, 0.08, Vector3(-0.8, 2.15, -0.5), Color(0.8, 0.8, 0.9), 1.0)  # Steam
	_add_emissive_sphere(r, 0.06, Vector3(-1.0, 2.2, -0.3), Color(0.9, 0.85, 0.8), 0.8)  # Steam
	
	# Blue operational status lights
	_add_emissive_sphere(r, 0.05, Vector3(0.8, 1.4, 0.76), blue, 3.0)
	_add_emissive_sphere(r, 0.05, Vector3(-0.8, 1.4, 0.76), blue, 3.0)
	_add_emissive_sphere(r, 0.05, Vector3(0, 1.6, 0.76), blue, 3.0)
	
	# Additional status lights on crane and gantry
	_add_emissive_sphere(crane_system, 0.03, Vector3(0, 0.4, 0.42), blue, 2.0)
	_add_emissive_sphere(gantry_system, 0.025, Vector3(0, 1.15, 0.05), blue, 2.0)
	
	# Blue accent lighting strips
	_add_emissive_box(r, Vector3(2.4, 0.03, 0.04), Vector3(0, 0.4, 0.76), blue, 2.0)
	_add_emissive_box(r, Vector3(0.04, 1.0, 0.04), Vector3(1.25, 0.75, 0.76), blue, 2.0)
	_add_emissive_box(r, Vector3(0.04, 1.0, 0.04), Vector3(-1.25, 0.75, 0.76), blue, 2.0)
	
	# Interior work lights
	_add_emissive_box(r, Vector3(1.8, 0.04, 0.04), Vector3(0, 1.5, 0.72), Color(0.9, 0.9, 1.0), 1.0)
	
	# Enhanced visual details for Task 1A - Advanced Mech Bay Atmospherics
	# Add reinforced structural supports and industrial details
	_add_box(r, Vector3(0.06, 1.3, 0.06), Vector3(1.15, 0.9, 0.65), dark_steel.lightened(0.1))
	_add_box(r, Vector3(0.06, 1.3, 0.06), Vector3(-1.15, 0.9, 0.65), dark_steel.lightened(0.1))
	_add_box(r, Vector3(0.06, 1.3, 0.06), Vector3(1.15, 0.9, -0.65), dark_steel.lightened(0.1))
	_add_box(r, Vector3(0.06, 1.3, 0.06), Vector3(-1.15, 0.9, -0.65), dark_steel.lightened(0.1))
	
	# Heavy-duty electrical conduits
	_add_cylinder(r, 0.04, 2.4, Vector3(1.2, 1.2, 0), dark_steel.darkened(0.3))
	_add_cylinder(r, 0.04, 2.4, Vector3(-1.2, 1.2, 0), dark_steel.darkened(0.3))
	
	# Industrial cooling vents with glowing heat indicators
	for i in range(8):
		var vent_x: float = -1.0 + i * 0.25
		_add_emissive_box(r, Vector3(0.08, 0.02, 0.06), Vector3(vent_x, 1.4, -0.75), Color(0.8, 0.4, 0.2), 1.5)
	
	# Task 1A: Enhanced mech bay environmental atmosphere
	# Add pressurized forge effect glows for heavy industry feel
	_add_emissive_sphere(r, 0.06, Vector3(0.8, 0.8, 0.3), Color(1.0, 0.6, 0.1), 3.0)  # Forge glow
	_add_emissive_sphere(r, 0.06, Vector3(-0.8, 0.8, 0.3), Color(1.0, 0.6, 0.1), 3.0)
	
	# Enhanced bay door frame with military warning strips
	for strip_i in range(6):
		var strip_y: float = 0.4 + strip_i * 0.15
		_add_box(r, Vector3(0.08, 0.04, 0.02), Vector3(0.95, strip_y, 0.78), Color(1.0, 0.5, 0.0))
		_add_box(r, Vector3(0.08, 0.04, 0.02), Vector3(-0.95, strip_y, 0.78), Color(1.0, 0.5, 0.0))
	
	# Power coupling nodes for heavy machinery
	_add_emissive_cylinder(r, 0.03, 0.08, Vector3(1.0, 0.6, -0.8), blue, 2.5)
	_add_emissive_cylinder(r, 0.03, 0.08, Vector3(-1.0, 0.6, -0.8), blue, 2.5)
	
	# Environmental monitoring systems
	_add_emissive_box(r, Vector3(0.06, 0.06, 0.02), Vector3(0.6, 1.8, -0.9), Color(0.2, 1.0, 0.4), 1.8)  # Air quality
	_add_emissive_box(r, Vector3(0.06, 0.06, 0.02), Vector3(-0.6, 1.8, -0.9), Color(1.0, 0.8, 0.2), 1.8)  # Temperature
	
	# Store animation nodes for future use
	r.set_meta("gantry_system_node", gantry_system.get_path())
	r.set_meta("welding_arm1_node", welding_arm_1.get_path())
	r.set_meta("welding_arm2_node", welding_arm_2.get_path())
	r.set_meta("crane_system_node", crane_system.get_path())
	r.set_meta("sentinel_frame_node", mech_frame_1.get_path())
	r.set_meta("juggernaut_frame_node", mech_frame_2.get_path())
	r.set_meta("supports_gantry_animation", true)
	r.set_meta("supports_welding_animation", true)
	r.set_meta("supports_crane_animation", true)
	r.set_meta("production_type", "mech")
	r.set_meta("welding_spark_points", [
		Vector3(-0.2, 0.95, 0.4),   # Welding arm 1 spark
		Vector3(0.15, 0.75, 0.35)   # Welding arm 2 spark
	])
	r.set_meta("steam_vent_points", [
		Vector3(-0.8, 2.15, -0.5),  # Exhaust stack 1
		Vector3(-1.0, 2.2, -0.3)    # Exhaust stack 2
	])
	
	return r


static func _create_war_factory(c: Color) -> Node3D:
	## Massive factory (3x3): Industrial complex with vehicle ramp, heavy machinery, orange accent lighting
	## Based on design: "Massive industrial complex with a reinforced vehicle ramp exit. Tank treads and heavy machinery 
	## visible inside. Thick armored walls with blast-resistant construction. Orange warning lights and hazard striping 
	## around the deployment ramp. Heavy crane arm extends from the roof for lifting components. Exhaust stacks release 
	## bursts of steam during production. Dark industrial metal with orange accent lighting matching Siege Walker plasma glow."
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.3)
	var industrial_metal := Color(0.15, 0.15, 0.18)  # Dark industrial metal as specified
	var orange := Color(1.0, 0.5, 0.1)  # Orange accent lighting matching Siege Walker plasma glow
	
	# Foundation (blast-resistant)
	_add_box(r, Vector3(2.8, 0.3, 2.8), Vector3(0, 0.15, 0), industrial_metal.darkened(0.3))
	
	# Massive main complex (thick armored walls)
	_add_box(r, Vector3(2.5, 1.4, 2.5), Vector3(0, 1.0, 0), industrial_metal)
	
	# Thick armored walls with blast resistance
	_add_box(r, Vector3(0.12, 1.2, 2.3), Vector3(1.31, 0.9, 0), industrial_metal.darkened(0.2))
	_add_box(r, Vector3(0.12, 1.2, 2.3), Vector3(-1.31, 0.9, 0), industrial_metal.darkened(0.2))
	_add_box(r, Vector3(2.3, 0.12, 1.2), Vector3(0, 0.9, -1.31), industrial_metal.darkened(0.2))
	
	# Reinforced vehicle ramp exit with track marks
	_add_box(r, Vector3(1.5, 1.2, 0.1), Vector3(0, 0.9, 1.35), industrial_metal.darkened(0.4))
	_add_box(r, Vector3(1.5, 0.08, 0.6), Vector3(0, 0.24, 1.65), industrial_metal.darkened(0.2))
	
	# Tank tread marks on ramp
	_add_box(r, Vector3(0.3, 0.02, 0.5), Vector3(0.4, 0.25, 1.65), industrial_metal.darkened(0.4))
	_add_box(r, Vector3(0.3, 0.02, 0.5), Vector3(-0.4, 0.25, 1.65), industrial_metal.darkened(0.4))
	
	# Interior assembly line (visible through openings)
	var assembly_line := Node3D.new()
	assembly_line.name = "AssemblyLine"
	assembly_line.position = Vector3(0, 0.45, 0.8)
	r.add_child(assembly_line)
	
	# Conveyor tracks
	_add_box(assembly_line, Vector3(1.8, 0.05, 0.3), Vector3(0, 0, 0), industrial_metal.lightened(0.05))
	_add_box(assembly_line, Vector3(1.8, 0.05, 0.3), Vector3(0, 0, -0.6), industrial_metal.lightened(0.05))
	
	# Vehicle chassis in various stages
	var striker_chassis := Node3D.new()
	striker_chassis.name = "StrikerChassis"
	striker_chassis.position = Vector3(0.3, 0.15, 0)
	assembly_line.add_child(striker_chassis)
	_add_box(striker_chassis, Vector3(0.8, 0.3, 0.15), Vector3(0, 0, 0), industrial_metal.lightened(0.1))
	_add_box(striker_chassis, Vector3(0.15, 0.15, 0.12), Vector3(0.3, 0.2, 0), industrial_metal.lightened(0.05))  # Weapon mount
	_add_emissive_sphere(striker_chassis, 0.02, Vector3(0, 0.1, 0.08), orange, 1.5)  # Power core
	
	var siege_walker_chassis := Node3D.new()
	siege_walker_chassis.name = "SiegeWalkerChassis"
	siege_walker_chassis.position = Vector3(-0.3, 0.15, -0.6)
	assembly_line.add_child(siege_walker_chassis)
	_add_box(siege_walker_chassis, Vector3(0.8, 0.3, 0.15), Vector3(0, 0, 0), industrial_metal.lightened(0.1))
	# Walker legs (partially assembled)
	_add_box(siege_walker_chassis, Vector3(0.08, 0.25, 0.08), Vector3(0.25, -0.1, 0), industrial_metal.lightened(0.05))
	_add_box(siege_walker_chassis, Vector3(0.08, 0.25, 0.08), Vector3(-0.25, -0.1, 0), industrial_metal.lightened(0.05))
	_add_emissive_sphere(siege_walker_chassis, 0.03, Vector3(0, 0.2, 0), Color(0.8, 0.4, 1.0), 2.0)  # Plasma core
	
	# Large industrial machinery (gear systems)
	var machinery_1 := Node3D.new()
	machinery_1.name = "HeavyGearSystem1"
	machinery_1.position = Vector3(0.6, 0.8, 0.2)
	r.add_child(machinery_1)
	_add_cylinder(machinery_1, 0.3, 0.1, Vector3(0, 0, 0), industrial_metal.lightened(0.15))
	# Gear teeth
	for i in range(8):
		var angle: float = i * TAU / 8.0
		var tooth_x: float = cos(angle) * 0.32
		var tooth_z: float = sin(angle) * 0.32
		_add_box(machinery_1, Vector3(0.04, 0.12, 0.04), Vector3(tooth_x, 0, tooth_z), industrial_metal.lightened(0.2))
	
	var machinery_2 := Node3D.new()
	machinery_2.name = "HeavyGearSystem2"
	machinery_2.position = Vector3(-0.6, 0.8, 0.2)
	r.add_child(machinery_2)
	_add_cylinder(machinery_2, 0.25, 0.1, Vector3(0, 0, 0), industrial_metal.lightened(0.15))
	# Gear teeth
	for i in range(6):
		var angle: float = i * TAU / 6.0
		var tooth_x: float = cos(angle) * 0.27
		var tooth_z: float = sin(angle) * 0.27
		_add_box(machinery_2, Vector3(0.04, 0.12, 0.04), Vector3(tooth_x, 0, tooth_z), industrial_metal.lightened(0.2))
	
	# Heavy crane arm system
	var crane_system := Node3D.new()
	crane_system.name = "HeavyCraneSystem"
	crane_system.position = Vector3(0.9, 2.0, 0)
	r.add_child(crane_system)
	_add_box(crane_system, Vector3(0.15, 0.8, 0.15), Vector3(0, 0, 0), industrial_metal)
	_add_box(crane_system, Vector3(1.2, 0.1, 0.1), Vector3(0, 0.4, 0.5), industrial_metal)
	_add_box(crane_system, Vector3(0.08, 0.15, 0.08), Vector3(0.6, 0.25, 0.5), industrial_metal.lightened(0.2))  # Hook
	_add_cylinder(crane_system, 0.01, 0.4, Vector3(0.6, 0.05, 0.5), industrial_metal.darkened(0.3))  # Cable
	
	# Crane counterweight
	_add_box(crane_system, Vector3(0.4, 0.2, 0.2), Vector3(-0.5, 0.3, 0), industrial_metal.darkened(0.2))
	
	# Multiple exhaust stacks with realistic details
	var exhaust_1 := Node3D.new()
	exhaust_1.name = "ExhaustStack1"
	exhaust_1.position = Vector3(-0.8, 2.0, -0.8)
	r.add_child(exhaust_1)
	_add_cylinder(exhaust_1, 0.12, 0.6, Vector3(0, 0, 0), industrial_metal)
	_add_cylinder(exhaust_1, 0.14, 0.05, Vector3(0, 0.32, 0), industrial_metal.darkened(0.1))  # Flare
	_add_emissive_sphere(exhaust_1, 0.1, Vector3(0, 0.35, 0), Color(0.9, 0.9, 1.0), 1.5)  # Steam
	
	var exhaust_2 := Node3D.new()
	exhaust_2.name = "ExhaustStack2"
	exhaust_2.position = Vector3(-0.5, 2.0, -0.9)
	r.add_child(exhaust_2)
	_add_cylinder(exhaust_2, 0.1, 0.5, Vector3(0, 0, 0), industrial_metal)
	_add_emissive_sphere(exhaust_2, 0.08, Vector3(0, 0.28, 0), Color(0.9, 0.9, 1.0), 1.5)
	
	var exhaust_3 := Node3D.new()
	exhaust_3.name = "ExhaustStack3"
	exhaust_3.position = Vector3(0.8, 2.0, -0.8)
	r.add_child(exhaust_3)
	_add_cylinder(exhaust_3, 0.1, 0.5, Vector3(0, 0, 0), industrial_metal)
	_add_emissive_sphere(exhaust_3, 0.08, Vector3(0, 0.28, 0), Color(0.85, 0.9, 1.0), 1.2)
	
	# Orange warning lights and hazard systems
	_add_emissive_sphere(r, 0.08, Vector3(0.75, 1.5, 1.35), orange, 3.0)
	_add_emissive_sphere(r, 0.08, Vector3(-0.75, 1.5, 1.35), orange, 3.0)
	_add_emissive_sphere(r, 0.06, Vector3(0.75, 0.8, 1.35), orange, 2.5)
	_add_emissive_sphere(r, 0.06, Vector3(-0.75, 0.8, 1.35), orange, 2.5)
	
	# Rotating beacon light
	var beacon := Node3D.new()
	beacon.name = "WarningBeacon"
	beacon.position = Vector3(0, 1.8, 1.35)
	r.add_child(beacon)
	_add_cylinder(beacon, 0.06, 0.1, Vector3(0, 0, 0), industrial_metal.darkened(0.2))
	_add_emissive_sphere(beacon, 0.08, Vector3(0, 0.08, 0), orange, 4.0)
	
	# Hazard striping (improved pattern)
	for i in range(5):
		var stripe_x: float = -0.6 + i * 0.3
		var stripe_color: Color = orange if i % 2 == 0 else Color(0.1, 0.1, 0.1)
		_add_box(r, Vector3(0.08, 0.04, 0.1), Vector3(stripe_x, 0.28, 1.35), stripe_color)
		_add_box(r, Vector3(0.08, 0.04, 0.1), Vector3(stripe_x, 0.5, 1.35), stripe_color)
	
	# Orange accent lighting strips
	_add_emissive_box(r, Vector3(2.4, 0.04, 0.04), Vector3(0, 0.5, 1.35), orange, 2.0)
	_add_emissive_box(r, Vector3(0.04, 1.2, 0.04), Vector3(1.27, 0.9, 1.35), orange, 2.0)
	_add_emissive_box(r, Vector3(0.04, 1.2, 0.04), Vector3(-1.27, 0.9, 1.35), orange, 2.0)
	
	# Work area lighting
	_add_emissive_box(r, Vector3(2.2, 0.04, 0.04), Vector3(0, 1.3, 0.8), Color(0.9, 0.9, 1.0), 1.2)
	
	# Heavy reinforcement ribs (structural)
	for i in range(4):
		var z_pos: float = -1.0 + i * 0.65
		_add_box(r, Vector3(2.6, 0.08, 0.1), Vector3(0, 1.2, z_pos), industrial_metal.darkened(0.1))
		# Rivets on ribs
		for j in range(6):
			var rib_x: float = -1.1 + j * 0.44
			_add_cylinder(r, 0.015, 0.02, Vector3(rib_x, 1.2, z_pos + 0.05), industrial_metal.darkened(0.3))
	
	# Enhanced visual details for Task 1A - Advanced War Factory Atmospherics  
	# Add heavy industrial atmosphere with sparking electrical systems
	for i in range(4):
		var spark_x: float = -1.0 + i * 0.6
		_add_emissive_sphere(r, 0.02, Vector3(spark_x, 1.6, 1.0), Color(0.9, 0.7, 1.0), 2.5)
	
	# Massive support pylons for structural integrity
	_add_box(r, Vector3(0.15, 1.8, 0.15), Vector3(1.0, 0.9, 0.8), industrial_metal)
	_add_box(r, Vector3(0.15, 1.8, 0.15), Vector3(-1.0, 0.9, 0.8), industrial_metal)
	_add_box(r, Vector3(0.15, 1.8, 0.15), Vector3(1.0, 0.9, -0.8), industrial_metal)
	_add_box(r, Vector3(0.15, 1.8, 0.15), Vector3(-1.0, 0.9, -0.8), industrial_metal)
	
	# Heavy reinforcement beams
	_add_box(r, Vector3(2.0, 0.08, 0.08), Vector3(0, 1.8, 0.85), industrial_metal.darkened(0.2))
	_add_box(r, Vector3(2.0, 0.08, 0.08), Vector3(0, 1.8, -0.85), industrial_metal.darkened(0.2))
	
	# Industrial ventilation grilles with orange glow
	for i in range(6):
		var vent_angle: float = i * TAU / 6.0
		var vx: float = cos(vent_angle) * 1.1
		var vz: float = sin(vent_angle) * 1.1
		_add_emissive_box(r, Vector3(0.06, 0.8, 0.03), Vector3(vx, 1.0, vz), orange, 1.8)
	
	# Task 1A: Enhanced war factory heavy industry atmosphere
	# Add molten metal pour effects for vehicle forging
	_add_emissive_sphere(r, 0.08, Vector3(0.5, 1.2, 0.2), Color(1.0, 0.4, 0.1), 4.0)  # Molten pour
	_add_emissive_sphere(r, 0.06, Vector3(-0.5, 1.2, 0.2), Color(1.0, 0.3, 0.05), 3.5)
	
	# Enhanced hydraulic systems for heavy lifting
	_add_emissive_cylinder(r, 0.04, 0.8, Vector3(1.1, 0.8, 0.3), orange, 2.0)
	_add_emissive_cylinder(r, 0.04, 0.8, Vector3(-1.1, 0.8, 0.3), orange, 2.0)
	
	# Advanced fabrication guidance lasers
	for laser_i in range(4):
		var laser_x: float = -0.9 + laser_i * 0.6
		_add_emissive_box(r, Vector3(0.01, 0.01, 1.5), Vector3(laser_x, 1.5, 0), Color(0.8, 0.2, 0.2), 3.0)
	
	# Environmental safety monitoring arrays
	_add_emissive_box(r, Vector3(0.1, 0.04, 0.04), Vector3(1.2, 1.9, 0.9), Color(1.0, 1.0, 0.2), 2.0)  # Radiation
	_add_emissive_box(r, Vector3(0.1, 0.04, 0.04), Vector3(-1.2, 1.9, 0.9), Color(0.2, 1.0, 0.2), 2.0)  # Chemical
	
	# Store animation nodes for future use
	r.set_meta("assembly_line_node", assembly_line.get_path())
	r.set_meta("striker_chassis_node", striker_chassis.get_path())
	r.set_meta("siege_walker_chassis_node", siege_walker_chassis.get_path())
	r.set_meta("heavy_gear_system1_node", machinery_1.get_path())
	r.set_meta("heavy_gear_system2_node", machinery_2.get_path())
	r.set_meta("heavy_crane_system_node", crane_system.get_path())
	r.set_meta("warning_beacon_node", beacon.get_path())
	r.set_meta("exhaust_stack1_node", exhaust_1.get_path())
	r.set_meta("exhaust_stack2_node", exhaust_2.get_path())
	r.set_meta("exhaust_stack3_node", exhaust_3.get_path())
	r.set_meta("supports_assembly_animation", true)
	r.set_meta("supports_gear_rotation", true)
	r.set_meta("supports_crane_animation", true)
	r.set_meta("supports_beacon_rotation", true)
	r.set_meta("supports_steam_animation", true)
	r.set_meta("production_type", "vehicle")
	r.set_meta("conveyor_belt_nodes", [
		Vector3(0, 0.45, 0.8),      # Main assembly line
		Vector3(0, 0.45, 0.2)       # Secondary line
	])
	r.set_meta("hazard_warning_points", [
		Vector3(0.75, 1.5, 1.35),   # Right warning light
		Vector3(-0.75, 1.5, 1.35),  # Left warning light
		Vector3(0, 1.8, 1.35)       # Rotating beacon
	])
	
	return r


static func create_central_tower_visual(tier: int = 0) -> Node3D:
	## Builds a detailed 12-story tower building with antenna.
	## Tier 0: 6 floors, dim windows, basic antenna.
	## Tier 1: 8 floors, brighter windows, side dish.
	## Tier 2: 10 floors, cyan windows, dual dishes + cross-arms.
	## Tier 3: 12 floors, blue-white windows, full antenna array + rooftop beacons.
	var root := Node3D.new()
	root.name = "Visual"

	var num_floors: int = 6 + tier * 2
	var floor_height: float = 0.7
	var building_w: float = 2.2
	var building_d: float = 2.2
	var total_h: float = num_floors * floor_height

	# --- Foundation ---
	_add_box(root, Vector3(2.8, 0.4, 2.8), Vector3(0, 0.2, 0),
		Color(0.12, 0.12, 0.18))

	# --- Main Building Body ---
	_add_box(root, Vector3(building_w, total_h, building_d),
		Vector3(0, 0.4 + total_h / 2.0, 0), Color(0.15, 0.15, 0.25))

	# --- Floor Separator Lines ---
	for i in range(1, num_floors):
		var line_y: float = 0.4 + i * floor_height
		_add_box(root, Vector3(building_w + 0.04, 0.02, building_d + 0.04),
			Vector3(0, line_y, 0), Color(0.1, 0.1, 0.16))

	# --- Windows ---
	var win_color: Color = _get_tier_window_color(tier)
	var num_lit: int = _get_lit_floor_count(tier, num_floors)
	var emission_str: float = 1.0 + tier * 0.5

	for floor_idx in range(num_lit):
		var center_y: float = 0.4 + floor_idx * floor_height + floor_height * 0.5
		var win_h: float = floor_height * 0.35
		var win_w: float = building_w * 0.6
		var face_off: float = 0.026

		# Front (+Z), Back (-Z), Right (+X), Left (-X)
		_add_emissive_box(root, Vector3(win_w, win_h, 0.05),
			Vector3(0, center_y, building_d / 2.0 + face_off), win_color, emission_str)
		_add_emissive_box(root, Vector3(win_w, win_h, 0.05),
			Vector3(0, center_y, -building_d / 2.0 - face_off), win_color, emission_str)
		_add_emissive_box(root, Vector3(0.05, win_h, win_w),
			Vector3(building_w / 2.0 + face_off, center_y, 0), win_color, emission_str)
		_add_emissive_box(root, Vector3(0.05, win_h, win_w),
			Vector3(-building_w / 2.0 - face_off, center_y, 0), win_color, emission_str)

	# --- Roof Cap ---
	var roof_y: float = 0.4 + total_h
	_add_box(root, Vector3(building_w + 0.2, 0.15, building_d + 0.2),
		Vector3(0, roof_y + 0.075, 0), Color(0.2, 0.2, 0.3))

	# --- Roof Equipment (small HVAC boxes) ---
	_add_box(root, Vector3(0.5, 0.25, 0.5), Vector3(-0.5, roof_y + 0.275, -0.5),
		Color(0.18, 0.18, 0.26))
	_add_box(root, Vector3(0.4, 0.2, 0.3), Vector3(0.6, roof_y + 0.25, 0.4),
		Color(0.18, 0.18, 0.26))

	# --- Antenna Assembly ---
	var ant_base_y: float = roof_y + 0.15

	# Antenna base platform
	_add_box(root, Vector3(0.6, 0.3, 0.6), Vector3(0, ant_base_y + 0.15, 0),
		Color(0.25, 0.25, 0.35))

	# Main antenna mast
	var mast_h: float = 1.5 + tier * 0.5
	var mast_bottom: float = ant_base_y + 0.3
	_add_cylinder(root, 0.06, mast_h,
		Vector3(0, mast_bottom + mast_h / 2.0, 0), Color(0.4, 0.4, 0.5))

	# Antenna tip light (red)
	var tip_y: float = mast_bottom + mast_h
	_add_emissive_sphere(root, 0.1, Vector3(0, tip_y, 0),
		Color(1.0, 0.1, 0.1), 3.0)

	# --- Tier-Specific Antenna Extras ---
	if tier >= 1:
		# Side antenna dish
		_add_box(root, Vector3(0.4, 0.05, 0.2),
			Vector3(0.3, mast_bottom + mast_h * 0.4, 0.1), Color(0.35, 0.35, 0.45))

	if tier >= 2:
		# Second side dish + cross-arm
		_add_box(root, Vector3(0.4, 0.05, 0.2),
			Vector3(-0.3, mast_bottom + mast_h * 0.6, -0.1), Color(0.35, 0.35, 0.45))
		_add_box(root, Vector3(1.0, 0.04, 0.04),
			Vector3(0, mast_bottom + mast_h * 0.7, 0), Color(0.4, 0.4, 0.5))

	if tier >= 3:
		# Corner beacons on roof
		var boff: float = building_w / 2.0 - 0.15
		for bx in [-boff, boff]:
			for bz in [-boff, boff]:
				_add_emissive_sphere(root, 0.08,
					Vector3(bx, roof_y + 0.35, bz), Color(0.3, 0.6, 1.0), 4.0)
		# Extra cross-arm
		_add_box(root, Vector3(0.04, 0.04, 1.0),
			Vector3(0, mast_bottom + mast_h * 0.85, 0), Color(0.4, 0.4, 0.5))
		# Second red light on mast
		_add_emissive_sphere(root, 0.07,
			Vector3(0, mast_bottom + mast_h * 0.5, 0), Color(1.0, 0.1, 0.1), 2.0)

	root.scale = Vector3(1.5, 1.5, 1.5)
	return root


static func get_central_tower_top_y(tier: int = 0) -> float:
	## Returns the Y position just above the antenna tip for health bar placement.
	var num_floors: int = 6 + tier * 2
	var total_h: float = num_floors * 0.7
	var mast_h: float = 1.5 + tier * 0.5
	return (0.4 + total_h + 0.15 + 0.3 + mast_h + 0.5) * 1.5


static func _get_tier_window_color(tier: int) -> Color:
	match tier:
		0: return Color(0.8, 0.7, 0.3)
		1: return Color(0.9, 0.8, 0.3)
		2: return Color(0.3, 0.8, 0.9)
		3: return Color(0.7, 0.85, 1.0)
		_: return Color(0.8, 0.7, 0.3)


static func _get_lit_floor_count(tier: int, _total_floors: int) -> int:
	match tier:
		0: return 4
		1: return 7
		2: return 9
		3: return 12
		_: return 4


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


static func _add_emissive_cylinder(parent: Node3D, radius: float, height: float, pos: Vector3, color: Color, emission_strength: float = 2.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = height
	var mat := StandardMaterial3D.new()
	var opaque_color := Color(color.r, color.g, color.b, 1.0)
	mat.albedo_color = opaque_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	mat.emission_enabled = true
	mat.emission = opaque_color
	mat.emission_energy_multiplier = emission_strength
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cyl.material = mat
	mi.mesh = cyl
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


static func _add_muzzle_sphere(parent: Node3D, radius: float, pos: Vector3, color: Color, emission_strength: float = 2.0) -> MeshInstance3D:
	var mi := _add_emissive_sphere(parent, radius, pos, color, emission_strength)
	mi.set_meta("muzzle_point", true)
	return mi


# =============================================================================
# DECORATIVE BASE BUILDINGS
# =============================================================================

static func _create_barracks(c: Color) -> Node3D:
	## Military barracks: long low building with pitched roof and door
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.3)
	var lite := c.lightened(0.15)
	# Foundation
	_add_box(r, Vector3(2.6, 0.15, 1.8), Vector3(0, 0.075, 0), dark)
	# Main body
	_add_box(r, Vector3(2.4, 1.2, 1.6), Vector3(0, 0.15 + 0.6, 0), c)
	# Pitched roof (two angled slabs)
	_add_box(r, Vector3(2.5, 0.1, 0.9), Vector3(0, 1.55, -0.15), dark)
	_add_box(r, Vector3(2.5, 0.1, 0.9), Vector3(0, 1.55, 0.15), dark)
	_add_box(r, Vector3(2.5, 0.3, 0.15), Vector3(0, 1.6, 0), lite)  # Ridge cap
	# Door
	_add_box(r, Vector3(0.4, 0.7, 0.05), Vector3(0, 0.5, -0.83), lite.lightened(0.1))
	# Windows (3 per side)
	for i in range(3):
		var wx: float = -0.7 + i * 0.7
		_add_emissive_box(r, Vector3(0.25, 0.2, 0.04), Vector3(wx, 1.0, -0.83), Color(0.8, 0.7, 0.3), 0.6)
		_add_emissive_box(r, Vector3(0.25, 0.2, 0.04), Vector3(wx, 1.0, 0.83), Color(0.8, 0.7, 0.3), 0.6)
	return r


static func _create_warehouse(c: Color) -> Node3D:
	## Industrial warehouse: wide corrugated building with tall roll-up door
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.3)
	var lite := c.lightened(0.2)
	# Concrete pad
	_add_box(r, Vector3(2.8, 0.1, 2.2), Vector3(0, 0.05, 0), dark.darkened(0.2))
	# Main warehouse body
	_add_box(r, Vector3(2.6, 1.6, 2.0), Vector3(0, 0.1 + 0.8, 0), c)
	# Flat roof with slight overhang
	_add_box(r, Vector3(2.8, 0.08, 2.2), Vector3(0, 1.74, 0), dark)
	# Corrugation ridges (horizontal lines on sides)
	for i in range(4):
		var ry: float = 0.4 + i * 0.35
		_add_box(r, Vector3(2.62, 0.04, 0.04), Vector3(0, ry, -1.02), lite)
		_add_box(r, Vector3(2.62, 0.04, 0.04), Vector3(0, ry, 1.02), lite)
	# Large roll-up door
	_add_box(r, Vector3(1.2, 1.3, 0.05), Vector3(0, 0.75, -1.03), lite)
	_add_box(r, Vector3(1.3, 0.08, 0.06), Vector3(0, 1.42, -1.03), dark)  # Door frame top
	# Loading dock platform
	_add_box(r, Vector3(1.4, 0.2, 0.4), Vector3(0, 0.1, -1.2), dark)
	return r


static func _create_office(c: Color) -> Node3D:
	## Office building: 3-story tower with lit windows and antenna
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.3)
	var lite := c.lightened(0.15)
	# Foundation
	_add_box(r, Vector3(1.8, 0.12, 1.8), Vector3(0, 0.06, 0), dark.darkened(0.2))
	# 3 floors stacked
	for floor_i in range(3):
		var fy: float = 0.12 + floor_i * 1.0
		# Floor slab
		_add_box(r, Vector3(1.7, 0.08, 1.7), Vector3(0, fy, 0), dark)
		# Walls
		_add_box(r, Vector3(1.5, 0.9, 1.5), Vector3(0, fy + 0.08 + 0.45, 0), c)
		# Windows on 4 sides
		for side in range(4):
			for wi in range(2):
				var wx: float = -0.3 + wi * 0.6
				var wpos: Vector3
				match side:
					0: wpos = Vector3(wx, fy + 0.55, -0.78)
					1: wpos = Vector3(wx, fy + 0.55, 0.78)
					2: wpos = Vector3(-0.78, fy + 0.55, wx)
					3: wpos = Vector3(0.78, fy + 0.55, wx)
				_add_emissive_box(r, Vector3(0.22, 0.25, 0.04) if side < 2 else Vector3(0.04, 0.25, 0.22),
					wpos, Color(0.6, 0.75, 0.9), 0.5)
	# Flat roof
	_add_box(r, Vector3(1.7, 0.08, 1.7), Vector3(0, 3.12, 0), dark)
	# Rooftop antenna
	_add_cylinder(r, 0.03, 0.8, Vector3(0.4, 3.52, 0.4), lite)
	# Small dish
	_add_box(r, Vector3(0.2, 0.15, 0.02), Vector3(0.4, 3.8, 0.4), lite)
	return r


static func _create_depot(c: Color) -> Node3D:
	## Small supply depot: open-sided shelter with crates underneath
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.3)
	var lite := c.lightened(0.15)
	# Concrete slab
	_add_box(r, Vector3(1.6, 0.08, 1.4), Vector3(0, 0.04, 0), dark.darkened(0.2))
	# 4 corner posts
	_add_box(r, Vector3(0.08, 1.0, 0.08), Vector3(-0.65, 0.58, -0.55), dark)
	_add_box(r, Vector3(0.08, 1.0, 0.08), Vector3(0.65, 0.58, -0.55), dark)
	_add_box(r, Vector3(0.08, 1.0, 0.08), Vector3(-0.65, 0.58, 0.55), dark)
	_add_box(r, Vector3(0.08, 1.0, 0.08), Vector3(0.65, 0.58, 0.55), dark)
	# Flat roof
	_add_box(r, Vector3(1.5, 0.06, 1.3), Vector3(0, 1.11, 0), dark)
	# Supply crates underneath
	_add_box(r, Vector3(0.4, 0.35, 0.35), Vector3(-0.3, 0.255, -0.2), lite)
	_add_box(r, Vector3(0.35, 0.3, 0.4), Vector3(0.25, 0.23, 0.15), c.lightened(0.05))
	_add_box(r, Vector3(0.3, 0.25, 0.3), Vector3(-0.2, 0.205, 0.3), lite.darkened(0.1))
	# Stacked crate on top
	_add_box(r, Vector3(0.3, 0.25, 0.3), Vector3(-0.3, 0.48, -0.2), c)
	return r


static func _create_container(c: Color) -> Node3D:
	## Shipping container: simple rectangular metal box with ribbed sides and doors
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.25)
	var lite := c.lightened(0.15)
	# Main container body
	_add_box(r, Vector3(1.2, 0.9, 0.6), Vector3(0, 0.45, 0), c)
	# Ribbed side panels (vertical lines)
	for i in range(5):
		var rx: float = -0.4 + i * 0.2
		_add_box(r, Vector3(0.02, 0.8, 0.02), Vector3(rx, 0.45, -0.31), lite)
		_add_box(r, Vector3(0.02, 0.8, 0.02), Vector3(rx, 0.45, 0.31), lite)
	# Door end (two panels)
	_add_box(r, Vector3(0.03, 0.75, 0.22), Vector3(0.61, 0.43, -0.14), dark)
	_add_box(r, Vector3(0.03, 0.75, 0.22), Vector3(0.61, 0.43, 0.14), dark)
	# Door handles
	_add_box(r, Vector3(0.04, 0.15, 0.02), Vector3(0.63, 0.5, -0.03), lite)
	_add_box(r, Vector3(0.04, 0.15, 0.02), Vector3(0.63, 0.5, 0.03), lite)
	# Roof rail
	_add_box(r, Vector3(1.1, 0.03, 0.03), Vector3(0, 0.91, -0.25), dark)
	_add_box(r, Vector3(1.1, 0.03, 0.03), Vector3(0, 0.91, 0.25), dark)
	return r


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


# =============================================================================
# ENEMY MODELS
# =============================================================================

static func _create_thrasher(c: Color) -> Node3D:
	## Lean feline quadruped: low body, 4 legs, serrated claws, spine plates, yellow eyes
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.3)
	var lite := c.lightened(0.2)
	var bone := Color(0.85, 0.82, 0.75)
	# Main body (low oval shape)
	_add_box(r, Vector3(0.35, 0.18, 0.5), Vector3(0, 0.22, 0), c)
	# Head (small, angular, forward)
	_add_box(r, Vector3(0.14, 0.1, 0.16), Vector3(0, 0.26, 0.3), lite)
	# Snout
	_add_box(r, Vector3(0.08, 0.06, 0.08), Vector3(0, 0.23, 0.4), lite)
	# Eyes (yellow glow)
	_add_emissive_sphere(r, 0.02, Vector3(0.06, 0.28, 0.36), Color(1.0, 0.9, 0.2), 2.5)
	_add_emissive_sphere(r, 0.02, Vector3(-0.06, 0.28, 0.36), Color(1.0, 0.9, 0.2), 2.5)
	# Front legs (thin, with claws)
	_add_cylinder(r, 0.025, 0.2, Vector3(0.14, 0.1, 0.15), dark)
	_add_cylinder(r, 0.025, 0.2, Vector3(-0.14, 0.1, 0.15), dark)
	# Front claws (elongated, serrated - extending forward)
	_add_box(r, Vector3(0.02, 0.02, 0.12), Vector3(0.14, 0.02, 0.28), bone)
	_add_box(r, Vector3(0.02, 0.02, 0.12), Vector3(-0.14, 0.02, 0.28), bone)
	# Hind legs
	_add_cylinder(r, 0.03, 0.22, Vector3(0.13, 0.11, -0.15), dark)
	_add_cylinder(r, 0.03, 0.22, Vector3(-0.13, 0.11, -0.15), dark)
	# Bony spine plates along back
	_add_box(r, Vector3(0.04, 0.06, 0.04), Vector3(0, 0.34, -0.1), bone)
	_add_box(r, Vector3(0.05, 0.07, 0.04), Vector3(0, 0.35, 0.0), bone)
	_add_box(r, Vector3(0.04, 0.06, 0.04), Vector3(0, 0.34, 0.1), bone)
	# Tail (thin, whip-like)
	_add_box(r, Vector3(0.02, 0.02, 0.18), Vector3(0, 0.25, -0.33), dark)
	return r


static func _create_brute(c: Color) -> Node3D:
	## Hulking biped: massive upper body, hammer-like fists, chitinous plates, orange glow
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.3)
	var lite := c.lightened(0.15)
	var chitin := c.darkened(0.15)
	var glow := Color(0.8, 0.45, 0.1)
	# Legs (thick trunk-like)
	_add_box(r, Vector3(0.2, 0.5, 0.22), Vector3(0.22, 0.25, 0), dark)
	_add_box(r, Vector3(0.2, 0.5, 0.22), Vector3(-0.22, 0.25, 0), dark)
	# Torso (massive, hunched forward)
	_add_box(r, Vector3(0.9, 0.6, 0.7), Vector3(0, 0.8, 0.05), c)
	# Hunch/upper back
	_add_box(r, Vector3(0.7, 0.3, 0.5), Vector3(0, 1.15, -0.05), c)
	# Chitinous shoulder plates
	_add_box(r, Vector3(0.3, 0.12, 0.3), Vector3(0.4, 1.15, 0), chitin)
	_add_box(r, Vector3(0.3, 0.12, 0.3), Vector3(-0.4, 1.15, 0), chitin)
	# Head (small relative to body, hunched between shoulders)
	_add_box(r, Vector3(0.2, 0.18, 0.22), Vector3(0, 1.25, 0.18), lite)
	# Eyes (small, dim)
	_add_emissive_sphere(r, 0.025, Vector3(0.06, 1.28, 0.3), glow, 1.5)
	_add_emissive_sphere(r, 0.025, Vector3(-0.06, 1.28, 0.3), glow, 1.5)
	# Arms (disproportionately long, hanging down)
	_add_box(r, Vector3(0.14, 0.55, 0.14), Vector3(0.48, 0.6, 0.05), dark)
	_add_box(r, Vector3(0.14, 0.55, 0.14), Vector3(-0.48, 0.6, 0.05), dark)
	# Hammer-like bone fist growths
	_add_box(r, Vector3(0.2, 0.22, 0.2), Vector3(0.48, 0.22, 0.05), chitin)
	_add_box(r, Vector3(0.2, 0.22, 0.2), Vector3(-0.48, 0.22, 0.05), chitin)
	# Orange bioluminescent cracks on arms
	_add_emissive_box(r, Vector3(0.03, 0.3, 0.03), Vector3(0.48, 0.55, 0.12), glow, 1.5)
	_add_emissive_box(r, Vector3(0.03, 0.3, 0.03), Vector3(-0.48, 0.55, 0.12), glow, 1.5)
	# Chest plate
	_add_box(r, Vector3(0.5, 0.25, 0.08), Vector3(0, 0.9, 0.35), chitin)
	return r


static func _create_clugg(c: Color) -> Node3D:
	## Enormous turtle tank: thick domed carapace, 4 stumpy pillar legs, no eyes, scored shell
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.3)
	var lite := c.lightened(0.15)
	var shell := c.darkened(0.1)
	var moss := Color(0.2, 0.3, 0.15)
	# 4 stumpy pillar legs
	_add_box(r, Vector3(0.35, 0.6, 0.35), Vector3(0.55, 0.3, 0.55), dark)
	_add_box(r, Vector3(0.35, 0.6, 0.35), Vector3(-0.55, 0.3, 0.55), dark)
	_add_box(r, Vector3(0.35, 0.6, 0.35), Vector3(0.55, 0.3, -0.55), dark)
	_add_box(r, Vector3(0.35, 0.6, 0.35), Vector3(-0.55, 0.3, -0.55), dark)
	# Underbelly
	_add_box(r, Vector3(1.6, 0.3, 1.6), Vector3(0, 0.65, 0), dark)
	# Domed carapace (layered plates getting smaller toward top)
	_add_box(r, Vector3(1.8, 0.4, 1.8), Vector3(0, 1.0, 0), shell)
	_add_box(r, Vector3(1.5, 0.35, 1.5), Vector3(0, 1.38, 0), shell.lightened(0.05))
	_add_box(r, Vector3(1.1, 0.3, 1.1), Vector3(0, 1.7, 0), shell.lightened(0.1))
	_add_box(r, Vector3(0.6, 0.2, 0.6), Vector3(0, 1.95, 0), shell.lightened(0.12))
	# Calcified growths on shell
	_add_box(r, Vector3(0.2, 0.15, 0.2), Vector3(0.5, 1.55, 0.3), lite)
	_add_box(r, Vector3(0.15, 0.12, 0.15), Vector3(-0.4, 1.55, -0.35), lite)
	# Scoring/cracks on shell (dark lines)
	_add_box(r, Vector3(1.2, 0.02, 0.03), Vector3(0, 1.22, 0.5), dark.darkened(0.3))
	_add_box(r, Vector3(0.03, 0.02, 1.0), Vector3(0.4, 1.22, 0), dark.darkened(0.3))
	# Moss patches
	_add_box(r, Vector3(0.25, 0.03, 0.2), Vector3(-0.3, 1.42, 0.4), moss)
	_add_box(r, Vector3(0.2, 0.03, 0.25), Vector3(0.35, 1.78, -0.2), moss)
	# Head (barely visible, tucked under front of shell)
	_add_box(r, Vector3(0.35, 0.2, 0.2), Vector3(0, 0.65, 0.85), dark)
	return r


static func _create_scrit(c: Color) -> Node3D:
	## Bat-like flyer: tattered wings, thin angular body, barbed tail, green bioluminescence
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.3)
	var lite := c.lightened(0.2)
	var wing_glow := Color(0.3, 0.7, 0.2)
	# Central body (thin, angular)
	_add_box(r, Vector3(0.12, 0.1, 0.3), Vector3(0, 0.2, 0), c)
	# Head (mostly mouth)
	_add_box(r, Vector3(0.1, 0.08, 0.12), Vector3(0, 0.22, 0.2), lite)
	# Open mouth gash
	_add_box(r, Vector3(0.08, 0.02, 0.06), Vector3(0, 0.19, 0.24), dark.darkened(0.4))
	# Wing membranes (thin flat boxes extending to sides)
	# Left wing
	_add_box(r, Vector3(0.35, 0.02, 0.22), Vector3(0.25, 0.22, 0.0), c)
	_add_box(r, Vector3(0.15, 0.02, 0.18), Vector3(0.45, 0.21, -0.05), dark)
	# Right wing
	_add_box(r, Vector3(0.35, 0.02, 0.22), Vector3(-0.25, 0.22, 0.0), c)
	_add_box(r, Vector3(0.15, 0.02, 0.18), Vector3(-0.45, 0.21, -0.05), dark)
	# Wing finger struts (bony supports)
	_add_box(r, Vector3(0.4, 0.015, 0.015), Vector3(0.28, 0.23, 0.08), dark)
	_add_box(r, Vector3(0.35, 0.015, 0.015), Vector3(0.25, 0.23, -0.05), dark)
	_add_box(r, Vector3(0.4, 0.015, 0.015), Vector3(-0.28, 0.23, 0.08), dark)
	_add_box(r, Vector3(0.35, 0.015, 0.015), Vector3(-0.25, 0.23, -0.05), dark)
	# Green bioluminescent veins on wings
	_add_emissive_box(r, Vector3(0.25, 0.01, 0.01), Vector3(0.22, 0.24, 0.0), wing_glow, 1.5)
	_add_emissive_box(r, Vector3(0.25, 0.01, 0.01), Vector3(-0.22, 0.24, 0.0), wing_glow, 1.5)
	# Barbed tail
	_add_box(r, Vector3(0.02, 0.02, 0.25), Vector3(0, 0.18, -0.28), dark)
	# Tail tip (projectile emitter)
	_add_emissive_sphere(r, 0.02, Vector3(0, 0.18, -0.42), wing_glow, 2.0)
	return r


static func _create_blight_mite(c: Color) -> Node3D:
	## Tiny suicide insect: 6 spindly legs, volatile glowing sac on back, no head
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.3)
	var sac_glow := Color(0.5, 0.9, 0.2)
	# Main body (tiny, dark purple chitin)
	_add_box(r, Vector3(0.12, 0.06, 0.16), Vector3(0, 0.1, 0), dark)
	# Volatile sac on back (the defining feature - glowing green)
	_add_emissive_sphere(r, 0.07, Vector3(0, 0.17, -0.02), sac_glow, 2.5)
	# 6 spindly legs (3 per side)
	for side in [-1.0, 1.0]:
		_add_box(r, Vector3(0.08, 0.01, 0.01), Vector3(side * 0.1, 0.06, 0.06), dark)
		_add_box(r, Vector3(0.08, 0.01, 0.01), Vector3(side * 0.1, 0.06, 0.0), dark)
		_add_box(r, Vector3(0.08, 0.01, 0.01), Vector3(side * 0.1, 0.06, -0.06), dark)
	# Sensory nubs at front
	_add_box(r, Vector3(0.04, 0.02, 0.02), Vector3(0, 0.1, 0.1), dark)
	# Green bioluminescent veins on body
	_add_emissive_box(r, Vector3(0.02, 0.01, 0.1), Vector3(0.03, 0.08, 0), sac_glow, 1.0)
	_add_emissive_box(r, Vector3(0.02, 0.01, 0.1), Vector3(-0.03, 0.08, 0), sac_glow, 1.0)
	return r


static func _create_terror_bringer(c: Color) -> Node3D:
	## Towering boss battering ram: massive armored skull crest, trunk legs, red bioluminescence
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.3)
	var lite := c.lightened(0.15)
	var armor_plate := c.darkened(0.2)
	var glow := Color(0.9, 0.15, 0.05)
	# Trunk-like legs
	_add_box(r, Vector3(0.3, 0.7, 0.35), Vector3(0.3, 0.35, 0), dark)
	_add_box(r, Vector3(0.3, 0.7, 0.35), Vector3(-0.3, 0.35, 0), dark)
	# Clawed feet
	_add_box(r, Vector3(0.35, 0.08, 0.45), Vector3(0.3, 0.04, 0.05), dark.darkened(0.2))
	_add_box(r, Vector3(0.35, 0.08, 0.45), Vector3(-0.3, 0.04, 0.05), dark.darkened(0.2))
	# Massive torso (forward-leaning charge stance)
	_add_box(r, Vector3(1.0, 0.7, 0.8), Vector3(0, 1.05, 0.1), c)
	# Upper chest / shoulders
	_add_box(r, Vector3(1.1, 0.35, 0.7), Vector3(0, 1.48, 0.05), c)
	# Overlapping chitinous armor plates
	_add_box(r, Vector3(1.15, 0.08, 0.75), Vector3(0, 1.2, 0.05), armor_plate)
	_add_box(r, Vector3(1.0, 0.08, 0.65), Vector3(0, 1.0, 0.1), armor_plate)
	_add_box(r, Vector3(0.85, 0.08, 0.55), Vector3(0, 0.85, 0.15), armor_plate)
	# Massive armored skull with bone crest
	_add_box(r, Vector3(0.5, 0.3, 0.5), Vector3(0, 1.55, 0.35), lite)
	# Bone crest (battering ram)
	_add_box(r, Vector3(0.6, 0.2, 0.25), Vector3(0, 1.65, 0.55), lite.lightened(0.1))
	_add_box(r, Vector3(0.45, 0.15, 0.15), Vector3(0, 1.72, 0.7), lite.lightened(0.15))
	# Red bioluminescence in armor cracks
	_add_emissive_box(r, Vector3(0.03, 0.5, 0.03), Vector3(0.35, 1.0, 0.2), glow, 2.0)
	_add_emissive_box(r, Vector3(0.03, 0.5, 0.03), Vector3(-0.35, 1.0, 0.2), glow, 2.0)
	_add_emissive_box(r, Vector3(0.6, 0.03, 0.03), Vector3(0, 0.92, 0.35), glow, 1.5)
	# Glowing eyes
	_add_emissive_sphere(r, 0.03, Vector3(0.12, 1.6, 0.58), glow, 3.0)
	_add_emissive_sphere(r, 0.03, Vector3(-0.12, 1.6, 0.58), glow, 3.0)
	# Short arms (vestigial for a charger)
	_add_box(r, Vector3(0.12, 0.3, 0.12), Vector3(0.55, 1.1, 0.15), dark)
	_add_box(r, Vector3(0.12, 0.3, 0.12), Vector3(-0.55, 1.1, 0.15), dark)
	return r


static func _create_polus(c: Color) -> Node3D:
	## Compact jumper: 4 legs with powerful hind springs, bone spines on back, crimson markings
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.3)
	var exo := Color(0.12, 0.12, 0.12)  # Black exoskeleton
	var crimson := Color(0.7, 0.1, 0.15)
	# Main body (compact, crouched)
	_add_box(r, Vector3(0.5, 0.25, 0.6), Vector3(0, 0.35, 0), exo)
	# Front legs (thinner, lower)
	_add_cylinder(r, 0.04, 0.3, Vector3(0.2, 0.15, 0.25), exo)
	_add_cylinder(r, 0.04, 0.3, Vector3(-0.2, 0.15, 0.25), exo)
	# Powerful hind legs (spring-loaded, thicker, angled)
	_add_box(r, Vector3(0.08, 0.35, 0.08), Vector3(0.22, 0.18, -0.2), exo)
	_add_box(r, Vector3(0.08, 0.35, 0.08), Vector3(-0.22, 0.18, -0.2), exo)
	# Hind leg "spring" joints (thicker segments)
	_add_box(r, Vector3(0.1, 0.1, 0.12), Vector3(0.22, 0.15, -0.25), dark)
	_add_box(r, Vector3(0.1, 0.1, 0.12), Vector3(-0.22, 0.15, -0.25), dark)
	# Eyeless head with sensory pits
	_add_box(r, Vector3(0.18, 0.12, 0.15), Vector3(0, 0.42, 0.35), exo)
	# Sensory pits (dim red glow)
	_add_emissive_sphere(r, 0.015, Vector3(0.06, 0.44, 0.42), crimson, 1.5)
	_add_emissive_sphere(r, 0.015, Vector3(-0.06, 0.44, 0.42), crimson, 1.5)
	# Bone spine rows on back (detachable projectiles)
	for i in range(4):
		var z_pos: float = -0.15 + i * 0.1
		_add_box(r, Vector3(0.03, 0.1 + i * 0.01, 0.02), Vector3(0.08, 0.52, z_pos), Color(0.9, 0.85, 0.75))
		_add_box(r, Vector3(0.03, 0.1 + i * 0.01, 0.02), Vector3(-0.08, 0.52, z_pos), Color(0.9, 0.85, 0.75))
	# Crimson markings along spine and joints
	_add_emissive_box(r, Vector3(0.35, 0.01, 0.03), Vector3(0, 0.48, 0), crimson, 1.0)
	_add_emissive_box(r, Vector3(0.02, 0.01, 0.4), Vector3(0, 0.48, 0), crimson, 1.0)
	return r


static func _create_slinker(c: Color) -> Node3D:
	## Tall hunched ranged: oversized split skull, digitigrade legs, green energy organ
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.3)
	var lite := c.lightened(0.15)
	var energy := Color(0.3, 0.85, 0.2)
	# Digitigrade legs (long, thin, backward-jointed)
	# Upper leg
	_add_box(r, Vector3(0.06, 0.3, 0.08), Vector3(0.1, 0.4, -0.04), dark)
	_add_box(r, Vector3(0.06, 0.3, 0.08), Vector3(-0.1, 0.4, -0.04), dark)
	# Lower leg (angled forward)
	_add_box(r, Vector3(0.05, 0.25, 0.06), Vector3(0.1, 0.13, 0.06), dark)
	_add_box(r, Vector3(0.05, 0.25, 0.06), Vector3(-0.1, 0.13, 0.06), dark)
	# Feet
	_add_box(r, Vector3(0.06, 0.03, 0.1), Vector3(0.1, 0.02, 0.08), dark)
	_add_box(r, Vector3(0.06, 0.03, 0.1), Vector3(-0.1, 0.02, 0.08), dark)
	# Hunched torso
	_add_box(r, Vector3(0.25, 0.3, 0.2), Vector3(0, 0.7, 0), c)
	# Vestigial arms (small, tucked against chest)
	_add_box(r, Vector3(0.04, 0.12, 0.04), Vector3(0.12, 0.6, 0.08), dark)
	_add_box(r, Vector3(0.04, 0.12, 0.04), Vector3(-0.12, 0.6, 0.08), dark)
	# Neck (thin, angled forward)
	_add_cylinder(r, 0.04, 0.15, Vector3(0, 0.9, 0.05), c)
	# Oversized elongated skull
	_add_box(r, Vector3(0.18, 0.2, 0.3), Vector3(0, 1.05, 0.08), lite)
	# Split cranium top (the energy organ reveals when it fires)
	_add_box(r, Vector3(0.08, 0.04, 0.2), Vector3(0.08, 1.17, 0.08), lite)
	_add_box(r, Vector3(0.08, 0.04, 0.2), Vector3(-0.08, 1.17, 0.08), lite)
	# Green energy organ (visible between skull halves)
	_add_emissive_box(r, Vector3(0.06, 0.06, 0.15), Vector3(0, 1.17, 0.1), energy, 2.5)
	# Narrow slit eyes (same green)
	_add_emissive_box(r, Vector3(0.06, 0.015, 0.02), Vector3(0.1, 1.02, 0.22), energy, 1.5)
	_add_emissive_box(r, Vector3(0.06, 0.015, 0.02), Vector3(-0.1, 1.02, 0.22), energy, 1.5)
	# Mottled skin patches (lighter areas)
	_add_box(r, Vector3(0.06, 0.06, 0.04), Vector3(0.1, 0.75, 0.08), lite)
	_add_box(r, Vector3(0.05, 0.05, 0.04), Vector3(-0.08, 0.62, -0.06), lite)
	return r


static func _create_howler(c: Color) -> Node3D:
	## Small support biped: oversized cranium, split skull, red pulsing organ, spindly limbs
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.3)
	var lite := c.lightened(0.15)
	var pale := Color(0.85, 0.8, 0.82)  # Almost albino
	var pulse := Color(0.9, 0.2, 0.3)
	# Thin spindly legs
	_add_cylinder(r, 0.03, 0.4, Vector3(0.08, 0.2, 0), pale)
	_add_cylinder(r, 0.03, 0.4, Vector3(-0.08, 0.2, 0), pale)
	# Bony knee joints
	_add_sphere(r, 0.04, Vector3(0.08, 0.25, 0), pale)
	_add_sphere(r, 0.04, Vector3(-0.08, 0.25, 0), pale)
	# Small hunched body
	_add_box(r, Vector3(0.2, 0.15, 0.15), Vector3(0, 0.5, 0), pale)
	# Thin spindly arms
	_add_cylinder(r, 0.02, 0.2, Vector3(0.13, 0.42, 0), pale)
	_add_cylinder(r, 0.02, 0.2, Vector3(-0.13, 0.42, 0), pale)
	# Oversized cranium (nearly half body mass) - the defining feature
	_add_sphere(r, 0.22, Vector3(0, 0.82, 0), pale)
	# Horizontal skull seam (splits open for War Cry)
	_add_box(r, Vector3(0.45, 0.015, 0.15), Vector3(0, 0.82, 0.08), dark)
	# Red pulsing organ visible through seam
	_add_emissive_sphere(r, 0.1, Vector3(0, 0.82, 0.08), pulse, 2.5)
	# Large milky unfocused eyes
	_add_sphere(r, 0.04, Vector3(0.1, 0.78, 0.16), Color(0.9, 0.88, 0.85))
	_add_sphere(r, 0.04, Vector3(-0.1, 0.78, 0.16), Color(0.9, 0.88, 0.85))
	# Dark vein networks visible through translucent skin (surface detail)
	_add_box(r, Vector3(0.01, 0.12, 0.01), Vector3(0.12, 0.85, 0.1), dark)
	_add_box(r, Vector3(0.01, 0.12, 0.01), Vector3(-0.12, 0.85, 0.1), dark)
	_add_box(r, Vector3(0.01, 0.1, 0.01), Vector3(0.06, 0.9, -0.08), dark)
	return r


static func _create_gorger(c: Color) -> Node3D:
	## Hunched predator quadruped: oversized jaw, blade claws, bone ridges, red eyes
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.3)
	var lite := c.lightened(0.15)
	var hide := Color(0.55, 0.2, 0.12)  # Red-brown hide
	var bone := Color(0.85, 0.78, 0.4)  # Yellowish bone
	var eye_glow := Color(0.8, 0.1, 0.05)
	# Powerful body (hunched, low, forward-heavy)
	_add_box(r, Vector3(0.6, 0.35, 0.7), Vector3(0, 0.55, 0.05), hide)
	# Bulging shoulder muscles
	_add_box(r, Vector3(0.7, 0.2, 0.3), Vector3(0, 0.72, 0.15), hide)
	# 4 legs - front are larger with blade claws
	# Front legs (serrated forelimbs)
	_add_box(r, Vector3(0.1, 0.45, 0.1), Vector3(0.3, 0.25, 0.3), dark)
	_add_box(r, Vector3(0.1, 0.45, 0.1), Vector3(-0.3, 0.25, 0.3), dark)
	# Blade-like claws on front legs
	_add_box(r, Vector3(0.03, 0.04, 0.15), Vector3(0.3, 0.04, 0.42), bone)
	_add_box(r, Vector3(0.03, 0.04, 0.15), Vector3(-0.3, 0.04, 0.42), bone)
	# Hind legs
	_add_box(r, Vector3(0.09, 0.45, 0.09), Vector3(0.25, 0.23, -0.2), dark)
	_add_box(r, Vector3(0.09, 0.45, 0.09), Vector3(-0.25, 0.23, -0.2), dark)
	# Head with oversized unhinging jaw
	_add_box(r, Vector3(0.25, 0.2, 0.25), Vector3(0, 0.72, 0.45), hide)
	# Lower jaw (hangs open slightly)
	_add_box(r, Vector3(0.22, 0.06, 0.2), Vector3(0, 0.6, 0.48), dark)
	# Deep red predatory eyes
	_add_emissive_sphere(r, 0.025, Vector3(0.1, 0.78, 0.55), eye_glow, 3.0)
	_add_emissive_sphere(r, 0.025, Vector3(-0.1, 0.78, 0.55), eye_glow, 3.0)
	# Exposed bone ridges along spine and shoulders
	_add_box(r, Vector3(0.06, 0.08, 0.06), Vector3(0, 0.8, -0.15), bone)
	_add_box(r, Vector3(0.07, 0.1, 0.06), Vector3(0, 0.82, -0.05), bone)
	_add_box(r, Vector3(0.07, 0.1, 0.06), Vector3(0, 0.82, 0.05), bone)
	_add_box(r, Vector3(0.06, 0.08, 0.06), Vector3(0, 0.8, 0.15), bone)
	# Muscle tension lines (tight skin)
	_add_box(r, Vector3(0.02, 0.02, 0.5), Vector3(0.2, 0.65, 0.05), dark)
	_add_box(r, Vector3(0.02, 0.02, 0.5), Vector3(-0.2, 0.65, 0.05), dark)
	return r


static func _create_gloom_wing(c: Color) -> Node3D:
	## Massive manta ray flyer: wide flat wingspan, bioluminescent underbelly sacs, trailing tail
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.3)
	var lite := c.lightened(0.15)
	var glow := Color(0.3, 0.75, 0.9)  # Cyan-white
	var bomb_glow := Color(0.4, 0.6, 1.0)  # Blue-white for bomb sacs
	# Main flat body (triangular/diamond manta shape - wide and thin)
	_add_box(r, Vector3(1.4, 0.12, 1.0), Vector3(0, 0.3, 0), c)
	# Elevated center ridge (spine)
	_add_box(r, Vector3(0.2, 0.08, 1.1), Vector3(0, 0.38, -0.05), lite)
	# Wing tips (thinner, extending further out)
	_add_box(r, Vector3(0.5, 0.06, 0.6), Vector3(0.8, 0.28, 0.05), dark)
	_add_box(r, Vector3(0.5, 0.06, 0.6), Vector3(-0.8, 0.28, 0.05), dark)
	# Bioluminescent wing edge veins
	_add_emissive_box(r, Vector3(1.3, 0.01, 0.02), Vector3(0, 0.28, 0.5), glow, 1.5)
	_add_emissive_box(r, Vector3(1.3, 0.01, 0.02), Vector3(0, 0.28, -0.5), glow, 1.5)
	_add_emissive_box(r, Vector3(0.02, 0.01, 0.9), Vector3(1.0, 0.28, 0), glow, 1.5)
	_add_emissive_box(r, Vector3(0.02, 0.01, 0.9), Vector3(-1.0, 0.28, 0), glow, 1.5)
	# Spine glow line
	_add_emissive_box(r, Vector3(0.03, 0.01, 0.8), Vector3(0, 0.43, 0), glow, 1.0)
	# Underbelly bomb sacs (pulsing bioluminescent)
	_add_emissive_sphere(r, 0.08, Vector3(0.2, 0.2, 0), bomb_glow, 2.0)
	_add_emissive_sphere(r, 0.08, Vector3(-0.2, 0.2, 0), bomb_glow, 2.0)
	_add_emissive_sphere(r, 0.06, Vector3(0, 0.2, 0.15), bomb_glow, 2.0)
	_add_emissive_sphere(r, 0.06, Vector3(0, 0.2, -0.15), bomb_glow, 2.0)
	# Sensory organs along leading edge (no visible head)
	_add_box(r, Vector3(0.06, 0.04, 0.02), Vector3(0.25, 0.34, 0.5), lite)
	_add_box(r, Vector3(0.06, 0.04, 0.02), Vector3(-0.25, 0.34, 0.5), lite)
	# Trailing tendril tail
	_add_box(r, Vector3(0.04, 0.03, 0.4), Vector3(0, 0.28, -0.7), dark)
	_add_box(r, Vector3(0.02, 0.02, 0.25), Vector3(0, 0.26, -1.0), dark)
	return r


static func _create_bile_spitter(c: Color) -> Node3D:
	## Bloated slug siege unit: swollen spitting head, pale yellowish body, stubby legs, dark veins
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.3)
	var pale := Color(0.75, 0.72, 0.45)  # Pale yellowish skin
	var vein := c.darkened(0.4)
	var acid := Color(0.6, 0.8, 0.15)
	# 4 stubby legs (barely supporting its mass)
	_add_box(r, Vector3(0.1, 0.1, 0.08), Vector3(0.2, 0.05, 0.15), dark)
	_add_box(r, Vector3(0.1, 0.1, 0.08), Vector3(-0.2, 0.05, 0.15), dark)
	_add_box(r, Vector3(0.1, 0.1, 0.08), Vector3(0.2, 0.05, -0.15), dark)
	_add_box(r, Vector3(0.1, 0.1, 0.08), Vector3(-0.2, 0.05, -0.15), dark)
	# Bloated slug body (wider in middle, tapers at ends)
	_add_box(r, Vector3(0.45, 0.3, 0.55), Vector3(0, 0.25, 0), pale)
	# Even more bloated midsection
	_add_box(r, Vector3(0.5, 0.35, 0.4), Vector3(0, 0.28, -0.05), pale)
	# Grotesquely swollen head (rears back to spit)
	_add_sphere(r, 0.2, Vector3(0, 0.45, 0.3), pale)
	# Mouth (wide opening for spitting)
	_add_box(r, Vector3(0.12, 0.08, 0.06), Vector3(0, 0.4, 0.48), dark.darkened(0.3))
	# Acid drip from mouth
	_add_emissive_sphere(r, 0.03, Vector3(0, 0.37, 0.5), acid, 2.0)
	# Dark vein patterns across body
	_add_box(r, Vector3(0.02, 0.02, 0.4), Vector3(0.15, 0.35, 0), vein)
	_add_box(r, Vector3(0.02, 0.02, 0.4), Vector3(-0.15, 0.35, 0), vein)
	_add_box(r, Vector3(0.3, 0.02, 0.02), Vector3(0, 0.38, -0.1), vein)
	# Tail section (tapers down)
	_add_box(r, Vector3(0.25, 0.15, 0.2), Vector3(0, 0.15, -0.3), pale.darkened(0.1))
	_add_box(r, Vector3(0.12, 0.08, 0.12), Vector3(0, 0.1, -0.45), pale.darkened(0.15))
	return r


static func _create_behemoth(c: Color) -> Node3D:
	## Colossal boss: towering armored titan, massive limbs, ground-slam fists, dark with purple glow
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.3)
	var lite := c.lightened(0.2)
	var armor := c.lightened(0.1)
	var glow := Color(0.5, 0.2, 0.8)
	# Massive legs (pillar-like)
	_add_box(r, Vector3(0.6, 1.0, 0.7), Vector3(0.6, 0.5, 0), dark)
	_add_box(r, Vector3(0.6, 1.0, 0.7), Vector3(-0.6, 0.5, 0), dark)
	# Enormous feet
	_add_box(r, Vector3(0.7, 0.15, 0.9), Vector3(0.6, 0.08, 0.05), dark.darkened(0.2))
	_add_box(r, Vector3(0.7, 0.15, 0.9), Vector3(-0.6, 0.08, 0.05), dark.darkened(0.2))
	# Massive torso
	_add_box(r, Vector3(1.8, 1.2, 1.5), Vector3(0, 1.6, 0), c)
	# Upper chest / shoulder ridge
	_add_box(r, Vector3(2.0, 0.4, 1.3), Vector3(0, 2.4, 0), armor)
	# Layered armor plates across body
	_add_box(r, Vector3(1.9, 0.08, 1.4), Vector3(0, 1.9, 0), armor)
	_add_box(r, Vector3(1.7, 0.08, 1.3), Vector3(0, 1.5, 0.05), armor)
	_add_box(r, Vector3(1.5, 0.08, 1.2), Vector3(0, 1.2, 0.1), armor)
	# Head (armored, set between massive shoulders)
	_add_box(r, Vector3(0.6, 0.5, 0.6), Vector3(0, 2.65, 0.2), lite)
	# Heavy brow / forehead plate
	_add_box(r, Vector3(0.7, 0.15, 0.35), Vector3(0, 2.85, 0.35), armor)
	# Glowing eyes
	_add_emissive_sphere(r, 0.06, Vector3(0.18, 2.65, 0.5), glow, 3.0)
	_add_emissive_sphere(r, 0.06, Vector3(-0.18, 2.65, 0.5), glow, 3.0)
	# Massive arms
	_add_box(r, Vector3(0.35, 1.0, 0.35), Vector3(1.05, 1.6, 0), dark)
	_add_box(r, Vector3(0.35, 1.0, 0.35), Vector3(-1.05, 1.6, 0), dark)
	# Ground-slam fists (enormous)
	_add_box(r, Vector3(0.5, 0.45, 0.5), Vector3(1.05, 0.8, 0.05), armor)
	_add_box(r, Vector3(0.5, 0.45, 0.5), Vector3(-1.05, 0.8, 0.05), armor)
	# Purple bioluminescent cracks
	_add_emissive_box(r, Vector3(0.04, 0.8, 0.04), Vector3(0.5, 1.6, 0.4), glow, 2.0)
	_add_emissive_box(r, Vector3(0.04, 0.8, 0.04), Vector3(-0.5, 1.6, 0.4), glow, 2.0)
	_add_emissive_box(r, Vector3(1.2, 0.04, 0.04), Vector3(0, 1.35, 0.6), glow, 1.5)
	_add_emissive_box(r, Vector3(1.2, 0.04, 0.04), Vector3(0, 1.7, 0.6), glow, 1.5)
	# Shoulder spikes
	_add_box(r, Vector3(0.15, 0.35, 0.15), Vector3(0.85, 2.75, 0), armor)
	_add_box(r, Vector3(0.15, 0.35, 0.15), Vector3(-0.85, 2.75, 0), armor)
	_add_box(r, Vector3(0.1, 0.25, 0.1), Vector3(0.65, 2.7, -0.25), armor)
	_add_box(r, Vector3(0.1, 0.25, 0.1), Vector3(-0.65, 2.7, -0.25), armor)
	# Ground impact glow on fists
	_add_emissive_sphere(r, 0.1, Vector3(1.05, 0.65, 0.05), glow, 1.5)
	_add_emissive_sphere(r, 0.1, Vector3(-1.05, 0.65, 0.05), glow, 1.5)
	return r


static func _parse_scale(scale_val: Variant) -> Vector3:
	if scale_val is Array and scale_val.size() >= 3:
		return Vector3(float(scale_val[0]), float(scale_val[1]), float(scale_val[2]))
	elif scale_val is Vector3:
		return scale_val
	return Vector3.ONE


# =============================================================================
# ENHANCED TURRET ANIMATION SYSTEM
# =============================================================================

## Creates barrel recoil animation for rail guns and heavy weapons
static func animate_barrel_recoil(visual_node: Node3D, recoil_distance: float = -0.15, duration: float = 0.3) -> void:
	if not visual_node or not visual_node.has_meta("barrel_assembly_node"):
		return
	
	var barrel_path: String = visual_node.get_meta("barrel_assembly_node")
	var barrel_assembly := visual_node.get_node_or_null(NodePath(barrel_path))
	if not barrel_assembly:
		return
	
	var original_pos: Vector3 = barrel_assembly.position
	var recoil_pos: Vector3 = original_pos + Vector3(0, 0, recoil_distance)
	
	# Quick recoil back, slower return to position
	var tween := visual_node.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(barrel_assembly, "position", recoil_pos, duration * 0.2)
	tween.tween_property(barrel_assembly, "position", original_pos, duration * 0.8)


## Animates energy charging sequence for rail guns and plasma weapons
static func animate_energy_charge_sequence(visual_node: Node3D, charge_duration: float = 1.5) -> void:
	if not visual_node or not visual_node.has_meta("supports_sequential_coil_activation"):
		return
	
	var coil_count: int = visual_node.get_meta("coil_count", 0)
	if coil_count == 0:
		return
	
	# Find barrel assembly for coil access
	var barrel_path: String = visual_node.get_meta("barrel_assembly_node", "")
	var barrel_assembly := visual_node.get_node_or_null(NodePath(barrel_path))
	if not barrel_assembly:
		return
	
	# Activate coils sequentially with increasing intensity
	for i in range(coil_count):
		var coil_node := barrel_assembly.get_node_or_null("AcceleratorCoil_" + str(i))
		if not coil_node:
			continue
		
		var delay: float = (charge_duration / float(coil_count)) * float(i)
		var activation_duration: float = charge_duration - delay
		
		# Create charging effect for this coil
		visual_node.get_tree().create_timer(delay).timeout.connect(
			func(): _animate_coil_activation(coil_node, activation_duration, 1.5 + i * 0.5)
		)


## Animates individual accelerator coil charging
static func _animate_coil_activation(coil_node: Node3D, duration: float, max_intensity: float) -> void:
	# Find emissive materials in the coil
	for child in coil_node.get_children():
		if child is MeshInstance3D:
			var mesh_inst := child as MeshInstance3D
			var mat := mesh_inst.get_surface_override_material(0) as StandardMaterial3D
			if not mat:
				mat = mesh_inst.mesh.material as StandardMaterial3D
			
			if mat and mat.emission_enabled:
				var base_intensity: float = mat.emission_energy_multiplier
				var tween := coil_node.create_tween()
				tween.set_ease(Tween.EASE_OUT)
				tween.set_trans(Tween.TRANS_EXPO)
				
				# Ramp up to max intensity
				tween.tween_method(
					func(intensity): mat.emission_energy_multiplier = intensity,
					base_intensity, max_intensity, duration * 0.7
				)
				# Brief peak hold
				tween.tween_delay(duration * 0.1)
				# Quick discharge
				tween.tween_method(
					func(intensity): mat.emission_energy_multiplier = intensity,
					max_intensity, base_intensity, duration * 0.2
				)


## Animates spinning barrel rotation for autocannons and gatling weapons
static func animate_barrel_spin(visual_node: Node3D, spin_duration: float = 2.0, max_speed: float = 720.0) -> void:
	if not visual_node or not visual_node.has_meta("barrel_spinner_node"):
		return
	
	var spinner_path: String = visual_node.get_meta("barrel_spinner_node")
	var barrel_spinner := visual_node.get_node_or_null(NodePath(spinner_path))
	if not barrel_spinner:
		return
	
	# Ramp up spin, sustain, then ramp down
	var tween := visual_node.create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	
	# Calculate total rotation for smooth spinning
	var spin_up_time: float = spin_duration * 0.3
	var sustain_time: float = spin_duration * 0.4
	var spin_down_time: float = spin_duration * 0.3
	
	# Spin up
	tween.tween_method(
		func(speed): barrel_spinner.rotation_degrees.z += speed * visual_node.get_process_delta_time(),
		0.0, max_speed, spin_up_time
	)
	
	# Sustain high speed
	tween.tween_method(
		func(speed): barrel_spinner.rotation_degrees.z += speed * visual_node.get_process_delta_time(),
		max_speed, max_speed, sustain_time
	)
	
	# Spin down
	tween.tween_method(
		func(speed): barrel_spinner.rotation_degrees.z += speed * visual_node.get_process_delta_time(),
		max_speed, 0.0, spin_down_time
	)


## Animates missile visibility during reload sequences
static func animate_missile_reload(visual_node: Node3D, missile_index: int = -1, reload_duration: float = 3.0) -> void:
	if not visual_node or not visual_node.has_meta("launcher_assembly_node"):
		return
	
	var launcher_path: String = visual_node.get_meta("launcher_assembly_node")
	var launcher_assembly := visual_node.get_node_or_null(NodePath(launcher_path))
	if not launcher_assembly:
		return
	
	# If missile_index is -1, reload all missiles
	var missile_count: int = visual_node.get_meta("missile_count", 4)
	var missiles_to_reload: Array = []
	
	if missile_index >= 0:
		missiles_to_reload.append(missile_index)
	else:
		for i in range(missile_count):
			missiles_to_reload.append(i)
	
	# Animate each missile reload
	for i in missiles_to_reload:
		var missile_node := launcher_assembly.get_node_or_null("Missile_" + str(i))
		if missile_node:
			# Hide missile, wait for reload time, then show with assembly animation
			missile_node.visible = false
			
			visual_node.get_tree().create_timer(reload_duration * randf_range(0.7, 1.3)).timeout.connect(
				func(): _animate_missile_assembly(missile_node)
			)


## Animates individual missile assembly process
static func _animate_missile_assembly(missile_node: Node3D) -> void:
	if not missile_node:
		return
	
	# Start below assembly position
	var original_pos: Vector3 = missile_node.position
	missile_node.position = original_pos + Vector3(0, -0.2, 0)
	missile_node.visible = true
	missile_node.modulate.a = 0.3
	
	# Animate assembly rising into position with fade in
	var tween := missile_node.create_tween()
	tween.set_parallel(true)
	tween.tween_property(missile_node, "position", original_pos, 1.5)
	tween.tween_property(missile_node, "modulate:a", 1.0, 1.5)


## Creates muzzle flash effects at specified points
static func create_muzzle_flash_effects(visual_node: Node3D, flash_points: Array) -> void:
	for point in flash_points:
		if point is Vector3:
			_create_single_muzzle_flash(visual_node, point)


## Creates individual muzzle flash effect
static func _create_single_muzzle_flash(visual_node: Node3D, position: Vector3) -> void:
	var flash := MeshInstance3D.new()
	flash.name = "MuzzleFlash"
	
	# Create bright sphere for flash
	var flash_mesh := SphereMesh.new()
	flash_mesh.radius = 0.08
	flash_mesh.height = 0.16
	
	var flash_mat := StandardMaterial3D.new()
	flash_mat.albedo_color = Color(1.0, 0.9, 0.4, 1.0)
	flash_mat.emission_enabled = true
	flash_mat.emission = Color(1.0, 0.8, 0.2)
	flash_mat.emission_energy_multiplier = 8.0
	flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	flash_mesh.material = flash_mat
	flash.mesh = flash_mesh
	flash.position = position
	
	visual_node.add_child(flash)
	
	# Brief intense flash, then fade
	var tween := visual_node.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(flash, "modulate:a", 0.0, 0.15)
	tween.tween_callback(flash.queue_free)


## Animates brass ejection from specified ejection ports
static func animate_brass_ejection(visual_node: Node3D, ejection_points: Array, count: int = 3) -> void:
	for point in ejection_points:
		if point is Vector3:
			for i in range(count):
				var delay: float = i * 0.05  # Stagger ejection
				visual_node.get_tree().create_timer(delay).timeout.connect(
					func(): _create_ejected_brass(visual_node, point)
				)


## Creates animated ejected brass casing
static func _create_ejected_brass(visual_node: Node3D, ejection_point: Vector3) -> void:
	var brass := MeshInstance3D.new()
	brass.name = "EjectedBrass"
	
	# Small cylinder for brass casing
	var brass_mesh := CylinderMesh.new()
	brass_mesh.top_radius = 0.01
	brass_mesh.bottom_radius = 0.01
	brass_mesh.height = 0.03
	
	var brass_mat := StandardMaterial3D.new()
	brass_mat.albedo_color = Color(0.8, 0.7, 0.4, 1.0)
	brass_mat.metallic = 0.7
	brass_mat.roughness = 0.3
	
	brass_mesh.material = brass_mat
	brass.mesh = brass_mesh
	brass.position = ejection_point
	
	visual_node.add_child(brass)
	
	# Physics-like ejection trajectory
	var eject_velocity: Vector3 = Vector3(
		randf_range(-1.0, 1.0),    # Random sideways
		randf_range(0.5, 1.5),     # Always upward
		randf_range(-0.5, 0.5)     # Random forward/back
	) * 2.0
	
	var gravity: Vector3 = Vector3(0, -9.8, 0)
	var duration: float = 2.0
	var steps: int = 60
	var step_time: float = duration / float(steps)
	
	# Animate parabolic trajectory
	var tween := visual_node.create_tween()
	for i in range(steps):
		var t: float = float(i) * step_time
		var pos: Vector3 = ejection_point + eject_velocity * t + 0.5 * gravity * t * t
		tween.tween_property(brass, "position", pos, step_time)
		
		# Rotate brass as it falls
		var rotation: Vector3 = Vector3(t * 720, t * 360, t * 180)
		tween.parallel().tween_property(brass, "rotation_degrees", rotation, step_time)
	
	# Fade out and cleanup
	tween.tween_property(brass, "modulate:a", 0.0, 0.5)
	tween.tween_callback(brass.queue_free)


# =============================================================================
# BUILDING ANIMATION SYSTEM
# =============================================================================

## Animates robotic arms for drone printer and mech bay assembly
static func animate_robotic_arms(visual_node: Node3D, assembly_duration: float = 5.0) -> void:
	if not visual_node:
		return
	
	var arm_paths: Array = []
	if visual_node.has_meta("robotic_arm1_node"):
		arm_paths.append(visual_node.get_meta("robotic_arm1_node"))
	if visual_node.has_meta("robotic_arm2_node"):
		arm_paths.append(visual_node.get_meta("robotic_arm2_node"))
	
	for arm_path in arm_paths:
		var arm_node := visual_node.get_node_or_null(NodePath(arm_path))
		if arm_node:
			_animate_single_robotic_arm(arm_node, assembly_duration)


## Animates individual robotic arm with realistic assembly motions
static func _animate_single_robotic_arm(arm_node: Node3D, duration: float) -> void:
	if not arm_node:
		return
	
	var original_rotation: Vector3 = arm_node.rotation_degrees
	var tween := arm_node.create_tween()
	tween.set_loops(int(duration / 3.0))  # Repeat cycle every 3 seconds
	
	# Assembly motion cycle: extend, work, retract
	tween.tween_property(arm_node, "rotation_degrees", original_rotation + Vector3(0, -20, 15), 1.0)
	tween.tween_property(arm_node, "rotation_degrees", original_rotation + Vector3(0, -25, 20), 0.5)
	tween.tween_property(arm_node, "rotation_degrees", original_rotation, 1.5)


## Creates welding spark effects at specified points
static func animate_welding_sparks(visual_node: Node3D, spark_points: Array) -> void:
	for point in spark_points:
		if point is Vector3:
			_create_welding_spark_effect(visual_node, point)


## Creates individual welding spark effect
static func _create_welding_spark_effect(visual_node: Node3D, position: Vector3) -> void:
	var spark_count: int = 8
	for i in range(spark_count):
		var spark := MeshInstance3D.new()
		spark.name = "WeldingSpark"
		
		# Tiny sphere for spark
		var spark_mesh := SphereMesh.new()
		spark_mesh.radius = 0.005
		spark_mesh.height = 0.01
		
		var spark_mat := StandardMaterial3D.new()
		spark_mat.albedo_color = Color(1.0, 0.8, 0.2, 1.0)
		spark_mat.emission_enabled = true
		spark_mat.emission = Color(1.0, 0.7, 0.1)
		spark_mat.emission_energy_multiplier = 4.0
		spark_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		
		spark_mesh.material = spark_mat
		spark.mesh = spark_mesh
		spark.position = position
		
		visual_node.add_child(spark)
		
		# Random spark trajectory
		var velocity: Vector3 = Vector3(
			randf_range(-0.5, 0.5),
			randf_range(-0.2, 0.3),
			randf_range(-0.3, 0.3)
		)
		
		var tween := visual_node.create_tween()
		tween.set_parallel(true)
		tween.tween_property(spark, "position", position + velocity, 0.8)
		tween.tween_property(spark, "modulate:a", 0.0, 0.8)
		tween.tween_callback(spark.queue_free)


## Animates steam/smoke vents for industrial buildings
static func animate_steam_vents(visual_node: Node3D, vent_points: Array) -> void:
	for point in vent_points:
		if point is Vector3:
			_create_steam_puff_effect(visual_node, point)


## Creates steam puff effect at vent points
static func _create_steam_puff_effect(visual_node: Node3D, position: Vector3) -> void:
	var steam := MeshInstance3D.new()
	steam.name = "SteamPuff"
	
	# Sphere for steam cloud
	var steam_mesh := SphereMesh.new()
	steam_mesh.radius = 0.08
	steam_mesh.height = 0.16
	
	var steam_mat := StandardMaterial3D.new()
	steam_mat.albedo_color = Color(0.9, 0.9, 1.0, 0.4)
	steam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	steam_mat.emission_enabled = true
	steam_mat.emission = Color(0.95, 0.95, 1.0)
	steam_mat.emission_energy_multiplier = 0.5
	
	steam_mesh.material = steam_mat
	steam.mesh = steam_mesh
	steam.position = position
	
	visual_node.add_child(steam)
	
	# Steam rises and expands
	var tween := visual_node.create_tween()
	tween.set_parallel(true)
	tween.tween_property(steam, "position", position + Vector3(0, 0.3, 0), 2.0)
	tween.tween_property(steam, "scale", Vector3(2.5, 2.5, 2.5), 2.0)
	tween.tween_property(steam, "modulate:a", 0.0, 2.0)
	tween.tween_callback(steam.queue_free)


## Animates gear rotation for heavy machinery
static func animate_gear_systems(visual_node: Node3D, rotation_speed: float = 30.0) -> void:
	var gear_paths: Array = []
	if visual_node.has_meta("heavy_gear_system1_node"):
		gear_paths.append(visual_node.get_meta("heavy_gear_system1_node"))
	if visual_node.has_meta("heavy_gear_system2_node"):
		gear_paths.append(visual_node.get_meta("heavy_gear_system2_node"))
	
	for i in range(gear_paths.size()):
		var gear_node := visual_node.get_node_or_null(NodePath(gear_paths[i]))
		if gear_node:
			# Alternate rotation direction for meshing gears
			var direction: float = 1.0 if i % 2 == 0 else -1.0
			_animate_gear_rotation(gear_node, rotation_speed * direction)


## Animates continuous gear rotation
static func _animate_gear_rotation(gear_node: Node3D, speed_deg_per_sec: float) -> void:
	if not gear_node:
		return
	
	# Create continuous rotation tween
	var tween := gear_node.create_tween()
	tween.set_loops()
	tween.tween_method(
		func(angle): gear_node.rotation_degrees.y = fmod(angle, 360.0),
		0.0, 360.0, abs(360.0 / speed_deg_per_sec)
	)


## Animates warning beacon rotation and pulsing
static func animate_warning_beacons(visual_node: Node3D) -> void:
	if visual_node.has_meta("warning_beacon_node"):
		var beacon_path: String = visual_node.get_meta("warning_beacon_node")
		var beacon_node := visual_node.get_node_or_null(NodePath(beacon_path))
		if beacon_node:
			_animate_warning_beacon(beacon_node)
	
	# Also animate hazard warning lights if present
	var warning_points: Array = visual_node.get_meta("hazard_warning_points", [])
	for point in warning_points:
		if point is Vector3:
			_create_warning_light_pulse(visual_node, point)


## Animates rotating beacon with pulsing light
static func _animate_warning_beacon(beacon_node: Node3D) -> void:
	if not beacon_node:
		return
	
	# Continuous rotation
	var rotation_tween := beacon_node.create_tween()
	rotation_tween.set_loops()
	rotation_tween.tween_property(beacon_node, "rotation_degrees:y", 360.0, 2.0)
	
	# Pulsing light effect
	var light_tween := beacon_node.create_tween()
	light_tween.set_loops()
	for child in beacon_node.get_children():
		if child is MeshInstance3D:
			var mat: StandardMaterial3D = child.mesh.material as StandardMaterial3D
			if mat and mat.emission_enabled:
				var base_emission: float = mat.emission_energy_multiplier
				light_tween.tween_method(
					func(intensity): mat.emission_energy_multiplier = intensity,
					base_emission, base_emission * 3.0, 0.5
				)
				light_tween.tween_method(
					func(intensity): mat.emission_energy_multiplier = intensity,
					base_emission * 3.0, base_emission, 0.5
				)


## Creates pulsing warning light effect
static func _create_warning_light_pulse(visual_node: Node3D, position: Vector3) -> void:
	# Find existing light nodes near this position and pulse them
	# This is a simplified version - in a real implementation you'd find the actual light nodes
	pass  # Implementation depends on specific node structure


## Task 1B: Enhanced weapon-specific muzzle flash effects
static func _create_autocannon_muzzle_flash(visual_node: Node3D) -> void:
	var muzzle_points: Array = visual_node.get_meta("muzzle_flash_points", [])
	for point in muzzle_points:
		if point is Vector3:
			var flash := _create_weapon_flash_node(visual_node, point, Color(1.0, 0.8, 0.2), 0.12, 0.08)
			_animate_autocannon_flash(flash, 0.1)


static func _create_missile_launch_flash(visual_node: Node3D) -> void:
	var launch_points: Array = visual_node.get_meta("missile_launch_points", [])
	for point in launch_points:
		if point is Vector3:
			var flash := _create_weapon_flash_node(visual_node, point, Color(1.0, 0.5, 0.1), 0.2, 0.15)
			_animate_missile_flash(flash, 0.3)


static func _create_rail_gun_discharge(visual_node: Node3D) -> void:
	var beam_origin: Vector3 = visual_node.get_meta("energy_beam_origin", Vector3.ZERO)
	if beam_origin != Vector3.ZERO:
		var flash := _create_weapon_flash_node(visual_node, beam_origin, Color(0.3, 0.6, 1.0), 0.08, 0.5)
		_animate_rail_gun_flash(flash, 0.2)


static func _create_plasma_discharge_flash(visual_node: Node3D) -> void:
	var muzzle_points: Array = visual_node.get_meta("muzzle_flash_points", [])
	for point in muzzle_points:
		if point is Vector3:
			var flash := _create_weapon_flash_node(visual_node, point, Color(0.8, 0.2, 0.9), 0.15, 0.12)
			_animate_plasma_flash(flash, 0.25)


static func _create_tesla_arc_flash(visual_node: Node3D) -> void:
	# Tesla coils create arcing effects between the top sphere and nearby points
	var tesla_pos: Vector3 = visual_node.get_meta("tesla_discharge_point", Vector3.ZERO)
	if tesla_pos != Vector3.ZERO:
		_create_tesla_arc_effects(visual_node, tesla_pos)


## Creates basic weapon flash node with specified properties
static func _create_weapon_flash_node(visual_node: Node3D, position: Vector3, color: Color, radius: float, duration: float) -> MeshInstance3D:
	var flash := MeshInstance3D.new()
	flash.name = "WeaponFlash"
	
	var flash_mesh := SphereMesh.new()
	flash_mesh.radius = radius
	flash_mesh.height = radius * 2.0
	
	var flash_mat := StandardMaterial3D.new()
	flash_mat.albedo_color = color
	flash_mat.emission_enabled = true
	flash_mat.emission = color
	flash_mat.emission_energy_multiplier = 10.0
	flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flash_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	flash_mesh.material = flash_mat
	flash.mesh = flash_mesh
	flash.position = position
	
	visual_node.add_child(flash)
	return flash


## Animates autocannon muzzle flash with quick strobe
static func _animate_autocannon_flash(flash_node: MeshInstance3D, duration: float) -> void:
	var tween := flash_node.create_tween()
	tween.tween_property(flash_node, "modulate:a", 0.0, duration)
	tween.tween_callback(flash_node.queue_free)


## Animates missile launch flash with expanding smoke
static func _animate_missile_flash(flash_node: MeshInstance3D, duration: float) -> void:
	var tween := flash_node.create_tween()
	tween.set_parallel(true)
	tween.tween_property(flash_node, "scale", Vector3(3.0, 3.0, 3.0), duration)
	tween.tween_property(flash_node, "modulate:a", 0.0, duration)
	tween.tween_callback(flash_node.queue_free)


## Animates rail gun energy discharge with beam effects
static func _animate_rail_gun_flash(flash_node: MeshInstance3D, duration: float) -> void:
	var tween := flash_node.create_tween()
	tween.set_parallel(true)
	# Brief intense flash followed by linear fade
	tween.tween_property(flash_node, "scale", Vector3(1.0, 1.0, 8.0), duration * 0.1)  # Beam stretch
	tween.tween_property(flash_node, "scale", Vector3(0.2, 0.2, 8.0), duration * 0.9).set_delay(duration * 0.1)
	tween.tween_property(flash_node, "modulate:a", 0.0, duration)
	tween.tween_callback(flash_node.queue_free)


## Animates plasma discharge with pulsing energy
static func _animate_plasma_flash(flash_node: MeshInstance3D, duration: float) -> void:
	var tween := flash_node.create_tween()
	tween.set_parallel(true)
	# Pulsing effect
	tween.tween_method(
		func(scale): flash_node.scale = Vector3(scale, scale, scale),
		1.0, 2.5, duration * 0.3
	)
	tween.tween_method(
		func(scale): flash_node.scale = Vector3(scale, scale, scale),
		2.5, 1.0, duration * 0.7
	).set_delay(duration * 0.3)
	tween.tween_property(flash_node, "modulate:a", 0.0, duration)
	tween.tween_callback(flash_node.queue_free)


## Creates tesla arc effects between coil and nearby targets
static func _create_tesla_arc_effects(visual_node: Node3D, tesla_position: Vector3) -> void:
	# Create multiple arc lines radiating from tesla coil
	for i in range(3):
		var arc_target: Vector3 = tesla_position + Vector3(
			randf_range(-2.0, 2.0),
			randf_range(-0.5, 0.5), 
			randf_range(-2.0, 2.0)
		)
		_create_tesla_arc_line(visual_node, tesla_position, arc_target)


## Creates a single tesla arc line effect
static func _create_tesla_arc_line(visual_node: Node3D, start_pos: Vector3, end_pos: Vector3) -> void:
	var arc := MeshInstance3D.new()
	arc.name = "TeslaArc"
	
	# Create a cylinder representing the electric arc
	var arc_mesh := CylinderMesh.new()
	var distance: float = start_pos.distance_to(end_pos)
	arc_mesh.height = distance
	arc_mesh.top_radius = 0.02
	arc_mesh.bottom_radius = 0.02
	
	var arc_mat := StandardMaterial3D.new()
	arc_mat.albedo_color = Color(0.6, 0.4, 1.0, 0.8)
	arc_mat.emission_enabled = true
	arc_mat.emission = Color(0.6, 0.4, 1.0)
	arc_mat.emission_energy_multiplier = 8.0
	arc_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	arc_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	arc_mesh.material = arc_mat
	arc.mesh = arc_mesh
	
	# Position and orient the arc between start and end points
	var mid_point: Vector3 = (start_pos + end_pos) * 0.5
	arc.position = mid_point
	arc.look_at(end_pos, Vector3.UP)
	
	visual_node.add_child(arc)
	
	# Animate the arc with flickering and fade
	var tween := visual_node.create_tween()
	tween.set_parallel(true)
	
	# Flickering effect
	for flicker_i in range(5):
		tween.tween_property(arc, "modulate:a", randf_range(0.3, 1.0), 0.02).set_delay(flicker_i * 0.04)
	
	# Final fade
	tween.tween_property(arc, "modulate:a", 0.0, 0.1).set_delay(0.2)
	tween.tween_callback(arc.queue_free).set_delay(0.3)


## Task 1B: Enhanced charge buildup animations
static func _create_tesla_charge_buildup(visual_node: Node3D, charge_duration: float) -> void:
	# Find tesla coil nodes and create charge effects
	for child in visual_node.get_children():
		if "Sphere" in child.name or "Emissive" in child.name:
			var mesh_inst := child as MeshInstance3D
			if mesh_inst and mesh_inst.mesh:
				var mat: StandardMaterial3D = mesh_inst.mesh.material as StandardMaterial3D
				if mat and mat.emission_enabled:
					_animate_tesla_coil_charge(mesh_inst, charge_duration)


static func _create_rail_gun_charge_buildup(visual_node: Node3D, charge_duration: float) -> void:
	# Animate the energy conduit system charging up
	if visual_node.has_meta("supports_sequential_coil_activation"):
		animate_energy_charge_sequence(visual_node, charge_duration)


static func _create_plasma_charge_buildup(visual_node: Node3D, charge_duration: float) -> void:
	# Create pulsing plasma core effects
	for child in visual_node.get_children():
		if child is MeshInstance3D:
			var mesh_inst := child as MeshInstance3D
			if mesh_inst.name.contains("Plasma") or mesh_inst.name.contains("Core"):
				_animate_plasma_core_charge(mesh_inst, charge_duration)


## Animates tesla coil charging with crackling energy
static func _animate_tesla_coil_charge(coil_node: MeshInstance3D, duration: float) -> void:
	var mat: StandardMaterial3D = coil_node.mesh.material as StandardMaterial3D
	if not mat:
		return
	
	var base_emission: float = mat.emission_energy_multiplier
	var tween := coil_node.create_tween()
	
	# Building charge effect with crackling
	for i in range(int(duration * 10)):
		var intensity: float = base_emission + (float(i) / (duration * 10)) * base_emission * 3.0
		intensity += randf_range(-0.5, 0.5)  # Crackling effect
		tween.tween_method(
			func(energy): mat.emission_energy_multiplier = energy,
			mat.emission_energy_multiplier, intensity, 0.1
		)


## Animates plasma core charging with pulsing intensity
static func _animate_plasma_core_charge(core_node: MeshInstance3D, duration: float) -> void:
	var mat: StandardMaterial3D = core_node.mesh.material as StandardMaterial3D
	if not mat:
		return
	
	var base_emission: float = mat.emission_energy_multiplier
	var tween := core_node.create_tween()
	
	# Pulsing charge buildup
	for pulse_i in range(int(duration)):
		var target_intensity: float = base_emission * (2.0 + pulse_i)
		tween.tween_method(
			func(energy): mat.emission_energy_multiplier = energy,
			base_emission, target_intensity, 0.3
		)
		tween.tween_method(
			func(energy): mat.emission_energy_multiplier = energy,
			target_intensity, base_emission * 1.5, 0.7
		)


## Animates conveyor belt movement
static func animate_conveyor_belts(visual_node: Node3D, belt_speed: float = 1.0) -> void:
	var belt_positions: Array = visual_node.get_meta("conveyor_belt_nodes", [])
	for pos in belt_positions:
		if pos is Vector3:
			_create_conveyor_movement_effect(visual_node, pos, belt_speed)


## Creates visual conveyor belt movement effect
static func _create_conveyor_movement_effect(visual_node: Node3D, belt_position: Vector3, speed: float) -> void:
	# Create moving texture effect or moving objects on the belt
	# This would require UV animation or moving child objects
	# Implementation depends on specific conveyor visual design
	pass  # Placeholder for future implementation


# =============================================================================
# ENHANCED TOWER TURRET ANIMATIONS - TASK 1B
# =============================================================================

## Enhanced turret tracking with smooth acceleration and barrel elevation
static func animate_turret_advanced_tracking(visual_node: Node3D, target_position: Vector3, tracking_speed: float = 90.0) -> void:
	if not visual_node or not visual_node.has_meta("turret_body_node"):
		return
	
	var turret_path: String = visual_node.get_meta("turret_body_node")
	var turret_node := visual_node.get_node_or_null(NodePath(turret_path))
	if not turret_node:
		return
	
	var turret_pos: Vector3 = turret_node.global_position
	var target_dir: Vector3 = (target_position - turret_pos).normalized()
	var target_angle: float = atan2(target_dir.x, target_dir.z) * 180.0 / PI
	var current_angle: float = turret_node.rotation_degrees.y
	
	# Smooth angle interpolation
	var angle_diff := _normalize_angle_difference(target_angle - current_angle)
	var rotation_tween := visual_node.create_tween()
	rotation_tween.tween_method(
		func(angle): turret_node.rotation_degrees.y = angle,
		current_angle, current_angle + angle_diff, abs(angle_diff) / tracking_speed
	)
	
	# Enhanced barrel elevation for realistic targeting
	if visual_node.has_meta("barrel_assembly_node"):
		var barrel_path: String = visual_node.get_meta("barrel_assembly_node")
		var barrel_node := visual_node.get_node_or_null(NodePath(barrel_path))
		if barrel_node:
			var distance: float = turret_pos.distance_to(target_position)
			var elevation_angle: float = atan2(target_position.y - turret_pos.y, distance) * 180.0 / PI
			elevation_angle = clamp(elevation_angle, -10.0, 45.0)  # Physical limits
			
			var elevation_tween := visual_node.create_tween()
			elevation_tween.tween_property(barrel_node, "rotation_degrees:x", elevation_angle, 0.3)


## Enhanced barrel spinning animation for multi-barrel weapons
static func animate_turret_barrel_spinning(visual_node: Node3D, spin_duration: float = 2.0, max_speed: float = 1800.0) -> void:
	if not visual_node or not visual_node.has_meta("barrel_spinner_node"):
		return
	
	var spinner_path: String = visual_node.get_meta("barrel_spinner_node")
	var spinner_node := visual_node.get_node_or_null(NodePath(spinner_path))
	if not spinner_node:
		return
	
	var spin_tween := visual_node.create_tween()
	
	# Ramp up phase - realistic acceleration
	spin_tween.tween_method(
		func(speed): _set_barrel_spin_velocity(spinner_node, speed),
		0.0, max_speed, spin_duration * 0.2
	)
	
	# Sustained firing phase
	spin_tween.tween_delay(spin_duration * 0.6)
	
	# Ramp down phase - realistic deceleration
	spin_tween.tween_method(
		func(speed): _set_barrel_spin_velocity(spinner_node, speed),
		max_speed, 0.0, spin_duration * 0.2
	)


## Enhanced recoil animation with barrel displacement and muzzle effects
static func animate_turret_enhanced_recoil(visual_node: Node3D, recoil_strength: float = 0.15) -> void:
	if not visual_node:
		return
	
	# Main barrel recoil
	if visual_node.has_meta("barrel_assembly_node"):
		var barrel_path: String = visual_node.get_meta("barrel_assembly_node")
		var barrel_node := visual_node.get_node_or_null(NodePath(barrel_path))
		if barrel_node:
			var original_pos: Vector3 = barrel_node.position
			var recoil_tween := visual_node.create_tween()
			recoil_tween.set_parallel(true)
			
			# Sharp recoil backward
			recoil_tween.tween_property(barrel_node, "position", 
				original_pos + Vector3(0, 0, -recoil_strength), 0.05)
			
			# Gradual return with slight overshoot for realism
			recoil_tween.tween_property(barrel_node, "position", 
				original_pos + Vector3(0, 0, 0.02), 0.2).set_delay(0.05)
			recoil_tween.tween_property(barrel_node, "position", 
				original_pos, 0.1).set_delay(0.25)
	
	# Turret body slight shake for heavy weapons
	if visual_node.has_meta("turret_body_node"):
		var turret_path: String = visual_node.get_meta("turret_body_node")
		var turret_node := visual_node.get_node_or_null(NodePath(turret_path))
		if turret_node:
			var shake_tween := visual_node.create_tween()
			var original_rot: Vector3 = turret_node.rotation_degrees
			shake_tween.tween_property(turret_node, "rotation_degrees", 
				original_rot + Vector3(randf_range(-0.5, 0.5), 0, randf_range(-0.5, 0.5)), 0.08)
			shake_tween.tween_property(turret_node, "rotation_degrees", original_rot, 0.12)


## Advanced muzzle flash with dynamic lighting and particle effects
static func animate_turret_advanced_muzzle_flash(visual_node: Node3D, weapon_type: String = "autocannon") -> void:
	if not visual_node:
		return
	
	# Create enhanced muzzle flash based on weapon type
	match weapon_type:
		"autocannon":
			_create_autocannon_muzzle_flash(visual_node)
		"missile":
			_create_missile_launch_flash(visual_node)
		"rail_gun":
			_create_rail_gun_discharge(visual_node)
		"plasma":
			_create_plasma_discharge_flash(visual_node)
		"tesla":
			_create_tesla_arc_flash(visual_node)


## Enhanced turret idle scanning with realistic search patterns
static func animate_turret_enhanced_idle_scan(visual_node: Node3D, scan_range: float = 60.0, scan_speed: float = 15.0) -> void:
	if not visual_node or not visual_node.has_meta("turret_body_node"):
		return
	
	var turret_path: String = visual_node.get_meta("turret_body_node")
	var turret_node := visual_node.get_node_or_null(NodePath(turret_path))
	if not turret_node:
		return
	
	var scan_tween := visual_node.create_tween()
	scan_tween.set_loops()
	
	# Realistic search pattern: pause, scan, pause, return
	var current_angle: float = turret_node.rotation_degrees.y
	
	# Scan to one side
	scan_tween.tween_property(turret_node, "rotation_degrees:y", 
		current_angle - scan_range/2, scan_range/(2*scan_speed))
	scan_tween.tween_delay(0.5)  # Brief pause to "look"
	
	# Scan across to other side
	scan_tween.tween_property(turret_node, "rotation_degrees:y", 
		current_angle + scan_range/2, scan_range/scan_speed)
	scan_tween.tween_delay(0.5)  # Brief pause
	
	# Return to center
	scan_tween.tween_property(turret_node, "rotation_degrees:y", 
		current_angle, scan_range/(2*scan_speed))
	scan_tween.tween_delay(1.0)  # Longer pause at center


## Advanced turret pre-fire charge animation for energy weapons
static func animate_turret_charge_sequence(visual_node: Node3D, charge_duration: float = 1.5, weapon_type: String = "tesla") -> void:
	if not visual_node:
		return
	
	match weapon_type:
		"tesla":
			_create_tesla_charge_buildup(visual_node, charge_duration)
		"rail_gun":
			_create_rail_gun_charge_buildup(visual_node, charge_duration)
		"plasma":
			_create_plasma_charge_buildup(visual_node, charge_duration)


## Missile battery tube reload animation with realistic mechanics
static func animate_turret_missile_reload(visual_node: Node3D, tube_count: int = 4, reload_duration: float = 3.0) -> void:
	if not visual_node:
		return
	
	# Simulate individual missile tube reloading with staggered timing
	for i in range(tube_count):
		var delay: float = i * 0.3  # Stagger reloads
		visual_node.get_tree().create_timer(delay).timeout.connect(
			func(): _animate_single_missile_reload(visual_node, i, reload_duration)
		)


# Helper functions for enhanced turret animations

static func _normalize_angle_difference(angle_diff: float) -> float:
	while angle_diff > 180.0:
		angle_diff -= 360.0
	while angle_diff < -180.0:
		angle_diff += 360.0
	return angle_diff


## Sets barrel spinner velocity for continuous rotation
static func _set_barrel_spin_velocity(spinner_node: Node3D, angular_velocity: float) -> void:
	if not spinner_node:
		return
	# Convert degrees per second to rotation delta
	var delta: float = angular_velocity * spinner_node.get_process_delta_time()
	spinner_node.rotation_degrees.z = fmod(spinner_node.rotation_degrees.z + delta, 360.0)


static func _create_tesla_arc_effect(visual_node: Node3D, intensity: float) -> void:
	# Create small electrical arc effect
	var arc := MeshInstance3D.new()
	arc.name = "ElectricalArc"
	
	var arc_mesh := CylinderMesh.new()
	arc_mesh.top_radius = 0.02
	arc_mesh.bottom_radius = 0.02
	arc_mesh.height = randf_range(0.3, 0.8)
	
	var arc_mat := StandardMaterial3D.new()
	arc_mat.albedo_color = Color(0.6, 0.8, 1.0, 0.8)
	arc_mat.emission_enabled = true
	arc_mat.emission = Color(0.8, 0.9, 1.0)
	arc_mat.emission_energy_multiplier = intensity
	arc_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	arc_mesh.material = arc_mat
	arc.mesh = arc_mesh
	arc.position = Vector3(randf_range(-0.2, 0.2), randf_range(0.5, 1.5), randf_range(-0.2, 0.2))
	
	visual_node.add_child(arc)
	
	# Quick fade and cleanup
	var arc_tween := visual_node.create_tween()
	arc_tween.tween_property(arc, "modulate:a", 0.0, 0.3)
	arc_tween.tween_callback(arc.queue_free)


static func _animate_single_missile_reload(visual_node: Node3D, missile_index: int, duration: float) -> void:
	# Simulate individual missile tube reloading
	# This would involve moving a missile visual into position
	# For now, create a simple loading effect
	var reload_pos := Vector3(0.2 * missile_index - 0.3, 0.8, 0.3)
	
	var missile := MeshInstance3D.new()
	missile.name = "ReloadingMissile"
	
	var missile_mesh := CylinderMesh.new()
	missile_mesh.top_radius = 0.04
	missile_mesh.bottom_radius = 0.04
	missile_mesh.height = 0.3
	
	var missile_mat := StandardMaterial3D.new()
	missile_mat.albedo_color = Color(0.4, 0.4, 0.5, 0.0)  # Start invisible
	
	missile_mesh.material = missile_mat
	missile.mesh = missile_mesh
	missile.position = reload_pos + Vector3(0, -0.5, 0)  # Start below
	
	visual_node.add_child(missile)
	
	# Loading animation: rise into position and fade in
	var reload_tween := visual_node.create_tween()
	reload_tween.set_parallel(true)
	reload_tween.tween_property(missile, "position", reload_pos, duration)
	reload_tween.tween_property(missile, "modulate:a", 1.0, duration)
	reload_tween.tween_callback(missile.queue_free).set_delay(duration + 1.0)


# =============================================================================
# TASK 1B: ENHANCED TURRET ANIMATION SYSTEM
# =============================================================================

## Initialize turret animation components from visual metadata
static func setup_turret_animations(tower_node: Node3D) -> void:
	if not tower_node or not tower_node.has_child("Visual"):
		return
	
	var visual_node := tower_node.get_node("Visual")
	if not visual_node.has_meta("supports_rotation"):
		return
	
	# Extract animation node references from metadata
	var turret_body_path: String = visual_node.get_meta("turret_body_node", "")
	var barrel_assembly_path: String = visual_node.get_meta("barrel_assembly_node", "")
	var barrel_spinner_path: String = visual_node.get_meta("barrel_spinner_node", "")
	
	# Store references on the tower for easy access during combat
	if not turret_body_path.is_empty():
		var turret_node := visual_node.get_node_or_null(NodePath(turret_body_path))
		if turret_node:
			tower_node.set_meta("turret_body", turret_node)
			tower_node.set_meta("supports_rotation", true)
	
	if not barrel_assembly_path.is_empty():
		var barrel_node := visual_node.get_node_or_null(NodePath(barrel_assembly_path))
		if barrel_node:
			tower_node.set_meta("barrel_assembly", barrel_node)
			tower_node.set_meta("supports_elevation", true)
			tower_node.set_meta("supports_recoil", visual_node.has_meta("supports_recoil"))
	
	if not barrel_spinner_path.is_empty():
		var spinner_node := visual_node.get_node_or_null(NodePath(barrel_spinner_path))
		if spinner_node:
			tower_node.set_meta("barrel_spinner", spinner_node)
			tower_node.set_meta("supports_barrel_spin", true)
	
	# Initialize idle scan state
	tower_node.set_meta("idle_scan_direction", 1)
	tower_node.set_meta("idle_scan_timer", 0.0)
	tower_node.set_meta("base_rotation", 0.0)


## Enhanced turret tracking with realistic physics and constraints
static func animate_turret_tracking(tower_node: Node3D, target_position: Vector3) -> void:
	if not tower_node.has_meta("turret_body"):
		return
	
	var turret_body: Node3D = tower_node.get_meta("turret_body")
	var tower_pos: Vector3 = tower_node.global_position

	# Calculate horizontal rotation (turret body)
	var to_target: Vector3 = (target_position - tower_pos)
	to_target.y = 0  # Flatten for horizontal rotation
	var target_angle: float = rad_to_deg(atan2(to_target.x, to_target.z))

	# Smooth rotation with realistic constraints
	var current_angle: float = turret_body.rotation_degrees.y
	var angle_diff := _normalize_angle_difference(target_angle - current_angle)
	
	# Limit rotation speed for realism (120 deg/sec max)
	var max_rotation_speed := 120.0
	var frame_time := tower_node.get_process_delta_time()
	var max_turn_this_frame := max_rotation_speed * frame_time
	
	if abs(angle_diff) > max_turn_this_frame:
		angle_diff = sign(angle_diff) * max_turn_this_frame
	
	turret_body.rotation_degrees.y = current_angle + angle_diff
	
	# Calculate barrel elevation if supported
	if tower_node.has_meta("barrel_assembly"):
		var barrel_assembly: Node3D = tower_node.get_meta("barrel_assembly")
		var distance: float = tower_pos.distance_to(target_position)
		var height_diff: float = target_position.y - tower_pos.y
		var elevation_angle: float = rad_to_deg(atan2(height_diff, distance))
		
		# Apply realistic elevation constraints (-10 to +45 degrees)
		elevation_angle = clamp(elevation_angle, -10.0, 45.0)
		
		# Smooth elevation change
		var current_elevation: float = barrel_assembly.rotation_degrees.x
		var elevation_diff: float = elevation_angle - current_elevation
		var max_elevation_speed := 60.0  # degrees per second
		var max_elevation_this_frame := max_elevation_speed * frame_time
		
		if abs(elevation_diff) > max_elevation_this_frame:
			elevation_diff = sign(elevation_diff) * max_elevation_this_frame
		
		barrel_assembly.rotation_degrees.x = current_elevation + elevation_diff


## Enhanced idle scanning animation with natural movement patterns
static func animate_turret_idle_scan(tower_node: Node3D, delta: float) -> void:
	if not tower_node.has_meta("turret_body"):
		return
	
	var turret_body: Node3D = tower_node.get_meta("turret_body")
	var scan_direction: int = tower_node.get_meta("idle_scan_direction", 1)
	var scan_timer: float = tower_node.get_meta("idle_scan_timer", 0.0)
	var base_rotation: float = tower_node.get_meta("base_rotation", 0.0)
	
	# Scanning parameters
	var scan_speed := 25.0  # degrees per second
	var scan_range := 60.0  # total scan range
	var pause_duration := 1.0  # pause at each end
	
	scan_timer += delta
	
	# Calculate target angle based on scan pattern
	var scan_progress := sin(scan_timer * 0.8) * 0.5 + 0.5  # Smooth sine wave 0-1
	var target_angle := base_rotation + (scan_progress - 0.5) * scan_range
	
	# Smooth movement toward target angle
	var current_angle := turret_body.rotation_degrees.y
	var angle_diff := _normalize_angle_difference(target_angle - current_angle)
	var max_turn := scan_speed * delta
	
	if abs(angle_diff) > max_turn:
		angle_diff = sign(angle_diff) * max_turn
	
	turret_body.rotation_degrees.y = current_angle + angle_diff
	
	# Update timer metadata
	tower_node.set_meta("idle_scan_timer", scan_timer)


## Enhanced firing animation with weapon-specific effects
static func animate_turret_firing_sequence(tower_node: Node3D, weapon_type: String) -> void:
	match weapon_type:
		"autocannon":
			_animate_autocannon_firing(tower_node)
		"missile_battery":
			_animate_missile_launch(tower_node)
		"rail_gun":
			_animate_rail_gun_firing(tower_node)
		"plasma_mortar":
			_animate_plasma_firing(tower_node)
		"tesla_coil":
			_animate_tesla_discharge(tower_node)
		"inferno_tower":
			_animate_flame_discharge(tower_node)
		_:
			# Generic firing animation
			_animate_generic_firing(tower_node)


## Autocannon firing animation with barrel spin and muzzle flash
static func _animate_autocannon_firing(tower_node: Node3D) -> void:
	# Start barrel spin
	if tower_node.has_meta("barrel_spinner"):
		var spinner: Node3D = tower_node.get_meta("barrel_spinner")
		var spin_tween := tower_node.create_tween()
		
		# Spin up, sustain, spin down
		for i in range(20):  # 20 shots over 2 seconds
			var delay := i * 0.1
			spin_tween.tween_callback(_create_autocannon_muzzle_flash_at_spinner.bind(spinner)).set_delay(delay)
			
		# Barrel spin animation
		var barrel_tween := tower_node.create_tween()
		barrel_tween.set_loops()
		barrel_tween.tween_property(spinner, "rotation_degrees:z", spinner.rotation_degrees.z + 360, 0.1)
	
	# Recoil animation
	if tower_node.has_meta("supports_recoil"):
		_animate_barrel_recoil_enhanced(tower_node, 0.08, 2.0)


## Missile launch animation with sequential firing
static func _animate_missile_launch(tower_node: Node3D) -> void:
	if not tower_node.has_child("Visual"):
		return
	
	var visual_node := tower_node.get_node("Visual")
	
	# Find missile launch points from metadata
	var launch_points: Array = visual_node.get_meta("missile_launch_points", [])
	for i in range(min(4, launch_points.size())):
		var delay := i * 0.3  # Stagger launches
		tower_node.get_tree().create_timer(delay).timeout.connect(
			func(): _create_missile_launch_effect(visual_node, launch_points[i])
		)


## Rail gun firing with charge buildup and energy discharge
static func _animate_rail_gun_firing(tower_node: Node3D) -> void:
	if not tower_node.has_child("Visual"):
		return
	
	var visual_node := tower_node.get_node("Visual")
	
	# Energy charge sequence
	_create_rail_gun_charge_buildup(visual_node, 1.0)
	
	# Discharge and recoil after charge
	tower_node.get_tree().create_timer(1.0).timeout.connect(
		func(): 
			_create_rail_gun_discharge(visual_node)
			_animate_barrel_recoil_enhanced(tower_node, 0.2, 1.0)
	)


## Tesla coil discharge with electrical arcs
static func _animate_tesla_discharge(tower_node: Node3D) -> void:
	if not tower_node.has_child("Visual"):
		return
	
	var visual_node := tower_node.get_node("Visual")
	
	# Create multiple electrical arcs
	for i in range(5):
		var delay := i * 0.05
		tower_node.get_tree().create_timer(delay).timeout.connect(
			func(): _create_tesla_arc_effect(visual_node, 4.0 + i * 0.5)
		)


## Enhanced barrel recoil with realistic physics
static func _animate_barrel_recoil_enhanced(tower_node: Node3D, recoil_distance: float, duration: float) -> void:
	if not tower_node.has_meta("barrel_assembly"):
		return
	
	var barrel: Node3D = tower_node.get_meta("barrel_assembly")
	var original_pos := barrel.position
	
	var recoil_tween := tower_node.create_tween()
	recoil_tween.set_ease(Tween.EASE_OUT)
	recoil_tween.set_trans(Tween.TRANS_BACK)
	
	# Sharp recoil back
	recoil_tween.tween_property(barrel, "position", 
		original_pos + Vector3(0, 0, -recoil_distance), duration * 0.1)
	
	# Slow return with slight overshoot
	recoil_tween.tween_property(barrel, "position", 
		original_pos + Vector3(0, 0, 0.02), duration * 0.6)
	
	# Settle to original position  
	recoil_tween.tween_property(barrel, "position", original_pos, duration * 0.3)


## Create enhanced muzzle flash for spinning barrels
static func _create_autocannon_muzzle_flash_at_spinner(spinner_node: Node3D) -> void:
	if not spinner_node:
		return
	
	# Create flash at current barrel positions
	var barrel_count := 2  # Twin barrels
	for i in range(barrel_count):
		var flash_pos := Vector3((-0.08 if i == 0 else 0.08), 0, 0.5)
		
		var flash := MeshInstance3D.new()
		flash.name = "MuzzleFlash" + str(i)
		
		var flash_mesh := SphereMesh.new()
		flash_mesh.radius = 0.06
		flash_mesh.height = 0.12
		
		var flash_mat := StandardMaterial3D.new()
		flash_mat.albedo_color = Color(1.0, 0.85, 0.3)
		flash_mat.emission_enabled = true
		flash_mat.emission = Color(1.0, 0.75, 0.2)
		flash_mat.emission_energy_multiplier = 6.0
		flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		
		flash_mesh.material = flash_mat
		flash.mesh = flash_mesh
		flash.position = flash_pos
		
		spinner_node.add_child(flash)
		
		# Quick flash and fade
		var flash_tween := spinner_node.create_tween()
		flash_tween.tween_property(flash, "modulate:a", 0.0, 0.08)
		flash_tween.tween_callback(flash.queue_free)


## Create missile launch effect with smoke trail
static func _create_missile_launch_effect(visual_node: Node3D, launch_point: Vector3) -> void:
	# Bright launch flash
	var flash := MeshInstance3D.new()
	flash.name = "LaunchFlash"
	
	var flash_mesh := SphereMesh.new()
	flash_mesh.radius = 0.1
	
	var flash_mat := StandardMaterial3D.new()
	flash_mat.albedo_color = Color(1.0, 0.6, 0.2)
	flash_mat.emission_enabled = true
	flash_mat.emission = Color(1.0, 0.5, 0.1)
	flash_mat.emission_energy_multiplier = 8.0
	flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	flash_mesh.material = flash_mat
	flash.mesh = flash_mesh
	flash.position = launch_point
	
	visual_node.add_child(flash)
	
	# Flash animation
	var flash_tween := visual_node.create_tween()
	flash_tween.set_parallel(true)
	flash_tween.tween_property(flash, "scale", Vector3(2.0, 2.0, 2.0), 0.2)
	flash_tween.tween_property(flash, "modulate:a", 0.0, 0.2)
	flash_tween.tween_callback(flash.queue_free)
	
	# Smoke trail effect
	for i in range(8):
		var delay := i * 0.05
		visual_node.get_tree().create_timer(delay).timeout.connect(
			func(): _create_smoke_puff(visual_node, launch_point + Vector3(0, i * 0.1, 0))
		)


## Create smoke puff for missile trails and steam vents
static func _create_smoke_puff(visual_node: Node3D, position: Vector3) -> void:
	var smoke := MeshInstance3D.new()
	smoke.name = "SmokePuff"
	
	var smoke_mesh := SphereMesh.new()
	smoke_mesh.radius = 0.05
	
	var smoke_mat := StandardMaterial3D.new()
	smoke_mat.albedo_color = Color(0.7, 0.7, 0.8, 0.6)
	smoke_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	smoke_mesh.material = smoke_mat
	smoke.mesh = smoke_mesh
	smoke.position = position
	
	visual_node.add_child(smoke)
	
	# Smoke rises and dissipates
	var smoke_tween := visual_node.create_tween()
	smoke_tween.set_parallel(true)
	smoke_tween.tween_property(smoke, "position", position + Vector3(0, 0.4, 0), 1.5)
	smoke_tween.tween_property(smoke, "scale", Vector3(2.0, 2.0, 2.0), 1.5)
	smoke_tween.tween_property(smoke, "modulate:a", 0.0, 1.5)
	smoke_tween.tween_callback(smoke.queue_free)


## Generic firing animation fallback
static func _animate_generic_firing(tower_node: Node3D) -> void:
	# Simple recoil for any tower
	if tower_node.has_meta("barrel_assembly"):
		_animate_barrel_recoil_enhanced(tower_node, 0.05, 0.5)
	
	# Flash effect at tower center if no specific muzzle points
	if tower_node.has_child("Visual"):
		var visual_node := tower_node.get_node("Visual")
		var flash_pos := Vector3(0, 1.0, 0.5)  # Default position
		_create_generic_muzzle_flash(visual_node, flash_pos)


## Create generic muzzle flash
static func _create_generic_muzzle_flash(visual_node: Node3D, position: Vector3) -> void:
	var flash := MeshInstance3D.new()
	flash.name = "MuzzleFlash"
	
	var flash_mesh := SphereMesh.new()
	flash_mesh.radius = 0.08
	
	var flash_mat := StandardMaterial3D.new()
	flash_mat.albedo_color = Color(1.0, 0.8, 0.4)
	flash_mat.emission_enabled = true
	flash_mat.emission = Color(1.0, 0.7, 0.3)
	flash_mat.emission_energy_multiplier = 4.0
	flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	flash_mesh.material = flash_mat
	flash.mesh = flash_mesh
	flash.position = position
	
	visual_node.add_child(flash)
	
	var flash_tween := visual_node.create_tween()
	flash_tween.tween_property(flash, "modulate:a", 0.0, 0.15)
	flash_tween.tween_callback(flash.queue_free)


## Plasma mortar firing animation
static func _animate_plasma_firing(tower_node: Node3D) -> void:
	if not tower_node.has_child("Visual"):
		return
	
	var visual_node := tower_node.get_node("Visual")
	
	# Plasma buildup
	_create_plasma_charge_buildup(visual_node, 0.8)
	
	# Launch after buildup
	tower_node.get_tree().create_timer(0.8).timeout.connect(
		func(): 
			var launch_pos := Vector3(0, 1.2, 0.3)  # Mortar tube position
			_create_plasma_launch_effect(visual_node, launch_pos)
	)


## Create plasma launch effect
static func _create_plasma_launch_effect(visual_node: Node3D, position: Vector3) -> void:
	var plasma := MeshInstance3D.new()
	plasma.name = "PlasmaLaunch"
	
	var plasma_mesh := SphereMesh.new()
	plasma_mesh.radius = 0.12
	
	var plasma_mat := StandardMaterial3D.new()
	plasma_mat.albedo_color = Color(1.0, 0.3, 0.8)
	plasma_mat.emission_enabled = true
	plasma_mat.emission = Color(1.0, 0.2, 0.6)
	plasma_mat.emission_energy_multiplier = 10.0
	plasma_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	plasma_mesh.material = plasma_mat
	plasma.mesh = plasma_mesh
	plasma.position = position
	
	visual_node.add_child(plasma)
	
	# Plasma projectile animation (brief visibility before it flies away)
	var plasma_tween := visual_node.create_tween()
	plasma_tween.set_parallel(true)
	plasma_tween.tween_property(plasma, "position", position + Vector3(0, 2.0, 0), 0.3)
	plasma_tween.tween_property(plasma, "modulate:a", 0.0, 0.3)
	plasma_tween.tween_callback(plasma.queue_free)


## Flame thrower discharge animation
static func _animate_flame_discharge(tower_node: Node3D) -> void:
	if not tower_node.has_child("Visual"):
		return
	
	var visual_node := tower_node.get_node("Visual")
	
	# Create flame stream effect
	for i in range(10):
		var delay := i * 0.05
		tower_node.get_tree().create_timer(delay).timeout.connect(
			func(): _create_flame_puff(visual_node, Vector3(0, 1.3, 0.5 + i * 0.1))
		)


## Create flame puff effect
static func _create_flame_puff(visual_node: Node3D, position: Vector3) -> void:
	var flame := MeshInstance3D.new()
	flame.name = "FlamePuff"
	
	var flame_mesh := SphereMesh.new()
	flame_mesh.radius = 0.08
	
	var flame_mat := StandardMaterial3D.new()
	flame_mat.albedo_color = Color(1.0, 0.5, 0.1, 0.8)
	flame_mat.emission_enabled = true
	flame_mat.emission = Color(1.0, 0.4, 0.1)
	flame_mat.emission_energy_multiplier = 4.0
	flame_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flame_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	flame_mesh.material = flame_mat
	flame.mesh = flame_mesh
	flame.position = position
	
	visual_node.add_child(flame)
	
	# Flame flickers and fades
	var flame_tween := visual_node.create_tween()
	flame_tween.set_parallel(true)
	flame_tween.tween_property(flame, "scale", Vector3(1.5, 1.5, 1.5), 0.4)
	flame_tween.tween_property(flame, "modulate:a", 0.0, 0.4)
	flame_tween.tween_callback(flame.queue_free)
