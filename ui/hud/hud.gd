extends CanvasLayer
## HUD - StarCraft-style HUD layout.
## Top bar: resources, population, timer, kills.
## Minimap: upper-right corner.
## Bottom bar: permanent panel - left (build/commands), center (name/HP/armor/sell), right (stats/upgrades, taller).

var _top_bar: HBoxContainer

# Component references
var resource_panel: PanelContainer
var population_panel: PanelContainer
var timer_panel: PanelContainer
var minimap_panel: PanelContainer
var info_panel: PanelContainer
var build_menu_button: Button
var kills_label: Label

# Bottom bar center selection display
var _selection_name: Label
var _selection_type: Label
var _selection_hp_bar: ProgressBar
var _selection_hp_label: Label
var _selection_armor_label: Label
var _selection_container: VBoxContainer
var _selected_entity: Node = null
var _sell_mode_button: Button
var _is_sell_mode: bool = false

# Bottom bar constants
const BOTTOM_BAR_HEIGHT := 150
const LEFT_SECTION_WIDTH := 140
const RIGHT_PANEL_RATIO := 0.30  # Right panel takes 30% of screen width
const RIGHT_PANEL_HEIGHT := 315  # 25% shorter than original 420


func _ready() -> void:
	layer = 10
	_build_layout()
	_connect_signals()


func _build_layout() -> void:
	# --- TOP BAR (absolute positioned at top) ---
	var top_margin := MarginContainer.new()
	top_margin.name = "TopMargin"
	top_margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top_margin.offset_bottom = 56
	top_margin.add_theme_constant_override("margin_left", 10)
	top_margin.add_theme_constant_override("margin_right", 10)
	top_margin.add_theme_constant_override("margin_top", 8)
	top_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_margin)

	_top_bar = HBoxContainer.new()
	_top_bar.name = "TopBar"
	_top_bar.add_theme_constant_override("separation", 12)
	_top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_margin.add_child(_top_bar)

	# Resource panel
	var ResourcePanelScript := preload("res://ui/hud/resource_panel.gd")
	resource_panel = PanelContainer.new()
	resource_panel.set_script(ResourcePanelScript)
	_top_bar.add_child(resource_panel)

	# Population panel
	var PopulationPanelScript := preload("res://ui/hud/population_panel.gd")
	population_panel = PanelContainer.new()
	population_panel.set_script(PopulationPanelScript)
	_top_bar.add_child(population_panel)

	# Spacer to push timer + kills toward center
	var center_spacer := Control.new()
	center_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_top_bar.add_child(center_spacer)

	# Timer panel (top center)
	var TimerPanelScript := preload("res://ui/hud/timer_panel.gd")
	timer_panel = PanelContainer.new()
	timer_panel.set_script(TimerPanelScript)
	_top_bar.add_child(timer_panel)

	# Kills counter (right of timer)
	var kills_panel := PanelContainer.new()
	kills_panel.custom_minimum_size = Vector2(120, 40)
	var kills_style := StyleBoxFlat.new()
	kills_style.bg_color = Color(0.08, 0.08, 0.12, 0.9)
	kills_style.border_color = Color(0.6, 0.2, 0.2, 0.8)
	kills_style.set_border_width_all(1)
	kills_style.set_corner_radius_all(4)
	kills_style.set_content_margin_all(8)
	kills_panel.add_theme_stylebox_override("panel", kills_style)
	_top_bar.add_child(kills_panel)

	var kills_hbox := HBoxContainer.new()
	kills_hbox.add_theme_constant_override("separation", 4)
	kills_panel.add_child(kills_hbox)

	var kills_icon := Label.new()
	kills_icon.text = "Kills:"
	kills_icon.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	kills_icon.add_theme_font_size_override("font_size", 12)
	kills_hbox.add_child(kills_icon)

	kills_label = Label.new()
	kills_label.text = "0"
	kills_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	kills_label.add_theme_font_size_override("font_size", 14)
	kills_hbox.add_child(kills_label)

	# Right spacer to balance centering (leave room for minimap)
	var right_spacer := Control.new()
	right_spacer.custom_minimum_size = Vector2(200, 0)
	right_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_top_bar.add_child(right_spacer)

	# --- MINIMAP (upper-right corner, absolute positioned) ---
	var MinimapScript := preload("res://ui/hud/minimap.gd")
	minimap_panel = PanelContainer.new()
	minimap_panel.set_script(MinimapScript)
	minimap_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	minimap_panel.offset_left = -198
	minimap_panel.offset_top = 8
	minimap_panel.offset_right = -8
	minimap_panel.offset_bottom = 198
	add_child(minimap_panel)

	# --- BOTTOM BAR (permanent, full-width) ---
	_build_bottom_bar()

	# --- RIGHT PANEL (taller, floating above bottom bar) ---
	_build_right_panel()



