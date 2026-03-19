class_name AmbientVfx
extends Node
## AmbientVfx - Manages ambient and environmental visual effects
## Handles background atmosphere, weather-like effects, and area ambiance

# --- Static Instance Management ---
static var _instance: AmbientVfx = null

# --- Ambient Effect Types ---
enum AmbientType {
	BATTLEFIELD_SMOKE,
	SPARKS_SHOWER,
	ENERGY_DISTURBANCE,
	HEAT_SHIMMER,
	DUST_PARTICLES,
	FIRE_EMBERS,
	ELECTRIC_ARCS,
	CORRUPTION_TENDRILS
}

# --- Active Ambient Effects ---
var _active_ambients: Array[Dictionary] = []
var _ambient_timer: Timer = null

func _ready() -> void:
	if not AmbientVfx._instance:
		AmbientVfx._instance = self
	
	# Setup ambient effect timer
	_ambient_timer = Timer.new()
	_ambient_timer.wait_time = 0.5  # Check every half second
	_ambient_timer.timeout.connect(_update_ambient_effects)
	_ambient_timer.autostart = true
	add_child(_ambient_timer)

## Get the main ambient VFX instance
static func get_instance() -> AmbientVfx:
	if not AmbientVfx._instance:
		var instance := AmbientVfx.new()
		instance.name = "AmbientVfx"
		Engine.get_main_loop().current_scene.add_child(instance)
		AmbientVfx._instance = instance
	return AmbientVfx._instance

# =============================================================================
# Public API
# =============================================================================

## Create ambient battlefield smoke at position
static func create_battlefield_smoke(pos: Vector3, duration: float = 30.0, intensity: float = 1.0) -> void:
	var instance := get_instance()
	instance._create_ambient_effect(AmbientType.BATTLEFIELD_SMOKE, pos, duration, intensity)

## Create sparks shower effect (welding, electrical damage)
static func create_sparks_shower(pos: Vector3, duration: float = 5.0, intensity: float = 1.0) -> void:
	var instance := get_instance()
	instance._create_ambient_effect(AmbientType.SPARKS_SHOWER, pos, duration, intensity)

## Create energy disturbance field
static func create_energy_disturbance(pos: Vector3, duration: float = 10.0, intensity: float = 1.0) -> void:
	var instance := get_instance()
	instance._create_ambient_effect(AmbientType.ENERGY_DISTURBANCE, pos, duration, intensity)

## Create heat shimmer effect
static func create_heat_shimmer(pos: Vector3, duration: float = 15.0, intensity: float = 1.0) -> void:
	var instance := get_instance()
	instance._create_ambient_effect(AmbientType.HEAT_SHIMMER, pos, duration, intensity)

## Create floating dust particles
static func create_dust_particles(pos: Vector3, duration: float = 20.0, intensity: float = 1.0) -> void:
	var instance := get_instance()
	instance._create_ambient_effect(AmbientType.DUST_PARTICLES, pos, duration, intensity)

## Create floating fire embers
static func create_fire_embers(pos: Vector3, duration: float = 12.0, intensity: float = 1.0) -> void:
	var instance := get_instance()
	instance._create_ambient_effect(AmbientType.FIRE_EMBERS, pos, duration, intensity)

## Create electric arc discharge
static func create_electric_arcs(pos: Vector3, duration: float = 3.0, intensity: float = 1.0) -> void:
	var instance := get_instance()
	instance._create_ambient_effect(AmbientType.ELECTRIC_ARCS, pos, duration, intensity)

## Create corruption tendrils (alien influence)
static func create_corruption_tendrils(pos: Vector3, duration: float = 25.0, intensity: float = 1.0) -> void:
	var instance := get_instance()
	instance._create_ambient_effect(AmbientType.CORRUPTION_TENDRILS, pos, duration, intensity)

# =============================================================================
# Impact Effects API
# =============================================================================

