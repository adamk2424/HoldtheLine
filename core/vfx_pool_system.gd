class_name VfxPoolSystem
extends Node
## VFX Pool System - Centralized management for all visual effects
## Integrates VfxPool, AmbientVfx, ProjectileVfxEnhanced, and ImpactEffectsEnhanced

signal vfx_system_ready
signal vfx_performance_warning(performance_level: String)

# --- Performance Management ---
var _active_effect_count: int = 0
var _max_effects: int = 200
var _performance_mode: PerformanceMode = PerformanceMode.NORMAL

enum PerformanceMode {
	LOW,      # Minimal effects for performance
	NORMAL,   # Standard effect quality
	HIGH,     # Full quality effects
	ULTRA     # All effects + enhancements
}

# --- System State ---
var _is_initialized: bool = false
var _subsystems: Dictionary = {}

func _ready() -> void:
	name = "VfxPoolSystem"
	_initialize_subsystems()

func _initialize_subsystems() -> void:
	# Initialize all VFX subsystems
	_subsystems["vfx_pool"] = VfxPool.get_main_pool()
	_subsystems["ambient_vfx"] = AmbientVfx.get_instance()
	_subsystems["impact_effects"] = ImpactEffectsEnhanced.get_instance()
	
	# Set up performance monitoring
	_setup_performance_monitoring()
	
	_is_initialized = true
	vfx_system_ready.emit()
	print("VFX Pool System initialized with ", _subsystems.size(), " subsystems")

func _setup_performance_monitoring() -> void:
	var timer := Timer.new()
	timer.wait_time = 2.0  # Check performance every 2 seconds
	timer.timeout.connect(_check_performance)
	timer.autostart = true
	add_child(timer)

# =============================================================================
# Public API - Unified VFX Interface
# =============================================================================

## Create weapon fire effect with full integration
func create_weapon_fire_complete(
	weapon_pos: Vector3,
	target_pos: Vector3,
	weapon_type: String,
	damage: float,
	target: Node = null,
	travel_time: float = 1.0
) -> void:
	if not _is_initialized:
		push_warning("VFX System not initialized")
		return
	
	# Muzzle flash
	var direction := (target_pos - weapon_pos).normalized()
	ProjectileVfxEnhanced.create_weapon_muzzle_flash(weapon_pos, weapon_type, direction)
	
	# Projectile trail
	ProjectileVfxEnhanced.create_projectile_vfx(
		weapon_pos,
		target_pos,
		weapon_type,
		travel_time,
		false,  # homing
		target
	)
	
	_track_effect_creation(2)  # Muzzle + trail

## Create environmental destruction sequence
func create_destruction_sequence(
	pos: Vector3,
	destruction_type: String,
	intensity: float = 1.0,
	chain_positions: Array[Vector3] = []
) -> void:
	if not _is_initialized:
		return
	
	# Primary destruction
	ImpactEffectsEnhanced.create_environmental_destruction(pos, destruction_type, intensity, intensity * 2.0)
	
	# Chain reactions if specified
	if not chain_positions.is_empty():
		ImpactEffectsEnhanced.create_chain_reaction(pos, chain_positions, "explosion_chain", 0.3)
	
	_track_effect_creation(1 + chain_positions.size())

## Create atmospheric battlefield effects
func create_battlefield_atmosphere(center_pos: Vector3, radius: float, battle_intensity: float = 1.0) -> void:
	if not _is_initialized or _performance_mode == PerformanceMode.LOW:
		return
	
	var effect_count := int(battle_intensity * 5)
	
	# Distribute effects around battlefield
	for i in range(effect_count):
		var offset := Vector3(
			randf_range(-radius, radius),
			randf_range(0, 2),
			randf_range(-radius, radius)
		)
		var effect_pos := center_pos + offset
		
		match randi() % 4:
			0:
				AmbientVfx.create_battlefield_smoke(effect_pos, 20.0, battle_intensity * 0.5)
			1:
				AmbientVfx.create_sparks_shower(effect_pos, 3.0, battle_intensity * 0.3)
			2:
				AmbientVfx.create_dust_particles(effect_pos, 15.0, battle_intensity * 0.4)
			3:
				AmbientVfx.create_fire_embers(effect_pos, 10.0, battle_intensity * 0.6)
	
	_track_effect_creation(effect_count)

## Create enemy death effects based on enemy type and cause
func create_enemy_death_effects(enemy: Node, death_pos: Vector3, killer_weapon: String = "") -> void:
	if not _is_initialized:
		return
	
	if not is_instance_valid(enemy):
		return
	
	var enemy_id := ""
	var enemy_data := {}
	
	if enemy.has_method("get_entity_id"):
		enemy_id = enemy.get_entity_id()
	if enemy.has_method("get_data"):
		enemy_data = enemy.get_data()
	
	# Enhanced death effects based on enemy type
	_create_specific_death_effects(enemy_id, death_pos, killer_weapon, enemy_data)

