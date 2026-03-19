class_name DroneDisruptor
extends UnitBase
## DroneDisruptor - Offensive drone that attacks enemies and applies a slow debuff.
## Attacks deal damage and apply 30% slow for 3 seconds on hit.

var slow_percent: float = 0.30  # 30%
var slow_duration: float = 3.0

const SLOW_DEBUFF_ID_PREFIX: String = "disruptor_slow_"


func initialize(p_entity_id: String, p_entity_type: String, p_data: Dictionary = {}) -> void:
	super.initialize(p_entity_id, p_entity_type, p_data)

	# Parse slow_shot special from data
	var specials: Array = data.get("specials", [])
	for special: Dictionary in specials:
		if special.get("id", "") == "slow_shot":
			slow_percent = float(special.get("slow_percent", 30)) / 100.0
			slow_duration = float(special.get("duration", 3))

	# Connect to combat attack event to apply slow on hit
	if combat_component:
		combat_component.attack_fired.connect(_on_attack_fired)

	add_to_group("drones")


func _on_attack_fired(target: Node) -> void:
	if not _is_valid_node(target):
		return

	# Apply slow debuff to the target
	if target is EntityBase and target.buff_debuff_component:
		var debuff_id: String = SLOW_DEBUFF_ID_PREFIX + str(get_instance_id())
		target.buff_debuff_component.apply_debuff(
			debuff_id, "slow", slow_percent, slow_duration, self
		)