func _build_bottom_bar() -> void:
	var bottom_anchor := PanelContainer.new()
	bottom_anchor.name = "BottomBar"
	# Left 60% of screen, anchored to bottom
	bottom_anchor.anchor_left = 0.0
	bottom_anchor.anchor_right = 1.0 - RIGHT_PANEL_RATIO
	bottom_anchor.anchor_top = 1.0
	bottom_anchor.anchor_bottom = 1.0
	bottom_anchor.offset_top = -BOTTOM_BAR_HEIGHT
	bottom_anchor.offset_left = 0
	bottom_anchor.offset_right = 0
	bottom_anchor.offset_bottom = 0

	var bar_style := StyleBoxFlat.new()
	bar_style.bg_color = Color(0.04, 0.04, 0.06, 0.97)
	bar_style.border_color = Color(0.15, 0.35, 0.25, 0.8)
	bar_style.border_width_top = 2
	bar_style.border_width_bottom = 0
	bar_style.border_width_left = 0
	bar_style.border_width_right = 0
	bar_style.set_content_margin_all(0)
	bottom_anchor.add_theme_stylebox_override("panel", bar_style)
	add_child(bottom_anchor)

	var bar_hbox := HBoxContainer.new()
	bar_hbox.name = "BarContent"
	bar_hbox.add_theme_constant_override("separation", 0)
	bottom_anchor.add_child(bar_hbox)

	# --- LEFT SECTION: Build / Commands ---
	_build_left_section(bar_hbox)

	# Vertical separator
	_add_bar_separator(bar_hbox)

	# --- CENTER SECTION: Name / HP / armor / sell ---
	_build_center_section(bar_hbox)


func _build_left_section(parent: HBoxContainer) -> void:
	var left_margin := MarginContainer.new()
	left_margin.custom_minimum_size = Vector2(LEFT_SECTION_WIDTH, 0)
	left_margin.add_theme_constant_override("margin_left", 12)
	left_margin.add_theme_constant_override("margin_right", 8)
	left_margin.add_theme_constant_override("margin_top", 12)
	left_margin.add_theme_constant_override("margin_bottom", 12)
	parent.add_child(left_margin)

	var left := VBoxContainer.new()
	left.name = "LeftSection"
	left.add_theme_constant_override("separation", 8)
	left_margin.add_child(left)

	# Build menu button
	build_menu_button = Button.new()
	build_menu_button.name = "BuildMenuButton"
	build_menu_button.text = "Build [B]"
	build_menu_button.custom_minimum_size = Vector2(0, 36)
	build_menu_button.add_theme_font_size_override("font_size", 13)

	var build_btn_style := StyleBoxFlat.new()
	build_btn_style.bg_color = Color(0.1, 0.25, 0.15, 0.95)
	build_btn_style.border_color = Color(0.2, 0.7, 0.3)
	build_btn_style.set_border_width_all(2)
	build_btn_style.set_corner_radius_all(6)
	build_btn_style.set_content_margin_all(8)
	build_menu_button.add_theme_stylebox_override("normal", build_btn_style)

	var build_btn_hover := build_btn_style.duplicate()
	build_btn_hover.bg_color = Color(0.15, 0.35, 0.2, 0.95)
	build_menu_button.add_theme_stylebox_override("hover", build_btn_hover)

	build_menu_button.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	build_menu_button.pressed.connect(_on_build_menu_pressed)
	left.add_child(build_menu_button)

	# Sell mode button
	_sell_mode_button = Button.new()
	_sell_mode_button.name = "SellModeButton"
	_sell_mode_button.text = "Sell [X]"
	_sell_mode_button.custom_minimum_size = Vector2(0, 36)
	_sell_mode_button.add_theme_font_size_override("font_size", 13)

	var sell_btn_style := StyleBoxFlat.new()
	sell_btn_style.bg_color = Color(0.2, 0.2, 0.2, 0.95)
	sell_btn_style.border_color = Color(0.5, 0.5, 0.5)
	sell_btn_style.set_border_width_all(2)
	sell_btn_style.set_corner_radius_all(6)
	sell_btn_style.set_content_margin_all(8)
	_sell_mode_button.add_theme_stylebox_override("normal", sell_btn_style)

	var sell_btn_hover := sell_btn_style.duplicate()
	sell_btn_hover.bg_color = Color(0.3, 0.3, 0.3, 0.95)
	_sell_mode_button.add_theme_stylebox_override("hover", sell_btn_hover)

	_sell_mode_button.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	_sell_mode_button.pressed.connect(_on_sell_mode_pressed)
	left.add_child(_sell_mode_button)


