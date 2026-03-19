extends Button
## BuildItem - Single buildable item button showing name, cost (E/M),
## whether affordable, and whether tech requirements are met.

signal item_selected(entity_id: String)

var entity_id: String = ""
var entity_data: Dictionary = {}
var energy_cost: float = 0.0
var material_cost: float = 0.0
var required_tech_level: String = "none"  # "none", "tier_1", "tier_2", "tier_3"


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
	alignment = HORIZONTAL_ALIGNMENT_LEFT

	var display_name: String = entity_data.get("name", entity_id.capitalize())
	text = "%s  [E:%d M:%d]" % [display_name, int(energy_cost), int(material_cost)]

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
	if not tech_ok:
		add_theme_color_override("font_color", Color(0.6, 0.3, 0.3))
		tooltip_text = "Requires Central Tower %s" % required_tech_level.replace("_", " ").capitalize()
	elif affordable:
		add_theme_color_override("font_color", Color(0.85, 0.95, 0.85))
		tooltip_text = ""
	else:
		add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))
		tooltip_text = ""
