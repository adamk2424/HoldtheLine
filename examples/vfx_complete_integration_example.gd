extends Node3D
## Complete VFX Integration Example
## Demonstrates all VFX systems working together with the new integration framework

# --- Example Settings ---
var demo_mode := VfxIntegrationComplete.VfxMode.STANDARD
var auto_demo_timer := 0.0
var demo_cycle_time := 8.0
var current_demo_phase := 0

# --- Demo Projectile Sources ---
var demo_towers: Array[Node3D] = []
var demo_targets: Array[Node3D] = []
var demo_enemies: Array[Node3D] = []

func _ready() -> void:
	print("🎬 Starting Complete VFX Integration Demo")
	print("📝 Controls:")
	print("  Q - Toggle VFX Quality Mode")
	print("  1-6 - Demo Individual Systems")
	print("  Space - Auto Demo Cycle")
	print("  P - Performance Test")
	print("  C - Cleanup All Effects")
	print("  S - Show Statistics")
	
	# Initialize the complete VFX system
	VfxIntegrationComplete.initialize_vfx_system()
	
	# Setup demo environment
	_setup_demo_environment()
	
	# Start with standard quality
	VfxIntegrationComplete.set_vfx_mode(demo_mode)

func _process(delta: float) -> void:
	# Update performance monitoring
	VfxIntegrationComplete.update_performance_monitoring()
	
	# Auto demo cycle
	auto_demo_timer += delta
	if auto_demo_timer >= demo_cycle_time:
		auto_demo_timer = 0.0
		_run_auto_demo_cycle()

func _input(event: InputEvent) -> void:
	if not event.is_pressed():
		return
	
	match event.keycode:
		KEY_Q:
			_cycle_vfx_quality()
		KEY_1:
			_demo_projectile_effects()
		KEY_2:
			_demo_impact_effects()
		KEY_3:
			_demo_enemy_visuals()
		KEY_4:
			_demo_ambient_effects()
		KEY_5:
			_demo_environmental_hazards()
		KEY_6:
			_demo_battlefield_ambience()
		KEY_SPACE:
			_toggle_auto_demo()
		KEY_P:
			_run_performance_test()
		KEY_C:
			_cleanup_all_demo_effects()
		KEY_S:
			_show_vfx_statistics()

# =============================================================================
# Demo Environment Setup
# =============================================================================

func _setup_demo_environment() -> void:
	# Create demo towers (projectile sources)
	var tower_positions := [
		Vector3(-5, 0, -5),
		Vector3(5, 0, -5),
		Vector3(-5, 0, 5),
		Vector3(5, 0, 5)
	]
	
	var tower_types := ["autocannon", "missile_battery", "rail_gun", "plasma_mortar"]
	
	for i in range(tower_positions.size()):
		var tower := _create_demo_tower(tower_types[i], tower_positions[i])
		demo_towers.append(tower)
		add_child(tower)
	
	# Create demo targets
	var target_positions := [
		Vector3(-2, 0, 0),
		Vector3(2, 0, 0),
		Vector3(0, 0, -2),
		Vector3(0, 0, 2)
	]
	
	for pos in target_positions:
		var target := _create_demo_target(pos)
		demo_targets.append(target)
		add_child(target)
	
	# Create demo enemies with enhanced visuals
	_create_demo_enemy_showcase()

func _create_demo_tower(tower_type: String, position: Vector3) -> Node3D:
	var tower := Node3D.new()
	tower.name = "DemoTower_" + tower_type
	tower.position = position
	
	# Create tower visual
	var visual := VisualGenerator.create_entity_visual(tower_type, Color.CYAN)
	if visual:
		tower.add_child(visual)
	
	# Store tower type for weapon effects
	tower.set_meta("weapon_type", tower_type)
	
	return tower

func _create_demo_target(position: Vector3) -> Node3D:
	var target := Node3D.new()
	target.name = "DemoTarget"
	target.position = position
	
	# Simple target visual
	var mesh_instance := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	var material := StandardMaterial3D.new()
	material.albedo_color = Color.RED
	sphere.material = material
	mesh_instance.mesh = sphere
	target.add_child(mesh_instance)
	
	return target

