extends Node3D
## Complete VFX Integration Example - Demonstrates all enhanced VFX systems working together
## Shows how to use the new pooling system, impact effects, and enemy visuals

class_name VfxIntegrationCompleteExample

# Example of how to integrate all the VFX systems in your game

func _ready() -> void:
	# Initialize VFX systems
	_setup_vfx_systems()
	
	# Example usage scenarios
	_demonstrate_projectile_vfx()
	_demonstrate_enemy_death_effects()
	_demonstrate_weapon_firing()
	_demonstrate_ambient_effects()

# =============================================================================
# VFX System Setup
# =============================================================================

func _setup_vfx_systems() -> void:
	# VfxPoolSystem is automatically initialized as singleton
	# Set performance mode if needed
	VfxPoolSystem.set_performance_mode(false)  # Full quality for this demo
	
	# Print current VFX statistics
	var stats := VfxPoolSystem.get_statistics()
	print("VFX Pool System initialized:")
	print("  - Total active effects: ", stats["total_active_effects"])
	print("  - Performance mode: ", stats["performance_mode"])
	print("  - Pools initialized: ", stats["pools_initialized"])

# =============================================================================
# Projectile VFX Examples
# =============================================================================

func _demonstrate_projectile_vfx() -> void:
	print("\n--- Projectile VFX Demonstration ---")
	
	var start_pos := Vector3(0, 1, 0)
	var end_pos := Vector3(10, 1, 0)
	
	# Example 1: Autocannon bullet
	print("Creating autocannon bullet trail...")
	ProjectileVfxEnhanced.create_projectile_vfx(
		start_pos,
		end_pos,
		"autocannon",
		0.3,  # Fast travel time
		false,
		null
	)
	
	# Example 2: Missile with homing
	print("Creating missile trail...")
	ProjectileVfxEnhanced.create_projectile_vfx(
		start_pos + Vector3(0, 0.5, 0),
		end_pos + Vector3(0, 0.5, 0),
		"missile_battery",
		1.2,  # Slower travel time
		true,  # Homing enabled
		null
	)
	
	# Example 3: Energy beam (instant)
	print("Creating energy beam...")
	ProjectileVfxEnhanced.create_projectile_vfx(
		start_pos + Vector3(0, 1, 0),
		end_pos + Vector3(0, 1, 0),
		"rail_gun",
		0.1,  # Nearly instant
		false,
		null
	)

func _demonstrate_impact_effects() -> void:
	print("\n--- Impact Effects Demonstration ---")
	
	var impact_pos := Vector3(10, 1, 0)
	var normal := Vector3.UP
	
	# Example 1: Kinetic impact on armor
	print("Creating kinetic impact on armor...")
	ImpactEffectsEnhanced.create_weapon_impact(
		impact_pos,
		normal,
		50.0,  # Damage amount
		"autocannon",
		null  # No specific target
	)
	
	# Example 2: Energy impact on organic target
	print("Creating energy impact on organic...")
	ImpactEffectsEnhanced.create_weapon_impact(
		impact_pos + Vector3(1, 0, 0),
		normal,
		75.0,
		"plasma_mortar",
		null
	)
	
	# Example 3: Explosive impact
	print("Creating explosive impact...")
	ImpactEffectsEnhanced.create_weapon_impact(
		impact_pos + Vector3(2, 0, 0),
		normal,
		100.0,
		"missile_battery",
		null
	)

# =============================================================================
# Enemy Visual Effects Examples
# =============================================================================

func _demonstrate_enemy_death_effects() -> void:
	print("\n--- Enemy Death Effects Demonstration ---")
	
	# Example 1: Blight Mite explosive death
	var blight_pos := Vector3(5, 0, 5)
	print("Simulating blight mite suicide explosion...")
	AmbientVfx.create_area_damage_effect(blight_pos, 2.0, "explosive")
	
	# Example 2: Boss death
	var boss_pos := Vector3(0, 0, 10)
	print("Simulating boss death...")
	AmbientVfx.create_area_damage_effect(boss_pos, 3.0, "explosive")
	AmbientVfx.create_battlefield_smoke(boss_pos, 30.0, 2.0)

