class_name WarFactory
extends ProductionBuildingBase
## WarFactory - Production building for war vehicle units.
## Produces: striker, siege_walker
## Upgrades:
##   Level 1 - Improved Treads: All vehicles gain +15% speed
##   Level 2 - Heavy Ordinance: All vehicles gain +20% damage
##   Level 3 - War Machine: All vehicles gain +4 armor; Siege Walker deploys instantly


func _apply_upgrade_effects(_level: int) -> void:
	# All upgrade effects are applied via _get_modified_unit_data for future units
	pass


func _get_modified_unit_data(base_data: Dictionary) -> Dictionary:
	var modified: Dictionary = base_data.duplicate(true)

	if upgrade_level >= 1:
		# +15% speed
		var base_speed: float = float(modified.get("speed", 5))
		modified["speed"] = base_speed * 1.15

	if upgrade_level >= 2:
		# +20% damage
		var base_damage: float = float(modified.get("damage", 0))
		modified["damage"] = base_damage * 1.2

	if upgrade_level >= 3:
		# +4 armor
		var base_armor: float = float(modified.get("armor", 0))
		modified["armor"] = base_armor + 4.0

		# Siege Walker deploys instantly
		if modified.get("id", "") == "siege_walker":
			var specials: Array = modified.get("specials", [])
			for special: Dictionary in specials:
				if special.get("type", "") == "deploy":
					special["deploy_time"] = 0.0

	return modified