## Create impact effect based on material types
static func create_material_impact(pos: Vector3, material_type: String, intensity: float = 1.0) -> void:
	match material_type:
		"metal":
			VfxPool.play_impact_spark(pos, Vector3.UP, Color(1.0, 0.7, 0.3), intensity)
			create_sparks_shower(pos, 2.0, intensity * 0.5)
		"concrete":
			VfxPool.play_impact_spark(pos, Vector3.UP, Color(0.8, 0.8, 0.7), intensity)
			create_dust_particles(pos, 5.0, intensity * 0.3)
		"energy":
			VfxPool.play_impact_spark(pos, Vector3.UP, Color(0.3, 0.8, 1.0), intensity)
			create_energy_disturbance(pos, 3.0, intensity)
		"organic":
			VfxPool.play_impact_spark(pos, Vector3.UP, Color(0.8, 0.3, 0.2), intensity)
			if randf() < 0.3:  # 30% chance for blood-like effect
				create_corruption_tendrils(pos, 8.0, intensity * 0.2)
		"fire":
			VfxPool.play_fire_burst(pos, intensity, intensity)
			create_fire_embers(pos, 8.0, intensity * 0.7)
		"electric":
			VfxPool.play_beam_hit(pos, Color(0.7, 0.9, 1.0), intensity)
			create_electric_arcs(pos, 2.0, intensity)
		_:
			VfxPool.play_impact_spark(pos, Vector3.UP, Color.WHITE, intensity)

## Create area damage effect (explosions, AOE attacks)
static func create_area_damage_effect(pos: Vector3, radius: float, damage_type: String = "explosive") -> void:
	match damage_type:
		"explosive":
			VfxPool.play_explosion(pos, radius * 0.5, Color.ORANGE)
			create_battlefield_smoke(pos, 15.0, radius * 0.3)
			create_fire_embers(pos, 10.0, radius * 0.2)
		"energy":
			VfxPool.play_explosion(pos, radius * 0.4, Color.CYAN)
			create_energy_disturbance(pos, 8.0, radius * 0.4)
		"fire":
			VfxPool.play_fire_burst(pos, radius * 0.6, 1.5)
			create_heat_shimmer(pos, 20.0, radius * 0.3)
			create_fire_embers(pos, 15.0, radius * 0.5)
		"electric":
			VfxPool.play_beam_hit(pos, Color(0.8, 0.9, 1.0), radius)
			create_electric_arcs(pos, 5.0, radius * 0.6)
		"corruption":
			VfxPool.play_explosion(pos, radius * 0.3, Color(0.6, 0.2, 0.8))
			create_corruption_tendrils(pos, 30.0, radius * 0.4)
		_:
			VfxPool.play_explosion(pos, radius * 0.5, Color.YELLOW)

# =============================================================================
# Weapon-Specific Effects
# =============================================================================

## Create weapon firing effects
static func create_weapon_fire_effect(pos: Vector3, weapon_type: String, target_pos: Vector3 = Vector3.ZERO) -> void:
	match weapon_type:
		"autocannon":
			VfxPool.play_muzzle_flash(pos, Color(1.0, 0.8, 0.2), 1.0, 0.1)
			create_sparks_shower(pos, 1.0, 0.3)
		"missile":
			VfxPool.play_muzzle_flash(pos, Color(1.0, 0.4, 0.1), 1.5, 0.2)
			create_battlefield_smoke(pos, 5.0, 0.5)
		"railgun":
			VfxPool.play_energy_charge(pos, target_pos, Color(0.3, 0.6, 1.0), 1.0)
			create_energy_disturbance(pos, 3.0, 0.8)
		"plasma":
			VfxPool.play_muzzle_flash(pos, Color(0.8, 0.2, 0.9), 2.0, 0.3)
			create_heat_shimmer(pos, 8.0, 1.0)
		"tesla":
			VfxPool.play_beam_hit(pos, Color(0.4, 0.8, 1.0), 2.0)
			create_electric_arcs(pos, 2.0, 1.5)
		"flame":
			VfxPool.play_fire_burst(pos, 1.5, 2.0)
			create_fire_embers(pos, 6.0, 1.0)
			create_heat_shimmer(pos, 10.0, 0.8)
		_:
			VfxPool.play_muzzle_flash(pos)

