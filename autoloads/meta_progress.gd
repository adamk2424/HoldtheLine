extends Node
## MetaProgress - Persistent between-run data.
## Tracks tech points, high scores, unlocks, and settings across game sessions.

const SAVE_PATH := "user://meta_progress.json"

# Persistent data
var high_scores: Array = []  # Array of {time: float, kills: int, date: String}
var total_games_played: int = 0
var total_enemies_killed: int = 0
var tech_points: int = 0
var permanent_upgrades: Dictionary = {}  # Between-run upgrades and level progression

# Settings
var master_volume: float = 1.0
var sfx_volume: float = 1.0
var music_volume: float = 0.4
var fullscreen: bool = true
var edge_pan_enabled: bool = true
var camera_speed: float = 20.0


func _ready() -> void:
	load_data()


func save_data() -> void:
	var data := {
		"high_scores": high_scores,
		"total_games_played": total_games_played,
		"total_enemies_killed": total_enemies_killed,
		"tech_points": tech_points,
		"permanent_upgrades": permanent_upgrades,
		"settings": {
			"master_volume": master_volume,
			"sfx_volume": sfx_volume,
			"music_volume": music_volume,
			"fullscreen": fullscreen,
			"edge_pan_enabled": edge_pan_enabled,
			"camera_speed": camera_speed
		}
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))


func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	if err != OK:
		push_warning("[MetaProgress] Failed to load save: %s" % json.get_error_message())
		return
	var data: Dictionary = json.data
	high_scores = data.get("high_scores", [])
	total_games_played = data.get("total_games_played", 0)
	total_enemies_killed = data.get("total_enemies_killed", 0)
	tech_points = data.get("tech_points", 0)
	permanent_upgrades = data.get("permanent_upgrades", {})
	var settings: Dictionary = data.get("settings", {})
	master_volume = settings.get("master_volume", 1.0)
	sfx_volume = settings.get("sfx_volume", 1.0)
	music_volume = settings.get("music_volume", 1.0)
	fullscreen = settings.get("fullscreen", true)
	edge_pan_enabled = settings.get("edge_pan_enabled", true)
	camera_speed = settings.get("camera_speed", 20.0)


func record_game_result(survival_time: float, kills: int) -> void:
	total_games_played += 1
	total_enemies_killed += kills
	
	# Calculate tech points earned
	var tech_earned := _calculate_tech_points(survival_time, kills)
	var item_multiplier := 1.0
	if ItemSystem.has_effect("tech_point_multiplier"):
		item_multiplier = ItemSystem.get_effect_value("tech_point_multiplier", 1.0)
	tech_earned = int(tech_earned * item_multiplier)
	
	tech_points += tech_earned
	
	var entry := {
		"time": survival_time,
		"kills": kills,
		"tech_points_earned": tech_earned,
		"date": Time.get_datetime_string_from_system()
	}
	high_scores.append(entry)
	high_scores.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["time"] > b["time"])
	if high_scores.size() > 10:
		high_scores.resize(10)
	
	print("[MetaProgress] Game completed: +%d tech points (%.1fx multiplier)" % [tech_earned, item_multiplier])
	save_data()


func _calculate_tech_points(survival_time: float, kills: int) -> int:
	# Base tech points: 1 per minute survived + 1 per 10 kills
	var time_points := int(survival_time / 60.0)
	var kill_points := int(kills / 10.0)
	
	# Bonus for milestones
	var milestone_bonus := 0
	if survival_time >= 1800:  # 30 minutes
		milestone_bonus += 20
	if survival_time >= 3600:  # 60 minutes
		milestone_bonus += 50
	if kills >= 1000:
		milestone_bonus += 25
	if kills >= 2000:
		milestone_bonus += 50
	
	# Boss kill bonus
	var boss_bonus := GameState.boss_kills * 10
	
	var total: int = max(1, time_points + kill_points + milestone_bonus + boss_bonus)
	return total


func get_best_time() -> float:
	var best := 0.0
	for entry: Dictionary in high_scores:
		best = max(best, entry.get("time", 0.0))
	return best
