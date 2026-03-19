extends Control
## Leaderboard - Shows top 10 scores from MetaProgress.high_scores.

signal back_requested


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	name = "Leaderboard"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Background overlay
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
	style.bg_color = Color(0.05, 0.06, 0.08, 0.98)
	style.border_color = Color(0.5, 0.4, 0.2, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(20)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "Leaderboard"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	# Column headers
	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 8)
	vbox.add_child(header_row)

	var rank_header := Label.new()
	rank_header.text = "#"
	rank_header.custom_minimum_size = Vector2(30, 0)
	rank_header.add_theme_font_size_override("font_size", 14)
	rank_header.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	header_row.add_child(rank_header)

	var time_header := Label.new()
	time_header.text = "Time"
	time_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	time_header.custom_minimum_size = Vector2(70, 0)
	time_header.add_theme_font_size_override("font_size", 14)
	time_header.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	header_row.add_child(time_header)

	var kills_header := Label.new()
	kills_header.text = "Kills"
	kills_header.custom_minimum_size = Vector2(60, 0)
	kills_header.add_theme_font_size_override("font_size", 14)
	kills_header.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	header_row.add_child(kills_header)

	var date_header := Label.new()
	date_header.text = "Date"
	date_header.custom_minimum_size = Vector2(100, 0)
	date_header.add_theme_font_size_override("font_size", 14)
	date_header.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	header_row.add_child(date_header)

	# Separator
	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 2)
	vbox.add_child(sep)

	# Scores list
	var scores: Array = MetaProgress.high_scores

	if scores.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No scores recorded yet.\nPlay a game to set your first record!"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_font_size_override("font_size", 16)
		empty_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		vbox.add_child(empty_label)
	else:
		for i in min(scores.size(), 10):
			var entry: Dictionary = scores[i]
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			vbox.add_child(row)

			# Rank colors
			var rank_color := Color(0.7, 0.7, 0.7)
			var time_color := Color(0.9, 0.9, 0.9)
			if i == 0:
				rank_color = Color(1.0, 0.85, 0.2)
				time_color = Color(1.0, 0.9, 0.4)
			elif i == 1:
				rank_color = Color(0.75, 0.75, 0.8)
				time_color = Color(0.85, 0.85, 0.9)
			elif i == 2:
				rank_color = Color(0.8, 0.5, 0.2)
				time_color = Color(0.9, 0.7, 0.4)

			# Rank
			var rank_label := Label.new()
			rank_label.text = str(i + 1)
			rank_label.custom_minimum_size = Vector2(30, 0)
			rank_label.add_theme_font_size_override("font_size", 16)
			rank_label.add_theme_color_override("font_color", rank_color)
			row.add_child(rank_label)

			# Time
			var time_val: float = entry.get("time", 0.0)
			var minutes := int(time_val) / 60
			var seconds := int(time_val) % 60
			var time_label := Label.new()
			time_label.text = "%02d:%02d" % [minutes, seconds]
			time_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			time_label.add_theme_font_size_override("font_size", 16)
			time_label.add_theme_color_override("font_color", time_color)
			row.add_child(time_label)

			# Kills
			var kills_label := Label.new()
			kills_label.text = str(entry.get("kills", 0))
			kills_label.custom_minimum_size = Vector2(60, 0)
			kills_label.add_theme_font_size_override("font_size", 16)
			kills_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
			row.add_child(kills_label)

			# Date
			var date_str: String = entry.get("date", "")
			if date_str.length() > 10:
				date_str = date_str.substr(0, 10)
			var date_label := Label.new()
			date_label.text = date_str
			date_label.custom_minimum_size = Vector2(100, 0)
			date_label.add_theme_font_size_override("font_size", 14)
			date_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
			row.add_child(date_label)

	# Spacer
	var bottom_spacer := Control.new()
	bottom_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(bottom_spacer)

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
