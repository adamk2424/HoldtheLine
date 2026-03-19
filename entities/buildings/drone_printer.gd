class_name DronePrinter
extends ProductionBuildingBase
## DronePrinter - Production building for drone units.
## Produces: repair_drone, shield_drone, disruptor_drone
## Upgrades:
##   Level 1 - Advanced Circuits: All drones gain +20% HP
##   Level 2 - Swarm Protocol: All drones build 30% faster
##   Level 3 - Nanite Enhancement: All drones gain +1 armor; Repair Drone heals 50% more


func _apply_upgrade_effects(level: int) -> void:
	match level:
		1:
			# Advanced Circuits: future drones get +20% HP (handled in _get_modified_unit_data)
			pass
		2:
			# Swarm Protocol: 30% faster build speed
			build_speed_multiplier = 1.3
		3:
			# Nanite Enhancement: +1 armor + repair heal bonus (handled in _get_modified_unit_data)
			pass


func _get_modified_unit_data(base_data: Dictionary) -> Dictionary:
	var modified: Dictionary = base_data.duplicate(true)

	if upgrade_level >= 1:
		# +20% HP
		var base_hp: float = float(modified.get("hp", 100))
		modified["hp"] = base_hp * 1.2

	if upgrade_level >= 3:
		# +1 armor for all drones
		var base_armor: float = float(modified.get("armor", 0))
		modified["armor"] = base_armor + 1.0

		# Repair Drone heals 50% more
		if modified.get("id", "") == "repair_drone":
			var specials: Array = modified.get("specials", [])
			for special: Dictionary in specials:
				if special.get("type", "") == "repair_beam":
					var base_heal: float = float(special.get("heal_per_sec", 10))
					special["heal_per_sec"] = base_heal * 1.5

	return modified
