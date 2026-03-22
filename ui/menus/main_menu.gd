extends Control
## MainMenu - Main menu with buttons: New Game, Settings, Upgrades (future), Quit.
## This is the entry scene alternative.

var _title_label: Label
var _subtitle_label: Label
var _buttons_vbox: VBoxContainer
var _settings_menu: Control = null
var _upgrades_menu: Control = null
var _loadout_menu: Control = null
var _leaderboard: Control = null
var _pre_game_menu: Control = null
var _level_select_menu: Control = null
var _progression_dashboard: Control = null


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

	_add_menu_button("Select Level", _on_level_select)
	_add_menu_button("Quick Game", _on_new_game)
	_add_menu_button("📊 Progression", _on_progression)
	_add_menu_button("Loadout", _on_loadout)
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


func _on_progression() -> void:
	# Show progression dashboard
	var ProgressionDashboardScript := preload("res://ui/menus/progression_dashboard.gd")
	_progression_dashboard = Control.new()
	_progression_dashboard.set_script(ProgressionDashboardScript)
	add_child(_progression_dashboard)
	
	_buttons_vbox.visible = false
	_title_label.visible = false
	_subtitle_label.visible = false
	
	# Add back button to dashboard
	var back_button := Button.new()
	back_button.text = "◄ Back to Main Menu"
	back_button.custom_minimum_size = Vector2(200, 40)
	back_button.set_anchors_preset(Control.PRESET_TOP_LEFT)
	back_button.offset_left = 30
	back_button.offset_top = 30
	back_button.offset_right = 230
	back_button.offset_bottom = 70
	back_button.pressed.connect(func() -> void:
		_progression_dashboard.queue_free()
		_progression_dashboard = null
		_buttons_vbox.visible = true
		_title_label.visible = true
		_subtitle_label.visible = true
	)
	_progression_dashboard.add_child(back_button)


func _on_level_select() -> void:
	print("[MainMenu] _on_level_select called")
	var LevelSelectScript := preload("res://ui/menus/level_select_menu.gd")
	_level_select_menu = Control.new()
	_level_select_menu.set_script(LevelSelectScript)
	add_child(_level_select_menu)
	print("[MainMenu] Level select menu added to tree")
	_level_select_menu.level_selected.connect(_start_level)
	_level_select_menu.back_pressed.connect(func() -> void:
		_level_select_menu.queue_free()
		_level_select_menu = null
		_buttons_vbox.visible = true
		_title_label.visible = true
		_subtitle_label.visible = true
	)
	_buttons_vbox.visible = false
	_title_label.visible = false
	_subtitle_label.visible = false
	print("[MainMenu] Level select menu setup complete")


func _on_new_game() -> void:
	print("[MainMenu] _on_new_game called")
	var PreGameScript := preload("res://ui/menus/pre_game_menu.gd")
	_pre_game_menu = Control.new()
	_pre_game_menu.set_script(PreGameScript)
	add_child(_pre_game_menu)
	_pre_game_menu.game_start_requested.connect(_start_game)
	_pre_game_menu.back_requested.connect(func() -> void:
		_pre_game_menu.queue_free()
		_pre_game_menu = null
		_buttons_vbox.visible = true
		_title_label.visible = true
		_subtitle_label.visible = true
	)
	_buttons_vbox.visible = false
	_title_label.visible = false
	_subtitle_label.visible = false


func _start_level(level_id: String) -> void:
	GameState.reset_state()
	GameState.selected_level_id = level_id
	_change_to_game_scene()


func _start_game() -> void:
	print("[MainMenu] _start_game called")
	GameState.reset_state()
	GameState.selected_level_id = ""
	_change_to_game_scene()


func _change_to_game_scene() -> void:
	var scene_path := "res://scenes/main.tscn"
	print("[MainMenu] Loading scene: %s" % scene_path)

	# Try loading the scene first to catch errors
	var scene := load(scene_path) as PackedScene
	if scene == null:
		push_error("[MainMenu] FAILED to load %s - check Output for errors" % scene_path)
		print("[MainMenu] ERROR: Could not load %s" % scene_path)
		return

	print("[MainMenu] Scene loaded OK, changing scene...")
	var err := get_tree().change_scene_to_packed(scene)
	if err != OK:
		push_error("[MainMenu] Scene change failed with error: %s" % error_string(err))
		print("[MainMenu] ERROR: change_scene_to_packed returned: %s" % error_string(err))


func _on_loadout() -> void:
	var LoadoutScript := preload("res://ui/menus/loadout_screen.gd")
	var loadout_menu := Control.new()
	loadout_menu.set_script(LoadoutScript)
	add_child(loadout_menu)
	loadout_menu.loadout_screen_closed.connect(func() -> void:
		loadout_menu.queue_free()
		_buttons_vbox.visible = true
	)
	_buttons_vbox.visible = false


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
