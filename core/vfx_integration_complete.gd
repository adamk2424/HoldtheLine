class_name VfxIntegrationComplete
extends Node
## Complete VFX integration system that coordinates all visual effects
## Provides unified interface for projectiles, impacts, ambient effects, and enemy visuals

# --- Integration Modes ---
enum VfxMode {
	LIGHTWEIGHT,    # Maximum performance - simplified effects
	STANDARD,       # Balanced quality and performance  
	ENHANCED,       # Full quality effects
	CINEMATIC      # Maximum visual fidelity for screenshots/videos
}

# --- Current Settings ---
static var current_mode: VfxMode = VfxMode.STANDARD
static var performance_monitoring: bool = true
static var effect_budget: int = 800  # Maximum concurrent effects

# --- Performance Metrics ---
static var frame_time_samples: Array[float] = []
static var last_performance_check: float = 0.0
static var automatic_quality_adjustment: bool = true

## Initialize the complete VFX system
static func initialize_vfx_system() -> void:
	print("🎮 Initializing Complete VFX System...")
	
	# Initialize lightweight projectile system
	ProjectileVfxLightweight.initialize()
	
	# Initialize pool system if not already done
	if not VfxPoolSystem.get_instance():
		var pool_system := VfxPoolSystem.new()
		pool_system.name = "VfxPoolSystem"
		Engine.get_main_loop().current_scene.add_child(pool_system)
	
	# Set initial quality based on system capabilities
	_detect_and_set_initial_quality()
	
	print("✅ VFX System initialized with mode: ", VfxMode.keys()[current_mode])

## Set VFX quality mode
static func set_vfx_mode(mode: VfxMode) -> void:
	current_mode = mode
	_apply_mode_settings()
	print("🎨 VFX Mode changed to: ", VfxMode.keys()[mode])

## Create complete projectile effect with appropriate quality level
static func create_projectile_effect(
	weapon_type: String,
	start_pos: Vector3,
	end_pos: Vector3,
	travel_time: float,
	source: Node3D,
	target: Node = null
) -> void:
	
	match current_mode:
		VfxMode.LIGHTWEIGHT:
			# Use pure lightweight system
			ProjectileVfxLightweight.create_muzzle_flash(weapon_type, start_pos, (end_pos - start_pos).normalized())
			ProjectileVfxLightweight.create_projectile_trail(weapon_type, start_pos, end_pos, travel_time, source)
			
		VfxMode.STANDARD:
			# Use pool system for efficiency with some enhancement
			var direction := (end_pos - start_pos).normalized()
			ProjectileVfxEnhanced.create_weapon_muzzle_flash(start_pos, weapon_type, direction)
			VfxPoolSystem.create_projectile_trail(start_pos, end_pos, weapon_type, _get_weapon_color(weapon_type), travel_time)
			
		VfxMode.ENHANCED:
			# Full enhanced system
			var direction := (end_pos - start_pos).normalized()
			ProjectileVfxEnhanced.create_weapon_muzzle_flash(start_pos, weapon_type, direction)
			ProjectileVfxEnhanced.create_projectile_vfx(start_pos, end_pos, weapon_type, travel_time, target != null, target)
			
		VfxMode.CINEMATIC:
			# Maximum quality with additional effects
			var direction := (end_pos - start_pos).normalized()
			ProjectileVfxEnhanced.create_weapon_muzzle_flash(start_pos, weapon_type, direction)
			ProjectileVfxEnhanced.create_projectile_vfx(start_pos, end_pos, weapon_type, travel_time, target != null, target)
			# Add atmospheric trail effects
			_create_atmospheric_trail_effects(start_pos, end_pos, weapon_type)

## Create complete impact effect with material awareness
static func create_impact_effect(
	position: Vector3,
	normal: Vector3,
	weapon_type: String,
	damage: float,
	target: Node = null
) -> void:
	
	match current_mode:
		VfxMode.LIGHTWEIGHT:
			ProjectileVfxLightweight.create_impact_effect(weapon_type, position, normal, Engine.get_main_loop().current_scene)
			
		VfxMode.STANDARD, VfxMode.ENHANCED, VfxMode.CINEMATIC:
			ImpactEffectsEnhanced.create_weapon_impact(position, normal, damage, weapon_type, target)
			
			# Add ambient effects for higher quality modes
			if current_mode == VfxMode.ENHANCED or current_mode == VfxMode.CINEMATIC:
				_create_impact_ambient_effects(position, normal, weapon_type, damage)

