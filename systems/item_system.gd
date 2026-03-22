extends Node
## ItemSystem - Manages item unlocks, loadouts, and passive bonuses.
## Handles progression-based unlocking, loadout management, and applying
## item effects to towers, resources, and other game systems.

signal item_unlocked(item_id: String)
signal loadout_changed()

# --- Persistent Data ---
var unlocked_items: Array[String] = []
var owned_items: Array[String] = []
var active_loadout: Array[String] = ["", "", ""]  # 3 slots
var unlock_progress: Dictionary = {}

# --- Item Data ---
var _item_data: Dictionary = {}
var _rarity_data: Dictionary = {}
var _max_loadout_slots: int = 3

# --- Applied Effects Cache ---
var _active_effects: Dictionary = {}

const SAVE_PATH := "user://item_system.json"


func _ready() -> void:
	_load_item_data()
	_connect_signals()
	load_item_system()
	print("[ItemSystem] Initialized with %d items, %d unlocked" % [
		_item_data.size(), unlocked_items.size()
	])


func _load_item_data() -> void:
	var file := FileAccess.open("res://data/items.json", FileAccess.READ)
	if not file:
		push_error("[ItemSystem] Failed to load items.json")
		return

	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()

	if err != OK:
		push_error("[ItemSystem] Failed to parse items.json: %s" % json.get_error_message())
		return

	var data: Dictionary = json.data
	_item_data = data.get("items", {})
	_rarity_data = data.get("rarities", {})
	_max_loadout_slots = data.get("loadout_slots", 3)

	# Initialize empty loadout if needed
	if active_loadout.size() != _max_loadout_slots:
		active_loadout = []
		for i in _max_loadout_slots:
			active_loadout.append("")


func _connect_signals() -> void:
	# Listen to game events for unlock conditions
	GameBus.enemy_killed.connect(_on_enemy_killed)
	GameBus.build_completed.connect(_on_build_completed)
	GameBus.entity_died.connect(_on_entity_died)
	GameBus.game_over.connect(_on_game_over)
	
	# Apply effects when loadout changes or game starts
	GameBus.game_started.connect(_apply_loadout_effects)
	loadout_changed.connect(_apply_loadout_effects)


# --- Unlock System ---

func check_unlock_conditions() -> void:
	for item_id: String in _item_data.keys():
		if item_id in unlocked_items:
			continue

		var item: Dictionary = _item_data[item_id]
		var conditions: Dictionary = item.get("unlock_conditions", {})
		
		if _meets_unlock_conditions(conditions):
			unlock_item(item_id)


func _meets_unlock_conditions(conditions: Dictionary) -> bool:
	for condition: String in conditions.keys():
		var required_value = conditions[condition]
		var current_value = _get_progress_value(condition)
		
		if current_value < required_value:
			return false
	
	return true


func _get_progress_value(condition: String) -> int:
	match condition:
		"enemies_killed":
			return GameState.enemies_killed + MetaProgress.total_enemies_killed
		"buildings_built":
			return GameState.buildings_built
		"buildings_lost":
			return GameState.buildings_lost
		"survival_time":
			return int(GameState.game_time)
		"boss_kills":
			return GameState.boss_kills
		"tech_points_earned":
			return MetaProgress.tech_points
		"population_cap_reached":
			return unlock_progress.get("population_cap_reached", 0)
		"central_tower_upgrades":
			return GameState.central_tower_tier
		"enemy_variety_killed":
			return unlock_progress.get("enemy_variety_killed", 0)
		_:
			return unlock_progress.get(condition, 0)


func unlock_item(item_id: String) -> void:
	if item_id in unlocked_items:
		return

	unlocked_items.append(item_id)
	item_unlocked.emit(item_id)
	
	var item: Dictionary = _item_data[item_id]
	print("[ItemSystem] Item unlocked: %s" % item.get("name", item_id))
	
	# Play unlock sound/VFX
	GameBus.audio_play.emit("ui.item_unlocked")
	
	save_item_system()


# --- Purchase System ---

func can_purchase_item(item_id: String) -> bool:
	if not item_id in unlocked_items:
		return false
	
	if item_id in owned_items:
		return false  # Already owned
	
	var item: Dictionary = _item_data[item_id]
	var cost: Dictionary = item.get("cost", {})
	
	var tech_points_cost: int = cost.get("tech_points", 0)
	return MetaProgress.tech_points >= tech_points_cost


