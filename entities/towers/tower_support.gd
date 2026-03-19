class_name TowerSupport
extends TowerBase
## TowerSupport - Handles the 4 support tower types:
## repair_tower, war_beacon, targeting_array, shield_pylon.
## Uses effect_type/effect_value/effect_radius from data for aura configuration.

# Support aura state
var aura_range: float = 6.0
var aura_tick_interval: float = 1.0
var _aura_timer: float = 0.0

# Effect configuration from data
var effect_type: String = ""
var effect_value: float = 0.0
var effect_radius: float = 6.0

# Repair Tower
var is_repair_tower: bool = false
var heal_per_second: float = 8.0

# War Beacon
var is_war_beacon: bool = false
var damage_buff_percent: float = 15.0
var _beacon_buffed_entities: Array = []

# Targeting Array
var is_targeting_array: bool = false
var range_buff_percent: float = 20.0
var _array_buffed_entities: Array = []

# Shield Pylon
var is_shield_pylon: bool = false
var armor_buff_value: float = 3.0
var _shielded_entities: Array = []


func initialize(p_entity_id: String, p_entity_type: String, p_data: Dictionary = {}) -> void:
	if p_data.is_empty():
		p_data = GameData.get_tower_support(p_entity_id)
	super.initialize(p_entity_id, p_entity_type, p_data)

	# Parse support type from effect_type
	_parse_support_type()

	# Connect build completion
	build_completed_signal.connect(_on_build_completed)


func _parse_support_type() -> void:
	is_repair_tower = false
	is_war_beacon = false
	is_targeting_array = false
	is_shield_pylon = false

	effect_type = data.get("effect_type", "")
	effect_value = float(data.get("effect_value", 0))
	effect_radius = float(data.get("effect_radius", 6))
	aura_range = effect_radius

	match effect_type:
		"heal":
			is_repair_tower = true
			heal_per_second = effect_value
		"damage_buff":
			is_war_beacon = true
			damage_buff_percent = effect_value
		"range_buff":
			is_targeting_array = true
			range_buff_percent = effect_value
		"armor_buff":
			is_shield_pylon = true
			armor_buff_value = effect_value


func _on_build_completed() -> void:
	pass


func _process(delta: float) -> void:
	super._process(delta)

	if not is_built or is_building:
		return

	_aura_timer += delta
	if _aura_timer >= aura_tick_interval:
		_aura_timer -= aura_tick_interval

		if is_repair_tower:
			_tick_repair_aura()
		if is_war_beacon:
			_tick_war_beacon()
		if is_targeting_array:
			_tick_targeting_array()
		if is_shield_pylon:
			_tick_shield_pylon()


func _tick_repair_aura() -> void:
	# Heal all friendly structures and units in range
	var heal_types: Array[String] = ["tower", "building", "unit", "barrier", "central_tower"]
	for type_name: String in heal_types:
		var entities: Array = EntityRegistry.get_in_range(global_position, type_name, aura_range)
		for entity: Node in entities:
			if not is_instance_valid(entity) or entity == self:
				continue
			if entity is EntityBase and entity.health_component:
				var heal_amount: float = heal_per_second * aura_tick_interval
				entity.health_component.heal(heal_amount)


func _tick_war_beacon() -> void:
	var in_range_now: Array = []
	var buff_types: Array[String] = ["tower", "unit"]
	for type_name: String in buff_types:
		var entities: Array = EntityRegistry.get_in_range(global_position, type_name, aura_range)
		for entity: Node in entities:
			if not is_instance_valid(entity) or entity == self:
				continue
			in_range_now.append(entity)

	# Apply buff to new entities (only one war beacon can buff a tower at a time)
	for entity: Node in in_range_now:
		if entity not in _beacon_buffed_entities:
			if entity is EntityBase and entity.buff_debuff_component:
				if entity.buff_debuff_component.has_buff_with_prefix("war_beacon_"):
					continue
				var buff_id: String = "war_beacon_%d" % get_instance_id()
				var dmg_value: float = damage_buff_percent / 100.0
				entity.buff_debuff_component.apply_buff(buff_id, "damage", dmg_value, -1.0, self)
			_beacon_buffed_entities.append(entity)

	# Remove buff from entities that left range
	var to_remove: Array = []
	for entity: Node in _beacon_buffed_entities:
		if not is_instance_valid(entity) or entity not in in_range_now:
			if is_instance_valid(entity) and entity is EntityBase and entity.buff_debuff_component:
				var buff_id: String = "war_beacon_%d" % get_instance_id()
				entity.buff_debuff_component.remove_buff(buff_id)
			to_remove.append(entity)

	for entity: Node in to_remove:
		_beacon_buffed_entities.erase(entity)


