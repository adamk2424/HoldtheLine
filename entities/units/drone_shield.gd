class_name DroneShield
extends UnitBase
## DroneShield - Support drone that provides a +3 armor buff aura to nearby allies.
## No attack capability. Applies armor buff to all friendly units within radius 6.

var aura_armor_bonus: float = 3.0
var aura_radius: float = 6.0
var _aura_tick_timer: float = 0.0
var _buffed_entities: Array = []  # Track entities we've buffed

const AURA_TICK_INTERVAL: float = 0.5  # Check aura every 0.5s
const BUFF_ID_PREFIX: String = "shield_aura_"


func initialize(p_entity_id: String, p_entity_type: String, p_data: Dictionary = {}) -> void:
	super.initialize(p_entity_id, p_entity_type, p_data)

	# Disable combat (no attack)
	if combat_component:
		combat_component.is_active = false

	# Parse aura special from data
	var specials: Array = data.get("specials", [])
	for special: Dictionary in specials:
		if special.get("id", "") == "shield_aura":
			aura_armor_bonus = float(special.get("armor_bonus", 3))
			aura_radius = float(special.get("radius", 6))

	add_to_group("drones")


func _process(delta: float) -> void:
	super._process(delta)
	_process_aura(delta)


func _process_aura(delta: float) -> void:
	_aura_tick_timer += delta
	if _aura_tick_timer < AURA_TICK_INTERVAL:
		return
	_aura_tick_timer -= AURA_TICK_INTERVAL

	var current_in_range: Array = []

	# Find all friendly entities in aura range
	var units: Array = EntityRegistry.get_in_range(global_position, "unit", aura_radius)
	for unit: Node in units:
		if unit == self:
			continue
		if _is_valid_buff_target(unit):
			current_in_range.append(unit)

	var buildings: Array = EntityRegistry.get_in_range(global_position, "building", aura_radius)
	for bldg: Node in buildings:
		if _is_valid_buff_target(bldg):
			current_in_range.append(bldg)

	var towers: Array = EntityRegistry.get_in_range(global_position, "central_tower", aura_radius)
	for tower: Node in towers:
		if _is_valid_buff_target(tower):
			current_in_range.append(tower)

	# Remove buff from entities that left range
	var still_buffed: Array = []
	for entity: Node in _buffed_entities:
		if not is_instance_valid(entity) or not entity.is_inside_tree():
			continue
		if entity in current_in_range:
			still_buffed.append(entity)
		else:
			_remove_aura_buff(entity)
	_buffed_entities = still_buffed

	# Apply buff to new entities in range
	for entity: Node in current_in_range:
		if entity not in _buffed_entities:
			_apply_aura_buff(entity)
			_buffed_entities.append(entity)


func _is_valid_buff_target(entity: Node) -> bool:
	if not is_instance_valid(entity) or not entity.is_inside_tree():
		return false
	if entity is EntityBase:
		if entity.buff_debuff_component and entity.health_component:
			return not entity.health_component.is_dead
	return false


func _apply_aura_buff(entity: Node) -> void:
	if entity is EntityBase and entity.buff_debuff_component:
		var buff_id: String = BUFF_ID_PREFIX + str(get_instance_id())
		entity.buff_debuff_component.apply_buff(
			buff_id, "armor", aura_armor_bonus, -1.0, self
		)


func _remove_aura_buff(entity: Node) -> void:
	if entity is EntityBase and entity.buff_debuff_component:
		var buff_id: String = BUFF_ID_PREFIX + str(get_instance_id())
		entity.buff_debuff_component.remove_buff(buff_id)


func _on_died(killer: Node) -> void:
	# Remove all aura buffs before dying
	for entity: Node in _buffed_entities:
		if is_instance_valid(entity) and entity.is_inside_tree():
			_remove_aura_buff(entity)
	_buffed_entities.clear()
	super._on_died(killer)