func _create_demo_enemy_showcase() -> void:
	# Clear existing demo enemies
	for enemy in demo_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	demo_enemies.clear()
	
	# Enemy showcase positions
	var enemy_positions := [
		Vector3(-8, 0, 0),
		Vector3(-6, 0, 2),
		Vector3(-4, 0, -2),
		Vector3(-2, 0, 3),
		Vector3(8, 0, 0),
		Vector3(6, 0, -2)
	]
	
	var enemy_data_samples := [
		{"id": "thrasher", "hp": 94, "mesh_color": "#8B4513", "role": "swarm", "flying": false},
		{"id": "blight_mite", "hp": 125, "mesh_color": "#556B2F", "role": "swarm", "flying": false},
		{"id": "slinker", "hp": 425, "mesh_color": "#6A5ACD", "role": "ranged", "flying": false},
		{"id": "gloom_wing", "hp": 1063, "mesh_color": "#2C2C54", "role": "flying", "flying": true},
		{"id": "behemoth", "hp": 4688, "mesh_color": "#1A1A2E", "role": "boss", "is_boss": true},
		{"id": "brute", "hp": 329, "mesh_color": "#5C3A1E", "role": "bruiser", "flying": false}
	]
	
	for i in range(min(enemy_positions.size(), enemy_data_samples.size())):
		var enemy_container := Node3D.new()
		enemy_container.name = "DemoEnemy_" + enemy_data_samples[i]["id"]
		enemy_container.position = enemy_positions[i]
		
		# Create enhanced enemy visual using the new system
		var enemy_visual := VfxIntegrationComplete.create_enemy_visual(
			enemy_data_samples[i]["id"],
			enemy_data_samples[i]
		)
		
		enemy_container.add_child(enemy_visual)
		demo_enemies.append(enemy_container)
		add_child(enemy_container)

# =============================================================================
# Demo Functions
# =============================================================================

func _demo_projectile_effects() -> void:
	print("🚀 Demo: Projectile Effects")
	
	for i in range(demo_towers.size()):
		var tower := demo_towers[i]
		var target := demo_targets[i % demo_targets.size()]
		var weapon_type: String = tower.get_meta("weapon_type", "autocannon")
		
		var start_pos := tower.global_position + Vector3(0, 1, 0)
		var end_pos := target.global_position + Vector3(0, 0.5, 0)
		var travel_time := start_pos.distance_to(end_pos) / 10.0  # 10 units/second
		
		# Create complete projectile effect using integration system
		VfxIntegrationComplete.create_projectile_effect(
			weapon_type,
			start_pos,
			end_pos,
			travel_time,
			tower,
			target
		)
		
		# Create impact after travel time
		get_tree().create_timer(travel_time).timeout.connect(func():
			VfxIntegrationComplete.create_impact_effect(
				end_pos,
				Vector3.UP,
				weapon_type,
				50.0,
				target
			)
		)

func _demo_impact_effects() -> void:
	print("💥 Demo: Impact Effects")
	
	var weapons := ["autocannon", "rail_gun", "plasma_mortar", "tesla_coil", "inferno_tower"]
	var positions := [
		Vector3(-3, 0, -3),
		Vector3(3, 0, -3),
		Vector3(-3, 0, 3),
		Vector3(3, 0, 3),
		Vector3(0, 0, 0)
	]
	
	for i in range(positions.size()):
		var weapon_type := weapons[i]
		var position := positions[i] + Vector3(0, 0.1, 0)
		var normal := Vector3.UP
		var damage := 50.0 + i * 25.0
		
		# Delay each impact slightly
		get_tree().create_timer(i * 0.3).timeout.connect(func():
			VfxIntegrationComplete.create_impact_effect(
				position, normal, weapon_type, damage, null
			)
		)

func _demo_enemy_visuals() -> void:
	print("👹 Demo: Enemy Visuals")
	_create_demo_enemy_showcase()
	
	# Add some particle effects around enemies for showcase
	for enemy in demo_enemies:
		if is_instance_valid(enemy):
			var pos := enemy.global_position
			
			# Create subtle ambient glow around enemies
			VfxPoolSystem.create_environmental_effect(
				pos + Vector3(0, 0.5, 0),
				"ambient_glow",
				5.0,
				0.5
			)

func _demo_ambient_effects() -> void:
	print("🌫️ Demo: Ambient Effects")
	
	# Battlefield smoke
	AmbientEffectsEnhanced.create_battlefield_smoke(
		Vector3(-4, 0, 0), 3.0, 1.0, 20.0
	)
	
	# Electrical sparks
	AmbientEffectsEnhanced.create_spark_shower(
		Vector3(4, 2, 0), Vector3(0, -1, 0), 1.0, 10.0
	)
	
	# Fire ambience
	AmbientEffectsEnhanced.create_fire_ambience(
		Vector3(0, 0, -4), 1.5, 1.0, 25.0
	)
	
	# Energy dome
	AmbientEffectsEnhanced.create_energy_dome(
		Vector3(0, 0, 4), 3.0, Color(0.3, 0.6, 1.0), 15.0
	)