## Set performance mode (affects effect quality and quantity)
func set_performance_mode(mode: PerformanceMode) -> void:
	_performance_mode = mode
	
	match mode:
		PerformanceMode.LOW:
			_max_effects = 50
		PerformanceMode.NORMAL:
			_max_effects = 150
		PerformanceMode.HIGH:
			_max_effects = 250
		PerformanceMode.ULTRA:
			_max_effects = 400
	
	print("VFX Performance mode set to: ", PerformanceMode.keys()[mode])

## Get current system statistics
func get_vfx_statistics() -> Dictionary:
	return {
		"active_effects": _active_effect_count,
		"max_effects": _max_effects,
		"performance_mode": PerformanceMode.keys()[_performance_mode],
		"subsystems_active": _subsystems.size(),
		"memory_usage_mb": _estimate_memory_usage()
	}

# =============================================================================
# Performance Management
# =============================================================================

func _check_performance() -> void:
	var frame_time := Engine.get_frames_per_second()
	var effect_ratio := float(_active_effect_count) / float(_max_effects)
	
	if frame_time < 30 or effect_ratio > 0.9:
		vfx_performance_warning.emit("high")
		_reduce_effect_quality()
	elif frame_time < 45 or effect_ratio > 0.7:
		vfx_performance_warning.emit("medium")
	
	# Reset effect counter (it gets incremented throughout the frame)
	_active_effect_count = 0

func _reduce_effect_quality() -> void:
	match _performance_mode:
		PerformanceMode.ULTRA:
			set_performance_mode(PerformanceMode.HIGH)
		PerformanceMode.HIGH:
			set_performance_mode(PerformanceMode.NORMAL)
		PerformanceMode.NORMAL:
			set_performance_mode(PerformanceMode.LOW)

func _track_effect_creation(count: int) -> void:
	_active_effect_count += count

func _estimate_memory_usage() -> float:
	# Rough estimate based on active effects
	return _active_effect_count * 0.1  # Estimate 0.1 MB per effect

# =============================================================================
# Specific Effect Implementations
# =============================================================================

func _create_specific_death_effects(enemy_id: String, pos: Vector3, killer_weapon: String, enemy_data: Dictionary) -> void:
	var intensity := 1.0
	if enemy_data.has("hp"):
		intensity = clampf(float(enemy_data["hp"]) / 100.0, 0.3, 3.0)
	
	match enemy_id:
		"blight_mite":
			# Explosive suicide death
			ImpactEffectsEnhanced.create_environmental_destruction(pos, "ground_crater", intensity * 2.0, 2.0)
			VfxPool.play_explosion(pos, intensity * 1.5, Color.GREEN)
			AmbientVfx.create_corruption_tendrils(pos, 12.0, intensity)
		
		"terror_bringer", "behemoth", "abyssal_lord", "omega_destroyer":
			# Boss death - massive effects
			_create_boss_death_effects(pos, enemy_id, intensity * 2.0)
		
		"scrit", "gloom_wing", "nightmare_drone":
			# Flying enemy crash
			_create_flying_crash_effects(pos, intensity)
		
		"slinker", "bile_spitter":
			# Ranged enemy with energy/chemical effects
			if enemy_id == "slinker":
				ImpactEffectsEnhanced.create_enhanced_impact(
					pos, Vector3.UP, intensity * 50.0,
					ImpactEffectsEnhanced.ImpactCategory.ENERGY,
					ImpactEffectsEnhanced.MaterialType.ORGANIC
				)
			else:  # bile_spitter
				ImpactEffectsEnhanced.create_enhanced_impact(
					pos, Vector3.UP, intensity * 50.0,
					ImpactEffectsEnhanced.ImpactCategory.ACID,
					ImpactEffectsEnhanced.MaterialType.ORGANIC
				)
				ImpactEffectsEnhanced.create_persistent_area_effect(pos, "acid_pool", 15.0, 1.5, intensity)
		
		"crystal_golem":
			# Crystal shatter death
			_create_crystal_death_effects(pos, intensity)
		
		"void_spawner", "void_wraith":
			# Void/corruption death
			ImpactEffectsEnhanced.create_enhanced_impact(
				pos, Vector3.UP, intensity * 50.0,
				ImpactEffectsEnhanced.ImpactCategory.VOID,
				ImpactEffectsEnhanced.MaterialType.VOID_MATTER
			)
			AmbientVfx.create_corruption_tendrils(pos, 20.0, intensity)
		
		"soul_reaver":
			# Soul essence release
			_create_soul_release_effects(pos, intensity)
		
		_:
			# Generic organic death
			ImpactEffectsEnhanced.create_enhanced_impact(
				pos, Vector3.UP, intensity * 30.0,
				ImpactEffectsEnhanced.ImpactCategory.KINETIC,
				ImpactEffectsEnhanced.MaterialType.ORGANIC
			)
	
	# Weapon-specific overkill effects
	if killer_weapon != "":
		_create_overkill_effects(pos, killer_weapon, intensity)

