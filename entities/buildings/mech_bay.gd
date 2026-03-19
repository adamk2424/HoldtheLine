class_name MechBay
extends ProductionBuildingBase
## MechBay - Production building for mech units.
## Produces: sentinel, juggernaut
## Upgrades:
##   Level 1 - Reinforced Plating: All mechs gain +3 armor
##   Level 2 - Power Core: All mechs gain +25% damage
##   Level 3 - Titan Frame: All mechs gain +30% HP; Juggernaut ground pound AoE radius +2


func _apply_upgrade_effects(_level: int) -> void:
	# All upgrade effects are applied via _get_modified_unit_data for future units
	pass


func _get_modified_unit_data(base_data: Dictionary) -> Dictionary:
	var modified: Dictionary = base_data.duplicate(true)

	if upgrade_level >= 1:
		# +3 armor
		var base_armor: float = float(modified.get("armor", 0))
		modified["armor"] = base_armor + 3.0

	if upgrade_level >= 2:
		# +25% damage
		var base_damage: float = float(modified.get("damage", 0))
		modified["damage"] = base_damage * 1.25

	if upgrade_level >= 3:
		# +30% HP
		var base_hp: float = float(modified.get("hp", 100))
		modified["hp"] = base_hp * 1.3

		# Juggernaut fortify armor bonus +2
		if modified.get("id", "") == "juggernaut":
			var specials: Array = modified.get("specials", [])
			for special: Dictionary in specials:
				if special.get("type", "") == "fortify":
					var base_armor: float = float(special.get("armor_bonus", 3))
					special["armor_bonus"] = base_armor + 2.0

	return modified
