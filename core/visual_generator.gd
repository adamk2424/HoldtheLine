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
	## Military turret on pillar: rotating drum + twin barrels
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.3)
	var lite := c.lightened(0.2)
	var h := _add_tower_pedestal(r, 0.3, 0.6, c)
	# Turret body
	_add_box(r, Vector3(0.5, 0.45, 0.5), Vector3(0, h + 0.225, 0), c)
	# Barrel mount
	_add_box(r, Vector3(0.25, 0.2, 0.15), Vector3(0, h + 0.35, 0.32), lite)
	# Twin barrels
	_add_box(r, Vector3(0.06, 0.06, 0.6), Vector3(-0.08, h + 0.38, 0.6), lite)
	_add_box(r, Vector3(0.06, 0.06, 0.6), Vector3(0.08, h + 0.38, 0.6), lite)
	# Ammo box on side
	_add_box(r, Vector3(0.18, 0.15, 0.18), Vector3(-0.3, h + 0.2, 0), dark)
	# Muzzle flash emissive tips
	_add_muzzle_sphere(r, 0.04, Vector3(-0.08, h + 0.38, 0.9), Color(1.0, 0.8, 0.2), 2.0)
	_add_muzzle_sphere(r, 0.04, Vector3(0.08, h + 0.38, 0.9), Color(1.0, 0.8, 0.2), 2.0)
	return r


static func _create_missile_battery(c: Color) -> Node3D:
	## Missile launcher on pillar: 4 launch tubes + radar dish
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.3)
	var h := _add_tower_pedestal(r, 0.35, 0.7, c)
	# Launcher housing
	_add_box(r, Vector3(0.7, 0.4, 0.7), Vector3(0, h + 0.2, 0), c)
	# 4 missile tubes
	for tx in [-0.13, 0.13]:
		for tz in [-0.13, 0.13]:
			_add_cylinder(r, 0.07, 0.35, Vector3(tx, h + 0.575, tz), c.darkened(0.15))
	# Tube openings (emissive)
	for tx in [-0.13, 0.13]:
		for tz in [-0.13, 0.13]:
			_add_muzzle_sphere(r, 0.05, Vector3(tx, h + 0.75, tz), Color(0.9, 0.5, 0.1), 1.5)
	# Small radar dish on back
	_add_cylinder(r, 0.12, 0.03, Vector3(0, h + 0.55, -0.3), c.lightened(0.2))
	_add_cylinder(r, 0.02, 0.15, Vector3(0, h + 0.48, -0.3), c.lightened(0.1))
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
	## Sleek sniper on pillar: tall spine + long barrel with coil rings
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.3)
	var lite := c.lightened(0.2)
	var h := _add_tower_pedestal(r, 0.25, 0.5, c)
	# Support spine
	_add_box(r, Vector3(0.15, 1.2, 0.15), Vector3(0, h + 0.6, 0), c)
	# Barrel housing (extends forward along Z)
	_add_box(r, Vector3(0.1, 0.1, 1.0), Vector3(0, h + 1.1, 0.5), lite)
	# Coil rings around barrel
	for i in range(3):
		var z_pos: float = 0.2 + i * 0.3
		_add_emissive_box(r, Vector3(0.16, 0.16, 0.03), Vector3(0, h + 1.1, z_pos), Color(0.3, 0.5, 0.8), 1.5)
	# Emissive tip
	_add_muzzle_sphere(r, 0.06, Vector3(0, h + 1.1, 1.0), Color(0.4, 0.6, 1.0), 3.0)
	# Stabilizer fins
	_add_box(r, Vector3(0.4, 0.06, 0.06), Vector3(0, h + 0.15, 0), dark)
	_add_box(r, Vector3(0.06, 0.06, 0.4), Vector3(0, h + 0.15, 0), dark)
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
	# Foundation platform
	_add_box(r, Vector3(3.8, 0.25, 3.8), Vector3(0, 0.125, 0), dark)
	# Main processing building (taller)
	_add_box(r, Vector3(2.6, 1.3, 2.6), Vector3(0, 0.9, 0), c)
	# Roof
	_add_box(r, Vector3(2.7, 0.1, 2.7), Vector3(0, 1.6, 0), dark)
	# Dual hoppers
	_add_box(r, Vector3(0.9, 0.5, 0.9), Vector3(-0.5, 1.85, 0), dark)
	_add_box(r, Vector3(0.9, 0.5, 0.9), Vector3(0.5, 1.85, 0), dark)
	_add_box(r, Vector3(1.0, 0.08, 1.0), Vector3(-0.5, 2.14, 0), c.lightened(0.1))
	_add_box(r, Vector3(1.0, 0.08, 1.0), Vector3(0.5, 2.14, 0), c.lightened(0.1))
	# Conveyor belts
	_add_box(r, Vector3(3.4, 0.12, 0.6), Vector3(0, 0.3, 1.4), dark)
	_add_box(r, Vector3(3.4, 0.12, 0.6), Vector3(0, 0.3, -1.4), dark)
	# Output chutes (both sides)
	_add_box(r, Vector3(0.6, 0.5, 0.8), Vector3(1.4, 0.5, 0), dark)
	_add_box(r, Vector3(0.6, 0.5, 0.8), Vector3(-1.4, 0.5, 0), dark)
	# Status lights
	_add_emissive_sphere(r, 0.07, Vector3(1.3, 1.3, 1.3), accent, 2.5)
	_add_emissive_sphere(r, 0.07, Vector3(-1.3, 1.3, 1.3), accent, 2.5)
	_add_emissive_sphere(r, 0.07, Vector3(1.3, 1.3, -1.3), accent, 2.5)
	_add_emissive_sphere(r, 0.07, Vector3(-1.3, 1.3, -1.3), accent, 2.5)
	# Processing glow
	_add_emissive_sphere(r, 0.18, Vector3(-0.5, 1.8, 0), accent, 3.0)
	_add_emissive_sphere(r, 0.18, Vector3(0.5, 1.8, 0), accent, 3.0)
	return r


