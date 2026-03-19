extends Node
## VFX System Autoload - Global access to enhanced VFX capabilities
## Initializes and manages all VFX subsystems for the game

var pool_system: VfxPoolSystem

func _ready() -> void:
	name = "VfxSystem"
	
	# Create and initialize the VFX pool system
	pool_system = VfxPoolSystem.new()
	add_child(pool_system)
	
	# Connect to system signals
	pool_system.vfx_system_ready.connect(_on_vfx_system_ready)
	pool_system.vfx_performance_warning.connect(_on_performance_warning)
	
	print("VFX System Autoload initialized")

func _on_vfx_system_ready() -> void:
	print("VFX System fully operational")
	
	# Set initial performance mode based on settings
	var performance_mode := VfxPoolSystem.PerformanceMode.NORMAL
	if OS.has_feature("mobile"):
		performance_mode = VfxPoolSystem.PerformanceMode.LOW
	elif DisplayServer.get_name() == "headless":
		performance_mode = VfxPoolSystem.PerformanceMode.LOW
	
	pool_system.set_performance_mode(performance_mode)

func _on_performance_warning(level: String) -> void:
	print("VFX Performance Warning: ", level)
	# Could trigger UI warnings or automatic quality reduction

# =============================================================================
# Global VFX API - Accessible via VfxSystem singleton
# =============================================================================

## Create complete weapon firing sequence with all effects
func create_weapon_fire_complete(
	weapon_pos: Vector3,
	target_pos: Vector3,
	weapon_type: String,
	damage: float,
	target: Node = null,
	travel_time: float = 1.0
) -> void:
	if pool_system:
		pool_system.create_weapon_fire_complete(weapon_pos, target_pos, weapon_type, damage, target, travel_time)

## Create battlefield atmosphere effects
func create_battlefield_atmosphere(center_pos: Vector3, radius: float, intensity: float = 1.0) -> void:
	if pool_system:
		pool_system.create_battlefield_atmosphere(center_pos, radius, intensity)

## Create enemy death effects
func create_enemy_death_effects(enemy: Node, death_pos: Vector3, killer_weapon: String = "") -> void:
	if pool_system:
		pool_system.create_enemy_death_effects(enemy, death_pos, killer_weapon)

## Create environmental destruction
func create_destruction_sequence(pos: Vector3, destruction_type: String, intensity: float = 1.0) -> void:
	if pool_system:
		pool_system.create_destruction_sequence(pos, destruction_type, intensity)

## Set VFX quality level
func set_vfx_quality(mode: VfxPoolSystem.PerformanceMode) -> void:
	if pool_system:
		pool_system.set_performance_mode(mode)

## Get current VFX system statistics
func get_vfx_stats() -> Dictionary:
	if pool_system:
		return pool_system.get_vfx_statistics()
	return {}

## Quick access to enhanced impact effects
func create_impact_effect(
	pos: Vector3,
	normal: Vector3,
	damage: float,
	impact_type: ImpactEffectsEnhanced.ImpactCategory,
	material: ImpactEffectsEnhanced.MaterialType,
	weapon_id: String = ""
) -> void:
	ImpactEffectsEnhanced.create_enhanced_impact(pos, normal, damage, impact_type, material, weapon_id)

## Quick access to weapon-specific projectile VFX
func create_projectile_vfx(
	start_pos: Vector3,
	end_pos: Vector3,
	weapon_type: String,
	travel_time: float = 1.0
) -> void:
	ProjectileVfxEnhanced.create_projectile_vfx(start_pos, end_pos, weapon_type, travel_time)

## Cleanup and emergency stop for performance
func emergency_vfx_cleanup() -> void:
	print("Emergency VFX cleanup initiated")
	if pool_system:
		pool_system.set_performance_mode(VfxPoolSystem.PerformanceMode.LOW)

func _exit_tree() -> void:
	if pool_system:
		pool_system.queue_free()