## Create enhanced enemy visual based on current quality settings
static func create_enemy_visual(enemy_id: String, enemy_data: Dictionary) -> Node3D:
	match current_mode:
		VfxMode.LIGHTWEIGHT:
			# Use basic visual generator for performance
			var color := Color.html(enemy_data.get("mesh_color", "#FFFFFF"))
			return VisualGenerator.create_entity_visual(enemy_id, color) or _create_simple_enemy_visual(enemy_id, enemy_data)
			
		VfxMode.STANDARD:
			# Use existing enhanced system
			var color := Color.html(enemy_data.get("mesh_color", "#FFFFFF"))
			return EnemyVisualEnhanced.create_enhanced_enemy_visual(enemy_id, enemy_data, color)
			
		VfxMode.ENHANCED, VfxMode.CINEMATIC:
			# Use complete enhanced system with full detail
			return EnemyVisualEnhancedComplete.create_complete_enemy_visual(enemy_id, enemy_data)
	
	# Fallback
	return _create_simple_enemy_visual(enemy_id, enemy_data)

## Create ambient battlefield effects
static func create_battlefield_ambience(
	center_position: Vector3,
	battle_intensity: float,
	duration: float = 60.0
) -> Array[int]:
	var effect_ids: Array[int] = []
	
	# Scale effect count based on quality mode
	var effect_multiplier: float
	match current_mode:
		VfxMode.LIGHTWEIGHT: effect_multiplier = 0.3
		VfxMode.STANDARD: effect_multiplier = 0.7
		VfxMode.ENHANCED: effect_multiplier = 1.0
		VfxMode.CINEMATIC: effect_multiplier = 1.5
		_: effect_multiplier = 0.7
	
	# Create smoke effects
	if battle_intensity > 0.3:
		var smoke_count := int(3 * battle_intensity * effect_multiplier)
		for i in range(smoke_count):
			var offset := Vector3(
				randf_range(-8.0, 8.0),
				0.0,
				randf_range(-8.0, 8.0)
			)
			var smoke_id := AmbientEffectsEnhanced.create_battlefield_smoke(
				center_position + offset,
				3.0 + randf() * 2.0,
				battle_intensity,
				duration * randf_range(0.7, 1.3)
			)
			effect_ids.append(smoke_id)
	
	# Create spark showers from damaged equipment
	if battle_intensity > 0.5:
		var spark_count := int(2 * battle_intensity * effect_multiplier)
		for i in range(spark_count):
			var spark_pos := center_position + Vector3(
				randf_range(-6.0, 6.0),
				randf_range(1.0, 3.0),
				randf_range(-6.0, 6.0)
			)
			var spark_direction := Vector3(
				randf_range(-1.0, 1.0),
				-1.0,
				randf_range(-1.0, 1.0)
			).normalized()
			
			var spark_id := AmbientEffectsEnhanced.create_spark_shower(
				spark_pos, spark_direction, battle_intensity, duration * 0.3
			)
			effect_ids.append(spark_id)
	
	# Create fires for intense battles
	if battle_intensity > 0.7:
		var fire_count := int(1 + battle_intensity * effect_multiplier)
		for i in range(fire_count):
			var fire_pos := center_position + Vector3(
				randf_range(-5.0, 5.0),
				0.0,
				randf_range(-5.0, 5.0)
			)
			var fire_id := AmbientEffectsEnhanced.create_fire_ambience(
				fire_pos,
				1.5 + battle_intensity,
				battle_intensity,
				duration * randf_range(0.8, 1.2)
			)
			effect_ids.append(fire_id)
	
	return effect_ids

## Create environmental hazard effects
static func create_environmental_hazard(
	hazard_type: String,
	position: Vector3,
	intensity: float,
	duration: float = 30.0
) -> int:
	
	match hazard_type:
		"acid_pool":
			return AmbientEffectsEnhanced.create_acid_pool(
				position, 
				2.0 + intensity, 
				5.0 * intensity, 
				duration
			)
		"energy_field":
			return AmbientEffectsEnhanced.create_energy_dome(
				position,
				5.0 + intensity * 3.0,
				Color(0.3, 0.6, 1.0),
				duration
			)
		"corruption":
			return AmbientEffectsEnhanced.create_corruption_field(
				position,
				6.0 + intensity * 2.0,
				intensity,
				duration
			)
		"thermal":
			return AmbientEffectsEnhanced.create_heat_shimmer(
				position,
				Vector3(3.0 + intensity, 2.0, 3.0 + intensity),
				intensity,
				duration
			)
		"plasma_discharge":
			return AmbientEffectsEnhanced.create_plasma_discharge(
				position,
				int(3 + intensity * 5),
				3.0 + intensity * 2.0,
				duration
			)
		"debris_field":
			return AmbientEffectsEnhanced.create_debris_field(
				position,
				int(10 + intensity * 10),
				4.0 + intensity * 3.0,
				"concrete"
			)
		_:
			print("⚠️ Unknown hazard type: ", hazard_type)
			return -1