# =============================================================================
# Internal Ambient Effect Management
# =============================================================================

func _create_ambient_effect(ambient_type: AmbientType, pos: Vector3, duration: float, intensity: float) -> void:
	var effect_data := {
		"type": ambient_type,
		"position": pos,
		"duration": duration,
		"intensity": intensity,
		"start_time": Time.get_ticks_msec() / 1000.0,
		"last_spawn": 0.0,
		"spawn_interval": _get_spawn_interval(ambient_type),
		"effect_nodes": []
	}
	
	_active_ambients.append(effect_data)

func _get_spawn_interval(ambient_type: AmbientType) -> float:
	match ambient_type:
		AmbientType.BATTLEFIELD_SMOKE:
			return 2.0  # Smoke puffs every 2 seconds
		AmbientType.SPARKS_SHOWER:
			return 0.2  # Rapid sparks
		AmbientType.ENERGY_DISTURBANCE:
			return 0.8  # Pulsing energy
		AmbientType.HEAT_SHIMMER:
			return 1.5  # Slow heat waves
		AmbientType.DUST_PARTICLES:
			return 3.0  # Occasional dust
		AmbientType.FIRE_EMBERS:
			return 0.5  # Regular embers
		AmbientType.ELECTRIC_ARCS:
			return 0.3  # Quick arcs
		AmbientType.CORRUPTION_TENDRILS:
			return 2.5  # Slow corruption spread
		_:
			return 1.0

func _update_ambient_effects() -> void:
	var current_time := Time.get_ticks_msec() / 1000.0
	
	for i in range(_active_ambients.size() - 1, -1, -1):
		var effect := _active_ambients[i]
		var elapsed := current_time - effect["start_time"]
		
		# Check if effect has expired
		if elapsed >= effect["duration"]:
			_cleanup_ambient_effect(effect)
			_active_ambients.remove_at(i)
			continue
		
		# Check if it's time to spawn new particles
		var time_since_spawn := current_time - effect["last_spawn"]
		if time_since_spawn >= effect["spawn_interval"]:
			_spawn_ambient_particle(effect, current_time)
			effect["last_spawn"] = current_time

func _spawn_ambient_particle(effect: Dictionary, current_time: float) -> void:
	var ambient_type: AmbientType = effect["type"]
	var pos: Vector3 = effect["position"]
	var intensity: float = effect["intensity"]
	
	match ambient_type:
		AmbientType.BATTLEFIELD_SMOKE:
			var offset := Vector3(randf_range(-2, 2), randf_range(0, 1), randf_range(-2, 2))
			VfxPool.play_smoke_puff(pos + offset, Vector3(randf_range(-0.1, 0.1), 0.3, randf_range(-0.1, 0.1)), intensity)
		
		AmbientType.SPARKS_SHOWER:
			var offset := Vector3(randf_range(-0.5, 0.5), randf_range(-0.2, 0.2), randf_range(-0.5, 0.5))
			VfxPool.play_impact_spark(pos + offset, Vector3.UP, Color(1.0, 0.7, 0.1), intensity)
		
		AmbientType.ENERGY_DISTURBANCE:
			var offset := Vector3(randf_range(-1, 1), randf_range(-0.5, 0.5), randf_range(-1, 1))
			VfxPool.play_beam_hit(pos + offset, Color(0.3, 0.8, 1.0), intensity * 0.5)
		
		AmbientType.HEAT_SHIMMER:
			var offset := Vector3(randf_range(-1.5, 1.5), randf_range(0, 0.8), randf_range(-1.5, 1.5))
			VfxPool.play_energy_charge(pos + offset, pos + offset + Vector3.UP, Color(1.0, 0.6, 0.2), 2.0)
		
		AmbientType.DUST_PARTICLES:
			var offset := Vector3(randf_range(-3, 3), randf_range(0, 2), randf_range(-3, 3))
			VfxPool.play_smoke_puff(pos + offset, Vector3(randf_range(-0.2, 0.2), 0.1, randf_range(-0.2, 0.2)), intensity * 0.3)
		
		AmbientType.FIRE_EMBERS:
			var offset := Vector3(randf_range(-1, 1), randf_range(0, 1.5), randf_range(-1, 1))
			VfxPool.play_fire_burst(pos + offset, 0.1 * intensity, intensity)
		
		AmbientType.ELECTRIC_ARCS:
			var offset := Vector3(randf_range(-0.8, 0.8), randf_range(-0.3, 0.3), randf_range(-0.8, 0.8))
			VfxPool.play_beam_hit(pos + offset, Color(0.6, 0.9, 1.0), intensity)
		
		AmbientType.CORRUPTION_TENDRILS:
			var offset := Vector3(randf_range(-2, 2), randf_range(-0.5, 0.1), randf_range(-2, 2))
			VfxPool.play_energy_charge(pos + offset, pos + offset + Vector3(randf_range(-1, 1), 0.5, randf_range(-1, 1)), Color(0.6, 0.2, 0.8), 3.0)