func _create_boss_death_effects(pos: Vector3, boss_id: String, intensity: float) -> void:
	# Massive explosion
	VfxPool.play_explosion(pos, intensity * 2.0, Color(1.0, 0.3, 0.1))
	
	# Shockwave
	ImpactEffectsEnhanced.create_environmental_destruction(pos, "ground_crater", intensity, intensity * 3.0)
	
	# Lingering effects
	AmbientVfx.create_battlefield_smoke(pos, 60.0, intensity)
	AmbientVfx.create_fire_embers(pos, 30.0, intensity)
	
	# Boss-specific finale
	match boss_id:
		"terror_bringer":
			# Death blast special
			var chain_positions: Array[Vector3] = []
			for i in range(6):
				var angle := i * TAU / 6.0
				chain_positions.append(pos + Vector3(cos(angle), 0, sin(angle)) * 3.0)
			ImpactEffectsEnhanced.create_chain_reaction(pos, chain_positions, "explosion_chain", 0.2)
		
		"abyssal_lord":
			# Void portal collapse
			AmbientVfx.create_corruption_tendrils(pos, 45.0, intensity)
			for i in range(4):
				var spawn_pos := pos + Vector3(randf_range(-4, 4), randf_range(1, 3), randf_range(-4, 4))
				ImpactEffectsEnhanced.create_enhanced_impact(
					spawn_pos, Vector3.UP, 100.0,
					ImpactEffectsEnhanced.ImpactCategory.VOID,
					ImpactEffectsEnhanced.MaterialType.VOID_MATTER
				)
		
		"omega_destroyer":
			# Ultimate destruction - meteor shower effect
			for i in range(8):
				var impact_pos := pos + Vector3(
					randf_range(-6, 6),
					randf_range(8, 12),
					randf_range(-6, 6)
				)
				var timer := Timer.new()
				timer.wait_time = i * 0.3
				timer.one_shot = true
				timer.timeout.connect(_create_meteor_impact.bind(impact_pos))
				timer.timeout.connect(timer.queue_free)
				add_child(timer)
				timer.start()

func _create_flying_crash_effects(pos: Vector3, intensity: float) -> void:
	# Crash impact
	VfxPool.play_explosion(pos, intensity, Color(0.8, 0.6, 0.2))
	AmbientVfx.create_dust_particles(pos, 12.0, intensity)
	
	# Skid marks/crash trail
	for i in range(3):
		var trail_pos := pos + Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))
		VfxPool.play_impact_spark(trail_pos, Vector3.UP, Color(0.4, 0.3, 0.2), intensity * 0.7)

func _create_crystal_death_effects(pos: Vector3, intensity: float) -> void:
	# Crystal shatter with prismatic effects
	for i in range(8):
		var shard_pos := pos + Vector3(
			randf_range(-1.5, 1.5),
			randf_range(0, 2),
			randf_range(-1.5, 1.5)
		)
		var crystal_color := Color(0.3, 0.8, 1.0).lerp(Color(0.8, 0.3, 1.0), randf())
		VfxPool.play_impact_spark(shard_pos, Vector3.UP, crystal_color, intensity * 0.8)
	
	# Prismatic light burst
	VfxPool.play_beam_hit(pos, Color.WHITE, intensity * 2.0)

func _create_soul_release_effects(pos: Vector3, intensity: float) -> void:
	# Soul orbs rising
	for i in range(int(intensity * 3)):
		var soul_pos := pos + Vector3(randf_range(-0.5, 0.5), 0, randf_range(-0.5, 0.5))
		var timer := Timer.new()
		timer.wait_time = i * 0.1
		timer.one_shot = true
		timer.timeout.connect(_create_rising_soul.bind(soul_pos))
		timer.timeout.connect(timer.queue_free)
		add_child(timer)
		timer.start()

func _create_rising_soul(pos: Vector3) -> void:
	VfxPool.play_energy_charge(pos, pos + Vector3(0, 3, 0), Color(0.9, 0.9, 1.0), 2.0)

func _create_overkill_effects(pos: Vector3, weapon: String, intensity: float) -> void:
	if intensity < 2.0:  # Only for high damage
		return
	
	match weapon:
		"rail_gun":
			# Excessive penetration
			VfxPool.play_beam_hit(pos, Color(0.6, 0.9, 1.0), intensity)
			AmbientVfx.create_energy_disturbance(pos, 8.0, intensity)
		"missile_battery":
			# Excessive explosive damage
			VfxPool.play_explosion(pos, intensity, Color.ORANGE)
		"tesla_coil":
			# Electrical overkill
			AmbientVfx.create_electric_arcs(pos, 5.0, intensity)

func _create_meteor_impact(pos: Vector3) -> void:
	VfxPool.play_explosion(pos, 2.0, Color(1.0, 0.6, 0.2))
	ImpactEffectsEnhanced.create_environmental_destruction(pos, "ground_crater", 1.5, 2.5)
	_track_effect_creation(2)

# =============================================================================
# Cleanup and Resource Management
# =============================================================================

func _exit_tree() -> void:
	print("VFX Pool System shutting down...")
	for subsystem in _subsystems.values():
		if is_instance_valid(subsystem):
			subsystem.queue_free()
	_subsystems.clear()