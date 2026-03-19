extends Node3D
## Example of how to use the enhanced VFX system
## This demonstrates the integration of all VFX components

func _ready() -> void:
	# Wait for VFX system to be ready
	if VfxSystem.pool_system:
		_run_vfx_examples()
	else:
		VfxSystem.pool_system.vfx_system_ready.connect(_run_vfx_examples, CONNECT_ONE_SHOT)

func _run_vfx_examples() -> void:
	print("Running VFX integration examples...")
	
	# Example 1: Complete weapon fire sequence
	_example_weapon_fire()
	
	# Example 2: Enhanced enemy death effects
	_example_enemy_death()
	
	# Example 3: Environmental destruction
	_example_environmental_destruction()
	
	# Example 4: Battlefield atmosphere
	_example_battlefield_atmosphere()

func _example_weapon_fire() -> void:
	print("Example: Weapon Fire Sequence")
	
	var weapon_pos := Vector3(0, 1, 0)
	var target_pos := Vector3(10, 1, 5)
	
	# Complete firing sequence with muzzle flash, projectile trail, and impact
	VfxSystem.create_weapon_fire_complete(
		weapon_pos,
		target_pos,
		"autocannon",
		75.0,  # damage
		null,  # target node
		0.5    # travel time
	)
	
	# Alternative: Individual components
	# ProjectileVfxEnhanced.create_weapon_muzzle_flash(weapon_pos, "rail_gun", Vector3.FORWARD)
	# ProjectileVfxEnhanced.create_projectile_vfx(weapon_pos, target_pos, "plasma_mortar", 1.2)

func _example_enemy_death() -> void:
	print("Example: Enemy Death Effects")
	
	# Create a mock enemy node for demonstration
	var mock_enemy := Node3D.new()
	mock_enemy.name = "MockEnemy"
	mock_enemy.set_meta("entity_id", "terror_bringer")
	mock_enemy.set_meta("enemy_data", {"hp": 3750, "role": "boss", "is_boss": true})
	add_child(mock_enemy)
	
	# Enhanced death effects based on enemy type and killer weapon
	VfxSystem.create_enemy_death_effects(mock_enemy, Vector3(5, 0, 5), "missile_battery")
	
	mock_enemy.queue_free()

func _example_environmental_destruction() -> void:
	print("Example: Environmental Destruction")
	
	var destruction_pos := Vector3(-5, 0, -5)
	
	# Building collapse with chain reactions
	VfxSystem.create_destruction_sequence(
		destruction_pos,
		"building_collapse",
		2.0  # high intensity
	)
	
	# Ground crater from massive impact
	await get_tree().create_timer(2.0).timeout
	VfxSystem.create_destruction_sequence(
		destruction_pos + Vector3(3, 0, 0),
		"ground_crater",
		1.5
	)

func _example_battlefield_atmosphere() -> void:
	print("Example: Battlefield Atmosphere")
	
	# Create atmospheric effects across a large area
	VfxSystem.create_battlefield_atmosphere(
		Vector3(0, 0, 0),  # center
		15.0,              # radius
		1.2                # intensity
	)

func _example_direct_impact_effects() -> void:
	print("Example: Direct Impact Effects")
	
	# Kinetic impact on armor
	VfxSystem.create_impact_effect(
		Vector3(2, 0.5, 2),
		Vector3.UP,
		100.0,
		ImpactEffectsEnhanced.ImpactCategory.KINETIC,
		ImpactEffectsEnhanced.MaterialType.ARMOR,
		"autocannon"
	)
	
	# Energy beam on organic target
	await get_tree().create_timer(1.0).timeout
	VfxSystem.create_impact_effect(
		Vector3(-2, 0.5, 2),
		Vector3.UP,
		150.0,
		ImpactEffectsEnhanced.ImpactCategory.ENERGY,
		ImpactEffectsEnhanced.MaterialType.ORGANIC,
		"plasma_mortar"
	)
	
	# Acid splash on stone
	await get_tree().create_timer(1.0).timeout
	VfxSystem.create_impact_effect(
		Vector3(0, 0.5, -2),
		Vector3.UP,
		80.0,
		ImpactEffectsEnhanced.ImpactCategory.ACID,
		ImpactEffectsEnhanced.MaterialType.STONE,
		"bile_spitter"
	)

func _example_enemy_visual_showcase() -> void:
	print("Example: Enhanced Enemy Visuals")
	
	var enemy_data := {
		"mesh_color": "#8B4513",
		"role": "swarm",
		"attack_type": "melee",
		"specials": [{"type": "leap", "range": 4}],
		"hp": 94,
		"speed": 5.27
	}
	
	# Create enhanced enemy visual
	var enhanced_visual := EnemyVisualEnhanced.create_enhanced_enemy_visual(
		"thrasher",
		enemy_data,
		Color.html("#8B4513")
	)
	
	if enhanced_visual:
		enhanced_visual.position = Vector3(8, 0, 0)
		add_child(enhanced_visual)
		
		# Set up animations
		EnemyVisualEnhanced.setup_enemy_animations(enhanced_visual, "thrasher", enemy_data)
		
		print("Enhanced thrasher visual created with razor claws and predator features")

# Input handling for manual testing
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				_example_weapon_fire()
			KEY_2:
				_example_enemy_death()
			KEY_3:
				_example_environmental_destruction()
			KEY_4:
				_example_battlefield_atmosphere()
			KEY_5:
				_example_direct_impact_effects()
			KEY_6:
				_example_enemy_visual_showcase()
			KEY_0:
				# Emergency VFX cleanup
				VfxSystem.emergency_vfx_cleanup()
				print("VFX Stats: ", VfxSystem.get_vfx_stats())

func _on_performance_test() -> void:
	print("Running VFX performance test...")
	
	# Stress test with many effects
	for i in range(50):
		var pos := Vector3(
			randf_range(-10, 10),
			randf_range(0, 2),
			randf_range(-10, 10)
		)
		
		VfxSystem.create_impact_effect(
			pos,
			Vector3.UP,
			randf_range(50, 200),
			[ImpactEffectsEnhanced.ImpactCategory.KINETIC, 
			 ImpactEffectsEnhanced.ImpactCategory.EXPLOSIVE,
			 ImpactEffectsEnhanced.ImpactCategory.ENERGY][randi() % 3],
			[ImpactEffectsEnhanced.MaterialType.ORGANIC,
			 ImpactEffectsEnhanced.MaterialType.ARMOR,
			 ImpactEffectsEnhanced.MaterialType.STONE][randi() % 3]
		)
		
		await get_tree().process_frame
	
	print("Performance test complete. Stats: ", VfxSystem.get_vfx_stats())