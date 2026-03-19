class_name TowerBase
extends EntityBase
## TowerBase - Base class for all tower entities.
## Placed on the BuildGrid, has HealthComponent + CombatComponent (auto-targeting enemies).
## Tracks build progress with a construction animation (scale 0 -> 1 over build_time).
## On death: emits entity_died, frees grid cells.

signal build_completed_signal()

# Build state
var build_time: float = 5.0
var build_timer: float = 0.0
var is_building: bool = true
var is_built: bool = false

# Sell cost tracking (base costs for 50% refund)
var base_cost_energy: float = 0.0
var base_cost_materials: float = 0.0
var total_invested_energy: float = 0.0
var total_invested_materials: float = 0.0

# Upgrade tracking
var current_upgrade_index: int = -1  # -1 = no upgrade applied
var upgrade_paths: Array = []
var sequential_upgrades: bool = false  # true = tier-based upgrades (tier 2, tier 3, etc.)
var current_tier: int = 0  # 0 = base, 1 = tier 2 applied, 2 = tier 3 applied, etc.

# Selection state
var is_selected: bool = false
var selection_ring: MeshInstance3D = null

# Health bar reference
var health_bar: Node3D = null
var health_bar_width: float = 1.0

# Muzzle flash
var _muzzle_nodes: Array = []
var _muzzle_flash_active: bool = false

# Turret animation components
var turret_body_node: Node3D = null
var barrel_assembly_node: Node3D = null
var barrel_spinner_node: Node3D = null
var supports_rotation: bool = false
var supports_elevation: bool = false
var supports_barrel_spin: bool = false

# Animation state
var _target_rotation: float = 0.0
var _current_rotation: float = 0.0
var _target_elevation: float = 0.0
var _current_elevation: float = 0.0
var _barrel_spin_velocity: float = 0.0
var _is_firing: bool = false

# Idle animation state
var _idle_scan_direction: int = 1  # 1 for right, -1 for left
var _idle_scan_timer: float = 0.0
var _idle_scan_speed: float = 30.0  # degrees per second
var _idle_scan_range: float = 60.0  # total scan range in degrees

# Animation tweens
var _rotation_tween: Tween = null
var _elevation_tween: Tween = null

# Reference to the BuildGrid (set by whoever spawns the tower)
var build_grid: BuildGrid = null


func _ready() -> void:
	super._ready()
	add_to_group("tower")


func initialize(p_entity_id: String, p_entity_type: String, p_data: Dictionary = {}) -> void:
	super.initialize(p_entity_id, p_entity_type, p_data)

	build_time = float(data.get("build_time", 5.0))
	base_cost_energy = float(data.get("cost_energy", 0))
	base_cost_materials = float(data.get("cost_materials", 0))
	total_invested_energy = base_cost_energy
	total_invested_materials = base_cost_materials
	upgrade_paths = data.get("upgrade_paths", data.get("upgrades", []))
	sequential_upgrades = data.get("sequential_upgrades", false)

	# Apply item effects to build time
	var item_modifiers := ItemSystem.get_structure_modifiers()
	build_time /= item_modifiers.get("build_speed_multiplier", 1.0)

	# Configure combat component to target enemies
	if combat_component:
		combat_component.target_type = "enemy"
		combat_component.is_active = false  # Disable until build completes

	# Scale tower visual 25% larger to match 2x2 grid
	if visual_node:
		visual_node.scale = Vector3.ONE * 1.25

	# Create health bar above the tower
	_setup_health_bar()

	# Create selection ring
	_create_selection_ring()

	# Start construction
	_start_building()
	
	# Apply item effects to tower stats after construction starts
	_apply_item_effects()


func _process(delta: float) -> void:
	if is_building:
		_process_build(delta)
	elif is_built:
		# Handle animations when built
		if combat_component and combat_component.current_target:
			# Continuously track target while in combat
			if supports_rotation:
				_animate_turret_to_target(combat_component.current_target)
		else:
			# Idle scanning behavior
			_process_idle_animations(delta)


func _setup_health_bar() -> void:
	var mesh_scale: Array = data.get("mesh_scale", [1.0, 1.0, 1.0])
	var tower_height: float = 1.0
	if mesh_scale is Array and mesh_scale.size() >= 2:
		tower_height = float(mesh_scale[1])
	health_bar_width = max(float(grid_size), 1.0)

	# Towers with detailed visuals sit on tall pillars, so health bar goes higher
	var bar_y: float
	if entity_id in ["autocannon", "missile_battery", "rail_gun", "plasma_mortar",
			"tesla_coil", "inferno_tower", "repair_tower", "war_beacon",
			"targeting_array", "shield_pylon", "leach_tower", "thermal_siphon"]:
		bar_y = VisualGenerator.TOWER_PILLAR_HEIGHT + tower_height + 0.8
	else:
		bar_y = tower_height + 0.3

	health_bar = VisualGenerator.create_health_bar(health_bar_width)
	health_bar.position.y = bar_y
	add_child(health_bar)

	# Connect health changes to update the bar
	if health_component:
		health_component.health_changed.connect(_on_health_changed)
		health_component.died.connect(_on_died)


