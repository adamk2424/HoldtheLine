extends Node
## AchievementSystem - Tracks and manages player achievements
## Integrates with progression and rewards systems

const ACHIEVEMENT_DATA_PATH := "res://data/achievements.json"

var _achievements_data: Dictionary = {}
var _session_tracking: Dictionary = {}
var _unlocked_achievements: Array = []

signal achievement_unlocked(achievement_id: String, achievement_data: Dictionary)
signal achievement_progress_updated(achievement_id: String, progress: Dictionary)


func _ready() -> void:
	_load_achievement_data()
	_load_unlocked_achievements()
	_initialize_session_tracking()
	
	# Connect to game events
	GameBus.game_started.connect(_on_game_started)
	GameBus.game_over.connect(_on_game_over)
	GameBus.level_completed.connect(_on_level_completed)
	GameBus.progression_milestone_reached.connect(_on_milestone_reached)


func _load_achievement_data() -> void:
	if not FileAccess.file_exists(ACHIEVEMENT_DATA_PATH):
		push_error("[AchievementSystem] Achievement data not found: " + ACHIEVEMENT_DATA_PATH)
		return
	
	var file := FileAccess.open(ACHIEVEMENT_DATA_PATH, FileAccess.READ)
	if not file:
		push_error("[AchievementSystem] Cannot open achievement data file")
		return
	
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	
	if err != OK:
		push_error("[AchievementSystem] Invalid JSON in achievement data")
		return
	
	_achievements_data = json.data
	print("[AchievementSystem] Loaded %d achievements" % _achievements_data.get("achievements", []).size())


func _load_unlocked_achievements() -> void:
	_unlocked_achievements = MetaProgress.permanent_upgrades.get("unlocked_achievements", [])


func _initialize_session_tracking() -> void:
	_session_tracking = {
		"levels_completed": 0,
		"enemies_killed": 0,
		"buildings_built": 0,
		"perfect_runs": 0,
		"session_start_time": Time.get_unix_time_from_system()
	}


func _on_game_started() -> void:
	_session_tracking["levels_completed"] = 0
	_session_tracking["enemies_killed"] = 0
	_session_tracking["buildings_built"] = 0


func _on_level_completed(level_id: String, rewards: Dictionary) -> void:
	_session_tracking["levels_completed"] += 1
	
	# Check for perfect run
	if GameState.towers_lost == 0:
		_session_tracking["perfect_runs"] += 1
	
	# Check level-specific achievements
	_check_level_completion_achievements(level_id)
	
	# Check progression achievements
	_check_progression_achievements()


func _on_game_over(survival_time: float) -> void:
	_session_tracking["enemies_killed"] = GameState.total_enemies_killed
	_session_tracking["buildings_built"] = GameState.total_buildings_built
	
	# Check survival-based achievements
	_check_survival_achievements(survival_time)
	
	# Check combat achievements
	_check_combat_achievements()
	
	# Check building achievements
	_check_building_achievements()


func _on_milestone_reached(milestone_type: String, data: Dictionary) -> void:
	_check_milestone_achievements(milestone_type, data)


func _check_level_completion_achievements(level_id: String) -> void:
	var achievements: Array = _achievements_data.get("achievements", [])
	
	for achievement: Dictionary in achievements:
		if _is_achievement_unlocked(achievement.get("id", "")):
			continue
		
		var requirements: Dictionary = achievement.get("requirements", {})
		var req_type: String = requirements.get("type", "")
		
		match req_type:
			"level_completion":
				var required_count: int = requirements.get("count", 1)
				var total_completed := _get_total_completed_levels()
				if total_completed >= required_count:
					_unlock_achievement(achievement)
			
			"specific_level":
				var required_level: String = requirements.get("level_id", "")
				if level_id == required_level:
					_unlock_achievement(achievement)
			
			"specific_levels":
				var required_levels: Array = requirements.get("level_ids", [])
				var completed_levels: Array = MetaProgress.permanent_upgrades.get("completed_levels", [])
				var all_completed := true
				for req_level: String in required_levels:
					if req_level not in completed_levels:
						all_completed = false
						break
				if all_completed:
					_unlock_achievement(achievement)
			
			"difficulty_completion":
				var required_difficulty: String = requirements.get("difficulty", "")
				var level_data := LevelSystem.get_level_data(level_id)
				var level_difficulty: String = level_data.get("difficulty", "")
				if level_difficulty == required_difficulty:
					_unlock_achievement(achievement)
			
			"perfect_run":
				var required_count: int = requirements.get("count", 1)
				if _session_tracking["perfect_runs"] >= required_count:
					_unlock_achievement(achievement)