static func _create_recycler_t3(c: Color) -> Node3D:
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.25)
	var accent := Color(0.5, 1.0, 0.5)
	# Foundation platform
	_add_box(r, Vector3(3.9, 0.3, 3.9), Vector3(0, 0.15, 0), dark)
	# Main processing building (taller still)
	_add_box(r, Vector3(2.8, 1.6, 2.8), Vector3(0, 1.1, 0), c)
	# Roof
	_add_box(r, Vector3(2.9, 0.12, 2.9), Vector3(0, 1.96, 0), dark)
	# Large central hopper
	_add_box(r, Vector3(1.4, 0.6, 1.4), Vector3(0, 2.26, 0), dark)
	_add_box(r, Vector3(1.6, 0.1, 1.6), Vector3(0, 2.61, 0), c.lightened(0.1))
	# Conveyor belts (wider)
	_add_box(r, Vector3(3.6, 0.15, 0.7), Vector3(0, 0.35, 1.5), dark)
	_add_box(r, Vector3(3.6, 0.15, 0.7), Vector3(0, 0.35, -1.5), dark)
	# Heavy output chutes
	_add_box(r, Vector3(0.8, 0.6, 1.0), Vector3(1.5, 0.6, 0), dark)
	_add_box(r, Vector3(0.8, 0.6, 1.0), Vector3(-1.5, 0.6, 0), dark)
	# Exhaust stacks
	_add_cylinder(r, 0.08, 0.5, Vector3(1.1, 2.21, 1.1), dark)
	_add_cylinder(r, 0.08, 0.5, Vector3(-1.1, 2.21, -1.1), dark)
	# Corner status lights
	_add_emissive_sphere(r, 0.08, Vector3(1.4, 1.7, 1.4), accent, 3.0)
	_add_emissive_sphere(r, 0.08, Vector3(-1.4, 1.7, 1.4), accent, 3.0)
	_add_emissive_sphere(r, 0.08, Vector3(1.4, 1.7, -1.4), accent, 3.0)
	_add_emissive_sphere(r, 0.08, Vector3(-1.4, 1.7, -1.4), accent, 3.0)
	# Processing glow
	_add_emissive_sphere(r, 0.25, Vector3(0, 2.2, 0), accent, 4.0)
	# Capacitor banks on sides
	_add_box(r, Vector3(0.2, 0.4, 0.2), Vector3(1.2, 0.5, 1.2), c.darkened(0.15))
	_add_box(r, Vector3(0.2, 0.4, 0.2), Vector3(-1.2, 0.5, -1.2), c.darkened(0.15))
	_add_emissive_box(r, Vector3(2.81, 0.04, 2.81), Vector3(0, 1.0, 0), accent, 1.5)
	return r