func _on_health_changed(current_hp: float, max_hp: float) -> void:
	if health_bar and max_hp > 0.0:
		VisualGenerator.update_health_bar(health_bar, current_hp / max_hp, health_bar_width)
		# Only show health bar when damaged
		health_bar.visible = is_built and current_hp < max_hp


func _on_died(killer: Node) -> void:
	_free_grid_cells()
	GameBus.audio_play_3d.emit("tower.%s.destroyed" % entity_id, global_position)


func _start_building() -> void:
	is_building = true
	is_built = false
	build_timer = 0.0

	# Start at scale 0 for construction animation
	if visual_node:
		visual_node.scale = Vector3.ZERO

	# Hide health bar during construction
	if health_bar:
		health_bar.visible = false

	# Make invulnerable during construction
	if health_component:
		health_component.is_invulnerable = true

	GameBus.build_started.emit(self, entity_id, grid_position)


func _process_build(delta: float) -> void:
	build_timer += delta
	var progress: float = clampf(build_timer / build_time, 0.0, 1.0)

	# Animate scale from 0 to 1
	if visual_node:
		visual_node.scale = Vector3.ONE * progress

	if progress >= 1.0:
		_complete_build()


func _complete_build() -> void:
	is_building = false
	is_built = true

	# Ensure full scale
	if visual_node:
		visual_node.scale = Vector3.ONE

	# Health bar stays hidden until damaged
	if health_bar:
		health_bar.visible = false

	# Enable combat
	if combat_component:
		combat_component.is_active = true
		combat_component.attack_fired.connect(_on_attack_fired)
		combat_component.target_acquired.connect(_on_target_acquired)

	# Cache muzzle flash nodes and animation components
	_cache_muzzle_nodes()
	_cache_animation_components()

	# Remove invulnerability
	if health_component:
		health_component.is_invulnerable = false

	GameBus.build_completed.emit(self, entity_id, grid_position)
	GameBus.audio_play_3d.emit("tower.%s.build_complete" % entity_id, global_position)
	build_completed_signal.emit()


func _free_grid_cells() -> void:
	if build_grid:
		build_grid.free_cells(grid_position, grid_size)


func die(killer: Node = null) -> void:
	_free_grid_cells()
	GameState.buildings_lost += 1
	super.die(killer)


func select() -> void:
	if is_selected:
		return
	is_selected = true
	if selection_ring:
		selection_ring.visible = true


func deselect() -> void:
	if not is_selected:
		return
	is_selected = false
	if selection_ring:
		selection_ring.visible = false


func _create_selection_ring() -> void:
	selection_ring = MeshInstance3D.new()
	selection_ring.name = "SelectionRing"
	var torus := TorusMesh.new()
	var ring_scale: float = max(1.0, float(grid_size)) * 0.8
	torus.inner_radius = ring_scale * 0.75
	torus.outer_radius = ring_scale * 0.95
	torus.rings = 16
	torus.ring_segments = 12
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 1.0, 0.2, 0.8)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.no_depth_test = true
	torus.material = mat
	selection_ring.mesh = torus
	selection_ring.position.y = 0.05
	selection_ring.visible = false
	add_child(selection_ring)


func get_sell_refund() -> Dictionary:
	return {
		"energy": total_invested_energy * 0.75,
		"materials": total_invested_materials * 0.75
	}


func apply_upgrade_modifications(modifications: Dictionary) -> void:
	# Apply stat modifications from an upgrade
	if modifications.has("damage") and combat_component:
		combat_component.damage = float(modifications["damage"])
	if modifications.has("attack_rate") and combat_component:
		combat_component.attack_rate = float(modifications["attack_rate"])
	if modifications.has("attack_range") and combat_component:
		combat_component.attack_range = float(modifications["attack_range"])
	if modifications.has("hp") and health_component:
		health_component.max_hp = float(modifications["hp"])
		health_component.current_hp = health_component.max_hp
		health_component.health_changed.emit(health_component.current_hp, health_component.max_hp)
	if modifications.has("armor") and health_component:
		health_component.base_armor = float(modifications["armor"])
		health_component.current_armor = health_component.base_armor
	if modifications.has("regen_percent") and health_component:
		health_component.regen_percent = float(modifications["regen_percent"])

	# Handle specials override
	if modifications.has("specials_override") and combat_component:
		var new_specials: Array = modifications["specials_override"]
		data["specials"] = new_specials
		combat_component.initialize(data)

	# Handle specials add
	if modifications.has("specials_add"):
		var existing_specials: Array = data.get("specials", [])
		for special: Dictionary in modifications["specials_add"]:
			existing_specials.append(special)
		data["specials"] = existing_specials
		if combat_component:
			combat_component.initialize(data)

	# Update data dictionary for consistency
	for key: String in modifications:
		if key != "specials_override" and key != "specials_add":
			data[key] = modifications[key]


