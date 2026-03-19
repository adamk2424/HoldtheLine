extends Node
## LevelSystem - Manages level-specific mechanics, objectives, and progression.
## Handles level modifiers, unlock requirements, and rewards.

const LEVEL_DATA_PATH := "res://data/levels.json"

var _levels_data: Dictionary = {}
var _current_level: Dictionary = {}
var _objectives_tracker: Dictionary = {}

signal level_objective_completed(objective_type: String)
signal level_completed(level_id: String, rewards: Dictionary)
signal level_failed(reason: String)


func _ready() -> void:
	_load_level_data()
	GameBus.game_started.connect(_on_game_started)
	GameBus.game_over.connect(_on_game_over)


func _load_level_data() -> void:
	if not FileAccess.file_exists(LEVEL_DATA_PATH):
		push_error("[LevelSystem] Level data not found: " + LEVEL_DATA_PATH)
		return
	
	var file := FileAccess.open(LEVEL_DATA_PATH, FileAccess.READ)
	if not file:
		push_error("[LevelSystem] Cannot open level data file")
		return
	
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	
	if err != OK:
		push_error("[LevelSystem] Invalid JSON in level data")
		return
	
	_levels_data = json.data
	print("[LevelSystem] Loaded %d levels" % _levels_data.get("levels", []).size())


func get_level_data(level_id: String) -> Dictionary:
	var levels: Array = _levels_data.get("levels", [])
	for level_data: Dictionary in levels:
		if level_data.get("id", "") == level_id:
			return level_data
	return {}


func start_level(level_id: String) -> bool:
	if level_id.is_empty():
		# Default game mode (no level restrictions)
		_current_level = {}
		GameState.current_level_data = {}
		return true
	
	_current_level = get_level_data(level_id)
	if _current_level.is_empty():
		push_error("[LevelSystem] Level not found: " + level_id)
		return false
	
	GameState.current_level_data = _current_level
	_apply_level_modifiers()
	_setup_objectives()
	
	print("[LevelSystem] Started level: %s" % _current_level.get("name", level_id))
	return true


func _apply_level_modifiers() -> void:
	# Apply starting resources
	var starting_resources: Dictionary = _current_level.get("starting_resources", {})
	if starting_resources.has("energy"):
		GameState.energy = float(starting_resources.get("energy", 100))
	if starting_resources.has("materials"):
		GameState.materials = float(starting_resources.get("materials", 100))
	
	# Apply special modifiers
	var modifiers: Dictionary = _current_level.get("special_modifiers", {})
	
	if modifiers.has("resource_bonus"):
		GameState.income_multiplier = float(modifiers.get("resource_bonus", 1.0))
	
	if modifiers.has("resource_penalty"):
		GameState.income_multiplier = float(modifiers.get("resource_penalty", 1.0))
	
	if modifiers.has("forced_game_speed"):
		var speed: float = float(modifiers.get("forced_game_speed", 1.0))
		GameState.set_game_speed(speed)
	
	# Notify systems about level-specific settings
	GameBus.level_modifiers_applied.emit(modifiers)


func _setup_objectives() -> void:
	_objectives_tracker.clear()
	
	var objective: String = _current_level.get("objective", "")
	var duration: int = _current_level.get("duration_seconds", -1)
	
	if duration > 0:
		_objectives_tracker["survival_time"] = {
			"target": duration,
			"current": 0,
			"completed": false
		}
	
	# Add other objective types as needed
	# e.g., kill count, building requirements, etc.


func _process(_delta: float) -> void:
	if _current_level.is_empty() or not GameState.is_game_active:
		return
	
	_check_objectives()


func _check_objectives() -> void:
	# Check survival time objective
	if _objectives_tracker.has("survival_time"):
		var obj := _objectives_tracker["survival_time"]
		obj["current"] = GameState.game_time
		
		if not obj["completed"] and obj["current"] >= obj["target"]:
			obj["completed"] = true
			_complete_objective("survival_time")
			_complete_level()


func _complete_objective(objective_type: String) -> void:
	level_objective_completed.emit(objective_type)
	print("[LevelSystem] Objective completed: " + objective_type)


func _complete_level() -> void:
	if GameState.level_objectives_completed:
		return  # Already completed
	
	GameState.level_objectives_completed = true
	var level_id: String = _current_level.get("id", "")
	var rewards: Dictionary = _current_level.get("rewards", {})
	
	# Award rewards
	_award_rewards(rewards)
	
	# Mark level as completed
	_mark_level_completed(level_id)
	
	level_completed.emit(level_id, rewards)
	print("[LevelSystem] Level completed: %s" % _current_level.get("name", level_id))


func _award_rewards(rewards: Dictionary) -> void:
	var tech_points: int = rewards.get("tech_points", 0)
	if tech_points > 0:
		MetaProgress.tech_points += tech_points
		print("[LevelSystem] Awarded %d tech points" % tech_points)
	
	var unlocks: Array = rewards.get("unlocks", [])
	for unlock_id: String in unlocks:
		_unlock_content(unlock_id)
	
	# Award items
	var items: Array = rewards.get("items", [])
	for item_id: String in items:
		_award_item(item_id)
	
	# Trigger achievement notifications
	if not unlocks.is_empty():
		GameBus.achievements_unlocked.emit(unlocks)


