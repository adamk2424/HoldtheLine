class_name HealthComponent
extends Node
## HealthComponent - Manages HP, armor, regen, damage, and death.
## HP stored as float with 3 decimal precision. Armor reduces damage 1:1 per hit.
## Regen: 1% max HP every 5 seconds (configurable).

signal health_changed(current_hp: float, max_hp: float)
signal armor_changed(current_armor: float)
signal died(killer: Node)
signal damage_taken(amount: float, source: Node)

var max_hp: float = 100.0
var current_hp: float = 100.0
var base_armor: float = 0.0
var current_armor: float = 0.0
var armor_bonus: float = 0.0  # From buffs

var regen_percent: float = 1.0  # % of max HP
var regen_interval: float = 5.0  # seconds
var _regen_timer: float = 0.0

# Auto-repair from items (like Nanobotic Swarm)
var auto_repair_rate: float = 0.0  # % of max HP per second
var _auto_repair_timer: float = 0.0

var is_dead: bool = false
var is_invulnerable: bool = false

@onready var entity: EntityBase = get_parent() as EntityBase


func initialize(data: Dictionary) -> void:
	max_hp = float(data.get("hp", 100))
	current_hp = max_hp
	base_armor = float(data.get("armor", 0))
	current_armor = base_armor
	regen_percent = float(data.get("regen_percent", 1.0))
	regen_interval = float(data.get("regen_interval", 5.0))
	is_dead = false
	
	# Apply item modifiers for structures
	_apply_item_modifiers()
	
	# Apply auto-repair from items
	if is_instance_valid(ItemSystem):
		auto_repair_rate = ItemSystem.get_structure_modifiers().get("auto_repair", 0.0)
	
	# No need to tick regen when starting at full HP, unless we have auto-repair
	if auto_repair_rate > 0.0:
		set_process(true)
	else:
		set_process(false)


func _process(delta: float) -> void:
	if is_dead:
		return
	
	# Standard regen
	_regen_timer += delta
	if _regen_timer >= regen_interval:
		_regen_timer -= regen_interval
		_regen_tick()
	
	# Auto-repair from items
	if auto_repair_rate > 0.0 and current_hp < max_hp:
		_auto_repair_timer += delta
		if _auto_repair_timer >= 1.0:  # Apply every second
			_auto_repair_timer -= 1.0
			var repair_amount: float = max_hp * auto_repair_rate
			heal(repair_amount)


func _regen_tick() -> void:
	if current_hp < max_hp and current_hp > 0.0:
		var regen_amount: float = max_hp * (regen_percent / 100.0)
		heal(regen_amount)


func take_damage(amount: float, source: Node = null) -> float:
	if is_dead or is_invulnerable:
		return 0.0

	var effective_armor: float = current_armor + armor_bonus
	var actual_damage: float = max(0.0, amount - effective_armor)

	current_hp = snapped(max(0.0, current_hp - actual_damage), 0.001)
	health_changed.emit(current_hp, max_hp)
	damage_taken.emit(actual_damage, source)
	GameBus.damage_dealt.emit(entity, actual_damage, source)

	# Enable regen ticking now that HP is below max, or if we have auto-repair
	if (current_hp > 0.0 and current_hp < max_hp) or auto_repair_rate > 0.0:
		set_process(true)

	if current_hp <= 0.0:
		_die(source)

	return actual_damage


func heal(amount: float) -> void:
	if is_dead:
		return
	current_hp = snapped(min(max_hp, current_hp + amount), 0.001)
	health_changed.emit(current_hp, max_hp)
	# Disable regen ticking when back to full HP, unless we have auto-repair
	if current_hp >= max_hp and auto_repair_rate <= 0.0:
		set_process(false)


func set_armor_bonus(bonus: float) -> void:
	armor_bonus = bonus
	armor_changed.emit(current_armor + armor_bonus)


func get_hp_percent() -> float:
	if max_hp <= 0.0:
		return 0.0
	return current_hp / max_hp


func get_hp_display() -> int:
	return int(current_hp)


func get_effective_armor() -> float:
	return current_armor + armor_bonus


func _die(killer: Node = null) -> void:
	if is_dead:
		return
	is_dead = true
	set_process(false)
	died.emit(killer)
	if entity:
		entity.die(killer)


func _apply_item_modifiers() -> void:
	if not ItemSystem:
		return
	
	# Check if this is a building/structure 
	if entity and (entity.is_in_group("tower") or entity.is_in_group("barrier")):
		var structure_mods := ItemSystem.get_structure_modifiers()
		
		# Apply health multiplier
		var health_mult: float = structure_mods.get("health_multiplier", 1.0)
		if health_mult != 1.0:
			max_hp *= health_mult
			current_hp = max_hp  # Start at full health with new max
			
		# Apply auto-repair rate
		auto_repair_rate = structure_mods.get("auto_repair", 0.0)
