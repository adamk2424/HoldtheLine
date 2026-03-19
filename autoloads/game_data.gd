extends Node
## GameData - Loads and caches all JSON data files.
## Access entity stats via: GameData.get_enemy("thrasher"), GameData.get_tower("autocannon"), etc.

var _enemies: Dictionary = {}
var _towers_offensive: Dictionary = {}
var _towers_resource: Dictionary = {}
var _towers_support: Dictionary = {}
var _barriers: Dictionary = {}
var _units_drone: Dictionary = {}
var _units_mech: Dictionary = {}
var _units_war: Dictionary = {}
var _production_buildings: Dictionary = {}
var _decorative_buildings: Dictionary = {}
var _central_tower: Dictionary = {}
var _difficulty_scaling: Dictionary = {}
var _audio_hooks: Dictionary = {}

# Combined lookup caches
var _all_towers: Dictionary = {}
var _all_units: Dictionary = {}


func _ready() -> void:
	_load_all_data()
	_build_caches()
	print("[GameData] Loaded: %d enemies, %d towers, %d units, %d barriers, %d buildings" % [
		_enemies.size(), _all_towers.size(), _all_units.size(),
		_barriers.size(), _production_buildings.size()
	])


func _load_all_data() -> void:
	_enemies = _load_json_array("res://data/enemies.json", "enemies", "id")
	_towers_offensive = _load_json_array("res://data/towers_offensive.json", "towers", "id")
	_towers_resource = _load_json_array("res://data/towers_resource.json", "towers", "id")
	_towers_support = _load_json_array("res://data/towers_support.json", "towers", "id")
	_barriers = _load_json_array("res://data/barriers.json", "barriers", "id")
	_units_drone = _load_json_array("res://data/units_drone.json", "units", "id")
	_units_mech = _load_json_array("res://data/units_mech.json", "units", "id")
	_units_war = _load_json_array("res://data/units_war.json", "units", "id")
	_production_buildings = _load_json_array("res://data/production_buildings.json", "buildings", "id")
	_decorative_buildings = _load_json_array("res://data/buildings_decorative.json", "buildings", "id")
	_central_tower = _load_json_object("res://data/central_tower.json")
	_difficulty_scaling = _load_json_object("res://data/difficulty_scaling.json")
	_audio_hooks = _load_json_object("res://data/audio_hooks.json")


func _build_caches() -> void:
	_all_towers.merge(_towers_offensive)
	_all_towers.merge(_towers_resource)
	_all_towers.merge(_towers_support)
	_all_units.merge(_units_drone)
	_all_units.merge(_units_mech)
	_all_units.merge(_units_war)


func _load_json_array(path: String, array_key: String, id_key: String) -> Dictionary:
	var result: Dictionary = {}
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_warning("[GameData] Could not open: %s" % path)
		return result
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	if err != OK:
		push_warning("[GameData] JSON parse error in %s: %s" % [path, json.get_error_message()])
		return result
	var data: Dictionary = json.data
	if data.has(array_key):
		for entry: Dictionary in data[array_key]:
			if entry.has(id_key):
				result[entry[id_key]] = entry
	return result


func _load_json_object(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_warning("[GameData] Could not open: %s" % path)
		return {}
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	if err != OK:
		push_warning("[GameData] JSON parse error in %s: %s" % [path, json.get_error_message()])
		return {}
	return json.data


# --- Public API ---

func get_enemy(id: String) -> Dictionary:
	return _enemies.get(id, {})

func get_all_enemies() -> Dictionary:
	return _enemies

func get_tower(id: String) -> Dictionary:
	return _all_towers.get(id, {})

func get_tower_offensive(id: String) -> Dictionary:
	return _towers_offensive.get(id, {})

func get_tower_resource(id: String) -> Dictionary:
	return _towers_resource.get(id, {})

func get_tower_support(id: String) -> Dictionary:
	return _towers_support.get(id, {})

func get_all_towers() -> Dictionary:
	return _all_towers

func get_all_towers_offensive() -> Dictionary:
	return _towers_offensive

func get_all_towers_resource() -> Dictionary:
	return _towers_resource

func get_all_towers_support() -> Dictionary:
	return _towers_support

func get_barrier(id: String) -> Dictionary:
	return _barriers.get(id, {})

func get_all_barriers() -> Dictionary:
	return _barriers

func get_unit(id: String) -> Dictionary:
	return _all_units.get(id, {})

func get_all_units() -> Dictionary:
	return _all_units

func get_all_units_drone() -> Dictionary:
	return _units_drone

func get_all_units_mech() -> Dictionary:
	return _units_mech

func get_all_units_war() -> Dictionary:
	return _units_war

func get_production_building(id: String) -> Dictionary:
	return _production_buildings.get(id, {})

func get_all_production_buildings() -> Dictionary:
	return _production_buildings

func get_decorative_building(id: String) -> Dictionary:
	return _decorative_buildings.get(id, {})

func get_central_tower() -> Dictionary:
	return _central_tower

func get_difficulty_scaling() -> Dictionary:
	return _difficulty_scaling

func get_audio_hook(hook_id: String) -> String:
	# Traverse nested audio hooks: "ui.button_click" -> audio_hooks["ui"]["button_click"]
	var parts := hook_id.split(".")
	var current: Variant = _audio_hooks
	for part in parts:
		if current is Dictionary and current.has(part):
			current = current[part]
		else:
			return ""
	if current is String:
		return current
	return ""

func get_entity_data(entity_id: String) -> Dictionary:
	# Universal lookup across all entity types
	var result := get_tower(entity_id)
	if not result.is_empty():
		return result
	result = get_unit(entity_id)
	if not result.is_empty():
		return result
	result = get_enemy(entity_id)
	if not result.is_empty():
		return result
	result = get_barrier(entity_id)
	if not result.is_empty():
		return result
	result = get_production_building(entity_id)
	if not result.is_empty():
		return result
	result = get_decorative_building(entity_id)
	if not result.is_empty():
		return result
	if entity_id == "central_tower":
		return get_central_tower()
	return {}

func get_cost(entity_id: String) -> Dictionary:
	var data := get_entity_data(entity_id)
	return {
		"energy": data.get("cost_energy", 0),
		"materials": data.get("cost_materials", 0)
	}

func get_build_time(entity_id: String) -> float:
	var data := get_entity_data(entity_id)
	return data.get("build_time", 0.0)