func get_next_sequential_upgrade() -> Dictionary:
	## Returns the next tier upgrade for sequential-upgrade towers, or empty if fully upgraded.
	if not sequential_upgrades:
		return {}
	if current_tier >= upgrade_paths.size():
		return {}
	return upgrade_paths[current_tier]


func is_fully_upgraded() -> bool:
	if sequential_upgrades:
		return current_tier >= upgrade_paths.size()
	return current_upgrade_index >= 0


func _cache_muzzle_nodes() -> void:
	_muzzle_nodes.clear()
	if not visual_node:
		return
	for child in visual_node.get_children():
		if child is MeshInstance3D and child.has_meta("muzzle_point"):
			var mat: StandardMaterial3D = child.mesh.material as StandardMaterial3D
			if mat:
				child.set_meta("base_emission", mat.emission_energy_multiplier)
				child.set_meta("base_scale", child.scale)
				_muzzle_nodes.append(child)


func _trigger_muzzle_flash(_target: Node) -> void:
	if _muzzle_nodes.is_empty() or _muzzle_flash_active:
		return
	_muzzle_flash_active = true
	for node: MeshInstance3D in _muzzle_nodes:
		if not is_instance_valid(node):
			continue
		var mat: StandardMaterial3D = node.mesh.material as StandardMaterial3D
		if mat:
			mat.emission_energy_multiplier = node.get_meta("base_emission") * 4.0
		node.scale = node.get_meta("base_scale") * 2.5
	get_tree().create_timer(0.08).timeout.connect(_reset_muzzle_flash)


func _reset_muzzle_flash() -> void:
	_muzzle_flash_active = false
	for node: MeshInstance3D in _muzzle_nodes:
		if not is_instance_valid(node):
			continue
		var mat: StandardMaterial3D = node.mesh.material as StandardMaterial3D
		if mat:
			mat.emission_energy_multiplier = node.get_meta("base_emission")
		node.scale = node.get_meta("base_scale")


func _cache_animation_components() -> void:
	## Cache references to animatable components from visual metadata
	if not visual_node:
		return
	
	# Check for animation metadata
	supports_rotation = visual_node.get_meta("supports_rotation", false)
	supports_elevation = visual_node.get_meta("supports_elevation", false)
	supports_barrel_spin = visual_node.get_meta("supports_barrel_spin", false)
	
	# Cache node references
	if visual_node.has_meta("turret_body_node"):
		var path: String = visual_node.get_meta("turret_body_node")
		turret_body_node = visual_node.get_node_or_null(NodePath(path))
	
	if visual_node.has_meta("barrel_assembly_node"):
		var path: String = visual_node.get_meta("barrel_assembly_node")
		barrel_assembly_node = visual_node.get_node_or_null(NodePath(path))
	
	if visual_node.has_meta("barrel_spinner_node"):
		var path: String = visual_node.get_meta("barrel_spinner_node")
		barrel_spinner_node = visual_node.get_node_or_null(NodePath(path))


func _animate_turret_to_target(target: Node) -> void:
	## Animates turret rotation and elevation to track target
	if not target or not supports_rotation:
		return
	
	var target_pos: Vector3 = target.global_position
	var turret_pos: Vector3 = global_position
	
	# Calculate horizontal rotation (Y-axis)
	var direction: Vector3 = target_pos - turret_pos
	direction.y = 0  # Remove vertical component for rotation
	direction = direction.normalized()
	
	var target_rotation_rad: float = atan2(direction.x, direction.z)
	_target_rotation = rad_to_deg(target_rotation_rad)
	
	# Calculate elevation angle if supported
	if supports_elevation and barrel_assembly_node:
		var distance_horizontal: float = Vector2(direction.x, direction.z).length()
		var height_diff: float = target_pos.y - turret_pos.y
		var elevation_rad: float = atan2(height_diff, distance_horizontal)
		_target_elevation = rad_to_deg(elevation_rad)
		_target_elevation = clamp(_target_elevation, -10.0, 45.0)  # Limit elevation range
	
	# Smooth rotation with tween
	if turret_body_node:
		if _rotation_tween:
			_rotation_tween.kill()
		_rotation_tween = create_tween()
		_rotation_tween.tween_method(_set_turret_rotation, _current_rotation, _target_rotation, 0.2)
	
	# Smooth elevation with tween
	if barrel_assembly_node and supports_elevation:
		if _elevation_tween:
			_elevation_tween.kill()
		_elevation_tween = create_tween()
		_elevation_tween.tween_method(_set_barrel_elevation, _current_elevation, _target_elevation, 0.15)


