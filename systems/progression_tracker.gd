extends Node
## ProgressionTracker - Tracks player progression across the level system
## Provides analytics and milestone detection for the progression experience

var _progression_data: Dictionary = {}
var _session_stats: Dictionary = {}

signal milestone_reached(type: String, data: Dictionary)
signal progression_updated(stats: Dictionary)


func _ready() -> void:
	GameBus.game_started.connect(_on_game_started)
	GameBus.game_over.connect(_on_game_over)
	LevelSystem.level_completed.connect(_on_level_completed)
	_load_progression_data()


func _load_progression_data() -> void:
	_progression_data = {
		"levels_completed_by_difficulty": {},
		"total_play_time": 0.0,
		"fastest_completions": {},
		"perfect_runs": [],  # Levels completed without losing any towers
		"challenge_streaks": {},
		"progression_milestones": []
	}
	
	# Load from MetaProgress if available
	if MetaProgress.permanent_upgrades.has("progression_data"):
		var saved_data: Dictionary = MetaProgress.permanent_upgrades["progression_data"]
		for key in saved_data:
			_progression_data[key] = saved_data[key]


func _save_progression_data() -> void:
	MetaProgress.permanent_upgrades["progression_data"] = _progression_data
	MetaProgress.save_data()


func _on_game_started() -> void:
	_session_stats.clear()
	_session_stats = {
		"session_start_time": Time.get_unix_time_from_system(),
		"levels_attempted": 0,
		"levels_completed": 0
	}


func _on_level_completed(level_id: String, rewards: Dictionary) -> void:
	_session_stats["levels_completed"] += 1
	
	var level_data := LevelSystem.get_level_data(level_id)
	var difficulty: String = level_data.get("difficulty", "easy")
	
	# Track completion by difficulty
	if not _progression_data["levels_completed_by_difficulty"].has(difficulty):
		_progression_data["levels_completed_by_difficulty"][difficulty] = 0
	_progression_data["levels_completed_by_difficulty"][difficulty] += 1
	
	# Track fastest completion times
	var completion_time: float = GameState.game_time
	var fastest_key := level_id + "_fastest"
	if not _progression_data["fastest_completions"].has(fastest_key) or completion_time < _progression_data["fastest_completions"][fastest_key]:
		_progression_data["fastest_completions"][fastest_key] = completion_time
		_check_speed_milestone(level_id, completion_time)
	
	# Check for perfect run (no tower losses)
	if GameState.towers_lost == 0:
		var perfect_key := level_id + "_perfect"
		if perfect_key not in _progression_data["perfect_runs"]:
			_progression_data["perfect_runs"].append(perfect_key)
			_check_perfect_run_milestone(level_id)
	
	# Check progression milestones
	_check_progression_milestones()
	
	_save_progression_data()
	progression_updated.emit(get_progression_summary())


func _on_game_over(survival_time: float) -> void:
	_progression_data["total_play_time"] += survival_time
	
	if GameState.selected_level_id != "":
		_session_stats["levels_attempted"] += 1
	
	_save_progression_data()


func _check_progression_milestones() -> void:
	# Check difficulty progression milestones
	var difficulties := ["easy", "medium", "hard", "extreme", "nightmare"]
	var completed_by_diff: Dictionary = _progression_data["levels_completed_by_difficulty"]
	
	for i in range(difficulties.size()):
		var diff: String = difficulties[i]
		var count: int = completed_by_diff.get(diff, 0)
		
		# Milestone: First completion in difficulty
		var first_milestone := "first_" + diff + "_completion"
		if count >= 1 and first_milestone not in _progression_data["progression_milestones"]:
			_progression_data["progression_milestones"].append(first_milestone)
			_trigger_milestone("difficulty_breakthrough", {"difficulty": diff, "type": "first_completion"})
		
		# Milestone: Mastery of difficulty (3+ completions)
		var mastery_milestone := diff + "_mastery"
		if count >= 3 and mastery_milestone not in _progression_data["progression_milestones"]:
			_progression_data["progression_milestones"].append(mastery_milestone)
			_trigger_milestone("difficulty_mastery", {"difficulty": diff})
	
	# Check total level completion milestones
	var total_completed := 0
	for diff in completed_by_diff:
		total_completed += completed_by_diff[diff]
	
	var completion_milestones := [5, 10, 25, 50, 100]
	for threshold in completion_milestones:
		var milestone_key := "completed_" + str(threshold) + "_levels"
		if total_completed >= threshold and milestone_key not in _progression_data["progression_milestones"]:
			_progression_data["progression_milestones"].append(milestone_key)
			_trigger_milestone("level_completion", {"count": threshold})