func _build_center_section(parent: HBoxContainer) -> void:
	var center_margin := MarginContainer.new()
	center_margin.name = "CenterMargin"
	center_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_margin.add_theme_constant_override("margin_left", 16)
	center_margin.add_theme_constant_override("margin_right", 16)
	center_margin.add_theme_constant_override("margin_top", 10)
	center_margin.add_theme_constant_override("margin_bottom", 10)
	parent.add_child(center_margin)

	_selection_container = VBoxContainer.new()
	_selection_container.name = "SelectionInfo"
	_selection_container.add_theme_constant_override("separation", 4)
	_selection_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_selection_container.visible = false
	center_margin.add_child(_selection_container)

	# Entity name
	_selection_name = Label.new()
	_selection_name.text = ""
	_selection_name.add_theme_font_size_override("font_size", 21)
	_selection_name.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	_selection_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_selection_container.add_child(_selection_name)

	# Entity type
	_selection_type = Label.new()
	_selection_type.text = ""
	_selection_type.add_theme_font_size_override("font_size", 14)
	_selection_type.add_theme_color_override("font_color", Color(0.5, 0.7, 0.6))
	_selection_type.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_selection_container.add_child(_selection_type)

	# HP bar - centered under the name
	var hp_container := VBoxContainer.new()
	hp_container.add_theme_constant_override("separation", 2)
	hp_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	hp_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_selection_container.add_child(hp_container)

	_selection_hp_bar = ProgressBar.new()
	_selection_hp_bar.custom_minimum_size = Vector2(160, 14)
	_selection_hp_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_selection_hp_bar.max_value = 100.0
	_selection_hp_bar.value = 100.0
	_selection_hp_bar.show_percentage = false

	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.12, 0.04, 0.04)
	bar_bg.set_corner_radius_all(3)
	_selection_hp_bar.add_theme_stylebox_override("background", bar_bg)

	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = Color(0.2, 0.8, 0.3)
	bar_fill.set_corner_radius_all(3)
	_selection_hp_bar.add_theme_stylebox_override("fill", bar_fill)
	hp_container.add_child(_selection_hp_bar)

	_selection_hp_label = Label.new()
	_selection_hp_label.text = ""
	_selection_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_selection_hp_label.add_theme_font_size_override("font_size", 14)
	_selection_hp_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	hp_container.add_child(_selection_hp_label)

	# Armor row
	var armor_row := HBoxContainer.new()
	armor_row.add_theme_constant_override("separation", 6)
	armor_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_selection_container.add_child(armor_row)

	var armor_icon := Label.new()
	armor_icon.text = "Armor:"
	armor_icon.add_theme_font_size_override("font_size", 14)
	armor_icon.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	armor_row.add_child(armor_icon)

	_selection_armor_label = Label.new()
	_selection_armor_label.text = "0"
	_selection_armor_label.add_theme_font_size_override("font_size", 14)
	_selection_armor_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	armor_row.add_child(_selection_armor_label)




func _build_right_panel() -> void:
	# Right 40% of screen, taller than the bottom bar
	var InfoPanelScript := preload("res://ui/hud/info_panel.gd")
	info_panel = PanelContainer.new()
	info_panel.set_script(InfoPanelScript)
	info_panel.anchor_left = 1.0 - RIGHT_PANEL_RATIO
	info_panel.anchor_right = 1.0
	info_panel.anchor_top = 1.0
	info_panel.anchor_bottom = 1.0
	info_panel.offset_left = 0
	info_panel.offset_top = -RIGHT_PANEL_HEIGHT
	info_panel.offset_right = 0
	info_panel.offset_bottom = 0
	add_child(info_panel)


func _add_bar_separator(parent: HBoxContainer) -> void:
	var sep_container := Control.new()
	sep_container.custom_minimum_size = Vector2(2, 0)
	var sep_rect := ColorRect.new()
	sep_rect.color = Color(0.15, 0.35, 0.25, 0.6)
	sep_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sep_container.add_child(sep_rect)
	parent.add_child(sep_container)


func _connect_signals() -> void:
	GameBus.enemy_killed.connect(_on_enemy_killed)
	GameBus.ui_build_menu_toggled.connect(_on_build_menu_toggled)
	GameBus.ui_sell_mode_toggled.connect(_on_sell_mode_toggled)
	GameBus.ui_info_panel_show.connect(_on_selection_show)
	GameBus.ui_info_panel_hide.connect(_on_selection_hide)