func _set_turret_rotation(rotation_deg: float) -> void:
	## Sets the turret body rotation
	_current_rotation = rotation_deg
	if turret_body_node:
		turret_body_node.rotation_degrees.y = rotation_deg


func _set_barrel_elevation(elevation_deg: float) -> void:
	## Sets the barrel assembly elevation
	_current_elevation = elevation_deg
	if barrel_assembly_node:
		barrel_assembly_node.rotation_degrees.x = -elevation_deg  # Negative for proper direction


func _start_barrel_spin() -> void:
	## Starts barrel spinning animation for gatling-type weapons
	if not supports_barrel_spin or not barrel_spinner_node:
		return
	
	_is_firing = true
	_barrel_spin_velocity = 1800.0  # degrees per second
	
	# Create continuous spinning tween
	var spin_tween := create_tween()
	spin_tween.set_loops()
	spin_tween.tween_method(_set_barrel_spin, 0.0, 360.0, 360.0 / _barrel_spin_velocity)


func _stop_barrel_spin() -> void:
	## Gradually stops barrel spinning
	if not supports_barrel_spin or not barrel_spinner_node:
		return
	
	_is_firing = false
	
	# Gradually slow down the spin
	var slowdown_tween := create_tween()
	slowdown_tween.tween_method(_set_barrel_spin_velocity, _barrel_spin_velocity, 0.0, 1.0)


func _set_barrel_spin(rotation_deg: float) -> void:
	## Sets barrel spinner rotation
	if barrel_spinner_node:
		barrel_spinner_node.rotation_degrees.z = rotation_deg


func _set_barrel_spin_velocity(velocity: float) -> void:
	## Updates barrel spin velocity during slowdown
	_barrel_spin_velocity = velocity


func _trigger_rail_gun_charge_sequence() -> void:
	## Animates rail gun energy buildup before firing
	if not visual_node or not visual_node.has_meta("supports_energy_charging"):
		return
	
	# Find conduit system and coils for charging effect
	if visual_node.has_meta("conduit_system_node"):
		var conduit_path: String = visual_node.get_meta("conduit_system_node")
		var conduit_node := visual_node.get_node_or_null(NodePath(conduit_path))
		
		if conduit_node:
			# Animate energy buildup in conduits
			var charge_tween := create_tween()
			charge_tween.set_parallel(true)
			
			# Brighten conduits over 0.5 seconds
			for child in conduit_node.get_children():
				if child is MeshInstance3D and child.name.begins_with("AcceleratorCoil"):
					var mat: StandardMaterial3D = child.mesh.material as StandardMaterial3D
					if mat and mat.emission_enabled:
						var base_emission: float = mat.emission_energy_multiplier
						charge_tween.tween_method(
							func(energy): mat.emission_energy_multiplier = energy,
							base_emission, base_emission * 3.0, 0.5
						)
						# Return to normal after firing
						charge_tween.tween_delay(0.1)
						charge_tween.tween_method(
							func(energy): mat.emission_energy_multiplier = energy,
							base_emission * 3.0, base_emission, 0.2
						)


func _trigger_missile_reload_sequence() -> void:
	## Animates missile battery reload after firing
	if not visual_node or not visual_node.has_meta("supports_missile_visibility"):
		return
	
	# Hide missiles briefly then show them again (reload effect)
	if visual_node.has_meta("launcher_assembly_node"):
		var launcher_path: String = visual_node.get_meta("launcher_assembly_node")
		var launcher_node := visual_node.get_node_or_null(NodePath(launcher_path))
		
		if launcher_node:
			var missile_count: int = visual_node.get_meta("missile_count", 4)
			
			# Hide missiles
			for i in range(missile_count):
				var missile_node := launcher_node.get_node_or_null("Missile_" + str(i))
				if missile_node:
					missile_node.visible = false
			
			# Show them again after reload delay
			get_tree().create_timer(1.0).timeout.connect(func():
				for i in range(missile_count):
					var missile_node := launcher_node.get_node_or_null("Missile_" + str(i))
					if missile_node:
						missile_node.visible = true
			)


