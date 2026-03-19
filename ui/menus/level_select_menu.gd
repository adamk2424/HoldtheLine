extends Control
## LevelSelectMenu - Interface for choosing levels in the progression system.
## Shows level cards with difficulty, rewards, and unlock status.

const LEVEL_DATA_PATH := "res://data/levels.json"

var _levels_data: Dictionary = {}
var _level_cards: Array = []
var _scroll_container: ScrollContainer
var _grid_container: GridContainer
var _back_button: Button
var _filter_container: HBoxContainer
var _difficulty_filter: OptionButton
var _search_field: LineEdit
var _selected_level: String = ""

# UI References
var _level_detail_panel: Control
var _detail_title: Label
var _detail_description: Label
var _detail_objective: Label
var _detail_difficulty: Label
var _detail_rewards: Label
var _start_button: Button

signal level_selected(level_id: String)
signal back_pressed


func _ready() -> void:
	_load_level_data()
	_build_ui()
	_populate_levels()


func _load_level_data() -> void:
	if not FileAccess.file_exists(LEVEL_DATA_PATH):
		push_error("[LevelSelect] Level data not found: " + LEVEL_DATA_PATH)
		return
	
	var file := FileAccess.open(LEVEL_DATA_PATH, FileAccess.READ)
	if not file:
		push_error("[LevelSelect] Cannot open level data file")
		return
	
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	
	if err != OK:
		push_error("[LevelSelect] Invalid JSON in level data")
		return
	
	_levels_data = json.data


func _build_ui() -> void:
	name = "LevelSelectMenu"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Background
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.08, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Main horizontal split
	var main_hbox := HBoxContainer.new()
	main_hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_hbox.add_theme_constant_override("separation", 20)
	add_child(main_hbox)

	# Left side - Level list
	var left_panel := VBoxContainer.new()
	left_panel.custom_minimum_size = Vector2(700, 0)
	left_panel.add_theme_constant_override("separation", 10)
	main_hbox.add_child(left_panel)

	# Header with filters and back button
	var header := HBoxContainer.new()
	left_panel.add_child(header)

	_back_button = Button.new()
	_back_button.text = "◄ Back"
	_back_button.custom_minimum_size = Vector2(120, 40)
	_back_button.pressed.connect(_on_back_pressed)
	header.add_child(_back_button)

	var title := Label.new()
	title.text = "SELECT LEVEL"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color.WHITE)
	header.add_child(title)

	header.add_child(Control.new())  # Spacer

	# Filter controls
	_filter_container = HBoxContainer.new()
	_filter_container.add_theme_constant_override("separation", 10)
	header.add_child(_filter_container)

	var filter_label := Label.new()
	filter_label.text = "Filter:"
	filter_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	_filter_container.add_child(filter_label)

	_difficulty_filter = OptionButton.new()
	_difficulty_filter.add_item("All Difficulties")
	_difficulty_filter.add_item("Easy")
	_difficulty_filter.add_item("Medium") 
	_difficulty_filter.add_item("Hard")
	_difficulty_filter.add_item("Extreme")
	_difficulty_filter.add_item("Nightmare")
	_difficulty_filter.add_item("Endless")
	_difficulty_filter.item_selected.connect(_on_difficulty_filter_changed)
	_filter_container.add_child(_difficulty_filter)

	_search_field = LineEdit.new()
	_search_field.placeholder_text = "Search levels..."
	_search_field.custom_minimum_size = Vector2(200, 0)
	_search_field.text_changed.connect(_on_search_changed)
	_filter_container.add_child(_search_field)

	# Scrollable level grid
	_scroll_container = ScrollContainer.new()
	_scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_panel.add_child(_scroll_container)

	_grid_container = GridContainer.new()
	_grid_container.columns = 2
	_grid_container.add_theme_constant_override("h_separation", 15)
	_grid_container.add_theme_constant_override("v_separation", 15)
	_scroll_container.add_child(_grid_container)

	# Right side - Level details
	var right_panel := VBoxContainer.new()
	right_panel.custom_minimum_size = Vector2(400, 0)
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.add_theme_constant_override("separation", 15)
	main_hbox.add_child(right_panel)

	_level_detail_panel = _create_detail_panel()
	right_panel.add_child(_level_detail_panel)


