extends Control
## ProgressionDashboard - Shows overall player progression across the level system
## Displays achievements, completion stats, and progression insights

var _main_container: VBoxContainer
var _stats_panel: Control
var _achievements_panel: Control
var _insights_panel: Control

var _completion_chart: Control
var _achievement_list: VBoxContainer
var _stats_labels: Dictionary = {}


func _ready() -> void:
	_build_ui()
	_update_dashboard()
	
	# Connect to progression updates
	if has_node("/root/ProgressionTracker"):
		var tracker = get_node("/root/ProgressionTracker")
		tracker.progression_updated.connect(_on_progression_updated)
	
	if has_node("/root/AchievementSystem"):
		var achievement_sys = get_node("/root/AchievementSystem")
		achievement_sys.achievement_unlocked.connect(_on_achievement_unlocked)


func _build_ui() -> void:
	name = "ProgressionDashboard"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Background
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.08, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Main container with scroll
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.add_theme_constant_override("margin_left", 50)
	scroll.add_theme_constant_override("margin_right", 50)
	scroll.add_theme_constant_override("margin_top", 30)
	scroll.add_theme_constant_override("margin_bottom", 30)
	add_child(scroll)

	_main_container = VBoxContainer.new()
	_main_container.add_theme_constant_override("separation", 30)
	scroll.add_child(_main_container)

	# Title
	var title := Label.new()
	title.text = "PROGRESSION DASHBOARD"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_main_container.add_child(title)

	# Create main sections
	var sections_hbox := HBoxContainer.new()
	sections_hbox.add_theme_constant_override("separation", 20)
	_main_container.add_child(sections_hbox)

	# Left column - Stats and Completion
	var left_column := VBoxContainer.new()
	left_column.custom_minimum_size = Vector2(400, 0)
	left_column.add_theme_constant_override("separation", 15)
	sections_hbox.add_child(left_column)

	_stats_panel = _create_stats_panel()
	left_column.add_child(_stats_panel)

	_completion_chart = _create_completion_chart()
	left_column.add_child(_completion_chart)

	# Right column - Achievements and Insights
	var right_column := VBoxContainer.new()
	right_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_column.add_theme_constant_override("separation", 15)
	sections_hbox.add_child(right_column)

	_achievements_panel = _create_achievements_panel()
	right_column.add_child(_achievements_panel)

	_insights_panel = _create_insights_panel()
	right_column.add_child(_insights_panel)


func _create_stats_panel() -> Control:
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(0, 200)
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.9)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "📊 PROGRESSION STATS"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color.CYAN)
	vbox.add_child(title)

	# Stats grid
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 5)
	vbox.add_child(grid)

	_stats_labels["levels_completed"] = _create_stat_row(grid, "Levels Completed:", "0")
	_stats_labels["tech_points"] = _create_stat_row(grid, "Tech Points:", "0")
	_stats_labels["play_time"] = _create_stat_row(grid, "Total Play Time:", "0h")
	_stats_labels["achievements"] = _create_stat_row(grid, "Achievements:", "0/0")

	return panel


func _create_completion_chart() -> Control:
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(0, 250)
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.9)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "🎯 DIFFICULTY PROGRESSION"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color.CYAN)
	vbox.add_child(title)

	# Difficulty bars will be added in update_dashboard
	_stats_labels["difficulty_chart"] = vbox

	return panel


func _create_achievements_panel() -> Control:
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(0, 300)
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.9)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "🏆 RECENT ACHIEVEMENTS"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color.CYAN)
	vbox.add_child(title)

	# Scrollable achievement list
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_achievement_list = VBoxContainer.new()
	_achievement_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_achievement_list)

	return panel


func _create_insights_panel() -> Control:
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(0, 200)
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.9)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "💡 PROGRESSION INSIGHTS"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color.CYAN)
	vbox.add_child(title)

	_stats_labels["insights"] = vbox

	return panel


func _create_stat_row(parent: GridContainer, label_text: String, value_text: String) -> Label:
	var label := Label.new()
	label.text = label_text
	label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	parent.add_child(label)

	var value := Label.new()
	value.text = value_text
	value.add_theme_color_override("font_color", Color.WHITE)
	value.add_theme_font_size_override("font_size", 14)
	parent.add_child(value)

	return value


func _update_dashboard() -> void:
	# Get progression data
	var summary := {}
	if has_node("/root/ProgressionTracker"):
		var tracker = get_node("/root/ProgressionTracker")
		summary = tracker.get_progression_summary()
	
	# Update basic stats
	_stats_labels["levels_completed"].text = str(summary.get("total_levels_completed", 0))
	_stats_labels["tech_points"].text = str(MetaProgress.tech_points)
	
	var play_hours: float = summary.get("total_play_time_hours", 0.0)
	_stats_labels["play_time"].text = "%.1fh" % play_hours
	
	# Update achievements
	var achievement_summary := {}
	if has_node("/root/AchievementSystem"):
		var achievement_sys = get_node("/root/AchievementSystem")
		achievement_summary = achievement_sys.get_achievement_summary()
	
	var ach_unlocked: int = achievement_summary.get("unlocked_count", 0)
	var ach_total: int = achievement_summary.get("total_achievements", 0)
	_stats_labels["achievements"].text = "%d/%d (%.0f%%)" % [ach_unlocked, ach_total, achievement_summary.get("percentage", 0)]
	
	# Update difficulty chart
	_update_difficulty_chart(summary.get("levels_by_difficulty", {}))
	
	# Update achievements list
	_update_achievements_list(achievement_summary.get("recent_unlocks", []))
	
	# Update insights
	_update_insights()


