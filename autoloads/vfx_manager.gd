extends Node
## VfxManager - Autoload that connects game events to visual effects
## Automatically triggers appropriate VFX based on GameBus signals

func _ready() -> void:
	# Connect to GameBus signals for automatic VFX triggering
	GameBus.entity_died.connect(_on_entity_died)
	GameBus.damage_dealt.connect(_on_damage_dealt)
	GameBus.projectile_fired.connect(_on_projectile_fired)
	GameBus.aoe_triggered.connect(_on_aoe_triggered)
	GameBus.weapon_fired.connect(_on_weapon_fired)
	
	# Initialize VFX systems
	_ensure_vfx_systems()

func _ensure_vfx_systems() -> void:
	# Ensure VFX pool is available
	VfxPool.get_main_pool()
	# Ensure ambient VFX is available
	AmbientVfx.get_instance()

# =============================================================================
# Event Handlers
# =============================================================================

func _on_entity_died(entity: Node, entity_type: String, entity_id: String, killer: Node) -> void:
	if not is_instance_valid(entity):
		return
	
	# Trigger death VFX
	AmbientVfx.handle_entity_death(entity, entity_type)

func _on_damage_dealt(target: Node, amount: float, source: Node) -> void:
	if not is_instance_valid(target):
		return
	
	var pos := target.global_position
	
	# Determine damage type from source
	var damage_type := _determine_damage_type(source)
	
	# Create impact effect based on target type and damage
	if target.has_method("get_data_value"):
		var target_type := _determine_target_material(target)
		AmbientVfx.create_material_impact(pos, target_type, amount / 50.0)  # Scale intensity
	else:
		VfxPool.play_impact_spark(pos, Vector3.UP, Color.WHITE, amount / 100.0)

func _on_projectile_fired(source: Node, target: Node, projectile_type: String) -> void:
	if not is_instance_valid(source):
		return
	
	var source_pos := source.global_position
	var target_pos := target.global_position if is_instance_valid(target) else Vector3.ZERO
	
	# Create weapon-specific firing effect
	match projectile_type:
		"bullet", "shell":
			AmbientVfx.create_weapon_fire_effect(source_pos, "autocannon", target_pos)
		"missile", "rocket":
			AmbientVfx.create_weapon_fire_effect(source_pos, "missile", target_pos)
		"energy", "plasma":
			AmbientVfx.create_weapon_fire_effect(source_pos, "plasma", target_pos)
		"rail", "beam":
			AmbientVfx.create_weapon_fire_effect(source_pos, "railgun", target_pos)
		_:
			VfxPool.play_muzzle_flash(source_pos)

func _on_aoe_triggered(position: Vector3, radius: float, damage: float, source: Node) -> void:
	# Create area damage effect
	var damage_type := _determine_damage_type(source)
	AmbientVfx.create_area_damage_effect(position, radius, damage_type)

func _on_weapon_fired(position: Vector3, weapon_type: String, target_position: Vector3) -> void:
	AmbientVfx.create_weapon_fire_effect(position, weapon_type, target_position)

# =============================================================================
# Helper Functions
# =============================================================================

func _determine_damage_type(source: Node) -> String:
	if not is_instance_valid(source):
		return "generic"
	
	# Check entity ID for weapon type
	if source.has_method("get_data_value"):
		var entity_id: String = source.get("entity_id", "")
		match entity_id:
			"autocannon":
				return "explosive"
			"missile_battery":
				return "explosive"
			"rail_gun":
				return "energy"
			"plasma_mortar":
				return "fire"
			"tesla_coil":
				return "electric"
			"inferno_tower":
				return "fire"
			_:
				return "generic"
	
	return "generic"

func _determine_target_material(target: Node) -> String:
	if not target.has_method("get_data_value"):
		return "generic"
	
	var entity_type: String = target.get("entity_type", "")
	var entity_id: String = target.get("entity_id", "")
	
	match entity_type:
		"tower", "building":
			return "metal"
		"barrier":
			return "concrete"
		"enemy":
			# Check enemy type
			match entity_id:
				"scrit", "slinker":
					return "energy"
				_:
					return "organic"
		"central_tower":
			return "metal"
		_:
			return "generic"