func _create_detail_panel() -> Control:
	var panel := Panel.new()
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.15, 0.8)
	bg_style.corner_radius_top_left = 8
	bg_style.corner_radius_top_right = 8
	bg_style.corner_radius_bottom_left = 8
	bg_style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", bg_style)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	# Title
	_detail_title = Label.new()
	_detail_title.text = "Select a level"
	_detail_title.add_theme_font_size_override("font_size", 20)
	_detail_title.add_theme_color_override("font_color", Color.WHITE)
	_detail_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_detail_title)

	# Description
	_detail_description = Label.new()
	_detail_description.text = "Choose a level from the list to see details."
	_detail_description.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	_detail_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_detail_description)

	# Objective
	_detail_objective = Label.new()
	_detail_objective.add_theme_color_override("font_color", Color.CYAN)
	_detail_objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_detail_objective)

	# Difficulty
	_detail_difficulty = Label.new()
	_detail_difficulty.add_theme_font_size_override("font_size", 16)
	vbox.add_child(_detail_difficulty)

	# Rewards
	_detail_rewards = Label.new()
	_detail_rewards.add_theme_color_override("font_color", Color.YELLOW)
	_detail_rewards.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_detail_rewards)

	vbox.add_child(Control.new())  # Spacer

	# Start button
	_start_button = Button.new()
	_start_button.text = "START LEVEL"
	_start_button.custom_minimum_size = Vector2(0, 50)
	_start_button.disabled = true
	_start_button.pressed.connect(_on_start_level)
	vbox.add_child(_start_button)

	return panel


func _populate_levels() -> void:
	# Clear existing cards
	for card in _level_cards:
		if is_instance_valid(card):
			card.queue_free()
	_level_cards.clear()

	var levels: Array = _levels_data.get("levels", [])
	
	for level_data: Dictionary in levels:
		var card := _create_level_card(level_data)
		_level_cards.append(card)
		_grid_container.add_child(card)


func _create_level_card(level_data: Dictionary) -> Control:
	var card := Panel.new()
	card.custom_minimum_size = Vector2(320, 120)
	
	# Card styling based on unlock status and difficulty
	var is_unlocked := _is_level_unlocked(level_data)
	var difficulty: String = level_data.get("difficulty", "easy")
	
	var card_style := StyleBoxFlat.new()
	if is_unlocked:
		card_style.bg_color = _get_difficulty_color(difficulty)
	else:
		card_style.bg_color = Color(0.2, 0.2, 0.2, 0.5)
	
	card_style.corner_radius_top_left = 6
	card_style.corner_radius_top_right = 6
	card_style.corner_radius_bottom_left = 6
	card_style.corner_radius_bottom_right = 6
	card.add_theme_stylebox_override("panel", card_style)

	# Make clickable
	var button := Button.new()
	button.flat = true
	button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.disabled = not is_unlocked
	button.pressed.connect(_on_level_card_clicked.bind(level_data.get("id", "")))
	card.add_child(button)

	# Card content
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vbox)

	# Level name
	var name_label := Label.new()
	name_label.text = level_data.get("name", "Unknown Level")
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color.WHITE if is_unlocked else Color.GRAY)
	vbox.add_child(name_label)

	# Difficulty and duration
	var info_hbox := HBoxContainer.new()
	vbox.add_child(info_hbox)

	var difficulty_label := Label.new()
	difficulty_label.text = difficulty.capitalize()
	difficulty_label.add_theme_font_size_override("font_size", 12)
	difficulty_label.add_theme_color_override("font_color", _get_difficulty_text_color(difficulty))
	info_hbox.add_child(difficulty_label)

	info_hbox.add_child(Control.new())  # Spacer

	var duration := level_data.get("duration_seconds", 0)
	var duration_label := Label.new()
	if duration > 0:
		var minutes := duration / 60
		duration_label.text = "%d min" % minutes
	else:
		duration_label.text = "Endless"
	duration_label.add_theme_font_size_override("font_size", 12)
	duration_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	info_hbox.add_child(duration_label)

	# Description (truncated)
	var desc_label := Label.new()
	var description: String = level_data.get("description", "")
	if description.length() > 80:
		description = description.substr(0, 77) + "..."
	desc_label.text = description
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", Color.LIGHT_GRAY if is_unlocked else Color.DIM_GRAY)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)

	# Lock overlay for locked levels
	if not is_unlocked:
		var lock_icon := Label.new()
		lock_icon.text = "🔒"
		lock_icon.add_theme_font_size_override("font_size", 24)
		lock_icon.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
		lock_icon.offset_left = -40
		lock_icon.offset_top = -12
		lock_icon.offset_right = -16
		lock_icon.offset_bottom = 12
		card.add_child(lock_icon)

	return card