func _demonstrate_enemy_visuals() -> void:
	print("\n--- Enemy Visual Creation Demonstration ---")
	
	# Example: Create enhanced enemy visuals
	var enemy_data := {
		"mesh_color": "#FF4444",
		"role": "swarm",
		"flying": false
	}
	
	# Create thrasher visual
	var thrasher_visual := EnemyVisualEnhanced.create_enhanced_enemy_visual(
		"thrasher",
		enemy_data,
		Color.html("#FF4444")
	)
	
	if thrasher_visual:
		add_child(thrasher_visual)
		thrasher_visual.position = Vector3(-5, 0, 0)
		
		# Setup animations
		EnemyVisualEnhanced.setup_enemy_animations(thrasher_visual, "thrasher", enemy_data)
		
		print("Created enhanced thrasher visual with animations")

# =============================================================================
# Weapon Firing Effects Examples
# =============================================================================

func _demonstrate_weapon_firing() -> void:
	print("\n--- Weapon Firing Effects Demonstration ---")
	
	var weapon_pos := Vector3(0, 0.5, 0)
	var target_pos := Vector3(8, 0.5, 0)
	var direction := (target_pos - weapon_pos).normalized()
	
	# Example 1: Autocannon firing
	print("Autocannon muzzle flash...")
	ProjectileVfxEnhanced.create_weapon_muzzle_flash(weapon_pos, "autocannon", direction)
	
	# Example 2: Tesla coil discharge
	print("Tesla coil discharge...")
	ProjectileVfxEnhanced.create_weapon_muzzle_flash(weapon_pos, "tesla_coil", direction)
	
	# Example 3: Inferno tower flame burst
	print("Inferno tower flame burst...")
	ProjectileVfxEnhanced.create_weapon_muzzle_flash(weapon_pos, "inferno_tower", direction)

# =============================================================================
# Ambient Effects Examples
# =============================================================================

func _demonstrate_ambient_effects() -> void:
	print("\n--- Ambient Effects Demonstration ---")
	
	# Example 1: Battlefield smoke
	var smoke_pos := Vector3(-3, 0, 3)
	print("Creating battlefield smoke...")
	AmbientVfx.create_battlefield_smoke(smoke_pos, 20.0, 1.0)
	
	# Example 2: Sparks shower (electrical damage)
	var spark_pos := Vector3(3, 0, 3)
	print("Creating sparks shower...")
	AmbientVfx.create_sparks_shower(spark_pos, 5.0, 1.0)
	
	# Example 3: Heat shimmer (thermal effects)
	var heat_pos := Vector3(0, 0, -3)
	print("Creating heat shimmer...")
	AmbientVfx.create_heat_shimmer(heat_pos, 15.0, 1.0)
	
	# Example 4: Fire embers
	var ember_pos := Vector3(-3, 0, -3)
	print("Creating fire embers...")
	AmbientVfx.create_fire_embers(ember_pos, 12.0, 1.0)

# =============================================================================
# Pool System Management Examples
# =============================================================================

func _demonstrate_pool_management() -> void:
	print("\n--- VFX Pool Management Demonstration ---")
	
	# Create many effects to demonstrate pooling
	for i in range(20):
		var pos := Vector3(randf_range(-10, 10), 1, randf_range(-10, 10))
		
		# Create different types of pooled effects
		match i % 4:
			0:
				VfxPoolSystem.create_impact_effect(pos, Vector3.UP, "kinetic", "armor", 1.0)
			1:
				VfxPoolSystem.create_explosion(pos, "missile", 1.0, Color.ORANGE)
			2:
				VfxPoolSystem.create_environmental_effect(pos, "smoke", 8.0, 0.8)
			3:
				VfxPoolSystem.create_ui_effect(pos, "pickup_flash", Color.YELLOW, 1.0)
	
	# Print pool statistics
	var stats := VfxPoolSystem.get_statistics()
	print("After creating 20 effects:")
	print("  - Total active: ", stats["total_active_effects"])
	print("  - Per category: ", stats["effects_per_category"])

