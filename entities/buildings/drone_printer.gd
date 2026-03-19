class_name DronePrinter
extends ProductionBuildingBase
## DronePrinter - Production building for drone units.
## Produces: repair_drone, shield_drone, disruptor_drone
## Upgrades:
##   Level 1 - Advanced Circuits: All drones gain +20% HP
##   Level 2 - Swarm Protocol: All drones build 30% faster
##   Level 3 - Nanite Enhancement: All drones gain +1 armor; Repair Drone heals 50% more


func _ready() -> void:
	super._ready()
	# Initialize production animations
	if visual_node and visual_node.has_meta("supports_assembly_glow"):
		_start_production_animations()


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


func _start_production_animations() -> void:
	## Initialize enhanced building animations for Task 1B
	if not visual_node:
		return
	
	# Start continuous robotic arm assembly animations
	VisualGenerator.animate_robotic_arms(visual_node, 8.0)
	
	# Rotate antenna array for drone command signals
	if visual_node.has_meta("antenna_array_node"):
		var antenna_path: String = visual_node.get_meta("antenna_array_node")
		var antenna_node := visual_node.get_node_or_null(NodePath(antenna_path))
		if antenna_node:
			_animate_antenna_rotation(antenna_node)


func _animate_antenna_rotation(antenna_node: Node3D) -> void:
	## Continuous antenna rotation for drone coordination
	var rotation_tween := antenna_node.create_tween()
	rotation_tween.set_loops()
	rotation_tween.tween_property(antenna_node, "rotation_degrees:y", 360.0, 12.0)


func _on_production_started() -> void:
	## Enhanced production effects for Task 1A
	if visual_node and visual_node.has_meta("assembly_points"):
		var assembly_points: Array = visual_node.get_meta("assembly_points")
		_create_assembly_glow_effects(assembly_points)


func _create_assembly_glow_effects(assembly_points: Array) -> void:
	## Create pulsing assembly lights during production
	for point in assembly_points:
		if point is Vector3:
			_create_assembly_light_pulse(point)


func _create_assembly_light_pulse(position: Vector3) -> void:
	## Pulsing work light at assembly point
	var work_light := MeshInstance3D.new()
	work_light.name = "AssemblyLight"
	
	var light_mesh := SphereMesh.new()
	light_mesh.radius = 0.03
	
	var light_mat := StandardMaterial3D.new()
	light_mat.albedo_color = Color(0.2, 1.0, 0.3, 0.8)
	light_mat.emission_enabled = true
	light_mat.emission = Color(0.4, 1.0, 0.5)
	light_mat.emission_energy_multiplier = 3.0
	light_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	light_mesh.material = light_mat
	work_light.mesh = light_mesh
	work_light.position = position
	
	visual_node.add_child(work_light)
	
	# Pulsing animation
	var pulse_tween := visual_node.create_tween()
	pulse_tween.set_loops(6)  # Pulse during assembly
	pulse_tween.tween_method(
		func(intensity): light_mat.emission_energy_multiplier = intensity,
		1.0, 4.0, 0.5
	)
	pulse_tween.tween_method(
		func(intensity): light_mat.emission_energy_multiplier = intensity,
		4.0, 1.0, 0.5
	)
	
	# Cleanup after production cycle
	visual_node.get_tree().create_timer(6.0).timeout.connect(
		func(): work_light.queue_free()
	)


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