func _check_survival_achievements(survival_time: float) -> void:
	var achievements: Array = _achievements_data.get("achievements", [])
	
	for achievement: Dictionary in achievements:
		if _is_achievement_unlocked(achievement.get("id", "")):
			continue
		
		var requirements: Dictionary = achievement.get("requirements", {})
		var req_type: String = requirements.get("type", "")
		
		if req_type == "endless_survival":
			var required_level: String = requirements.get("level_id", "")
			var required_minutes: int = requirements.get("time_minutes", 60)
			
			if GameState.selected_level_id == required_level and survival_time >= (required_minutes * 60):
				_unlock_achievement(achievement)


func _check_combat_achievements() -> void:
	var achievements: Array = _achievements_data.get("achievements", [])
	
	for achievement: Dictionary in achievements:
		if _is_achievement_unlocked(achievement.get("id", "")):
			continue
		
		var requirements: Dictionary = achievement.get("requirements", {})
		var req_type: String = requirements.get("type", "")
		
		match req_type:
			"kills_in_game":
				var required_count: int = requirements.get("count", 1000)
				if GameState.total_enemies_killed >= required_count:
					_unlock_achievement(achievement)


func _check_building_achievements() -> void:
	var achievements: Array = _achievements_data.get("achievements", [])
	
	for achievement: Dictionary in achievements:
		if _is_achievement_unlocked(achievement.get("id", "")):
			continue
		
		var requirements: Dictionary = achievement.get("requirements", {})
		var req_type: String = requirements.get("type", "")
		
		if req_type == "buildings_built":
			var required_count: int = requirements.get("count", 100)
			if GameState.total_buildings_built >= required_count:
				_unlock_achievement(achievement)


func _check_progression_achievements() -> void:
	var achievements: Array = _achievements_data.get("achievements", [])
	
	for achievement: Dictionary in achievements:
		if _is_achievement_unlocked(achievement.get("id", "")):
			continue
		
		var requirements: Dictionary = achievement.get("requirements", {})
		var req_type: String = requirements.get("type", "")
		
		match req_type:
			"total_tech_points":
				var required_count: int = requirements.get("count", 1000)
				if MetaProgress.tech_points >= required_count:
					_unlock_achievement(achievement)
			
			"campaign_complete":
				var campaign_levels := [
					"tutorial", "outpost", "supply_depot", "mining_station", 
					"borderlands", "siege_point", "wasteland", "hive_approach", 
					"sky_fortress", "deep_tunnels", "core_breach", "nexus_prime"
				]
				var completed_levels: Array = MetaProgress.permanent_upgrades.get("completed_levels", [])
				var campaign_complete := true
				for level_id: String in campaign_levels:
					if level_id not in completed_levels:
						campaign_complete = false
						break
				if campaign_complete:
					_unlock_achievement(achievement)


func _check_milestone_achievements(milestone_type: String, data: Dictionary) -> void:
	var achievements: Array = _achievements_data.get("achievements", [])
	
	for achievement: Dictionary in achievements:
		if _is_achievement_unlocked(achievement.get("id", "")):
			continue
		
		var requirements: Dictionary = achievement.get("requirements", {})
		var req_type: String = requirements.get("type", "")
		
		match req_type:
			"speed_completion":
				if milestone_type == "speed_completion":
					var threshold_percent: float = requirements.get("threshold_percent", 80.0) / 100.0
					var level_data := LevelSystem.get_level_data(data.get("level_id", ""))
					var target_time: float = level_data.get("duration_seconds", 600)
					var completion_time: float = data.get("time", 0.0)
					if completion_time <= (target_time * threshold_percent):
						_unlock_achievement(achievement)