## Monitor performance and adjust quality automatically
static func update_performance_monitoring() -> void:
	if not performance_monitoring or not automatic_quality_adjustment:
		return
	
	var current_time := Time.get_ticks_msec() / 1000.0
	if current_time - last_performance_check < 1.0:  # Check every second
		return
	
	last_performance_check = current_time
	
	var fps := Engine.get_frames_per_second()
	frame_time_samples.append(1.0 / max(fps, 1.0))
	
	# Keep only last 10 samples
	if frame_time_samples.size() > 10:
		frame_time_samples = frame_time_samples.slice(-10)
	
	# Calculate average frame time
	var avg_frame_time := 0.0
	for sample in frame_time_samples:
		avg_frame_time += sample
	avg_frame_time /= frame_time_samples.size()
	
	var target_fps := _get_target_fps_for_mode(current_mode)
	var target_frame_time := 1.0 / target_fps
	
	# Adjust quality if performance is consistently poor
	if avg_frame_time > target_frame_time * 1.3:  # 30% over target
		if current_mode > VfxMode.LIGHTWEIGHT:
			set_vfx_mode(current_mode - 1)
			print("📉 Performance: Auto-reduced VFX quality to ", VfxMode.keys()[current_mode])
	elif avg_frame_time < target_frame_time * 0.8:  # 20% under target
		if current_mode < VfxMode.CINEMATIC:
			set_vfx_mode(current_mode + 1)
			print("📈 Performance: Auto-increased VFX quality to ", VfxMode.keys()[current_mode])

## Get VFX system statistics
static func get_vfx_statistics() -> Dictionary:
	var stats := {}
	
	# Pool system stats
	if VfxPoolSystem.get_instance():
		stats["pool_system"] = VfxPoolSystem.get_statistics()
	
	# Ambient effects stats  
	stats["ambient_effects"] = AmbientEffectsEnhanced.get_ambient_effect_stats()
	
	# Lightweight effects count
	stats["lightweight_effects"] = ProjectileVfxLightweight.get_active_effect_count()
	
	# Current settings
	stats["current_mode"] = VfxMode.keys()[current_mode]
	stats["performance_monitoring"] = performance_monitoring
	stats["effect_budget"] = effect_budget
	
	# Performance metrics
	if frame_time_samples.size() > 0:
		var avg_frame_time := 0.0
		for sample in frame_time_samples:
			avg_frame_time += sample
		avg_frame_time /= frame_time_samples.size()
		stats["average_fps"] = 1.0 / avg_frame_time
		stats["target_fps"] = _get_target_fps_for_mode(current_mode)
	
	return stats

## Cleanup all VFX effects
static func cleanup_all_vfx() -> void:
	print("🧹 Cleaning up all VFX effects...")
	
	# Clean pool system
	if VfxPoolSystem.get_instance():
		VfxPoolSystem.cleanup_all_effects()
	
	# Clean ambient effects
	AmbientEffectsEnhanced.clear_effects_by_type(AmbientEffectsEnhanced.AmbientType.BATTLEFIELD)
	AmbientEffectsEnhanced.clear_effects_by_type(AmbientEffectsEnhanced.AmbientType.ENVIRONMENTAL)
	AmbientEffectsEnhanced.clear_effects_by_type(AmbientEffectsEnhanced.AmbientType.ATMOSPHERIC)
	
	# Clean lightweight effects
	ProjectileVfxLightweight.cleanup_effects()
	
	print("✅ VFX cleanup complete")

## Force garbage collection of VFX resources
static func force_vfx_garbage_collection() -> void:
	# Clean invalid effects
	AmbientEffectsEnhanced.cleanup_invalid_effects()
	
	# Force Godot garbage collection
	if OS.is_debug_build():
		print("🗑️ Forcing VFX garbage collection...")
	
	# Clear frame time samples if too old
	if frame_time_samples.size() > 20:
		frame_time_samples = frame_time_samples.slice(-10)

# =============================================================================
# Private Helper Functions
# =============================================================================

static func _detect_and_set_initial_quality() -> void:
	# Simple heuristic based on rendering capabilities
	var render_info := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TYPE_GLOBAL, RenderingServer.RENDERING_INFO_DRAW_CALLS_IN_FRAME)
	
	# Default to standard mode
	var initial_mode := VfxMode.STANDARD
	
	# Adjust based on platform
	match OS.get_name():
		"Android", "iOS":
			initial_mode = VfxMode.LIGHTWEIGHT
		"Windows", "macOS", "Linux":
			initial_mode = VfxMode.STANDARD
		"Web":
			initial_mode = VfxMode.LIGHTWEIGHT
	
	set_vfx_mode(initial_mode)