func _update_difficulty_chart(levels_by_difficulty: Dictionary) -> void:
	var chart_container = _stats_labels.get("difficulty_chart", null)
	if not chart_container:
		return
	
	# Clear existing difficulty bars
	for child in chart_container.get_children():
		if child.has_method("set_text") and child.text.contains("▰"):
			child.queue_free()
	
	var difficulties := ["easy", "medium", "hard", "extreme", "nightmare"]
	var difficulty_colors := {
		"easy": Color.GREEN,
		"medium": Color.YELLOW,
		"hard": Color.ORANGE,
		"extreme": Color.RED,
		"nightmare": Color.MAGENTA
	}
	
	for difficulty in difficulties:
		var count: int = levels_by_difficulty.get(difficulty, 0)
		var hbox := HBoxContainer.new()
		chart_container.add_child(hbox)
		
		var label := Label.new()
		label.text = difficulty.capitalize() + ":"
		label.custom_minimum_size = Vector2(80, 0)
		label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
		hbox.add_child(label)
		
		var bar := Label.new()
		var bar_text := ""
		for i in range(count):
			bar_text += "▰"
		for i in range(max(0, 10 - count)):
			bar_text += "▱"
		bar.text = bar_text + " " + str(count)
		bar.add_theme_color_override("font_color", difficulty_colors[difficulty])
		hbox.add_child(bar)


func _update_achievements_list(recent_achievements: Array) -> void:
	# Clear existing achievement items
	for child in _achievement_list.get_children():
		child.queue_free()
	
	if recent_achievements.is_empty():
		var placeholder := Label.new()
		placeholder.text = "Complete levels to unlock achievements!"
		placeholder.add_theme_color_override("font_color", Color.GRAY)
		_achievement_list.add_child(placeholder)
		return
	
	for achievement: Dictionary in recent_achievements:
		var item_panel := Panel.new()
		item_panel.custom_minimum_size = Vector2(0, 60)
		
		var item_style := StyleBoxFlat.new()
		item_style.bg_color = Color(0.15, 0.15, 0.2, 0.8)
		item_style.corner_radius_top_left = 4
		item_style.corner_radius_top_right = 4
		item_style.corner_radius_bottom_left = 4
		item_style.corner_radius_bottom_right = 4
		item_panel.add_theme_stylebox_override("panel", item_style)
		
		var margin := MarginContainer.new()
		margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		margin.add_theme_constant_override("margin_left", 10)
		margin.add_theme_constant_override("margin_right", 10)
		margin.add_theme_constant_override("margin_top", 8)
		margin.add_theme_constant_override("margin_bottom", 8)
		item_panel.add_child(margin)
		
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		margin.add_child(hbox)
		
		var icon := Label.new()
		icon.text = achievement.get("icon", "🏆")
		icon.add_theme_font_size_override("font_size", 24)
		hbox.add_child(icon)
		
		var vbox := VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(vbox)
		
		var name_label := Label.new()
		name_label.text = achievement.get("name", "Achievement")
		name_label.add_theme_color_override("font_color", Color.YELLOW)
		name_label.add_theme_font_size_override("font_size", 14)
		vbox.add_child(name_label)
		
		var desc_label := Label.new()
		desc_label.text = achievement.get("description", "")
		desc_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
		desc_label.add_theme_font_size_override("font_size", 12)
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(desc_label)
		
		_achievement_list.add_child(item_panel)


func _update_insights() -> void:
	var insights_container = _stats_labels.get("insights", null)
	if not insights_container:
		return
	
	# Clear existing insights
	for child in insights_container.get_children():
		if child.has_method("set_text") and not child.text.contains("💡"):
			child.queue_free()
	
	var insights := []
	if has_node("/root/ProgressionTracker"):
		var tracker = get_node("/root/ProgressionTracker")
		insights = tracker.get_progression_insights()
	
	if insights.is_empty():
		var placeholder := Label.new()
		placeholder.text = "Keep playing to unlock personalized insights!"
		placeholder.add_theme_color_override("font_color", Color.GRAY)
		placeholder.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		insights_container.add_child(placeholder)
		return
	
	for insight: String in insights:
		var insight_label := Label.new()
		insight_label.text = "• " + insight
		insight_label.add_theme_color_override("font_color", Color.WHITE)
		insight_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		insights_container.add_child(insight_label)


func _on_progression_updated(stats: Dictionary) -> void:
	_update_dashboard()


func _on_achievement_unlocked(achievement_id: String, achievement_data: Dictionary) -> void:
	_update_dashboard()
	
	# Show achievement notification
	_show_achievement_notification(achievement_data)


func _show_achievement_notification(achievement: Dictionary) -> void:
	# Create a temporary notification overlay
	var notification := Panel.new()
	notification.custom_minimum_size = Vector2(400, 100)
	notification.set_anchors_preset(Control.PRESET_CENTER)
	notification.offset_left = -200
	notification.offset_right = 200
	notification.offset_top = -50
	notification.offset_bottom = 50
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.5, 0.2, 0.9)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	notification.add_theme_stylebox_override("panel", style)
	
	var label := Label.new()
	label.text = "🏆 ACHIEVEMENT UNLOCKED!\n%s" % achievement.get("name", "")
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_font_size_override("font_size", 16)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	notification.add_child(label)
	
	add_child(notification)
	
	# Auto-remove after 3 seconds
	var timer := Timer.new()
	timer.wait_time = 3.0
	timer.one_shot = true
	timer.timeout.connect(func(): notification.queue_free())
	add_child(timer)
	timer.start()