# =============================================================================
# PRODUCTION BUILDINGS
# =============================================================================

static func _create_drone_printer(c: Color) -> Node3D:
	## Drone factory (2x2): base + main building + conveyor opening + arm + chimney
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.3)
	var lite := c.lightened(0.15)
	var status := Color(0.2, 1.0, 0.3)
	# Foundation
	_add_box(r, Vector3(1.8, 0.2, 1.8), Vector3(0, 0.1, 0), dark)
	# Main building
	_add_box(r, Vector3(1.5, 0.8, 1.5), Vector3(0, 0.6, 0), c)
	# Roof
	_add_box(r, Vector3(1.6, 0.08, 1.6), Vector3(0, 1.04, 0), dark)
	# Conveyor opening (dark recessed area on front)
	_add_box(r, Vector3(0.6, 0.4, 0.08), Vector3(0, 0.4, 0.76), dark.darkened(0.3))
	# Assembly arm on top
	_add_box(r, Vector3(0.08, 0.35, 0.08), Vector3(0.3, 1.26, 0), lite)
	_add_box(r, Vector3(0.4, 0.06, 0.06), Vector3(0.3, 1.42, 0.15), lite)
	# Chimney
	_add_cylinder(r, 0.08, 0.4, Vector3(-0.5, 1.28, -0.5), dark)
	# Status lights
	_add_emissive_sphere(r, 0.04, Vector3(0.6, 0.7, 0.76), status, 2.0)
	_add_emissive_sphere(r, 0.04, Vector3(-0.6, 0.7, 0.76), status, 2.0)
	# Window strip
	_add_emissive_box(r, Vector3(0.8, 0.12, 0.04), Vector3(0, 0.75, 0.76), Color(0.8, 0.7, 0.3), 1.0)
	return r