func purchase_item(item_id: String) -> bool:
	if not can_purchase_item(item_id):
		return false

	var item: Dictionary = _item_data[item_id]
	var cost: Dictionary = item.get("cost", {})
	var tech_points_cost: int = cost.get("tech_points", 0)

	MetaProgress.tech_points -= tech_points_cost
	MetaProgress.save_data()
	
	owned_items.append(item_id)
	save_item_system()
	
	print("[ItemSystem] Item purchased: %s for %d tech points" % [
		item.get("name", item_id), tech_points_cost
	])
	
	GameBus.audio_play.emit("ui.item_purchased")
	return true


# --- Loadout Management ---

func equip_item(item_id: String, slot: int) -> bool:
	if slot < 0 or slot >= _max_loadout_slots:
		return false
		
	if not item_id in owned_items and item_id != "":
		return false

	# Remove item from other slots if equipped
	if item_id != "":
		for i in range(active_loadout.size()):
			if active_loadout[i] == item_id:
				active_loadout[i] = ""

	active_loadout[slot] = item_id
	loadout_changed.emit()
	save_item_system()
	
	print("[ItemSystem] Loadout updated: slot %d = %s" % [slot, item_id])
	return true


func unequip_slot(slot: int) -> bool:
	if slot < 0 or slot >= _max_loadout_slots:
		return false

	active_loadout[slot] = ""
	loadout_changed.emit()
	save_item_system()
	return true


func get_equipped_items() -> Array[String]:
	var equipped: Array[String] = []
	for item_id: String in active_loadout:
		if item_id != "":
			equipped.append(item_id)
	return equipped


# --- Effect Application ---

func _apply_loadout_effects() -> void:
	_active_effects.clear()
	
	for item_id: String in get_equipped_items():
		var item: Dictionary = _item_data.get(item_id, {})
		var effects: Dictionary = item.get("effects", {})
		
		for effect_name: String in effects.keys():
			var effect_value = effects[effect_name]
			
			if not _active_effects.has(effect_name):
				_active_effects[effect_name] = effect_value
			else:
				# Stack effects (could be additive or multiplicative based on type)
				if _is_multiplicative_effect(effect_name):
					_active_effects[effect_name] *= effect_value
				else:
					_active_effects[effect_name] += effect_value
	
	print("[ItemSystem] Applied effects: %s" % _active_effects)


func _is_multiplicative_effect(effect_name: String) -> bool:
	var multiplicative_effects: Array[String] = [
		"energy_rate_multiplier",
		"material_rate_multiplier", 
		"structure_health_multiplier",
		"build_speed_multiplier",
		"tower_range_multiplier",
		"tower_accuracy_multiplier",
		"unit_cost_multiplier",
		"tower_attack_speed_multiplier",
		"central_tower_health_multiplier",
		"all_multiplier",
		"tech_point_multiplier",
		"boss_damage_multiplier"
	]
	return effect_name in multiplicative_effects


# --- Public Effect Getters ---

func get_effect_value(effect_name: String, default_value: float = 1.0) -> float:
	return _active_effects.get(effect_name, default_value)


func has_effect(effect_name: String) -> bool:
	return _active_effects.has(effect_name)


func get_resource_multipliers() -> Dictionary:
	return {
		"energy_rate_multiplier": get_effect_value("energy_rate_multiplier", 1.0),
		"material_rate_multiplier": get_effect_value("material_rate_multiplier", 1.0),
		"energy_bonus": get_effect_value("energy_bonus", 0.0),
		"materials_bonus": get_effect_value("materials_bonus", 0.0),
		"population_cap_bonus": get_effect_value("population_cap_bonus", 0.0)
	}


func get_tower_modifiers() -> Dictionary:
	return {
		"range_multiplier": get_effect_value("tower_range_multiplier", 1.0),
		"accuracy_multiplier": get_effect_value("tower_accuracy_multiplier", 1.0),
		"attack_speed_multiplier": get_effect_value("tower_attack_speed_multiplier", 1.0),
		"energy_drain": get_effect_value("tower_energy_drain", 0.0),
		"armor_pierce": get_effect_value("kinetic_armor_pierce", 0.0),
		"chain_lightning_chance": get_effect_value("chain_lightning_chance", 0.0),
		"chain_lightning_bounces": get_effect_value("chain_lightning_bounces", 0)
	}


func get_structure_modifiers() -> Dictionary:
	return {
		"health_multiplier": get_effect_value("structure_health_multiplier", 1.0),
		"build_speed_multiplier": get_effect_value("build_speed_multiplier", 1.0),
		"auto_repair": get_effect_value("structure_auto_repair", 0.0)
	}


