class_name SaveSystem
extends Node
## SaveSystem - Save/resume game state to disk.
## Serializes GameState snapshot to JSON. Entity serialization can be enhanced later.

const SAVE_PATH := "user://save_game.json"


func _ready() -> void:
	GameBus.save_requested.connect(_on_save_requested)
	GameBus.load_requested.connect(_on_load_requested)
	print("[SaveSystem] Initialized")


# --- Signal handlers ---

func _on_save_requested() -> void:
	var success := save_game()
	GameBus.save_completed.emit(success)


func _on_load_requested() -> void:
	var success := load_game()
	GameBus.load_completed.emit(success)


# --- Save ---

func save_game() -> bool:
	var save_data := _create_save_data()
	var json_string := JSON.stringify(save_data, "\t")

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		push_error("[SaveSystem] Failed to open save file for writing: %s" % SAVE_PATH)
		return false

	file.store_string(json_string)
	file.close()
	print("[SaveSystem] Game saved to %s" % SAVE_PATH)
	return true


func _create_save_data() -> Dictionary:
	return {
		"version": 1,
		"timestamp": Time.get_datetime_string_from_system(),
		"game_state": {
			"energy": GameState.energy,
			"materials": GameState.materials,
			"energy_rate": GameState.energy_rate,
			"material_rate": GameState.material_rate,
			"energy_bonus_rate": GameState.energy_bonus_rate,
			"material_bonus_rate": GameState.material_bonus_rate,
			"population_current": GameState.population_current,
			"population_max": GameState.population_max,
			"game_time": GameState.game_time,
			"game_speed": GameState.game_speed,
			"enemies_killed": GameState.enemies_killed,
			"buildings_built": GameState.buildings_built,
			"buildings_lost": GameState.buildings_lost,
			"is_surge_active": GameState.is_surge_active,
			"surge_count": GameState.surge_count,
			"central_tower_alive": GameState.central_tower_alive,
			"tech_levels": GameState.tech_levels.duplicate(),
		},
		# Placeholder for future entity serialization
		"entities": [],
	}


# --- Load ---

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		push_warning("[SaveSystem] No save file found at: %s" % SAVE_PATH)
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		push_error("[SaveSystem] Failed to open save file for reading: %s" % SAVE_PATH)
		return false

	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	var err := json.parse(json_string)
	if err != OK:
		push_error("[SaveSystem] Failed to parse save file: %s" % json.get_error_message())
		return false

	var save_data: Dictionary = json.data
	if not _validate_save_data(save_data):
		push_error("[SaveSystem] Save data validation failed")
		return false

	_apply_save_data(save_data)
	print("[SaveSystem] Game loaded from %s" % SAVE_PATH)
	return true


func _validate_save_data(data: Dictionary) -> bool:
	if not data.has("version"):
		return false
	if not data.has("game_state"):
		return false
	var gs: Dictionary = data["game_state"]
	# Check for required keys
	var required_keys := [
		"energy", "materials", "game_time", "tech_levels"
	]
	for key: String in required_keys:
		if not gs.has(key):
			push_warning("[SaveSystem] Missing required key: %s" % key)
			return false
	return true


func _apply_save_data(data: Dictionary) -> void:
	var gs: Dictionary = data["game_state"]

	GameState.energy = gs.get("energy", 100.0)
	GameState.materials = gs.get("materials", 100.0)
	GameState.energy_rate = gs.get("energy_rate", 1.0)
	GameState.material_rate = gs.get("material_rate", 1.0)
	GameState.energy_bonus_rate = gs.get("energy_bonus_rate", 0.0)
	GameState.material_bonus_rate = gs.get("material_bonus_rate", 0.0)
	GameState.population_current = int(gs.get("population_current", 0))
	GameState.population_max = int(gs.get("population_max", 20))
	GameState.game_time = gs.get("game_time", 0.0)
	GameState.game_speed = gs.get("game_speed", 1.0)
	GameState.enemies_killed = int(gs.get("enemies_killed", 0))
	GameState.buildings_built = int(gs.get("buildings_built", 0))
	GameState.buildings_lost = int(gs.get("buildings_lost", 0))
	GameState.is_surge_active = gs.get("is_surge_active", false)
	GameState.surge_count = int(gs.get("surge_count", 0))
	GameState.central_tower_alive = gs.get("central_tower_alive", true)

	var tech: Dictionary = gs.get("tech_levels", {})
	for key: String in tech.keys():
		GameState.tech_levels[key] = int(tech[key])

	# Apply game speed to engine
	Engine.time_scale = GameState.game_speed

	# Emit resource changed so UI updates
	GameBus.resources_changed.emit(GameState.energy, GameState.materials)
	GameBus.resource_income_changed.emit(
		GameState.get_total_energy_rate(),
		GameState.get_total_material_rate()
	)
	GameBus.enemy_killed.emit(GameState.enemies_killed)
	GameBus.population_changed.emit(GameState.population_current, GameState.population_max)


# --- Public API ---

func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func delete_save_file() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
		print("[SaveSystem] Save file deleted")