func _cleanup_ambient_effect(effect: Dictionary) -> void:
	# Clean up any persistent effect nodes if we had them
	for node in effect.get("effect_nodes", []):
		if is_instance_valid(node):
			node.queue_free()

# =============================================================================
# Environmental Response System
# =============================================================================

## React to entity death with appropriate effects
static func handle_entity_death(entity: Node, entity_type: String) -> void:
	if not is_instance_valid(entity):
		return
	
	var pos := entity.global_position
	
	match entity_type:
		"enemy":
			_handle_enemy_death(entity, pos)
		"tower":
			_handle_tower_death(entity, pos)
		"building":
			_handle_building_death(entity, pos)
		_:
			create_material_impact(pos, "generic", 0.5)

static func _handle_enemy_death(entity: Node, pos: Vector3) -> void:
	if not entity.has_method("get_data_value"):
		return
	
	var enemy_id: String = entity.get("entity_id", "")
	match enemy_id:
		"blight_mite":
			# Explosive suicide
			create_area_damage_effect(pos, 2.0, "explosive")
		"terror_bringer", "behemoth":
			# Boss death explosion
			create_area_damage_effect(pos, 3.0, "explosive")
			create_battlefield_smoke(pos, 30.0, 2.0)
		"scrit", "gloom_wing":
			# Flying enemy crash
			create_material_impact(pos, "organic", 1.0)
			create_dust_particles(pos, 10.0, 0.8)
		"slinker":
			# Energy-based enemy
			create_area_damage_effect(pos, 1.5, "energy")
		_:
			# Generic enemy death
			create_material_impact(pos, "organic", 0.7)
			if randf() < 0.3:  # 30% chance for smoke
				create_battlefield_smoke(pos, 8.0, 0.4)

static func _handle_tower_death(entity: Node, pos: Vector3) -> void:
	# Towers explode with sparks and smoke
	create_area_damage_effect(pos, 2.0, "explosive")
	create_sparks_shower(pos, 8.0, 1.5)
	create_battlefield_smoke(pos, 20.0, 1.0)

static func _handle_building_death(entity: Node, pos: Vector3) -> void:
	# Buildings create large smoke and debris
	create_area_damage_effect(pos, 3.0, "explosive")
	create_battlefield_smoke(pos, 40.0, 2.0)
	create_dust_particles(pos, 30.0, 1.5)

# =============================================================================
# Cleanup
# =============================================================================

func _exit_tree() -> void:
	for effect in _active_ambients:
		_cleanup_ambient_effect(effect)
	_active_ambients.clear()
	
	if AmbientVfx._instance == self:
		AmbientVfx._instance = null