func _tick_targeting_array() -> void:
	var in_range_now: Array = []
	var towers: Array = EntityRegistry.get_in_range(global_position, "tower", aura_range)
	for tower: Node in towers:
		if not is_instance_valid(tower) or tower == self:
			continue
		in_range_now.append(tower)

	# Apply range buff to new towers (only one targeting array can buff a tower at a time)
	for tower: Node in in_range_now:
		if tower not in _array_buffed_entities:
			if tower is EntityBase and tower.buff_debuff_component:
				if tower.buff_debuff_component.has_buff_with_prefix("targeting_array_"):
					continue
				var range_buff_id: String = "targeting_array_%d" % get_instance_id()
				var range_value: float = range_buff_percent / 100.0
				tower.buff_debuff_component.apply_buff(range_buff_id, "range", range_value, -1.0, self)
			_array_buffed_entities.append(tower)

	# Remove buff from towers that left range
	var to_remove: Array = []
	for tower: Node in _array_buffed_entities:
		if not is_instance_valid(tower) or tower not in in_range_now:
			if is_instance_valid(tower) and tower is EntityBase and tower.buff_debuff_component:
				var range_buff_id: String = "targeting_array_%d" % get_instance_id()
				tower.buff_debuff_component.remove_buff(range_buff_id)
			to_remove.append(tower)

	for tower: Node in to_remove:
		_array_buffed_entities.erase(tower)


func _tick_shield_pylon() -> void:
	var in_range_now: Array = []
	var shield_types: Array[String] = ["tower", "building", "barrier", "central_tower"]
	for type_name: String in shield_types:
		var entities: Array = EntityRegistry.get_in_range(global_position, type_name, aura_range)
		for entity: Node in entities:
			if not is_instance_valid(entity) or entity == self:
				continue
			in_range_now.append(entity)

	# Apply armor buff to new entities
	for entity: Node in in_range_now:
		if entity not in _shielded_entities:
			if entity is EntityBase and entity.buff_debuff_component:
				var buff_id: String = "shield_pylon_%d" % get_instance_id()
				entity.buff_debuff_component.apply_buff(buff_id, "armor", armor_buff_value, -1.0, self)
			_shielded_entities.append(entity)

	# Remove buff from entities that left range
	var to_remove: Array = []
	for entity: Node in _shielded_entities:
		if not is_instance_valid(entity) or entity not in in_range_now:
			if is_instance_valid(entity) and entity is EntityBase and entity.buff_debuff_component:
				var buff_id: String = "shield_pylon_%d" % get_instance_id()
				entity.buff_debuff_component.remove_buff(buff_id)
			to_remove.append(entity)

	for entity: Node in to_remove:
		_shielded_entities.erase(entity)


func die(killer: Node = null) -> void:
	_remove_all_buffs()
	super.die(killer)


func on_sold() -> void:
	_remove_all_buffs()


func _remove_all_buffs() -> void:
	for entity: Node in _beacon_buffed_entities:
		if is_instance_valid(entity) and entity is EntityBase and entity.buff_debuff_component:
			var buff_id: String = "war_beacon_%d" % get_instance_id()
			entity.buff_debuff_component.remove_buff(buff_id)
	_beacon_buffed_entities.clear()

	for tower: Node in _array_buffed_entities:
		if is_instance_valid(tower) and tower is EntityBase and tower.buff_debuff_component:
			var range_buff_id: String = "targeting_array_%d" % get_instance_id()
			tower.buff_debuff_component.remove_buff(range_buff_id)
	_array_buffed_entities.clear()

	for entity: Node in _shielded_entities:
		if is_instance_valid(entity) and entity is EntityBase and entity.buff_debuff_component:
			var buff_id: String = "shield_pylon_%d" % get_instance_id()
			entity.buff_debuff_component.remove_buff(buff_id)
	_shielded_entities.clear()


func apply_upgrade_modifications(modifications: Dictionary) -> void:
	_remove_all_buffs()
	super.apply_upgrade_modifications(modifications)
	_parse_support_type()
