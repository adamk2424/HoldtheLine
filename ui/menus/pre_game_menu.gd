extends Control
## PreGameMenu - Simple "Start Game" screen with difficulty info.

signal game_start_requested
signal back_requested


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	name = "PreGameMenu"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Center panel
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -250
	panel.offset_right = 250
	panel.offset_top = -220
	panel.offset_bottom = 220

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.06, 0.08, 0.98)
	style.border_color = Color(0.2, 0.5, 0.3, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "Mission Briefing"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.3, 0.9, 0.5))
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	# Briefing text
	var briefing := Label.new()
	briefing.text = "The colony is under siege. Enemy forces\napproach from all directions.\n\nYour mission: Defend the Central Tower\nfor as long as possible.\n\nBuild towers, train units, and hold the line."
	briefing.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	briefing.add_theme_font_size_override("font_size", 15)
	briefing.add_theme_color_override("font_color", Color(0.7, 0.8, 0.7))
	vbox.add_child(briefing)

	vbox.add_child(HSeparator.new())

	# Difficulty info
	var diff_label := Label.new()
	diff_label.text = "Difficulty: Standard"
	diff_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	diff_label.add_theme_font_size_override("font_size", 16)
	diff_label.add_theme_color_override("font_color", Color(0.8, 0.7, 0.3))
	vbox.add_child(diff_label)

	var diff_desc := Label.new()
	diff_desc.text = "Enemies scale in strength and numbers\nover time. Periodic surges test your defenses."
	diff_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	diff_desc.add_theme_font_size_override("font_size", 13)
	diff_desc.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	vbox.add_child(diff_desc)

	# Starting resources info
	var resources_label := Label.new()
	resources_label.text = "Starting: 100 Energy | 100 Materials"
	resources_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	resources_label.add_theme_font_size_override("font_size", 14)
	resources_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.6))
	vbox.add_child(resources_label)

	vbox.add_child(HSeparator.new())

	# Buttons
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 16)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_row)

	# Back button
	var back_btn := _create_button("Back", Color(0.3, 0.3, 0.3))
	back_btn.pressed.connect(func() -> void:
		back_requested.emit()
	)
	btn_row.add_child(back_btn)

	# Start button
	var start_btn := _create_button("Start Mission", Color(0.2, 0.6, 0.3))
	start_btn.custom_minimum_size = Vector2(180, 50)
	start_btn.add_theme_font_size_override("font_size", 20)
	start_btn.pressed.connect(func() -> void:
		game_start_requested.emit()
	)
	btn_row.add_child(start_btn)


func _create_button(text: String, accent_color: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(120, 45)
	btn.add_theme_font_size_override("font_size", 16)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(accent_color.r * 0.3, accent_color.g * 0.3, accent_color.b * 0.3, 0.95)
	normal.border_color = accent_color
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(6)
	normal.set_content_margin_all(8)
	btn.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate()
	hover.bg_color = Color(accent_color.r * 0.5, accent_color.g * 0.5, accent_color.b * 0.5, 0.95)
	btn.add_theme_stylebox_override("hover", hover)

	btn.add_theme_color_override("font_color", Color(0.9, 0.95, 0.9))
	return btn
