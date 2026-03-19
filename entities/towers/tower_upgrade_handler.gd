class_name TowerUpgradeHandler
extends RefCounted
## TowerUpgradeHandler - Manages the tower upgrade system.
## Each tower has upgrade_paths from JSON (2 branches per tower).
## Validates cost via GameState, applies stat modifications, updates visuals.


## Attempt to upgrade a tower along the given branch index.
## For sequential-upgrade towers, branch_index is the tier index (0 = tier 2, 1 = tier 3).
## Returns true if the upgrade was applied successfully.
static func upgrade_tower(tower: TowerBase, branch_index: int) -> bool:
	if not is_instance_valid(tower):
		push_warning("[TowerUpgradeHandler] Invalid tower reference.")
		return false

	if not tower.is_built or tower.is_building:
		push_warning("[TowerUpgradeHandler] Tower is not built yet.")
		return false

	# Sequential tier upgrades (autocannon, missile_battery, etc.)
	if tower.sequential_upgrades:
		return _apply_sequential_upgrade(tower)

	if tower.current_upgrade_index >= 0:
		push_warning("[TowerUpgradeHandler] Tower already has an upgrade applied.")
		return false

	var paths: Array = tower.upgrade_paths
	if branch_index < 0 or branch_index >= paths.size():
		push_warning("[TowerUpgradeHandler] Invalid branch index: %d (paths: %d)" % [branch_index, paths.size()])
		return false

	var upgrade: Dictionary = paths[branch_index]
	var cost_energy: float = float(upgrade.get("cost_energy", 0))
	var cost_materials: float = float(upgrade.get("cost_materials", 0))

	# Check tech requirement
	var req_tech: String = upgrade.get("required_tech_level", "none")
	if not _meets_tech_requirement(req_tech):
		push_warning("[TowerUpgradeHandler] Requires %s, current tier: %d" % [req_tech, GameState.central_tower_tier])
		return false

	# Check affordability
	if not GameState.can_afford(cost_energy, cost_materials):
		GameBus.resources_insufficient.emit(cost_energy, cost_materials)
		return false

	# Spend resources
	if not GameState.spend_resources(cost_energy, cost_materials):
		return false

	# Apply modifications
	var modifications: Dictionary = upgrade.get("modifications", {})
	tower.apply_upgrade_modifications(modifications)

	# Track upgrade
	tower.current_upgrade_index = branch_index
	tower.total_invested_energy += cost_energy
	tower.total_invested_materials += cost_materials

	# Update visual color to indicate upgrade
	_update_upgrade_visual(tower, branch_index)

	var upgrade_name: String = upgrade.get("name", "Unknown Upgrade")
	GameBus.upgrade_completed.emit(tower, upgrade_name)
	GameBus.audio_play_3d.emit("tower.%s.upgraded" % tower.entity_id, tower.global_position)

	return true


## Apply the next sequential tier upgrade to a tower.
static func _apply_sequential_upgrade(tower: TowerBase) -> bool:
	var upgrade: Dictionary = tower.get_next_sequential_upgrade()
	if upgrade.is_empty():
		push_warning("[TowerUpgradeHandler] Tower fully upgraded (tier %d)." % tower.current_tier)
		return false

	var cost_energy: float = float(upgrade.get("cost_energy", 0))
	var cost_materials: float = float(upgrade.get("cost_materials", 0))

	var req_tech: String = upgrade.get("required_tech_level", "none")
	if not _meets_tech_requirement(req_tech):
		push_warning("[TowerUpgradeHandler] Requires %s, current tier: %d" % [req_tech, GameState.central_tower_tier])
		return false

	if not GameState.can_afford(cost_energy, cost_materials):
		GameBus.resources_insufficient.emit(cost_energy, cost_materials)
		return false

	if not GameState.spend_resources(cost_energy, cost_materials):
		return false

	var modifications: Dictionary = upgrade.get("modifications", {})
	tower.apply_upgrade_modifications(modifications)

	tower.current_tier += 1
	tower.total_invested_energy += cost_energy
	tower.total_invested_materials += cost_materials

	_update_upgrade_visual(tower, tower.current_tier - 1)

	var upgrade_name: String = upgrade.get("name", "Unknown Upgrade")
	GameBus.upgrade_completed.emit(tower, upgrade_name)
	GameBus.audio_play_3d.emit("tower.%s.upgraded" % tower.entity_id, tower.global_position)

	return true