func _demo_environmental_hazards() -> void:
	print("☠️ Demo: Environmental Hazards")
	
	# Create various hazards
	VfxIntegrationComplete.create_environmental_hazard(
		"acid_pool", Vector3(-6, 0, -6), 1.0, 30.0
	)
	VfxIntegrationComplete.create_environmental_hazard(
		"corruption", Vector3(6, 0, -6), 1.0, 25.0
	)
	VfxIntegrationComplete.create_environmental_hazard(
		"plasma_discharge", Vector3(-6, 0, 6), 1.0, 20.0
	)
	VfxIntegrationComplete.create_environmental_hazard(
		"debris_field", Vector3(6, 0, 6), 1.0, -1.0
	)

func _demo_battlefield_ambience() -> void:
	print("⚔️ Demo: Battlefield Ambience")
	
	# Create intense battlefield atmosphere
	var effect_ids := VfxIntegrationComplete.create_battlefield_ambience(
		Vector3.ZERO, 0.8, 45.0
	)
	
	print("Created ", effect_ids.size(), " battlefield effects")

# =============================================================================
# Demo Utilities
# =============================================================================

func _cycle_vfx_quality() -> void:
	demo_mode = (demo_mode + 1) % VfxIntegrationComplete.VfxMode.size()
	VfxIntegrationComplete.set_vfx_mode(demo_mode)
	print("🎨 VFX Quality: ", VfxIntegrationComplete.VfxMode.keys()[demo_mode])

func _toggle_auto_demo() -> void:
	if auto_demo_timer >= 0:
		auto_demo_timer = -1.0  # Disable
		print("⏸️ Auto demo disabled")
	else:
		auto_demo_timer = 0.0   # Enable
		print("▶️ Auto demo enabled")

func _run_auto_demo_cycle() -> void:
	if auto_demo_timer < 0:  # Auto demo disabled
		return
	
	match current_demo_phase % 6:
		0: _demo_projectile_effects()
		1: _demo_impact_effects()
		2: _demo_enemy_visuals()
		3: _demo_ambient_effects()
		4: _demo_environmental_hazards()
		5: _demo_battlefield_ambience()
	
	current_demo_phase += 1
	print("🔄 Auto Demo Phase: ", current_demo_phase % 6)

func _run_performance_test() -> void:
	print("📊 Running Performance Test...")
	
	# Create many effects to test performance
	var test_effects := 50
	
	for i in range(test_effects):
		var random_pos := Vector3(
			randf_range(-10, 10),
			randf_range(0, 3),
			randf_range(-10, 10)
		)
		
		# Stagger creation to avoid frame spike
		get_tree().create_timer(i * 0.02).timeout.connect(func():
			# Random effect type
			match i % 4:
				0: VfxPoolSystem.create_projectile_trail(
					random_pos, random_pos + Vector3(0, 0, 5), "autocannon", Color.YELLOW, 1.0
				)
				1: VfxPoolSystem.create_impact_effect(
					random_pos, Vector3.UP, "kinetic", "armor", 1.0
				)
				2: VfxPoolSystem.create_explosion(random_pos, "missile", 1.0, Color.ORANGE)
				3: VfxPoolSystem.create_environmental_effect(
					random_pos, "smoke", 3.0, 0.8
				)
		)
	
	# Show stats after test
	get_tree().create_timer(test_effects * 0.02 + 2.0).timeout.connect(_show_vfx_statistics)

func _cleanup_all_demo_effects() -> void:
	print("🧹 Cleaning up all demo effects...")
	VfxIntegrationComplete.cleanup_all_vfx()

func _show_vfx_statistics() -> void:
	print("📈 VFX Statistics:")
	var stats := VfxIntegrationComplete.get_vfx_statistics()
	
	for key in stats:
		if stats[key] is Dictionary:
			print("  ", key, ":")
			for subkey in stats[key]:
				print("    ", subkey, ": ", stats[key][subkey])
		else:
			print("  ", key, ": ", stats[key])
	
	# Also show FPS
	print("  Current FPS: ", Engine.get_frames_per_second())
	
	# Show budget status
	print("  Within Budget: ", VfxIntegrationComplete.is_within_effect_budget())

## Called when the example is removed from the scene
func _exit_tree() -> void:
	print("🏁 VFX Demo finished - cleaning up...")
	VfxIntegrationComplete.cleanup_all_vfx()