static func _create_mech_bay(c: Color) -> Node3D:
	## Heavy factory (3x2): large building + bay doors + crane arm + smoke stack
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.3)
	var lite := c.lightened(0.15)
	var warn := Color(1.0, 0.6, 0.1)
	# Foundation
	_add_box(r, Vector3(2.8, 0.2, 1.8), Vector3(0, 0.1, 0), dark)
	# Main building
	_add_box(r, Vector3(2.5, 1.2, 1.5), Vector3(0, 0.8, 0), c)
	# Roof
	_add_box(r, Vector3(2.6, 0.1, 1.6), Vector3(0, 1.45, 0), dark)
	# Bay door (large dark opening on front)
	_add_box(r, Vector3(1.0, 0.9, 0.08), Vector3(0, 0.65, 0.76), dark.darkened(0.4))
	# Door frame
	_add_box(r, Vector3(1.1, 0.06, 0.1), Vector3(0, 1.12, 0.76), lite)
	_add_box(r, Vector3(0.06, 0.9, 0.1), Vector3(-0.53, 0.65, 0.76), lite)
	_add_box(r, Vector3(0.06, 0.9, 0.1), Vector3(0.53, 0.65, 0.76), lite)
	# Crane arm extending from roof
	_add_box(r, Vector3(0.08, 0.6, 0.08), Vector3(0.8, 1.75, 0), lite)
	_add_box(r, Vector3(0.8, 0.06, 0.06), Vector3(0.8, 2.03, 0.3), lite)
	# Smoke stack
	_add_cylinder(r, 0.1, 0.6, Vector3(-0.9, 1.75, -0.5), dark)
	# Armored side plates
	_add_box(r, Vector3(0.06, 0.5, 1.2), Vector3(1.28, 0.65, 0), dark)
	_add_box(r, Vector3(0.06, 0.5, 1.2), Vector3(-1.28, 0.65, 0), dark)
	# Warning lights
	_add_emissive_sphere(r, 0.05, Vector3(0.53, 1.15, 0.76), warn, 2.5)
	_add_emissive_sphere(r, 0.05, Vector3(-0.53, 1.15, 0.76), warn, 2.5)
	# Window strip
	_add_emissive_box(r, Vector3(0.5, 0.1, 0.04), Vector3(0.8, 1.1, 0.76), Color(0.7, 0.7, 0.3), 1.0)
	return r


static func _create_war_factory(c: Color) -> Node3D:
	## Massive factory (3x3): huge building + chimneys + vehicle ramp + armored walls
	var r := Node3D.new()
	r.name = "Visual"
	var dark := c.darkened(0.3)
	var lite := c.lightened(0.15)
	var warn := Color(1.0, 0.3, 0.1)
	# Foundation
	_add_box(r, Vector3(2.8, 0.2, 2.8), Vector3(0, 0.1, 0), dark)
	# Main building
	_add_box(r, Vector3(2.5, 1.3, 2.5), Vector3(0, 0.85, 0), c)
	# Roof
	_add_box(r, Vector3(2.6, 0.1, 2.6), Vector3(0, 1.55, 0), dark)
	# Vehicle exit (large opening + ramp)
	_add_box(r, Vector3(1.2, 1.0, 0.08), Vector3(0, 0.7, 1.26), dark.darkened(0.4))
	_add_box(r, Vector3(1.2, 0.06, 0.5), Vector3(0, 0.22, 1.5), dark)
	# Door frame
	_add_box(r, Vector3(1.3, 0.08, 0.1), Vector3(0, 1.22, 1.26), lite)
	# Multiple chimneys
	_add_cylinder(r, 0.1, 0.5, Vector3(-0.8, 1.8, -0.8), dark)
	_add_cylinder(r, 0.1, 0.5, Vector3(-0.5, 1.8, -0.8), dark)
	_add_cylinder(r, 0.08, 0.4, Vector3(0.8, 1.75, -0.7), dark)
	# Armored wall panels
	_add_box(r, Vector3(0.08, 0.6, 2.0), Vector3(1.28, 0.7, 0), dark)
	_add_box(r, Vector3(0.08, 0.6, 2.0), Vector3(-1.28, 0.7, 0), dark)
	# Heavy reinforcement ribs
	for i in range(3):
		var z_pos: float = -0.8 + i * 0.8
		_add_box(r, Vector3(2.55, 0.06, 0.08), Vector3(0, 1.0, z_pos), dark)
	# Warning lights at entrance
	_add_emissive_sphere(r, 0.06, Vector3(0.65, 1.25, 1.26), warn, 3.0)
	_add_emissive_sphere(r, 0.06, Vector3(-0.65, 1.25, 1.26), warn, 3.0)
	# Window strips on sides
	_add_emissive_box(r, Vector3(0.04, 0.1, 1.5), Vector3(1.28, 1.1, 0), Color(0.7, 0.6, 0.3), 1.0)
	_add_emissive_box(r, Vector3(0.04, 0.1, 1.5), Vector3(-1.28, 1.1, 0), Color(0.7, 0.6, 0.3), 1.0)
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