func _trigger_tesla_discharge_effects() -> void:
	## Creates brief electrical discharge effects for tesla coil
	if not visual_node:
		return
	
	# Find all emissive spheres (coil rings and discharge points) and flash them
	for child in visual_node.get_children():
		if child is MeshInstance3D:
			var mat: StandardMaterial3D = child.mesh.material as StandardMaterial3D
			if mat and mat.emission_enabled:
				var base_emission: float = mat.emission_energy_multiplier
				
				# Create brief flash effect
				var flash_tween := create_tween()
				flash_tween.tween_method(
					func(energy): mat.emission_energy_multiplier = energy,
					base_emission, base_emission * 4.0, 0.1
				)
				flash_tween.tween_method(
					func(energy): mat.emission_energy_multiplier = energy,
					base_emission * 4.0, base_emission, 0.2
				)


func _process_idle_animations(delta: float) -> void:
	## Handles idle scanning and ambient animations when not in combat
	if not supports_rotation or not turret_body_node:
		return
	
	_idle_scan_timer += delta
	
	# Slow scanning behavior - sweep back and forth
	var scan_progress: float = _idle_scan_timer * _idle_scan_speed * _idle_scan_direction
	var current_scan_angle: float = sin(scan_progress * 0.01) * _idle_scan_range * 0.5
	
	# Apply smooth idle rotation
	if not _rotation_tween or not _rotation_tween.is_valid():
		_set_turret_rotation(current_scan_angle)


func _on_target_acquired(target: Node) -> void:
	## Called when combat component acquires a new target
	_animate_turret_to_target(target)


func _on_attack_fired(target: Node) -> void:
	## Called when tower fires at target - triggers muzzle flash and animations
	_trigger_muzzle_flash(target)
	
	# Tower-specific animations
	match entity_id:
		"autocannon":
			if supports_barrel_spin:
				_start_barrel_spin()
				# Stop spinning after a short burst
				get_tree().create_timer(0.5).timeout.connect(_stop_barrel_spin)
		"rail_gun":
			_trigger_rail_gun_charge_sequence()
		"missile_battery":
			_trigger_missile_reload_sequence()
		"tesla_coil":
			_trigger_tesla_discharge_effects()
	
	# Update turret tracking during combat
	if target:
		_animate_turret_to_target(target)


func _apply_item_effects() -> void:
	## Apply item bonuses to tower stats like health, range, damage, attack speed
	if not is_instance_valid(ItemSystem):
		return
	
	var structure_mods := ItemSystem.get_structure_modifiers()
	var tower_mods := ItemSystem.get_tower_modifiers()
	
	# Apply health multiplier
	var health_multiplier := structure_mods.get("health_multiplier", 1.0)
	if health_multiplier != 1.0 and health_component:
		var new_max_health := float(data.get("hp", 100)) * health_multiplier
		health_component.max_health = new_max_health
		health_component.current_health = new_max_health
		data["hp"] = new_max_health  # Update data for upgrades
	
	# Apply tower-specific modifiers
	if combat_component:
		# Range multiplier
		var range_multiplier := tower_mods.get("range_multiplier", 1.0)
		if range_multiplier != 1.0:
			var new_range := float(data.get("attack_range", 10)) * range_multiplier
			combat_component.attack_range = new_range
			data["attack_range"] = new_range
		
		# Attack speed multiplier  
		var speed_multiplier := tower_mods.get("attack_speed_multiplier", 1.0)
		if speed_multiplier != 1.0:
			var new_attack_rate := float(data.get("attack_rate", 1.0)) * speed_multiplier
			combat_component.attack_rate = new_attack_rate
			data["attack_rate"] = new_attack_rate
		
		# Energy drain for overclocker
		var energy_drain := tower_mods.get("energy_drain", 0.0)
		if energy_drain > 0.0:
			# Create timer to drain energy periodically
			var drain_timer := Timer.new()
			drain_timer.wait_time = 1.0
			drain_timer.autostart = true
			drain_timer.timeout.connect(_drain_energy.bind(energy_drain))
			add_child(drain_timer)
	
	print("[TowerBase] Applied item effects to %s: health x%.2f, range x%.2f, speed x%.2f" % [
		entity_id, health_multiplier, tower_mods.get("range_multiplier", 1.0), tower_mods.get("attack_speed_multiplier", 1.0)
	])


func _drain_energy(amount: float) -> void:
	## Drain energy from game state (used by overclocker item)
	if is_built and not is_building and GameState.energy > amount:
		GameState.energy -= amount
