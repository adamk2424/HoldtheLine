extends VBoxContainer
## BuildCategory - A collapsible category container for build items.
## Shows a header button that toggles the item list.

signal item_selected(entity_id: String)

var _header_button: Button
var _items_container: VBoxContainer
var _is_expanded: bool = true
var _category_name: String = ""


func setup(category_name: String, items: Dictionary) -> void:
	_category_name = category_name
	_build_ui()
	_populate_items(items)


func _build_ui() -> void:
	add_theme_constant_override("separation", 2)

	# Category header (toggle button)
	_header_button = Button.new()
	_header_button.text = "[-] %s" % _category_name
	_header_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_header_button.custom_minimum_size = Vector2(230, 32)
	_header_button.add_theme_font_size_override("font_size", 15)
	_header_button.add_theme_color_override("font_color", Color(0.8, 0.9, 0.7))

	var header_style := StyleBoxFlat.new()
	header_style.bg_color = Color(0.08, 0.12, 0.1, 0.95)
	header_style.border_color = Color(0.25, 0.5, 0.35, 0.7)
	header_style.set_border_width_all(1)
	header_style.border_width_bottom = 2
	header_style.set_corner_radius_all(4)
	header_style.set_content_margin_all(6)
	header_style.content_margin_left = 10
	_header_button.add_theme_stylebox_override("normal", header_style)

	var hover_style := header_style.duplicate()
	hover_style.bg_color = Color(0.12, 0.18, 0.14, 0.95)
	_header_button.add_theme_stylebox_override("hover", hover_style)

	_header_button.pressed.connect(_toggle)
	add_child(_header_button)

	# Items container
	_items_container = VBoxContainer.new()
	_items_container.add_theme_constant_override("separation", 2)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_child(_items_container)
	add_child(margin)


func _populate_items(items: Dictionary) -> void:
	var BuildItemScript := preload("res://ui/build_menu/build_item.gd")

	for entity_id: String in items:
		var data: Dictionary = items[entity_id]
		var item := Button.new()
		item.set_script(BuildItemScript)
		_items_container.add_child(item)
		item.setup(entity_id, data)
		item.item_selected.connect(_on_item_selected)


func _toggle() -> void:
	_is_expanded = not _is_expanded
	_items_container.get_parent().visible = _is_expanded
	if _is_expanded:
		_header_button.text = "[-] %s" % _category_name
	else:
		_header_button.text = "[+] %s" % _category_name


func _on_item_selected(entity_id: String) -> void:
	item_selected.emit(entity_id)
