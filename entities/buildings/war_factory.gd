class_name WarFactory
extends ProductionBuildingBase
## WarFactory - Production building for war vehicle units.
## Produces: striker, siege_walker
## Upgrades:
##   Level 1 - Improved Treads: All vehicles gain +15% speed
##   Level 2 - Heavy Ordinance: All vehicles gain +20% damage
##   Level 3 - War Machine: All vehicles gain +4 armor; Siege Walker deploys instantly


func _ready() -> void:
	super._ready()
	# Initialize enhanced production animations
	if visual_node and visual_node.has_meta("supports_assembly_animation"):
		_start_production_animations()


func _apply_upgrade_effects(_level: int) -> void:
	# All upgrade effects are applied via _get_modified_unit_data for future units
	pass


func _start_production_animations() -> void:
	## Initialize enhanced building animations for Task 1B
	if not visual_node:
		return
	
	# Start heavy machinery gear rotation
	VisualGenerator.animate_gear_systems(visual_node, 20.0)  # Slower for heavy machinery
	
	# Animate warning beacon system
	VisualGenerator.animate_warning_beacons(visual_node)
	
	# Initialize conveyor belt animations
	VisualGenerator.animate_conveyor_belts(visual_node, 0.8)  # Slower for heavy parts
	
	# Continuous exhaust stack steam
	if visual_node.has_meta("exhaust_stack1_node"):
		_start_continuous_exhaust_effects()


func _start_continuous_exhaust_effects() -> void:
	## Heavy industrial exhaust effects
	var exhaust_timer := Timer.new()
	exhaust_timer.wait_time = randf_range(1.5, 3.0)
	exhaust_timer.timeout.connect(
		func():
			_create_heavy_exhaust_burst()
			exhaust_timer.wait_time = randf_range(1.5, 3.0)
	)
	add_child(exhaust_timer)
	exhaust_timer.start()


func _create_heavy_exhaust_burst() -> void:
	## Heavy industrial exhaust with multiple stacks
	var exhaust_stacks: Array = []
	if visual_node.has_meta("exhaust_stack1_node"):
		exhaust_stacks.append(visual_node.get_meta("exhaust_stack1_node"))
	if visual_node.has_meta("exhaust_stack2_node"):
		exhaust_stacks.append(visual_node.get_meta("exhaust_stack2_node"))
	if visual_node.has_meta("exhaust_stack3_node"):
		exhaust_stacks.append(visual_node.get_meta("exhaust_stack3_node"))
	
	for stack_path in exhaust_stacks:
		var stack_node := visual_node.get_node_or_null(NodePath(stack_path))
		if stack_node:
			var exhaust_pos := stack_node.global_position + Vector3(0, 0.3, 0)
			VisualGenerator.animate_steam_vents(visual_node, [exhaust_pos])


func _on_production_started() -> void:
	## Enhanced production effects with heavy industrial atmosphere
	if visual_node:
		# Extra exhaust during production
		_create_heavy_exhaust_burst()
		
		# Flash warning lights during assembly
		if visual_node.has_meta("hazard_warning_points"):
			var warning_points: Array = visual_node.get_meta("hazard_warning_points")
			for point in warning_points:
				if point is Vector3:
					_create_hazard_flash(point)


func _create_hazard_flash(warning_position: Vector3) -> void:
	## Orange hazard light flashing during production
	var warning_flash := MeshInstance3D.new()
	warning_flash.name = "HazardFlash"
	
	var flash_mesh := SphereMesh.new()
	flash_mesh.radius = 0.06
	
	var flash_mat := StandardMaterial3D.new()
	flash_mat.albedo_color = Color(1.0, 0.5, 0.1, 1.0)
	flash_mat.emission_enabled = true
	flash_mat.emission = Color(1.0, 0.6, 0.2)
	flash_mat.emission_energy_multiplier = 5.0
	flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	flash_mesh.material = flash_mat
	warning_flash.mesh = flash_mesh
	warning_flash.position = warning_position
	
	visual_node.add_child(warning_flash)
	
	# Rapid flashing pattern
	var flash_tween := visual_node.create_tween()
	flash_tween.set_loops(8)  # 8 flashes during production
	flash_tween.tween_property(warning_flash, "modulate:a", 0.2, 0.2)
	flash_tween.tween_property(warning_flash, "modulate:a", 1.0, 0.2)
	
	# Cleanup
	visual_node.get_tree().create_timer(3.2).timeout.connect(
		func(): warning_flash.queue_free()
	)


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
