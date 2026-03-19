extends CanvasLayer
## GameOverScreen - Shows on GameBus.game_over.
## Displays survival time, enemies killed, buildings built.
## Buttons: Main Menu, Play Again.

var _panel: PanelContainer
var _time_label: Label
var _kills_label: Label
var _buildings_label: Label


func _ready() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_panel.get_parent().visible = false
	GameBus.game_over.connect(_on_game_over)


func _build_ui() -> void:
	# Dim overlay
	var overlay := ColorRect.new()
	overlay.name = "GameOverOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.02, 0.0, 0.0, 0.85)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	_panel = PanelContainer.new()
	_panel.name = "GameOverPanel"
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.offset_left = -220
	_panel.offset_right = 220
	_panel.offset_top = -260
	_panel.offset_bottom = 260

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.03, 0.05, 0.98)
	style.border_color = Color(0.6, 0.15, 0.15, 0.9)
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(24)
	_panel.add_theme_stylebox_override("panel", style)
	overlay.add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_panel.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "GAME OVER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(0.9, 0.15, 0.15))
	title.add_theme_color_override("font_shadow_color", Color(0.3, 0.0, 0.0, 0.5))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "The line has fallen."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(0.6, 0.4, 0.4))
	vbox.add_child(subtitle)

	vbox.add_child(HSeparator.new())

	# Stats
	var stats_vbox := VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 10)
	vbox.add_child(stats_vbox)

	_time_label = _create_stat_row(stats_vbox, "Survival Time", "00:00")
	_kills_label = _create_stat_row(stats_vbox, "Enemies Killed", "0")
	_buildings_label = _create_stat_row(stats_vbox, "Buildings Built", "0")

	vbox.add_child(HSeparator.new())

	# Buttons
	var btn_vbox := VBoxContainer.new()
	btn_vbox.add_theme_constant_override("separation", 10)
	btn_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_vbox)

	_add_button(btn_vbox, "Play Again", _on_play_again)
	_add_button(btn_vbox, "Main Menu", _on_main_menu)


func _create_stat_row(parent: VBoxContainer, label_text: String, default_value: String) -> Label:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	var value := Label.new()
	value.text = default_value
	value.add_theme_font_size_override("font_size", 18)
	value.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	row.add_child(value)

	return value


func _add_button(parent: VBoxContainer, text: String, callback: Callable) -> void:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(220, 45)
	btn.add_theme_font_size_override("font_size", 18)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.1, 0.1, 0.08, 0.95)
	normal.border_color = Color(0.3, 0.3, 0.2, 0.7)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(6)
	normal.set_content_margin_all(8)
	btn.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate()
	hover.bg_color = Color(0.15, 0.15, 0.1, 0.95)
	hover.border_color = Color(0.5, 0.5, 0.3, 0.9)
	btn.add_theme_stylebox_override("hover", hover)

	btn.add_theme_color_override("font_color", Color(0.8, 0.8, 0.7))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.9, 0.5))
	btn.pressed.connect(callback)
	parent.add_child(btn)


func _on_game_over(survival_time: float) -> void:
	# Populate stats
	var minutes := int(survival_time) / 60
	var seconds := int(survival_time) % 60
	_time_label.text = "%02d:%02d" % [minutes, seconds]
	_kills_label.text = str(GameState.enemies_killed)
	_buildings_label.text = str(GameState.buildings_built)

	# Show with a slight delay for dramatic effect
	await get_tree().create_timer(1.5).timeout
	_panel.get_parent().visible = true
	GameBus.audio_play.emit("ui.game_over")


func _on_play_again() -> void:
	GameState.reset_state()
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_main_menu() -> void:
	GameState.reset_state()
	Engine.time_scale = 1.0
	get_tree().paused = false
	if ResourceLoader.exists("res://ui/menus/main_menu.tscn"):
		get_tree().change_scene_to_file("res://ui/menus/main_menu.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/main.tscn")
