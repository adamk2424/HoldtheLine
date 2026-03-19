class_name BuffDebuffComponent
extends Node
## BuffDebuffComponent - Manages buff/debuff stacking and aura effects.

signal buff_added(buff_id: String)
signal buff_removed(buff_id: String)

# Active buffs: { buff_id: { "type": String, "value": float, "duration": float, "remaining": float, "source": Node } }
var active_buffs: Dictionary = {}
var active_debuffs: Dictionary = {}

@onready var entity: EntityBase = get_parent() as EntityBase


func initialize(_data: Dictionary) -> void:
	# Start with processing disabled — re-enabled when effects are applied.
	set_process(false)


func _process(delta: float) -> void:
	_tick_effects(active_buffs, delta, true)
	_tick_effects(active_debuffs, delta, false)
	# Auto-disable when all effects have expired.
	if active_buffs.is_empty() and active_debuffs.is_empty():
		set_process(false)


func apply_buff(buff_id: String, buff_type: String, value: float, duration: float, source: Node = null) -> void:
	active_buffs[buff_id] = {
		"type": buff_type,
		"value": value,
		"duration": duration,
		"remaining": duration,
		"source": source
	}
	_apply_effect(buff_type, value)
	set_process(true)
	buff_added.emit(buff_id)
	GameBus.buff_applied.emit(entity, buff_id, duration)


func apply_debuff(debuff_id: String, debuff_type: String, value: float, duration: float, source: Node = null) -> void:
	active_debuffs[debuff_id] = {
		"type": debuff_type,
		"value": value,
		"duration": duration,
		"remaining": duration,
		"source": source
	}
	_apply_effect(debuff_type, -value)
	set_process(true)
	GameBus.debuff_applied.emit(entity, debuff_id, duration)


func remove_buff(buff_id: String) -> void:
	if active_buffs.has(buff_id):
		var buff: Dictionary = active_buffs[buff_id]
		_remove_effect(buff["type"], buff["value"])
		active_buffs.erase(buff_id)
		buff_removed.emit(buff_id)
		GameBus.buff_removed.emit(entity, buff_id)


func remove_debuff(debuff_id: String) -> void:
	if active_debuffs.has(debuff_id):
		var debuff: Dictionary = active_debuffs[debuff_id]
		_remove_effect(debuff["type"], -debuff["value"])
		active_debuffs.erase(debuff_id)
		GameBus.debuff_removed.emit(entity, debuff_id)


func has_buff(buff_id: String) -> bool:
	return active_buffs.has(buff_id)


func has_debuff(debuff_id: String) -> bool:
	return active_debuffs.has(debuff_id)


func clear_all() -> void:
	for buff_id: String in active_buffs.keys():
		remove_buff(buff_id)
	for debuff_id: String in active_debuffs.keys():
		remove_debuff(debuff_id)


func _tick_effects(effects: Dictionary, delta: float, is_buff: bool) -> void:
	var expired: Array = []
	for effect_id: String in effects:
		var effect: Dictionary = effects[effect_id]
		if effect["duration"] > 0.0:  # duration <= 0 means permanent
			effect["remaining"] -= delta
			if effect["remaining"] <= 0.0:
				expired.append(effect_id)
	for effect_id: String in expired:
		if is_buff:
			remove_buff(effect_id)
		else:
			remove_debuff(effect_id)


func _apply_effect(effect_type: String, value: float) -> void:
	if not entity:
		return
	match effect_type:
		"armor":
			if entity.health_component:
				entity.health_component.set_armor_bonus(
					entity.health_component.armor_bonus + value
				)
		"speed":
			if entity.movement_component:
				entity.movement_component.speed_multiplier += value
		"damage":
			if entity.combat_component:
				entity.combat_component.damage_multiplier += value
		"range":
			if entity.combat_component:
				entity.combat_component.range_multiplier += value
		"slow":
			if entity.movement_component:
				entity.movement_component.speed_multiplier = max(0.1, entity.movement_component.speed_multiplier - value)


func _remove_effect(effect_type: String, value: float) -> void:
	if not entity:
		return
	match effect_type:
		"armor":
			if entity.health_component:
				entity.health_component.set_armor_bonus(
					entity.health_component.armor_bonus - value
				)
		"speed":
			if entity.movement_component:
				entity.movement_component.speed_multiplier -= value
		"damage":
			if entity.combat_component:
				entity.combat_component.damage_multiplier -= value
		"range":
			if entity.combat_component:
				entity.combat_component.range_multiplier -= value
		"slow":
			if entity.movement_component:
				entity.movement_component.speed_multiplier = min(2.0, entity.movement_component.speed_multiplier + value)
