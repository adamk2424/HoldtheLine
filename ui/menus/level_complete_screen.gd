extends CanvasLayer
## LevelCompleteScreen - Shows rewards and progression after completing a level.
## Displays tech points earned, unlocked content, and level progression.

var _level_data: Dictionary = {}
var _rewards: Dictionary = {}
var _survival_time: float = 0.0

# UI References
var _root: Control
var _title_label: Label
var _level_name_label: Label
var _time_label: Label
var _rewards_container: VBoxContainer
var _continue_button: Button
var _replay_button: Button

signal continue_requested
signal replay_requested


func _ready() -> void:
	layer = 26
	_build_ui()


func show_level_complete(level_data: Dictionary, rewards: Dictionary, survival_time: float) -> void:
	_level_data = level_data
	_rewards = rewards
	_survival_time = survival_time
	_populate_content()
	visible = true


func _build_ui() -> void:
	name = "LevelCompleteScreen"
	visible = false

	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	# Semi-transparent background
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.8)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(bg)

	# Main panel
	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -400
	panel.offset_right = 400
	panel.offset_top = -300
	panel.offset_bottom = 300

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.15, 0.2, 0.95)
	panel_style.border_color = Color(0.3, 0.6, 0.4, 0.8)
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", panel_style)
	_root.add_child(panel)

	# Content container
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	margin.add_child(vbox)

	# Title
	_title_label = Label.new()
	_title_label.text = "LEVEL COMPLETE!"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 32)
	_title_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6))
	vbox.add_child(_title_label)

	# Level name
	_level_name_label = Label.new()
	_level_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_name_label.add_theme_font_size_override("font_size", 20)
	_level_name_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(_level_name_label)

	# Time survived
	_time_label = Label.new()
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_time_label.add_theme_font_size_override("font_size", 16)
	_time_label.add_theme_color_override("font_color", Color.CYAN)
	vbox.add_child(_time_label)

	# Separator
	var separator := HSeparator.new()
	separator.add_theme_color_override("separator", Color(0.5, 0.5, 0.5, 0.5))
	vbox.add_child(separator)

	# Rewards section
	var rewards_label := Label.new()
	rewards_label.text = "REWARDS"
	rewards_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rewards_label.add_theme_font_size_override("font_size", 18)
	rewards_label.add_theme_color_override("font_color", Color.YELLOW)
	vbox.add_child(rewards_label)

	_rewards_container = VBoxContainer.new()
	_rewards_container.add_theme_constant_override("separation", 8)
	vbox.add_child(_rewards_container)

	# Spacer
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# Buttons
	var button_hbox := HBoxContainer.new()
	button_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	button_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(button_hbox)

	_replay_button = Button.new()
	_replay_button.text = "REPLAY LEVEL"
	_replay_button.custom_minimum_size = Vector2(150, 45)
	_replay_button.pressed.connect(_on_replay_pressed)
	_style_button(_replay_button, Color(0.2, 0.4, 0.6))
	button_hbox.add_child(_replay_button)

	_continue_button = Button.new()
	_continue_button.text = "CONTINUE"
	_continue_button.custom_minimum_size = Vector2(150, 45)
	_continue_button.pressed.connect(_on_continue_pressed)
	_style_button(_continue_button, Color(0.2, 0.6, 0.4))
	button_hbox.add_child(_continue_button)


func _style_button(button: Button, base_color: Color) -> void:
	button.add_theme_font_size_override("font_size", 16)

	var normal := StyleBoxFlat.new()
	normal.bg_color = base_color
	normal.border_color = base_color.lightened(0.3)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(6)
	button.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate()
	hover.bg_color = base_color.lightened(0.2)
	button.add_theme_stylebox_override("hover", hover)

	var pressed := normal.duplicate()
	pressed.bg_color = base_color.darkened(0.2)
	button.add_theme_stylebox_override("pressed", pressed)

	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)


func _populate_content() -> void:
	# Update labels
	_level_name_label.text = _level_data.get("name", "Unknown Level")

	var minutes := int(_survival_time) / 60
	var seconds := int(_survival_time) % 60
	_time_label.text = "Time Survived: %02d:%02d" % [minutes, seconds]

	# Clear existing reward items
	for child in _rewards_container.get_children():
		child.queue_free()

	# Add reward items
	var tech_points: int = _rewards.get("tech_points", 0)
	if tech_points > 0:
		_add_reward_item("Tech Points", "+%d" % tech_points, Color.YELLOW)

	var unlocks: Array = _rewards.get("unlocks", [])
	for unlock_id: String in unlocks:
		var unlock_name := _format_unlock_name(unlock_id)
		_add_reward_item("Unlocked", unlock_name, Color.LIGHT_GREEN)

	# Show progress summary
	var progress := LevelSystem.get_level_progress_summary()
	var progress_text := "Progress: %d/%d levels completed" % [progress["completed_count"], progress["total_levels"]]
	_add_reward_item("Overall Progress", progress_text, Color.LIGHT_GRAY)


func _add_reward_item(label_text: String, value_text: String, color: Color) -> void:
	var hbox := HBoxContainer.new()
	_rewards_container.add_child(hbox)

	var label := Label.new()
	label.text = label_text + ":"
	label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(label)

	var value := Label.new()
	value.text = value_text
	value.add_theme_color_override("font_color", color)
	value.add_theme_font_size_override("font_size", 14)
	hbox.add_child(value)


func _format_unlock_name(unlock_id: String) -> String:
	# Convert unlock IDs to readable names
	if unlock_id.begins_with("level_"):
		var level_name := unlock_id.substr(6).replace("_", " ").capitalize()
		return level_name + " Level"

	return unlock_id.replace("_", " ").capitalize()


func _on_continue_pressed() -> void:
	continue_requested.emit()


func _on_replay_pressed() -> void:
	replay_requested.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
				_on_continue_pressed()
			KEY_ESCAPE:
				_on_continue_pressed()
