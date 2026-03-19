class_name UpgradeSystem
extends Node
## UpgradeSystem - Connects to GameBus.upgrade_requested, validates cost,
## and delegates to TowerUpgradeHandler to apply the upgrade.
## Central tower uses sequential tier upgrades handled by CentralTower itself.


func _ready() -> void:
	GameBus.upgrade_requested.connect(_on_upgrade_requested)


func _on_upgrade_requested(entity: Node, upgrade_index: int) -> void:
	if not is_instance_valid(entity):
		push_warning("[UpgradeSystem] Upgrade requested for invalid entity.")
		return

	# Central tower has its own sequential tier upgrade system
	if entity is CentralTower:
		_handle_central_tower_upgrade(entity as CentralTower)
		return

	if not entity is TowerBase:
		push_warning("[UpgradeSystem] Upgrade requested for non-tower entity: %s" % entity.name)
		return

	var tower: TowerBase = entity as TowerBase

	if not tower.is_built or tower.is_building:
		push_warning("[UpgradeSystem] Cannot upgrade tower that is not fully built: %s" % tower.entity_id)
		return

	# Sequential tier upgrades (autocannon, missile_battery, etc.)
	if tower.sequential_upgrades:
		var upgrade: Dictionary = tower.get_next_sequential_upgrade()
		if upgrade.is_empty():
			push_warning("[UpgradeSystem] Tower fully upgraded (tier %d): %s" % [tower.current_tier, tower.entity_id])
			return
		var upgrade_name: String = upgrade.get("name", "Unknown")
		GameBus.upgrade_started.emit(tower, upgrade_name)
		var success: bool = TowerUpgradeHandler.upgrade_tower(tower, 0)
		if not success:
			push_warning("[UpgradeSystem] Sequential upgrade failed for tower %s" % tower.entity_id)
		return

	if tower.current_upgrade_index >= 0:
		push_warning("[UpgradeSystem] Tower already upgraded: %s" % tower.entity_id)
		return

	# Validate upgrade index
	var upgrade_info: Dictionary = TowerUpgradeHandler.get_upgrade_info(tower, upgrade_index)
	if upgrade_info.is_empty():
		push_warning("[UpgradeSystem] Invalid upgrade index %d for tower: %s" % [upgrade_index, tower.entity_id])
		return

	var upgrade_name: String = upgrade_info.get("name", "Unknown")
	GameBus.upgrade_started.emit(tower, upgrade_name)

	# Attempt the upgrade (handles cost check and application)
	var success: bool = TowerUpgradeHandler.upgrade_tower(tower, upgrade_index)
	if not success:
		push_warning("[UpgradeSystem] Upgrade failed for tower %s, branch %d" % [tower.entity_id, upgrade_index])


func _handle_central_tower_upgrade(central: CentralTower) -> void:
	if not central.is_built:
		push_warning("[UpgradeSystem] Central tower not built yet.")
		return

	var upgrade: Dictionary = central.get_next_upgrade()
	if upgrade.is_empty():
		push_warning("[UpgradeSystem] Central tower fully upgraded (tier %d)." % central.current_tier)
		return

	var upgrade_name: String = upgrade.get("name", "Unknown")
	GameBus.upgrade_started.emit(central, upgrade_name)

	var success: bool = central.apply_tier_upgrade()
	if not success:
		push_warning("[UpgradeSystem] Central tower tier upgrade failed.")