static func _apply_mode_settings() -> void:
	match current_mode:
		VfxMode.LIGHTWEIGHT:
			effect_budget = 400
		VfxMode.STANDARD:
			effect_budget = 800
		VfxMode.ENHANCED:
			effect_budget = 1200
		VfxMode.CINEMATIC:
			effect_budget = 2000

static func _get_target_fps_for_mode(mode: VfxMode) -> float:
	match mode:
		VfxMode.LIGHTWEIGHT: return 60.0
		VfxMode.STANDARD: return 45.0
		VfxMode.ENHANCED: return 30.0
		VfxMode.CINEMATIC: return 24.0
		_: return 45.0

static func _get_weapon_color(weapon_type: String) -> Color:
	match weapon_type:
		"autocannon": return Color.YELLOW
		"missile_battery": return Color.ORANGE
		"rail_gun": return Color.CYAN
		"plasma_mortar": return Color.MAGENTA
		"tesla_coil": return Color(0.4, 0.8, 1.0)
		"inferno_tower": return Color(1.0, 0.4, 0.1)
		_: return Color.WHITE

static func _create_atmospheric_trail_effects(start_pos: Vector3, end_pos: Vector3, weapon_type: String) -> void:
	# Additional atmospheric effects for cinematic mode
	match weapon_type:
		"rail_gun":
			# Ionization trail
			AmbientEffectsEnhanced.create_heat_shimmer(
				(start_pos + end_pos) / 2.0,
				Vector3(0.2, 0.2, start_pos.distance_to(end_pos)),
				0.8,
				2.0
			)
		"plasma_mortar":
			# Plasma discharge along path
			var segment_count := 5
			for i in range(segment_count):
				var t := float(i) / float(segment_count - 1)
				var pos := start_pos.lerp(end_pos, t)
				AmbientEffectsEnhanced.create_plasma_discharge(pos, 1, 1.0, 1.0)

static func _create_impact_ambient_effects(position: Vector3, normal: Vector3, weapon_type: String, damage: float) -> void:
	# Additional ambient effects for enhanced impacts
	if damage > 50:  # High damage impacts
		match weapon_type:
			"inferno_tower":
				AmbientEffectsEnhanced.create_fire_ambience(position, 1.0, 0.8, 15.0)
			"plasma_mortar":
				AmbientEffectsEnhanced.create_plasma_discharge(position, 2, 2.0, 8.0)
			"tesla_coil":
				AmbientEffectsEnhanced.create_spark_shower(position, normal, 1.0, 5.0)

static func _create_simple_enemy_visual(enemy_id: String, enemy_data: Dictionary) -> Node3D:
	var r := Node3D.new()
	r.name = "Visual"
	
	var color := Color.html(enemy_data.get("mesh_color", "#FFFFFF"))
	var size_scale := Vector3(1.0, 1.0, 1.0)
	
	if enemy_data.has("mesh_scale"):
		var scale_data = enemy_data["mesh_scale"]
		if scale_data is Array and scale_data.size() >= 3:
			size_scale = Vector3(scale_data[0], scale_data[1], scale_data[2])
	
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size_scale
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	box.material = material
	mesh_instance.mesh = box
	mesh_instance.position.y = size_scale.y / 2.0
	r.add_child(mesh_instance)
	
	return r

## Enable/disable automatic quality adjustment
static func set_automatic_quality_adjustment(enabled: bool) -> void:
	automatic_quality_adjustment = enabled
	print("🎛️ Automatic quality adjustment: ", "enabled" if enabled else "disabled")

## Enable/disable performance monitoring
static func set_performance_monitoring(enabled: bool) -> void:
	performance_monitoring = enabled
	if enabled:
		print("📊 Performance monitoring enabled")
	else:
		print("📊 Performance monitoring disabled")
		frame_time_samples.clear()

## Set custom effect budget
static func set_effect_budget(budget: int) -> void:
	effect_budget = max(100, budget)  # Minimum of 100 effects
	print("💰 Effect budget set to: ", effect_budget)

## Check if we're within effect budget
static func is_within_effect_budget() -> bool:
	var stats := get_vfx_statistics()
	var total_effects := 0
	
	if stats.has("pool_system"):
		total_effects += stats["pool_system"].get("total_active_effects", 0)
	
	total_effects += stats.get("lightweight_effects", 0)
	
	if stats.has("ambient_effects"):
		total_effects += stats["ambient_effects"].get("TOTAL_ACTIVE", 0)
	
	return total_effects < effect_budget

## Get recommended VFX mode for current hardware
static func get_recommended_vfx_mode() -> VfxMode:
	var avg_fps := Engine.get_frames_per_second()
	
	if avg_fps >= 60:
		return VfxMode.ENHANCED
	elif avg_fps >= 45:
		return VfxMode.STANDARD
	else:
		return VfxMode.LIGHTWEIGHT