func _process(_delta: float) -> void:
	if _selected_entity and is_instance_valid(_selected_entity):
		_update_selection_hp()
	elif _selected_entity:
		_selected_entity = null
		_selection_container.visible = false


func _on_build_menu_pressed() -> void:
	GameBus.ui_build_menu_toggled.emit(true)


func _on_enemy_killed(total_kills: int) -> void:
	kills_label.text = str(total_kills)


func _on_build_menu_toggled(is_open: bool) -> void:
	build_menu_button.disabled = is_open
	_sell_mode_button.disabled = is_open
	if is_open and _is_sell_mode:
		_is_sell_mode = false
		GameBus.ui_sell_mode_toggled.emit(false)
		_update_sell_button_style()


# --- Center selection display ---

func _on_selection_show(entity: Node) -> void:
	_selected_entity = entity
	_populate_selection()
	_selection_container.visible = true


func _on_selection_hide() -> void:
	_selected_entity = null
	_selection_container.visible = false


func _populate_selection() -> void:
	if not _selected_entity or not is_instance_valid(_selected_entity):
		_selection_container.visible = false
		return

	var data: Dictionary = {}
	var entity_id: String = ""
	var entity_type: String = ""

	if _selected_entity is EntityBase:
		data = _selected_entity.data
		entity_id = _selected_entity.entity_id
		entity_type = _selected_entity.entity_type

	if data.is_empty() and not entity_id.is_empty():
		data = GameData.get_entity_data(entity_id)

	_selection_name.text = data.get("name", entity_id.capitalize())
	_selection_type.text = entity_type.capitalize().replace("_", " ")
	_selection_armor_label.text = str(int(data.get("armor", 0)))
	_update_selection_hp()


func _update_selection_hp() -> void:
	if not _selected_entity or not is_instance_valid(_selected_entity):
		return

	var health_comp: Node = null
	if _selected_entity is EntityBase:
		health_comp = _selected_entity.health_component

	if health_comp and health_comp is HealthComponent:
		_selection_hp_bar.max_value = health_comp.max_hp
		_selection_hp_bar.value = health_comp.current_hp
		_selection_hp_label.text = "%d / %d" % [int(health_comp.current_hp), int(health_comp.max_hp)]

		var pct: float = health_comp.get_hp_percent()
		var fill: StyleBoxFlat = _selection_hp_bar.get_theme_stylebox("fill").duplicate()
		if pct > 0.6:
			fill.bg_color = Color(0.2, 0.8, 0.3)
		elif pct > 0.3:
			fill.bg_color = Color(0.8, 0.7, 0.2)
		else:
			fill.bg_color = Color(0.8, 0.2, 0.2)
		_selection_hp_bar.add_theme_stylebox_override("fill", fill)


func _on_sell_mode_pressed() -> void:
	_is_sell_mode = not _is_sell_mode
	GameBus.ui_sell_mode_toggled.emit(_is_sell_mode)
	_update_sell_button_style()


func _update_sell_button_style() -> void:
	if _is_sell_mode:
		var active_style := StyleBoxFlat.new()
		active_style.bg_color = Color(0.5, 0.15, 0.15, 0.95)
		active_style.border_color = Color(0.8, 0.3, 0.3)
		active_style.set_border_width_all(2)
		active_style.set_corner_radius_all(6)
		active_style.set_content_margin_all(8)
		_sell_mode_button.add_theme_stylebox_override("normal", active_style)
		var active_hover := active_style.duplicate()
		active_hover.bg_color = Color(0.6, 0.2, 0.2, 0.95)
		_sell_mode_button.add_theme_stylebox_override("hover", active_hover)
		_sell_mode_button.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	else:
		var normal_style := StyleBoxFlat.new()
		normal_style.bg_color = Color(0.2, 0.2, 0.2, 0.95)
		normal_style.border_color = Color(0.5, 0.5, 0.5)
		normal_style.set_border_width_all(2)
		normal_style.set_corner_radius_all(6)
		normal_style.set_content_margin_all(8)
		_sell_mode_button.add_theme_stylebox_override("normal", normal_style)
		var normal_hover := normal_style.duplicate()
		normal_hover.bg_color = Color(0.3, 0.3, 0.3, 0.95)
		_sell_mode_button.add_theme_stylebox_override("hover", normal_hover)
		_sell_mode_button.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))


func _on_sell_mode_toggled(is_active: bool) -> void:
	_is_sell_mode = is_active
	_update_sell_button_style()
