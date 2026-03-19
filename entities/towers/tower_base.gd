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
		combat_component.attack_fired.connect(_trigger_muzzle_flash)

	# Cache muzzle flash nodes
	_cache_muzzle_nodes()

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
