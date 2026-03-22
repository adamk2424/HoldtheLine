extends Node
## VfxManager - Autoload that connects game events to visual effects
## Automatically triggers appropriate VFX based on GameBus signals
## NOTE: VfxPool and AmbientVfx classes are not yet implemented.
## This is a no-op stub that compiles cleanly while preserving the public API.

func _ready() -> void:
	# Connect to GameBus signals for automatic VFX triggering
	GameBus.entity_died.connect(_on_entity_died)
	GameBus.damage_dealt.connect(_on_damage_dealt)
	GameBus.projectile_fired.connect(_on_projectile_fired)
	GameBus.aoe_triggered.connect(_on_aoe_triggered)
	GameBus.weapon_fired.connect(_on_weapon_fired)

# =============================================================================
# Event Handlers
# =============================================================================

func _on_entity_died(_entity: Node, _entity_type: String, _entity_id: String, _killer: Node) -> void:
	pass

func _on_damage_dealt(_target: Node, _amount: float, _source: Node) -> void:
	pass

func _on_projectile_fired(_source: Node, _target: Node, _projectile_type: String) -> void:
	pass

func _on_aoe_triggered(_position: Vector3, _radius: float, _damage: float, _source: Node) -> void:
	pass

func _on_weapon_fired(_position: Vector3, _weapon_type: String, _target_position: Vector3) -> void:
	pass

# =============================================================================
# Helper Functions
# =============================================================================

func _determine_damage_type(source: Node) -> String:
	if not is_instance_valid(source):
		return "generic"

	if source.has_method("get_data_value"):
		var entity_id_value: Variant = source.get("entity_id")
		var entity_id: String = entity_id_value if entity_id_value is String else ""
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

	var entity_type_value: Variant = target.get("entity_type")
	var entity_type: String = entity_type_value if entity_type_value is String else ""
	var entity_id_value: Variant = target.get("entity_id")
	var entity_id: String = entity_id_value if entity_id_value is String else ""

	match entity_type:
		"tower", "building":
			return "metal"
		"barrier":
			return "concrete"
		"enemy":
			match entity_id:
				"scrit", "slinker":
					return "energy"
				_:
					return "organic"
		"central_tower":
			return "metal"
		_:
			return "generic"
