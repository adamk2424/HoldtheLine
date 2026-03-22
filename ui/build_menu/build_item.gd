extends Button
## BuildItem - Single buildable item button showing name, cost with
## energy/materials icons, and whether affordable/tech requirements are met.

signal item_selected(entity_id: String)

var entity_id: String = ""
var entity_data: Dictionary = {}
var energy_cost: float = 0.0
var material_cost: float = 0.0
var required_tech_level: String = "none"  # "none", "tier_1", "tier_2", "tier_3"

var _name_label: Label
var _energy_label: Label
var _material_label: Label


func setup(p_entity_id: String, p_data: Dictionary) -> void:
	entity_id = p_entity_id
	entity_data = p_data
	energy_cost = float(p_data.get("cost_energy", 0))
	material_cost = float(p_data.get("cost_materials", 0))
	required_tech_level = p_data.get("required_tech_level", "none")

	_build_ui()
	_update_affordability()

	GameBus.resources_changed.connect(_on_resources_changed)
	GameBus.central_tower_upgraded.connect(_on_tech_changed)


func _build_ui() -> void:
	custom_minimum_size = Vector2(220, 44)
	text = ""

	add_theme_font_size_override("font_size", 13)

	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(0.1, 0.15, 0.12, 0.9)
	normal_style.border_color = Color(0.2, 0.4, 0.3, 0.6)
	normal_style.set_border_width_all(1)
	normal_style.set_corner_radius_all(4)
	normal_style.set_content_margin_all(6)
	normal_style.content_margin_left = 12
	add_theme_stylebox_override("normal", normal_style)

	var hover_style := normal_style.duplicate()
	hover_style.bg_color = Color(0.15, 0.25, 0.18, 0.95)
	hover_style.border_color = Color(0.3, 0.6, 0.4, 0.8)
	add_theme_stylebox_override("hover", hover_style)

	var pressed_style := normal_style.duplicate()
	pressed_style.bg_color = Color(0.1, 0.3, 0.15, 0.95)
	add_theme_stylebox_override("pressed", pressed_style)

	var disabled_style := normal_style.duplicate()
	disabled_style.bg_color = Color(0.08, 0.08, 0.08, 0.7)
	disabled_style.border_color = Color(0.2, 0.2, 0.2, 0.4)
	add_theme_stylebox_override("disabled", disabled_style)

	# Build child layout with icons instead of text
	var display_name: String = entity_data.get("name", entity_id.capitalize())

	var hbox := HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = 12
	hbox.offset_right = -6
	hbox.offset_top = 0
	hbox.offset_bottom = 0
	hbox.add_theme_constant_override("separation", 3)
	hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hbox)

	_name_label = Label.new()
	_name_label.text = display_name + "  "
	_name_label.add_theme_font_size_override("font_size", 13)
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(_name_label)

	var energy_icon := _EnergyIconSmall.new()
	energy_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(energy_icon)

	_energy_label = Label.new()
	_energy_label.text = str(int(energy_cost))
	_energy_label.add_theme_font_size_override("font_size", 13)
	_energy_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(_energy_label)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(4, 0)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(spacer)

	var mat_icon := _MaterialsIconSmall.new()
	mat_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(mat_icon)

	_material_label = Label.new()
	_material_label.text = str(int(material_cost))
	_material_label.add_theme_font_size_override("font_size", 13)
	_material_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(_material_label)

	pressed.connect(_on_pressed)


func _on_pressed() -> void:
	item_selected.emit(entity_id)


func _on_resources_changed(_energy: float, _materials: float) -> void:
	_update_affordability()


func _on_tech_changed(_tier: int) -> void:
	_update_affordability()


func _meets_tech_requirement() -> bool:
	if required_tech_level == "none" or required_tech_level == "":
		return true
	var required_tier: int = 0
	match required_tech_level:
		"tier_1": required_tier = 1
		"tier_2": required_tier = 2
		"tier_3": required_tier = 3
	return GameState.central_tower_tier >= required_tier


func _update_affordability() -> void:
	var tech_ok := _meets_tech_requirement()
	var affordable := GameState.can_afford(energy_cost, material_cost)
	disabled = not (affordable and tech_ok)
	var color: Color
	if not tech_ok:
		color = Color(0.6, 0.3, 0.3)
		tooltip_text = "Requires Central Tower %s" % required_tech_level.replace("_", " ").capitalize()
	elif affordable:
		color = Color(0.85, 0.95, 0.85)
		tooltip_text = ""
	else:
		color = Color(0.45, 0.45, 0.45)
		tooltip_text = ""
	for lbl: Label in [_name_label, _energy_label, _material_label]:
		if lbl:
			lbl.add_theme_color_override("font_color", color)


class _EnergyIconSmall extends Control:
	func _init() -> void:
		custom_minimum_size = Vector2(14, 14)

	func _draw() -> void:
		var s := get_size()
		var rect := Rect2(Vector2.ZERO, s)
		draw_rect(rect, Color(0.08, 0.15, 0.45))
		draw_rect(rect, Color(0.25, 0.45, 0.85), false, 1.0)
		var arc: PackedVector2Array = PackedVector2Array([
			Vector2(s.x * 0.55, s.y * 0.08),
			Vector2(s.x * 0.38, s.y * 0.32),
			Vector2(s.x * 0.58, s.y * 0.38),
			Vector2(s.x * 0.30, s.y * 0.65),
			Vector2(s.x * 0.62, s.y * 0.52),
			Vector2(s.x * 0.42, s.y * 0.92),
		])
		for i in range(arc.size() - 1):
			draw_line(arc[i], arc[i + 1], Color(0.2, 0.5, 1.0, 0.3), 3.0)
		for i in range(arc.size() - 1):
			draw_line(arc[i], arc[i + 1], Color(0.5, 0.75, 1.0, 0.6), 1.8)
		for i in range(arc.size() - 1):
			draw_line(arc[i], arc[i + 1], Color(0.85, 0.92, 1.0), 1.0)


class _MaterialsIconSmall extends Control:
	func _init() -> void:
		custom_minimum_size = Vector2(14, 14)

	func _draw() -> void:
		var s := get_size()
		var metal := Color(0.55, 0.58, 0.62)
		var highlight := Color(0.75, 0.77, 0.80)
		var shadow := Color(0.35, 0.37, 0.40)
		var mx := s.x * 0.1
		var flange_h := s.y * 0.22
		var web_w := s.x * 0.28
		var tf := Rect2(mx, 0, s.x - mx * 2.0, flange_h)
		draw_rect(tf, metal)
		draw_line(Vector2(mx, 1), Vector2(s.x - mx, 1), highlight, 1.0)
		draw_line(Vector2(mx, flange_h), Vector2(s.x - mx, flange_h), shadow, 1.0)
		var bf := Rect2(mx, s.y - flange_h, s.x - mx * 2.0, flange_h)
		draw_rect(bf, metal)
		draw_line(Vector2(mx, s.y - flange_h), Vector2(s.x - mx, s.y - flange_h), highlight, 1.0)
		draw_line(Vector2(mx, s.y - 1), Vector2(s.x - mx, s.y - 1), shadow, 1.0)
		var web_x := (s.x - web_w) * 0.5
		var wr := Rect2(web_x, flange_h, web_w, s.y - flange_h * 2.0)
		draw_rect(wr, metal)
		draw_line(Vector2(web_x, flange_h), Vector2(web_x, s.y - flange_h), highlight, 1.0)
		draw_line(Vector2(web_x + web_w, flange_h), Vector2(web_x + web_w, s.y - flange_h), shadow, 1.0)
