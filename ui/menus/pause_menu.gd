extends CanvasLayer
## PauseMenu - Shown on ESC (pause_game input). Pauses game tree.
## Resume, Settings, Quit to Menu.

var _panel: PanelContainer
var _buttons_vbox: VBoxContainer
var _settings_menu: Control = null
var _is_paused: bool = false
var _build_menu_open: bool = false


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_panel.get_parent().visible = false
	GameBus.ui_build_menu_toggled.connect(func(is_open: bool) -> void: _build_menu_open = is_open)


func _build_ui() -> void:
	# Dim overlay
	var overlay := ColorRect.new()
	overlay.name = "PauseOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.0, 0.0, 0.0, 0.6)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	_panel = PanelContainer.new()
	_panel.name = "PausePanel"
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.offset_left = -180
	_panel.offset_right = 180
	_panel.offset_top = -200
	_panel.offset_bottom = 200
	overlay.add_child(_panel)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.06, 0.08, 0.98)
	style.border_color = Color(0.2, 0.5, 0.3, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(20)
	_panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_panel.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.3, 0.9, 0.5))
	vbox.add_child(title)

	# Game time display
	var time_label := Label.new()
	time_label.text = "Game Time: %s" % GameState.get_game_time_formatted()
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_label.add_theme_font_size_override("font_size", 14)
	time_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	vbox.add_child(time_label)

	# Separator
	vbox.add_child(HSeparator.new())

	# Buttons
	_buttons_vbox = VBoxContainer.new()
	_buttons_vbox.add_theme_constant_override("separation", 10)
	_buttons_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(_buttons_vbox)

	_add_button("Resume", _on_resume)
	_add_button("Settings", _on_settings)
	_add_button("Quit to Menu", _on_quit_to_menu)


func _add_button(text: String, callback: Callable) -> void:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(220, 45)
	btn.add_theme_font_size_override("font_size", 18)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.08, 0.12, 0.1, 0.95)
	normal.border_color = Color(0.15, 0.4, 0.25, 0.7)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(6)
	normal.set_content_margin_all(8)
	btn.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate()
	hover.bg_color = Color(0.12, 0.2, 0.15, 0.95)
	hover.border_color = Color(0.25, 0.7, 0.4, 0.9)
	btn.add_theme_stylebox_override("hover", hover)

	btn.add_theme_color_override("font_color", Color(0.8, 0.95, 0.85))
	btn.add_theme_color_override("font_hover_color", Color(0.3, 1.0, 0.5))
	btn.pressed.connect(callback)
	_buttons_vbox.add_child(btn)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game"):
		if _is_paused:
			_on_resume()
		elif _build_menu_open:
			GameBus.ui_build_menu_toggled.emit(false)
		else:
			_pause()
		get_viewport().set_input_as_handled()


func _pause() -> void:
	if not GameState.is_game_active:
		return
	GameBus.audio_play.emit("ui.button_click")
	_is_paused = true
	GameState.is_paused = true
	get_tree().paused = true
	_panel.get_parent().visible = true  # Show overlay
	_panel.visible = true
	GameBus.game_paused.emit()


func _on_resume() -> void:
	_is_paused = false
	GameState.is_paused = false
	get_tree().paused = false
	_panel.get_parent().visible = false  # Hide overlay
	_panel.visible = false

	if _settings_menu:
		_settings_menu.queue_free()
		_settings_menu = null
		_buttons_vbox.visible = true

	GameBus.game_resumed.emit()


func _on_settings() -> void:
	var SettingsScript := preload("res://ui/menus/settings_menu.gd")
	_settings_menu = Control.new()
	_settings_menu.set_script(SettingsScript)
	_settings_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_settings_menu)
	_settings_menu.back_requested.connect(func() -> void:
		_settings_menu.queue_free()
		_settings_menu = null
		_buttons_vbox.visible = true
	)
	_buttons_vbox.visible = false


func _on_quit_to_menu() -> void:
	_is_paused = false
	GameState.is_paused = false
	get_tree().paused = false
	Engine.time_scale = 1.0
	GameState.reset_state()
	AudioManager.stop_music()

	# Try to load main menu scene if it exists, otherwise load main.tscn
	if ResourceLoader.exists("res://ui/menus/main_menu.tscn"):
		get_tree().change_scene_to_file("res://ui/menus/main_menu.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/main.tscn")
