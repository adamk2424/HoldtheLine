extends Control
## MainMenu - Main menu with buttons: New Game, Settings, Upgrades (future), Quit.
## This is the entry scene alternative.

var _title_label: Label
var _subtitle_label: Label
var _buttons_vbox: VBoxContainer
var _settings_menu: Control = null
var _upgrades_menu: Control = null
var _leaderboard: Control = null
var _pre_game_menu: Control = null


func _ready() -> void:
	_build_ui()
	# Make sure game is not paused when in main menu
	get_tree().paused = false
	Engine.time_scale = 1.0


func _build_ui() -> void:
	name = "MainMenu"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Background
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.04, 0.06, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Vignette/decoration lines
	var decoration := Control.new()
	decoration.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	decoration.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(decoration)

	# Center container
	var center := VBoxContainer.new()
	center.set_anchors_preset(Control.PRESET_CENTER)
	center.offset_left = -250
	center.offset_right = 250
	center.offset_top = -250
	center.offset_bottom = 250
	center.add_theme_constant_override("separation", 20)
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(center)

	# Title
	_title_label = Label.new()
	_title_label.text = "HOLD THE LINE"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 52)
	_title_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.5))
	_title_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.3, 0.1, 0.5))
	_title_label.add_theme_constant_override("shadow_offset_x", 3)
	_title_label.add_theme_constant_override("shadow_offset_y", 3)
	center.add_child(_title_label)

	# Subtitle
	_subtitle_label = Label.new()
	_subtitle_label.text = "Survive. Build. Defend."
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle_label.add_theme_font_size_override("font_size", 18)
	_subtitle_label.add_theme_color_override("font_color", Color(0.5, 0.6, 0.5))
	center.add_child(_subtitle_label)

	# Spacer
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	center.add_child(spacer)

	# Buttons
	_buttons_vbox = VBoxContainer.new()
	_buttons_vbox.add_theme_constant_override("separation", 12)
	_buttons_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(_buttons_vbox)

	_add_menu_button("New Game", _on_new_game)
	_add_menu_button("Leaderboard", _on_leaderboard)
	_add_menu_button("Settings", _on_settings)
	_add_menu_button("Upgrades", _on_upgrades)
	_add_menu_button("Quit", _on_quit)

	# Version info
	var version := Label.new()
	version.text = "v0.1 - Prototype"
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version.add_theme_font_size_override("font_size", 12)
	version.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))
	center.add_child(version)

	# Best time display
	var best_time := MetaProgress.get_best_time()
	if best_time > 0.0:
		var minutes := int(best_time) / 60
		var seconds := int(best_time) % 60
		var best_label := Label.new()
		best_label.text = "Best Time: %02d:%02d" % [minutes, seconds]
		best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		best_label.add_theme_font_size_override("font_size", 14)
		best_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
		center.add_child(best_label)


func _add_menu_button(text: String, callback: Callable) -> void:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(250, 50)
	btn.add_theme_font_size_override("font_size", 20)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.08, 0.12, 0.1, 0.95)
	normal.border_color = Color(0.15, 0.4, 0.25, 0.7)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(6)
	normal.set_content_margin_all(10)
	btn.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate()
	hover.bg_color = Color(0.12, 0.2, 0.15, 0.95)
	hover.border_color = Color(0.25, 0.7, 0.4, 0.9)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed := normal.duplicate()
	pressed.bg_color = Color(0.08, 0.25, 0.12, 0.95)
	btn.add_theme_stylebox_override("pressed", pressed)

	btn.add_theme_color_override("font_color", Color(0.8, 0.95, 0.85))
	btn.add_theme_color_override("font_hover_color", Color(0.3, 1.0, 0.5))
	btn.pressed.connect(callback)
	_buttons_vbox.add_child(btn)


func _on_new_game() -> void:
	# Show pre-game menu
	var PreGameScript := preload("res://ui/menus/pre_game_menu.gd")
	_pre_game_menu = Control.new()
	_pre_game_menu.set_script(PreGameScript)
	add_child(_pre_game_menu)
	_pre_game_menu.game_start_requested.connect(_start_game)
	_pre_game_menu.back_requested.connect(func() -> void:
		_pre_game_menu.queue_free()
		_pre_game_menu = null
	)
	_buttons_vbox.visible = false
	_title_label.visible = false
	_subtitle_label.visible = false


func _start_game() -> void:
	GameState.reset_state()
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_leaderboard() -> void:
	var LeaderboardScript := preload("res://ui/menus/leaderboard.gd")
	_leaderboard = Control.new()
	_leaderboard.set_script(LeaderboardScript)
	add_child(_leaderboard)
	_leaderboard.back_requested.connect(func() -> void:
		_leaderboard.queue_free()
		_leaderboard = null
	)
	_buttons_vbox.visible = false


func _on_settings() -> void:
	var SettingsScript := preload("res://ui/menus/settings_menu.gd")
	_settings_menu = Control.new()
	_settings_menu.set_script(SettingsScript)
	add_child(_settings_menu)
	_settings_menu.back_requested.connect(func() -> void:
		_settings_menu.queue_free()
		_settings_menu = null
		_buttons_vbox.visible = true
	)
	_buttons_vbox.visible = false


func _on_upgrades() -> void:
	var UpgradesScript := preload("res://ui/menus/upgrades_menu.gd")
	_upgrades_menu = Control.new()
	_upgrades_menu.set_script(UpgradesScript)
	add_child(_upgrades_menu)
	_upgrades_menu.back_requested.connect(func() -> void:
		_upgrades_menu.queue_free()
		_upgrades_menu = null
		_buttons_vbox.visible = true
	)
	_buttons_vbox.visible = false


func _on_quit() -> void:
	get_tree().quit()