func _unlock_achievement(achievement: Dictionary) -> void:
	var achievement_id: String = achievement.get("id", "")
	
	if achievement_id in _unlocked_achievements:
		return  # Already unlocked
	
	_unlocked_achievements.append(achievement_id)
	
	# Update persistent data
	if not MetaProgress.permanent_upgrades.has("unlocked_achievements"):
		MetaProgress.permanent_upgrades["unlocked_achievements"] = []
	MetaProgress.permanent_upgrades["unlocked_achievements"] = _unlocked_achievements
	
	# Award rewards
	var rewards: Dictionary = achievement.get("rewards", {})
	_award_achievement_rewards(rewards)
	
	# Save progress
	MetaProgress.save_data()
	
	# Notify systems
	achievement_unlocked.emit(achievement_id, achievement)
	
	print("[AchievementSystem] Achievement unlocked: %s - %s" % [achievement.get("name", ""), achievement.get("description", "")])


func _award_achievement_rewards(rewards: Dictionary) -> void:
	var tech_points: int = rewards.get("tech_points", 0)
	if tech_points > 0:
		MetaProgress.tech_points += tech_points
		print("[AchievementSystem] Awarded %d tech points" % tech_points)
	
	var items: Array = rewards.get("items", [])
	for item_id: String in items:
		_unlock_item(item_id)


func _unlock_item(item_id: String) -> void:
	if not MetaProgress.permanent_upgrades.has("unlocked_items"):
		MetaProgress.permanent_upgrades["unlocked_items"] = []
	
	var unlocked_items: Array = MetaProgress.permanent_upgrades["unlocked_items"]
	if item_id not in unlocked_items:
		unlocked_items.append(item_id)
		print("[AchievementSystem] Item unlocked: %s" % item_id)


func _is_achievement_unlocked(achievement_id: String) -> bool:
	return achievement_id in _unlocked_achievements


func get_achievement_data(achievement_id: String) -> Dictionary:
	var achievements: Array = _achievements_data.get("achievements", [])
	for achievement: Dictionary in achievements:
		if achievement.get("id", "") == achievement_id:
			return achievement
	return {}


func get_achievement_progress(achievement_id: String) -> Dictionary:
	var achievement := get_achievement_data(achievement_id)
	if achievement.is_empty():
		return {}
	
	var requirements: Dictionary = achievement.get("requirements", {})
	var req_type: String = requirements.get("type", "")
	var progress := {"current": 0, "required": 1, "percentage": 0.0}
	
	match req_type:
		"level_completion":
			progress["required"] = requirements.get("count", 1)
			progress["current"] = _get_total_completed_levels()
		
		"total_tech_points":
			progress["required"] = requirements.get("count", 1000)
			progress["current"] = MetaProgress.tech_points
		
		"perfect_run":
			progress["required"] = requirements.get("count", 1)
			progress["current"] = _get_total_perfect_runs()
	
	progress["percentage"] = min(100.0, (float(progress["current"]) / float(progress["required"])) * 100.0)
	return progress


func get_unlocked_achievements() -> Array:
	return _unlocked_achievements.duplicate()


func get_achievement_summary() -> Dictionary:
	var achievements: Array = _achievements_data.get("achievements", [])
	var unlocked_count := _unlocked_achievements.size()
	
	return {
		"total_achievements": achievements.size(),
		"unlocked_count": unlocked_count,
		"percentage": (float(unlocked_count) / float(achievements.size())) * 100.0 if achievements.size() > 0 else 0.0,
		"recent_unlocks": _get_recent_unlocks()
	}


func _get_recent_unlocks() -> Array:
	# Return the last 3 unlocked achievements
	var recent := []
	var recent_count: int = min(3, _unlocked_achievements.size())
	for i in range(recent_count):
		var achievement_id: String = _unlocked_achievements[_unlocked_achievements.size() - 1 - i]
		recent.append(get_achievement_data(achievement_id))
	return recent


func _get_total_completed_levels() -> int:
	var completed_levels: Array = MetaProgress.permanent_upgrades.get("completed_levels", [])
	return completed_levels.size()


func _get_total_perfect_runs() -> int:
	# This would need to be tracked more precisely in the progression system
	# For now, return an estimated count
	var count: int = _session_tracking.get("perfect_runs", 0)
	return count