func _check_speed_milestone(level_id: String, completion_time: float) -> void:
	# Define speed thresholds for different level durations
	var level_data := LevelSystem.get_level_data(level_id)
	var target_duration: int = level_data.get("duration_seconds", 600)
	
	# Speed milestone if completed in less than 90% of target time
	var speed_threshold := target_duration * 0.9
	if completion_time <= speed_threshold:
		var milestone_key := "speed_run_" + level_id
		if milestone_key not in _progression_data["progression_milestones"]:
			_progression_data["progression_milestones"].append(milestone_key)
			_trigger_milestone("speed_completion", {"level_id": level_id, "time": completion_time, "threshold": speed_threshold})


func _check_perfect_run_milestone(level_id: String) -> void:
	var perfect_runs: Array = _progression_data["perfect_runs"]
	
	# Milestone for first perfect run
	if perfect_runs.size() == 1:
		_trigger_milestone("first_perfect_run", {"level_id": level_id})
	
	# Milestone for perfect run streak
	var perfect_streak_milestones := [5, 10, 25]
	for threshold in perfect_streak_milestones:
		if perfect_runs.size() >= threshold:
			var milestone_key := "perfect_streak_" + str(threshold)
			if milestone_key not in _progression_data["progression_milestones"]:
				_progression_data["progression_milestones"].append(milestone_key)
				_trigger_milestone("perfect_streak", {"count": threshold})


func _trigger_milestone(type: String, data: Dictionary) -> void:
	print("[ProgressionTracker] Milestone reached: %s - %s" % [type, data])
	milestone_reached.emit(type, data)
	GameBus.progression_milestone_reached.emit(type, data)


func get_progression_summary() -> Dictionary:
	var summary := {
		"total_levels_completed": 0,
		"levels_by_difficulty": {},
		"total_play_time_hours": _progression_data["total_play_time"] / 3600.0,
		"perfect_runs_count": _progression_data["perfect_runs"].size(),
		"milestones_reached": _progression_data["progression_milestones"].size(),
		"session_stats": _session_stats
	}
	
	# Calculate totals and organize by difficulty
	var completed_by_diff: Dictionary = _progression_data["levels_completed_by_difficulty"]
	for difficulty in completed_by_diff:
		var count: int = completed_by_diff[difficulty]
		summary["levels_by_difficulty"][difficulty] = count
		summary["total_levels_completed"] += count
	
	return summary


func get_level_completion_stats(level_id: String) -> Dictionary:
	var fastest_key := level_id + "_fastest"
	var perfect_key := level_id + "_perfect"
	
	return {
		"fastest_time": _progression_data["fastest_completions"].get(fastest_key, -1.0),
		"has_perfect_run": perfect_key in _progression_data["perfect_runs"],
		"completion_count": _get_level_completion_count(level_id)
	}


func _get_level_completion_count(level_id: String) -> int:
	# This would need to be enhanced to track individual level completions
	# For now, return estimated based on saved data
	var level_data := LevelSystem.get_level_data(level_id)
	var difficulty: String = level_data.get("difficulty", "easy")
	return _progression_data["levels_completed_by_difficulty"].get(difficulty, 0)


func get_unlock_requirements_progress(level_id: String) -> Dictionary:
	var level_data := LevelSystem.get_level_data(level_id)
	var requirements: Array = level_data.get("unlock_requirements", [])
	var completed_levels: Array = MetaProgress.permanent_upgrades.get("completed_levels", [])
	
	var progress := {
		"total_requirements": requirements.size(),
		"completed_requirements": 0,
		"missing_levels": []
	}
	
	for requirement in requirements:
		if requirement in completed_levels:
			progress["completed_requirements"] += 1
		else:
			progress["missing_levels"].append(requirement)
	
	return progress


func has_achievement(achievement_id: String) -> bool:
	var achievements: Array = MetaProgress.permanent_upgrades.get("unlocked_achievements", [])
	return achievement_id in achievements


func get_progression_insights() -> Array:
	var insights := []
	var summary := get_progression_summary()
	
	# Difficulty progression insights
	var difficulties := ["easy", "medium", "hard", "extreme", "nightmare"]
	var current_difficulty := "easy"
	
	for difficulty in difficulties:
		if summary["levels_by_difficulty"].get(difficulty, 0) >= 3:
			current_difficulty = difficulty
	
	if current_difficulty != "nightmare":
		var next_diff_index := difficulties.find(current_difficulty) + 1
		if next_diff_index < difficulties.size():
			insights.append("Ready to try %s difficulty levels!" % difficulties[next_diff_index])
	
	# Speed run opportunities
	if summary["total_levels_completed"] >= 5 and _progression_data["fastest_completions"].is_empty():
		insights.append("Try completing levels faster for speed run achievements!")
	
	# Perfect run encouragement
	if summary["perfect_runs_count"] == 0 and summary["total_levels_completed"] >= 3:
		insights.append("Challenge yourself with a perfect run - complete a level without losing any towers!")
	
	return insights