# =============================================================================
# Performance Testing
# =============================================================================

func _test_performance_impact() -> void:
	print("\n--- Performance Testing ---")
	
	var start_time := Time.get_ticks_msec()
	
	# Create 100 effects rapidly
	for i in range(100):
		var pos := Vector3(randf_range(-20, 20), randf_range(0, 5), randf_range(-20, 20))
		
		# Mix of different effect types
		VfxPoolSystem.create_projectile_trail(
			pos,
			pos + Vector3(randf_range(-5, 5), 0, randf_range(-5, 5)),
			["autocannon", "missile_battery", "rail_gun", "plasma_mortar"][i % 4],
			Color.WHITE,
			0.5
		)
		
		if i % 10 == 0:
			VfxPoolSystem.create_explosion(pos, "generic", 1.0, Color.RED)
	
	var end_time := Time.get_ticks_msec()
	var duration := end_time - start_time
	
	print("Created 100 effects in ", duration, " milliseconds")
	
	# Check final statistics
	var final_stats := VfxPoolSystem.get_statistics()
	print("Final statistics:")
	print("  - Total active: ", final_stats["total_active_effects"])
	print("  - Performance mode: ", final_stats["performance_mode"])

# =============================================================================
# Interactive Testing (called from input)
# =============================================================================

func _input(event: InputEvent) -> void:
	if not event.is_pressed():
		return
	
	match event as InputEventKey:
		var key_event:
			match key_event.keycode:
				KEY_1:
					_demonstrate_projectile_vfx()
				KEY_2:
					_demonstrate_impact_effects()
				KEY_3:
					_demonstrate_enemy_visuals()
				KEY_4:
					_demonstrate_weapon_firing()
				KEY_5:
					_demonstrate_ambient_effects()
				KEY_6:
					_demonstrate_pool_management()
				KEY_P:
					_test_performance_impact()
				KEY_C:
					VfxPoolSystem.cleanup_all_effects()
					print("Cleaned up all VFX effects")
				KEY_M:
					var current_mode := VfxPoolSystem.get_statistics()["performance_mode"]
					VfxPoolSystem.set_performance_mode(not current_mode)
					print("Performance mode toggled to: ", not current_mode)

# =============================================================================
# Integration Notes and Best Practices
# =============================================================================

## INTEGRATION CHECKLIST:
##
## 1. VFX Pool System Setup:
##    - VfxPoolSystem is automatically available as singleton
##    - Use VfxPoolSystem.create_* for frequent effects (projectiles, impacts)
##    - Monitor performance with get_statistics()
##    - Enable performance mode in low-FPS situations
##
## 2. Projectile Integration:
##    - Use ProjectileVfxEnhanced.create_projectile_vfx() for trail effects
##    - Use ImpactEffectsEnhanced.create_weapon_impact() for hit effects
##    - Both systems work together automatically in core/projectile.gd
##
## 3. Enemy Visual Integration:
##    - Use EnemyVisualEnhanced.create_enhanced_enemy_visual() for detailed models
##    - Call setup_enemy_animations() after creating visuals
##    - Enemy models match JSON visualDescription fields exactly
##
## 4. Ambient Effects:
##    - Use AmbientVfx.create_* for environmental and atmospheric effects
##    - Effects automatically handle their own lifetime and cleanup
##    - Create area damage effects for explosions and boss deaths
##
## 5. Performance Considerations:
##    - Pool system automatically manages effect reuse
##    - Performance mode reduces quality for better FPS
##    - Use cleanup_all_effects() if needed to free memory
##    - Monitor active effect counts to avoid overwhelming the system
##
## KEYBINDINGS FOR TESTING:
## 1 - Projectile VFX demo
## 2 - Impact effects demo  
## 3 - Enemy visuals demo
## 4 - Weapon firing demo
## 5 - Ambient effects demo
## 6 - Pool management demo
## P - Performance stress test
## C - Cleanup all effects
## M - Toggle performance mode