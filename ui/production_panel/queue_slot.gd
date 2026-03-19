extends PanelContainer
## QueueSlot - Single queue slot showing unit icon/name and remaining time.
## Click to cancel production.

signal cancel_requested(slot_index: int)

var _name_label: Label
var _time_label: Label
var _cancel_button: Button

var slot_index: int = 0
var unit_id: String = ""
var is_active: bool = false


func setup(p_slot_index: int, p_unit_id: String, remaining_time: float, p_is_active: bool) -> void:
	slot_index = p_slot_index
	unit_id = p_unit_id
	is_active = p_is_active
	_build_ui()
	_update_display(remaining_time)


func _build_ui() -> void:
	custom_minimum_size = Vector2(200, 32)

	var style := StyleBoxFlat.new()
	if is_active:
		style.bg_color = Color(0.1, 0.2, 0.15, 0.9)
		style.border_color = Color(0.3, 0.7, 0.4, 0.7)
	else:
		style.bg_color = Color(0.08, 0.1, 0.08, 0.8)
		style.border_color = Color(0.2, 0.3, 0.2, 0.5)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(4)
	add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	add_child(hbox)

	_name_label = Label.new()
	_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_label.add_theme_font_size_override("font_size", 12)
	_name_label.add_theme_color_override("font_color", Color(0.8, 0.9, 0.8))
	hbox.add_child(_name_label)

	_time_label = Label.new()
	_time_label.add_theme_font_size_override("font_size", 12)
	_time_label.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6))
	hbox.add_child(_time_label)

	_cancel_button = Button.new()
	_cancel_button.text = "X"
	_cancel_button.custom_minimum_size = Vector2(24, 24)
	_cancel_button.add_theme_font_size_override("font_size", 10)
	_cancel_button.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))

	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color(0.25, 0.08, 0.08, 0.8)
	btn_style.set_corner_radius_all(2)
	btn_style.set_content_margin_all(2)
	_cancel_button.add_theme_stylebox_override("normal", btn_style)

	_cancel_button.pressed.connect(func() -> void: cancel_requested.emit(slot_index))
	hbox.add_child(_cancel_button)


func _update_display(remaining_time: float) -> void:
	var data := GameData.get_unit(unit_id)
	var display_name: String = data.get("name", unit_id.capitalize())

	if is_active:
		_name_label.text = "> %s" % display_name
		_time_label.text = "%.1fs" % remaining_time
	else:
		_name_label.text = "  %s" % display_name
		_time_label.text = "queued"


func update_time(remaining_time: float) -> void:
	if is_active:
		_time_label.text = "%.1fs" % remaining_time