func _unlock_content(unlock_id: String) -> void:
	# Handle different types of unlocks
	if unlock_id.begins_with("level_"):
		# Level unlock
		if not MetaProgress.permanent_upgrades.has("unlocked_levels"):
			MetaProgress.permanent_upgrades["unlocked_levels"] = []
		
		var unlocked_levels: Array = MetaProgress.permanent_upgrades["unlocked_levels"]
		if unlock_id not in unlocked_levels:
			unlocked_levels.append(unlock_id)
			print("[LevelSystem] Unlocked level: %s" % unlock_id)
	
	elif unlock_id.begins_with("achievement_"):
		# Achievement unlock
		if not MetaProgress.permanent_upgrades.has("unlocked_achievements"):
			MetaProgress.permanent_upgrades["unlocked_achievements"] = []
		
		var unlocked_achievements: Array = MetaProgress.permanent_upgrades["unlocked_achievements"]
		if unlock_id not in unlocked_achievements:
			unlocked_achievements.append(unlock_id)
			print("[LevelSystem] Achievement unlocked: %s" % unlock_id)
	
	else:
		# Generic unlock
		if not MetaProgress.permanent_upgrades.has("misc_unlocks"):
			MetaProgress.permanent_upgrades["misc_unlocks"] = []
		
		var misc_unlocks: Array = MetaProgress.permanent_upgrades["misc_unlocks"]
		if unlock_id not in misc_unlocks:
			misc_unlocks.append(unlock_id)
			print("[LevelSystem] Unlocked: %s" % unlock_id)


func _award_item(item_id: String) -> void:
	# Award items to inventory/collection
	if not MetaProgress.permanent_upgrades.has("unlocked_items"):
		MetaProgress.permanent_upgrades["unlocked_items"] = []
	
	var unlocked_items: Array = MetaProgress.permanent_upgrades["unlocked_items"]
	if item_id not in unlocked_items:
		unlocked_items.append(item_id)
		print("[LevelSystem] Item unlocked: %s" % item_id)
		
		# Notify item system if available
		if has_node("/root/ItemSystem"):
			get_node("/root/ItemSystem").unlock_item(item_id)


func _mark_level_completed(level_id: String) -> void:
	if not MetaProgress.permanent_upgrades.has("completed_levels"):
		MetaProgress.permanent_upgrades["completed_levels"] = []
	
	var completed_levels: Array = MetaProgress.permanent_upgrades["completed_levels"]
	if level_id not in completed_levels:
		completed_levels.append(level_id)
		MetaProgress.save_data()


func is_level_unlocked(level_id: String) -> bool:
	var level_data := get_level_data(level_id)
	var requirements: Array = level_data.get("unlock_requirements", [])
	
	# Tutorial level is always unlocked
	if level_id == "tutorial":
		return true
		
	# No requirements means it's unlocked
	if requirements.is_empty():
		return true
	
	# Check if all requirements are met
	var completed_levels: Array = MetaProgress.permanent_upgrades.get("completed_levels", [])
	
	for requirement: String in requirements:
		if requirement not in completed_levels:
			return false
	
	return true


func get_level_progress_summary() -> Dictionary:
	var levels: Array = _levels_data.get("levels", [])
	var completed_levels: Array = MetaProgress.permanent_upgrades.get("completed_levels", [])
	
	var summary := {
		"total_levels": levels.size(),
		"completed_count": completed_levels.size(),
		"unlocked_count": 0,
		"available_tech_points": MetaProgress.tech_points
	}
	
	for level_data: Dictionary in levels:
		var level_id: String = level_data.get("id", "")
		if is_level_unlocked(level_id):
			summary["unlocked_count"] += 1
	
	return summary


func get_difficulty_multipliers() -> Dictionary:
	if _current_level.is_empty():
		return {
			"enemy_spawn_multiplier": 1.0,
			"enemy_health_multiplier": 1.0,
			"enemy_damage_multiplier": 1.0
		}
	
	return {
		"enemy_spawn_multiplier": _current_level.get("enemy_spawn_multiplier", 1.0),
		"enemy_health_multiplier": _current_level.get("enemy_health_multiplier", 1.0),
		"enemy_damage_multiplier": _current_level.get("enemy_damage_multiplier", 1.0)
	}


func get_enabled_enemies() -> Array:
	if _current_level.is_empty():
		return []  # All enemies enabled by default
	
	return _current_level.get("enabled_enemies", [])


func get_disabled_enemies() -> Array:
	if _current_level.is_empty():
		return []
	
	return _current_level.get("disabled_enemies", [])


func should_enemy_spawn(enemy_id: String) -> bool:
	var enabled_enemies := get_enabled_enemies()
	var disabled_enemies := get_disabled_enemies()
	
	# If no restrictions, allow all
	if enabled_enemies.is_empty() and disabled_enemies.is_empty():
		return true
	
	# Check disabled list first
	if enemy_id in disabled_enemies:
		return false
	
	# If there's an enabled list, check it
	if not enabled_enemies.is_empty():
		return enemy_id in enabled_enemies
	
	return true


func get_current_level_info() -> Dictionary:
	return {
		"level_data": _current_level,
		"objectives": _objectives_tracker,
		"progress_summary": get_level_progress_summary()
	}


func _on_game_started() -> void:
	var selected_level := GameState.selected_level_id
	if not start_level(selected_level):
		push_warning("[LevelSystem] Failed to start level: " + selected_level)


func _on_game_over(survival_time: float) -> void:
	# Check if this was a level completion or failure
	if GameState.level_objectives_completed:
		# Success was already handled in _complete_level()
		return
	
	# Level was not completed - this is a failure
	var reason := "Time limit not reached"
	if not GameState.central_tower_alive:
		reason = "Central tower destroyed"
	
	level_failed.emit(reason)
	print("[LevelSystem] Level failed: %s" % reason)