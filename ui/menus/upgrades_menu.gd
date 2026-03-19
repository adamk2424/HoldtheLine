extends Control
## UpgradesMenu - Placeholder for future meta-progression upgrades.
## Just shows "Coming Soon".

signal back_requested


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	name = "UpgradesMenu"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Background overlay
	var overlay := ColorRect.new()
	overlay.color = Color(0.02, 0.02, 0.04, 0.9)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	# Center panel
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -200
	panel.offset_right = 200
	panel.offset_top = -150
	panel.offset_bottom = 150

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.07, 0.1, 0.98)
	style.border_color = Color(0.4, 0.3, 0.15, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "Upgrades"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
	vbox.add_child(title)

	# Coming soon text
	var coming_soon := Label.new()
	coming_soon.text = "Coming Soon"
	coming_soon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coming_soon.add_theme_font_size_override("font_size", 22)
	coming_soon.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	vbox.add_child(coming_soon)

	var desc := Label.new()
	desc.text = "Meta-progression upgrades will\nbe available in a future update."
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 14)
	desc.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	vbox.add_child(desc)

	# Back button
	var back_btn := Button.new()
	back_btn.text = "Back"
	back_btn.custom_minimum_size = Vector2(120, 40)
	back_btn.add_theme_font_size_override("font_size", 16)

	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color(0.1, 0.15, 0.12, 0.95)
	btn_style.border_color = Color(0.2, 0.5, 0.3, 0.7)
	btn_style.set_border_width_all(1)
	btn_style.set_corner_radius_all(4)
	btn_style.set_content_margin_all(8)
	back_btn.add_theme_stylebox_override("normal", btn_style)

	var hover := btn_style.duplicate()
	hover.bg_color = Color(0.15, 0.25, 0.18, 0.95)
	back_btn.add_theme_stylebox_override("hover", hover)

	back_btn.add_theme_color_override("font_color", Color(0.8, 0.95, 0.85))
	back_btn.pressed.connect(func() -> void:
		back_requested.emit()
	)
	vbox.add_child(back_btn)
