extends Control
## SettingsMenu - Volume sliders (master, SFX, music), fullscreen toggle,
## edge pan toggle, camera speed. Saves to MetaProgress.

signal back_requested

var _master_slider: HSlider
var _sfx_slider: HSlider
var _music_slider: HSlider
var _fullscreen_check: CheckButton
var _edge_pan_check: CheckButton
var _camera_speed_slider: HSlider
var _master_value_label: Label
var _sfx_value_label: Label
var _music_value_label: Label
var _camera_speed_value_label: Label


func _ready() -> void:
	_build_ui()
	_load_current_settings()


func _build_ui() -> void:
	name = "SettingsMenu"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Semi-transparent overlay
	var overlay := ColorRect.new()
	overlay.color = Color(0.02, 0.02, 0.04, 0.9)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	# Center panel
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -250
	panel.offset_right = 250
	panel.offset_top = -280
	panel.offset_bottom = 280

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.07, 0.1, 0.98)
	style.border_color = Color(0.2, 0.5, 0.3, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(20)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "Settings"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.3, 0.9, 0.5))
	vbox.add_child(title)

	# Separator
	vbox.add_child(HSeparator.new())

	# Audio section
	var audio_label := Label.new()
	audio_label.text = "Audio"
	audio_label.add_theme_font_size_override("font_size", 18)
	audio_label.add_theme_color_override("font_color", Color(0.7, 0.8, 0.7))
	vbox.add_child(audio_label)

	# Master volume
	var master_row := _create_slider_row("Master Volume")
	_master_slider = master_row[0]
	_master_value_label = master_row[1]
	_master_slider.value_changed.connect(func(val: float) -> void:
		_master_value_label.text = "%d%%" % int(val * 100)
	)
	vbox.add_child(master_row[2])

	# SFX volume
	var sfx_row := _create_slider_row("SFX Volume")
	_sfx_slider = sfx_row[0]
	_sfx_value_label = sfx_row[1]
	_sfx_slider.value_changed.connect(func(val: float) -> void:
		_sfx_value_label.text = "%d%%" % int(val * 100)
	)
	vbox.add_child(sfx_row[2])

	# Music volume
	var music_row := _create_slider_row("Music Volume")
	_music_slider = music_row[0]
	_music_value_label = music_row[1]
	_music_slider.value_changed.connect(func(val: float) -> void:
		_music_value_label.text = "%d%%" % int(val * 100)
	)
	vbox.add_child(music_row[2])

	# Separator
	vbox.add_child(HSeparator.new())

	# Display section
	var display_label := Label.new()
	display_label.text = "Display"
	display_label.add_theme_font_size_override("font_size", 18)
	display_label.add_theme_color_override("font_color", Color(0.7, 0.8, 0.7))
	vbox.add_child(display_label)

	# Fullscreen
	_fullscreen_check = CheckButton.new()
	_fullscreen_check.text = "Fullscreen"
	_fullscreen_check.add_theme_font_size_override("font_size", 14)
	_fullscreen_check.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(_fullscreen_check)

	# Edge pan
	_edge_pan_check = CheckButton.new()
	_edge_pan_check.text = "Edge Panning"
	_edge_pan_check.add_theme_font_size_override("font_size", 14)
	_edge_pan_check.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(_edge_pan_check)

	# Camera speed
	var cam_row := _create_slider_row("Camera Speed", 5.0, 80.0, 1.0)
	_camera_speed_slider = cam_row[0]
	_camera_speed_value_label = cam_row[1]
	_camera_speed_slider.value_changed.connect(func(val: float) -> void:
		_camera_speed_value_label.text = "%d" % int(val)
	)
	vbox.add_child(cam_row[2])

	# Separator
	vbox.add_child(HSeparator.new())

	# Buttons
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_row)

	var save_btn := _create_button("Save", _on_save)
	btn_row.add_child(save_btn)

	var back_btn := _create_button("Back", _on_back)
	btn_row.add_child(back_btn)


func _create_slider_row(label_text: String, min_val: float = 0.0, max_val: float = 1.0, step: float = 0.05) -> Array:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 4)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	container.add_child(row)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(140, 0)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	row.add_child(label)

	var slider := HSlider.new()
	slider.min_value = min_val
	slider.max_value = max_val
	slider.step = step
	slider.custom_minimum_size = Vector2(180, 20)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)

	var value_label := Label.new()
	value_label.text = "100%"
	value_label.custom_minimum_size = Vector2(50, 0)
	value_label.add_theme_font_size_override("font_size", 13)
	value_label.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6))
	row.add_child(value_label)

	return [slider, value_label, container]


func _create_button(text: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(120, 40)
	btn.add_theme_font_size_override("font_size", 16)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.15, 0.12, 0.95)
	style.border_color = Color(0.2, 0.5, 0.3, 0.7)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8)
	btn.add_theme_stylebox_override("normal", style)

	var hover := style.duplicate()
	hover.bg_color = Color(0.15, 0.25, 0.18, 0.95)
	btn.add_theme_stylebox_override("hover", hover)

	btn.add_theme_color_override("font_color", Color(0.8, 0.95, 0.85))
	btn.pressed.connect(callback)
	return btn


func _load_current_settings() -> void:
	_master_slider.value = MetaProgress.master_volume
	_sfx_slider.value = MetaProgress.sfx_volume
	_music_slider.value = MetaProgress.music_volume
	_fullscreen_check.button_pressed = MetaProgress.fullscreen
	_edge_pan_check.button_pressed = MetaProgress.edge_pan_enabled
	_camera_speed_slider.value = MetaProgress.camera_speed

	_master_value_label.text = "%d%%" % int(MetaProgress.master_volume * 100)
	_sfx_value_label.text = "%d%%" % int(MetaProgress.sfx_volume * 100)
	_music_value_label.text = "%d%%" % int(MetaProgress.music_volume * 100)
	_camera_speed_value_label.text = "%d" % int(MetaProgress.camera_speed)


func _on_save() -> void:
	MetaProgress.master_volume = _master_slider.value
	MetaProgress.sfx_volume = _sfx_slider.value
	MetaProgress.music_volume = _music_slider.value
	MetaProgress.fullscreen = _fullscreen_check.button_pressed
	MetaProgress.edge_pan_enabled = _edge_pan_check.button_pressed
	MetaProgress.camera_speed = _camera_speed_slider.value

	# Apply fullscreen
	if MetaProgress.fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

	# Apply volume to audio buses
	AudioManager.apply_volume_settings()

	MetaProgress.save_data()


func _on_back() -> void:
	back_requested.emit()
