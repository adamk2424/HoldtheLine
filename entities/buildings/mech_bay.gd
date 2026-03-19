class_name MechBay
extends ProductionBuildingBase
## MechBay - Production building for mech units.
## Produces: sentinel, juggernaut
## Upgrades:
##   Level 1 - Reinforced Plating: All mechs gain +3 armor
##   Level 2 - Power Core: All mechs gain +25% damage
##   Level 3 - Titan Frame: All mechs gain +30% HP; Juggernaut ground pound AoE radius +2


func _ready() -> void:
	super._ready()
	# Initialize enhanced production animations
	if visual_node and visual_node.has_meta("supports_welding_animation"):
		_start_production_animations()


func _apply_upgrade_effects(_level: int) -> void:
	# All upgrade effects are applied via _get_modified_unit_data for future units
	pass


func _start_production_animations() -> void:
	## Initialize enhanced building animations for Task 1B
	if not visual_node:
		return
	
	# Start continuous gantry system animations
	VisualGenerator.animate_gear_systems(visual_node, 25.0)
	
	# Initialize steam venting from exhaust stacks
	if visual_node.has_meta("steam_vent_points"):
		var vent_points: Array = visual_node.get_meta("steam_vent_points")
		_start_steam_venting(vent_points)
	
	# Animate crane system
	if visual_node.has_meta("crane_system_node"):
		_animate_crane_system()


func _start_steam_venting(vent_points: Array) -> void:
	## Continuous steam venting during operation
	for point in vent_points:
		if point is Vector3:
			_create_continuous_steam_effect(point)


func _create_continuous_steam_effect(vent_position: Vector3) -> void:
	## Continuous steam puffs from exhaust
	var steam_timer := Timer.new()
	steam_timer.wait_time = randf_range(2.0, 4.0)
	steam_timer.timeout.connect(
		func(): 
			VisualGenerator.animate_steam_vents(visual_node, [vent_position])
			steam_timer.wait_time = randf_range(2.0, 4.0)
	)
	add_child(steam_timer)
	steam_timer.start()


func _animate_crane_system() -> void:
	## Realistic crane movement for heavy lifting
	var crane_path: String = visual_node.get_meta("crane_system_node")
	var crane_node := visual_node.get_node_or_null(NodePath(crane_path))
	if not crane_node:
		return
	
	var crane_tween := crane_node.create_tween()
	crane_tween.set_loops()
	
	# Crane movement cycle: position 1, lift, position 2, lower, return
	crane_tween.tween_property(crane_node, "rotation_degrees:y", 15.0, 3.0)
	crane_tween.tween_delay(1.0)
	crane_tween.tween_property(crane_node, "rotation_degrees:y", -15.0, 4.0)
	crane_tween.tween_delay(2.0)
	crane_tween.tween_property(crane_node, "rotation_degrees:y", 0.0, 2.0)
	crane_tween.tween_delay(3.0)


func _on_production_started() -> void:
	## Enhanced production effects with welding sparks
	if visual_node and visual_node.has_meta("welding_spark_points"):
		var spark_points: Array = visual_node.get_meta("welding_spark_points")
		VisualGenerator.animate_welding_sparks(visual_node, spark_points)
		
		# Additional steam bursts during active production
		if visual_node.has_meta("steam_vent_points"):
			var vent_points: Array = visual_node.get_meta("steam_vent_points")
			for point in vent_points:
				VisualGenerator.animate_steam_vents(visual_node, [point])


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
