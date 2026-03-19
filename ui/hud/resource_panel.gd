extends PanelContainer
## ResourcePanel - Displays Energy and Materials with icon art.
## Shows rate of gain only on hover. Updates on GameBus signals.

var energy_label: Label
var materials_label: Label
var energy_container: HBoxContainer
var mat_container: HBoxContainer
var _energy_rate_popup: PanelContainer
var _material_rate_popup: PanelContainer
var _energy_rate_label: Label
var _material_rate_label: Label

var _energy: float = 0.0
var _materials: float = 0.0
var _energy_rate: float = 0.0
var _material_rate: float = 0.0


func _ready() -> void:
	_build_ui()
	_connect_signals()
	_energy = GameState.energy
	_materials = GameState.materials
	_energy_rate = GameState.get_total_energy_rate()
	_material_rate = GameState.get_total_material_rate()
	_update_display()


func _build_ui() -> void:
	name = "ResourcePanel"
	custom_minimum_size = Vector2(280, 40)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.9)
	style.border_color = Color(0.2, 0.5, 0.3, 0.8)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8)
	add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	add_child(hbox)

	# Energy section
	energy_container = HBoxContainer.new()
	energy_container.add_theme_constant_override("separation", 6)
	energy_container.mouse_filter = Control.MOUSE_FILTER_STOP
	hbox.add_child(energy_container)

	var energy_icon := EnergyIcon.new()
	energy_container.add_child(energy_icon)

	energy_label = Label.new()
	energy_label.text = "0"
	energy_label.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0))
	energy_label.add_theme_font_size_override("font_size", 16)
	energy_container.add_child(energy_label)

	# Separator
	var sep := Label.new()
	sep.text = "|"
	sep.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	sep.add_theme_font_size_override("font_size", 16)
	hbox.add_child(sep)

	# Materials section
	mat_container = HBoxContainer.new()
	mat_container.add_theme_constant_override("separation", 6)
	mat_container.mouse_filter = Control.MOUSE_FILTER_STOP
	hbox.add_child(mat_container)

	var mat_icon := MaterialsIcon.new()
	mat_container.add_child(mat_icon)

	materials_label = Label.new()
	materials_label.text = "0"
	materials_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	materials_label.add_theme_font_size_override("font_size", 16)
	mat_container.add_child(materials_label)

	# Rate popups (hidden by default)
	_energy_rate_popup = _create_rate_popup()
	_energy_rate_label = _energy_rate_popup.get_child(0)
	_energy_rate_label.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0))
	energy_container.add_child(_energy_rate_popup)

	_material_rate_popup = _create_rate_popup()
	_material_rate_label = _material_rate_popup.get_child(0)
	_material_rate_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	mat_container.add_child(_material_rate_popup)

	# Connect hover signals
	energy_container.mouse_entered.connect(_on_energy_hover.bind(true))
	energy_container.mouse_exited.connect(_on_energy_hover.bind(false))
	mat_container.mouse_entered.connect(_on_material_hover.bind(true))
	mat_container.mouse_exited.connect(_on_material_hover.bind(false))


func _create_rate_popup() -> PanelContainer:
	var popup := PanelContainer.new()
	popup.visible = false

	var popup_style := StyleBoxFlat.new()
	popup_style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	popup_style.border_color = Color(0.3, 0.5, 0.4, 0.8)
	popup_style.set_border_width_all(1)
	popup_style.set_corner_radius_all(3)
	popup_style.content_margin_left = 6
	popup_style.content_margin_right = 6
	popup_style.content_margin_top = 3
	popup_style.content_margin_bottom = 3
	popup.add_theme_stylebox_override("panel", popup_style)

	var label := Label.new()
	label.add_theme_font_size_override("font_size", 13)
	popup.add_child(label)

	return popup


func _on_energy_hover(hovered: bool) -> void:
	_energy_rate_popup.visible = hovered


func _on_material_hover(hovered: bool) -> void:
	_material_rate_popup.visible = hovered


func _connect_signals() -> void:
	GameBus.resources_changed.connect(_on_resources_changed)
	GameBus.resource_income_changed.connect(_on_income_changed)