func _is_level_unlocked(level_data: Dictionary) -> bool:
	var level_id: String = level_data.get("id", "")
	return LevelSystem.is_level_unlocked(level_id)


func _get_difficulty_color(difficulty: String) -> Color:
	match difficulty.to_lower():
		"easy": return Color(0.2, 0.6, 0.2, 0.3)
		"medium": return Color(0.6, 0.6, 0.2, 0.3)
		"hard": return Color(0.6, 0.3, 0.1, 0.3)
		"extreme": return Color(0.6, 0.1, 0.1, 0.3)
		"nightmare": return Color(0.4, 0.1, 0.4, 0.3)
		"endless": return Color(0.1, 0.1, 0.6, 0.3)
		_: return Color(0.3, 0.3, 0.3, 0.3)


func _get_difficulty_text_color(difficulty: String) -> Color:
	match difficulty.to_lower():
		"easy": return Color(0.5, 1.0, 0.5)
		"medium": return Color(1.0, 1.0, 0.5)
		"hard": return Color(1.0, 0.7, 0.3)
		"extreme": return Color(1.0, 0.3, 0.3)
		"nightmare": return Color(1.0, 0.3, 1.0)
		"endless": return Color(0.5, 0.5, 1.0)
		_: return Color.GRAY


func _update_detail_panel(level_data: Dictionary) -> void:
	_detail_title.text = level_data.get("name", "Unknown Level")
	_detail_description.text = level_data.get("description", "No description available.")
	_detail_objective.text = "Objective: " + level_data.get("objective", "Survive")
	
	var difficulty: String = level_data.get("difficulty", "easy")
	_detail_difficulty.text = "Difficulty: " + difficulty.capitalize()
	_detail_difficulty.add_theme_color_override("font_color", _get_difficulty_text_color(difficulty))
	
	# Format rewards
	var rewards: Dictionary = level_data.get("rewards", {})
	var reward_text := "Rewards: "
	var tech_points := rewards.get("tech_points", 0)
	if tech_points > 0:
		reward_text += "%d Tech Points" % tech_points
	
	var unlocks: Array = rewards.get("unlocks", [])
	if not unlocks.is_empty():
		if tech_points > 0:
			reward_text += ", "
		reward_text += "Unlocks: " + ", ".join(unlocks)
	
	_detail_rewards.text = reward_text
	
	var is_unlocked := _is_level_unlocked(level_data)
	_start_button.disabled = not is_unlocked
	if not is_unlocked:
		_start_button.text = "LOCKED"
	else:
		_start_button.text = "START LEVEL"


func _on_level_card_clicked(level_id: String) -> void:
	_selected_level = level_id
	
	# Find level data
	var levels: Array = _levels_data.get("levels", [])
	for level_data: Dictionary in levels:
		if level_data.get("id", "") == level_id:
			_update_detail_panel(level_data)
			break


func _on_start_level() -> void:
	if _selected_level.is_empty():
		return
	
	level_selected.emit(_selected_level)


func _on_back_pressed() -> void:
	back_pressed.emit()


func _on_difficulty_filter_changed(index: int) -> void:
	_filter_levels()


func _on_search_changed(new_text: String) -> void:
	_filter_levels()


func _filter_levels() -> void:
	var search_term := _search_field.text.to_lower()
	var difficulty_filter := ""
	
	if _difficulty_filter.selected > 0:
		difficulty_filter = _difficulty_filter.get_item_text(_difficulty_filter.selected).to_lower()
	
	for i in range(_level_cards.size()):
		var card := _level_cards[i]
		if not is_instance_valid(card):
			continue
		
		var levels: Array = _levels_data.get("levels", [])
		if i >= levels.size():
			continue
		
		var level_data: Dictionary = levels[i]
		var show_card := true
		
		# Search filter
		if not search_term.is_empty():
			var name: String = level_data.get("name", "").to_lower()
			var desc: String = level_data.get("description", "").to_lower()
			if not (name.contains(search_term) or desc.contains(search_term)):
				show_card = false
		
		# Difficulty filter
		if show_card and not difficulty_filter.is_empty():
			var level_difficulty: String = level_data.get("difficulty", "easy").to_lower()
			if level_difficulty != difficulty_filter:
				show_card = false
		
		card.visible = show_card