## Returns the upgrade data for a specific branch, or empty dict if invalid.
static func get_upgrade_info(tower: TowerBase, branch_index: int) -> Dictionary:
	if not is_instance_valid(tower):
		return {}
	var paths: Array = tower.upgrade_paths
	if branch_index < 0 or branch_index >= paths.size():
		return {}
	return paths[branch_index]


## Returns true if the tower can be upgraded along the given branch.
static func can_upgrade(tower: TowerBase, branch_index: int) -> bool:
	if not is_instance_valid(tower):
		return false
	if not tower.is_built or tower.is_building:
		return false

	# Sequential tier upgrades
	if tower.sequential_upgrades:
		var upgrade: Dictionary = tower.get_next_sequential_upgrade()
		if upgrade.is_empty():
			return false
		var req_tech: String = upgrade.get("required_tech_level", "none")
		if not _meets_tech_requirement(req_tech):
			return false
		var cost_energy: float = float(upgrade.get("cost_energy", 0))
		var cost_materials: float = float(upgrade.get("cost_materials", 0))
		return GameState.can_afford(cost_energy, cost_materials)

	if tower.current_upgrade_index >= 0:
		return false

	var paths: Array = tower.upgrade_paths
	if branch_index < 0 or branch_index >= paths.size():
		return false

	var upgrade: Dictionary = paths[branch_index]
	var req_tech: String = upgrade.get("required_tech_level", "none")
	if not _meets_tech_requirement(req_tech):
		return false
	var cost_energy: float = float(upgrade.get("cost_energy", 0))
	var cost_materials: float = float(upgrade.get("cost_materials", 0))
	return GameState.can_afford(cost_energy, cost_materials)


## Check if the current Central Tower tier meets the tech requirement string.
static func _meets_tech_requirement(req: String) -> bool:
	if req == "none" or req == "":
		return true
	var required_tier: int = 0
	match req:
		"tier_1": required_tier = 1
		"tier_2": required_tier = 2
		"tier_3": required_tier = 3
	return GameState.central_tower_tier >= required_tier


## Updates the tower visual to reflect the upgrade (slight color shift + scale).
## For sequential upgrades, replaces the visual with a tier-specific model.
static func _update_upgrade_visual(tower: TowerBase, branch_index: int) -> void:
	if not tower.visual_node:
		return

	# Sequential upgrades: replace visual with tier-specific model and scale up
	if tower.sequential_upgrades:
		var tier: int = tower.current_tier
		var color_hex: String = tower.data.get("mesh_color", "#888888")
		var base_color: Color = Color.html(color_hex)
		var new_visual: Node3D = VisualGenerator.create_entity_visual_tier(tower.entity_id, base_color, tier)
		if new_visual:
			var old_visual: Node3D = tower.visual_node
			tower.visual_node = new_visual
			tower.add_child(new_visual)
			# Scale 30% larger per tier on top of the base 1.25x tower scale
			new_visual.scale = Vector3.ONE * 1.25 * (1.0 + 0.3 * tier)
			old_visual.queue_free()
			tower._cache_muzzle_nodes()
		return

	# Find the MeshInstance3D child (should be the visual_node itself or a child)
	var mesh_instance: MeshInstance3D = null
	if tower.visual_node is MeshInstance3D:
		mesh_instance = tower.visual_node as MeshInstance3D
	else:
		for child in tower.visual_node.get_children():
			if child is MeshInstance3D:
				mesh_instance = child as MeshInstance3D
				break

	if not mesh_instance or not mesh_instance.mesh:
		return

	var mat: StandardMaterial3D = mesh_instance.mesh.material as StandardMaterial3D
	if not mat:
		return

	# Create a unique material so we don't modify shared resources
	var new_mat: StandardMaterial3D = mat.duplicate() as StandardMaterial3D
	new_mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	# Brighten color slightly to indicate upgrade
	var base_color: Color = new_mat.albedo_color
	base_color.a = 1.0
	if branch_index == 0:
		new_mat.albedo_color = base_color.lightened(0.2)
	else:
		new_mat.albedo_color = base_color.lightened(0.15)
	new_mat.emission_enabled = true
	new_mat.emission = new_mat.albedo_color
	new_mat.emission_energy_multiplier = 0.5
	mesh_instance.mesh.material = new_mat
