extends PanelContainer
## PopulationPanel - Shows "Pop: X/Y". Updates on GameBus.population_changed.

var pop_label: Label

var _current: int = 0
var _maximum: int = 20


func _ready() -> void:
	_build_ui()
	GameBus.population_changed.connect(_on_population_changed)
	_current = GameState.population_current
	_maximum = GameState.population_max
	_update_display()


func _build_ui() -> void:
	name = "PopulationPanel"
	custom_minimum_size = Vector2(120, 40)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.9)
	style.border_color = Color(0.2, 0.5, 0.3, 0.8)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8)
	add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 4)
	add_child(hbox)

	var icon := Label.new()
	icon.text = "Pop:"
	icon.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	icon.add_theme_font_size_override("font_size", 14)
	hbox.add_child(icon)

	pop_label = Label.new()
	pop_label.text = "0/20"
	pop_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	pop_label.add_theme_font_size_override("font_size", 16)
	hbox.add_child(pop_label)


func _on_population_changed(current: int, maximum: int) -> void:
	_current = current
	_maximum = maximum
	_update_display()


func _update_display() -> void:
	pop_label.text = "%d/%d" % [_current, _maximum]
	if _current >= _maximum:
		pop_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	elif _current > _maximum * 0.8:
		pop_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
	else:
		pop_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