func _on_resources_changed(energy: float, materials: float) -> void:
	_energy = energy
	_materials = materials
	_update_display()


func _on_income_changed(energy_rate: float, material_rate: float) -> void:
	_energy_rate = energy_rate
	_material_rate = material_rate
	_update_display()


func _update_display() -> void:
	energy_label.text = "%d" % int(_energy)
	materials_label.text = "%d" % int(_materials)
	_energy_rate_label.text = "+%d/s" % int(_energy_rate)
	_material_rate_label.text = "+%d/s" % int(_material_rate)


# --- Custom Icon Controls ---


class EnergyIcon extends Control:
	## Blue square with an electrical arc (lightning bolt) through it.

	func _init() -> void:
		custom_minimum_size = Vector2(22, 22)

	func _draw() -> void:
		var s := get_size()
		var rect := Rect2(Vector2.ZERO, s)

		# Dark blue square background
		draw_rect(rect, Color(0.08, 0.15, 0.45))
		# Brighter blue border
		draw_rect(rect, Color(0.25, 0.45, 0.85), false, 1.5)

		# Electrical arc - zigzag lightning bolt from top to bottom
		var arc: PackedVector2Array = PackedVector2Array([
			Vector2(s.x * 0.55, s.y * 0.08),
			Vector2(s.x * 0.38, s.y * 0.32),
			Vector2(s.x * 0.58, s.y * 0.38),
			Vector2(s.x * 0.30, s.y * 0.65),
			Vector2(s.x * 0.62, s.y * 0.52),
			Vector2(s.x * 0.42, s.y * 0.92),
		])

		# Outer glow
		for i in range(arc.size() - 1):
			draw_line(arc[i], arc[i + 1], Color(0.2, 0.5, 1.0, 0.3), 4.0)
		# Inner glow
		for i in range(arc.size() - 1):
			draw_line(arc[i], arc[i + 1], Color(0.5, 0.75, 1.0, 0.6), 2.5)
		# Core bolt
		for i in range(arc.size() - 1):
			draw_line(arc[i], arc[i + 1], Color(0.85, 0.92, 1.0), 1.2)


class MaterialsIcon extends Control:
	## Metal I-beam cross-section icon.

	func _init() -> void:
		custom_minimum_size = Vector2(22, 22)

	func _draw() -> void:
		var s := get_size()
		var metal := Color(0.55, 0.58, 0.62)
		var highlight := Color(0.75, 0.77, 0.80)
		var shadow := Color(0.35, 0.37, 0.40)

		var mx := s.x * 0.1        # Horizontal margin
		var flange_h := s.y * 0.22  # Flange thickness
		var web_w := s.x * 0.28     # Web width

		# Top flange
		var tf := Rect2(mx, 0, s.x - mx * 2.0, flange_h)
		draw_rect(tf, metal)
		# Top flange highlight (top edge)
		draw_line(Vector2(mx, 1), Vector2(s.x - mx, 1), highlight, 1.0)
		# Top flange shadow (bottom edge)
		draw_line(Vector2(mx, flange_h), Vector2(s.x - mx, flange_h), shadow, 1.0)

		# Bottom flange
		var bf := Rect2(mx, s.y - flange_h, s.x - mx * 2.0, flange_h)
		draw_rect(bf, metal)
		# Bottom flange highlight
		draw_line(Vector2(mx, s.y - flange_h), Vector2(s.x - mx, s.y - flange_h), highlight, 1.0)
		# Bottom flange shadow
		draw_line(Vector2(mx, s.y - 1), Vector2(s.x - mx, s.y - 1), shadow, 1.0)

		# Vertical web
		var web_x := (s.x - web_w) * 0.5
		var wr := Rect2(web_x, flange_h, web_w, s.y - flange_h * 2.0)
		draw_rect(wr, metal)
		# Web highlight (left edge)
		draw_line(Vector2(web_x, flange_h), Vector2(web_x, s.y - flange_h), highlight, 1.0)
		# Web shadow (right edge)
		draw_line(Vector2(web_x + web_w, flange_h), Vector2(web_x + web_w, s.y - flange_h), shadow, 1.0)