func get_time_scaling_bonuses() -> Dictionary:
	var bonuses := {}
	var game_time_minutes: float = GameState.game_time / 60.0
	
	# Time scaling damage (Dimensional Amplifier)
	if has_effect("time_scaling_damage"):
		var scaling_rate: float = get_effect_value("time_scaling_damage", 0.0)
		bonuses["damage_multiplier"] = 1.0 + (scaling_rate * game_time_minutes)
	
	# Time scaling income (Dimensional Amplifier)
	if has_effect("time_scaling_income"):
		var scaling_rate: float = get_effect_value("time_scaling_income", 0.0)
		bonuses["income_multiplier"] = 1.0 + (scaling_rate * game_time_minutes)
	
	return bonuses


func get_adaptive_bonuses() -> Dictionary:
	var bonuses := {}
	
	# Adaptive damage based on enemy variety killed
	if has_effect("adaptive_damage_bonus"):
		var variety_killed: int = unlock_progress.get("enemy_variety_killed", 0)
		var bonus_per_type: float = get_effect_value("adaptive_damage_bonus", 0.0)
		bonuses["adaptive_damage"] = variety_killed * bonus_per_type
	
	# Adaptive speed based on enemy variety
	if has_effect("adaptive_speed_bonus"):
		var variety_killed: int = unlock_progress.get("enemy_variety_killed", 0)
		var bonus_per_type: float = get_effect_value("adaptive_speed_bonus", 0.0)
		bonuses["adaptive_speed"] = variety_killed * bonus_per_type
	
	return bonuses


# --- Signal Handlers ---

func _on_enemy_killed(_total_killed: int) -> void:
	check_unlock_conditions()


func _on_build_completed(_entity: Node, _entity_id: String, _grid_position: Vector2i) -> void:
	check_unlock_conditions()


func _on_entity_died(_entity: Node, entity_type: String, _entity_id: String, _killer: Node) -> void:
	if entity_type != "enemy":  # Building died
		check_unlock_conditions()


func _on_game_over(survival_time: float) -> void:
	# Update unlock progress
	unlock_progress["max_survival_time"] = max(
		unlock_progress.get("max_survival_time", 0),
		int(survival_time)
	)
	check_unlock_conditions()
	save_item_system()


# --- Save/Load ---

func save_item_system() -> void:
	var data := {
		"unlocked_items": unlocked_items,
		"owned_items": owned_items,
		"active_loadout": active_loadout,
		"unlock_progress": unlock_progress
	}
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()


func load_item_system() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return

	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()

	if err != OK:
		push_warning("[ItemSystem] Failed to load save: %s" % json.get_error_message())
		return

	var data: Dictionary = json.data
	var raw_unlocked: Array = data.get("unlocked_items", [])
	unlocked_items.clear()
	for item: String in raw_unlocked:
		unlocked_items.append(item)
	var raw_owned: Array = data.get("owned_items", [])
	owned_items.clear()
	for item: String in raw_owned:
		owned_items.append(item)
	var raw_loadout: Array = data.get("active_loadout", ["", "", ""])
	active_loadout.clear()
	for item: String in raw_loadout:
		active_loadout.append(item)
	unlock_progress = data.get("unlock_progress", {})

	# Ensure loadout has correct size
	while active_loadout.size() < _max_loadout_slots:
		active_loadout.append("")
	
	if active_loadout.size() > _max_loadout_slots:
		active_loadout = active_loadout.slice(0, _max_loadout_slots)


# --- Public API ---

func get_item_data(item_id: String) -> Dictionary:
	return _item_data.get(item_id, {})


func get_all_items() -> Dictionary:
	return _item_data


func get_rarity_data(rarity: String) -> Dictionary:
	return _rarity_data.get(rarity, {})


func is_item_unlocked(item_id: String) -> bool:
	return item_id in unlocked_items


func is_item_owned(item_id: String) -> bool:
	return item_id in owned_items


func get_items_by_rarity(rarity: String) -> Array[String]:
	var items: Array[String] = []
	for item_id: String in _item_data.keys():
		var item: Dictionary = _item_data[item_id]
		if item.get("rarity", "") == rarity:
			items.append(item_id)
	return items


func get_unlock_progress_for_item(item_id: String) -> Dictionary:
	var item: Dictionary = _item_data.get(item_id, {})
	var conditions: Dictionary = item.get("unlock_conditions", {})
	var progress: Dictionary = {}
	
	for condition: String in conditions.keys():
		var required = conditions[condition]
		var current = _get_progress_value(condition)
		progress[condition] = {
			"current": current,
			"required": required,
			"completed": current >= required
		}
	
	return progress


func debug_unlock_all_items() -> void:
	for item_id: String in _item_data.keys():
		if not item_id in unlocked_items:
			unlock_item(item_id)
		if not item_id in owned_items:
			owned_items.append(item_id)
	save_item_system()