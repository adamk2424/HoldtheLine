extends PanelContainer
## InfoPanel - Bottom-right panel.
## Shows stats, upgrades, and production controls for the focused entity.
## When multiple entities are selected, shows group thumbnails in the bottom half.

var _entity: Node = null

# UI elements
var _stats_container: VBoxContainer
var _upgrades_container: VBoxContainer
var _upgrade_title: Label
var _content_vbox: VBoxContainer
var _empty_label: Label

# Production elements
var _production_section: VBoxContainer
var _production_title: Label
var _unit_buttons_container: VBoxContainer
var _progress_bar: ProgressBar
var _progress_label: Label
var _queue_container: VBoxContainer

# Group selection elements
var _group_section: VBoxContainer
var _group_title: Label
var _group_grid: GridContainer
var _group_entities: Array = []

# Production state
var _building: Node = null
var _building_data: Dictionary = {}
var _queue: Array = []
var _build_progress: float = 0.0
var _current_build_time: float = 0.0


func _ready() -> void:
	_build_ui()
	_connect_signals()


func _build_ui() -> void:
	name = "InfoPanel"
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.04, 0.06, 0.97)
	style.border_color = Color(0.15, 0.35, 0.25, 0.8)
	style.border_width_top = 2
	style.border_width_left = 2
	style.border_width_bottom = 0
	style.border_width_right = 0
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	add_theme_stylebox_override("panel", style)

	# Main vertical split: top = entity details (scrollable), bottom = group thumbnails
	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 0)
	main_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(main_vbox)

	# --- Top section: scrollable entity details ---
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.clip_contents = true
	main_vbox.add_child(scroll)

	_content_vbox = VBoxContainer.new()
	_content_vbox.add_theme_constant_override("separation", 4)
	_content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_content_vbox)

	# Empty state label
	_empty_label = Label.new()
	_empty_label.text = ""
	_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_empty_label.add_theme_font_size_override("font_size", 10)
	_empty_label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))
	_empty_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_vbox.add_child(_empty_label)

	# --- Stats section ---
	_stats_container = VBoxContainer.new()
	_stats_container.name = "StatsContainer"
	_stats_container.add_theme_constant_override("separation", 3)
	_stats_container.visible = false
	_content_vbox.add_child(_stats_container)

	# --- Upgrades section ---
	var upgrade_sep := HSeparator.new()
	upgrade_sep.add_theme_constant_override("separation", 2)
	_content_vbox.add_child(upgrade_sep)

	_upgrade_title = Label.new()
	_upgrade_title.text = "Upgrades"
	_upgrade_title.add_theme_font_size_override("font_size", 11)
	_upgrade_title.add_theme_color_override("font_color", Color(0.8, 0.8, 0.3))
	_upgrade_title.visible = false
	_content_vbox.add_child(_upgrade_title)

	_upgrades_container = VBoxContainer.new()
	_upgrades_container.add_theme_constant_override("separation", 2)
	_upgrades_container.visible = false
	_content_vbox.add_child(_upgrades_container)

	# --- Production section ---
	_production_section = VBoxContainer.new()
	_production_section.add_theme_constant_override("separation", 4)
	_production_section.visible = false
	_content_vbox.add_child(_production_section)

	var prod_sep := HSeparator.new()
	prod_sep.add_theme_constant_override("separation", 2)
	_production_section.add_child(prod_sep)

	_production_title = Label.new()
	_production_title.text = "Production"
	_production_title.add_theme_font_size_override("font_size", 11)
	_production_title.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	_production_section.add_child(_production_title)

	_unit_buttons_container = VBoxContainer.new()
	_unit_buttons_container.add_theme_constant_override("separation", 2)
	_production_section.add_child(_unit_buttons_container)

	# Progress bar
	_progress_bar = ProgressBar.new()
	_progress_bar.custom_minimum_size = Vector2(0, 10)
	_progress_bar.max_value = 100.0
	_progress_bar.value = 0.0
	_progress_bar.show_percentage = false

	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.1, 0.1, 0.15)
	bar_bg.set_corner_radius_all(2)
	_progress_bar.add_theme_stylebox_override("background", bar_bg)

	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = Color(0.2, 0.6, 0.9)
	bar_fill.set_corner_radius_all(2)
	_progress_bar.add_theme_stylebox_override("fill", bar_fill)
	_production_section.add_child(_progress_bar)

	_progress_label = Label.new()
	_progress_label.text = "Idle"
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_progress_label.add_theme_font_size_override("font_size", 9)
	_progress_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	_production_section.add_child(_progress_label)

	# Queue
	var queue_label := Label.new()
	queue_label.text = "Queue"
	queue_label.add_theme_font_size_override("font_size", 10)
	queue_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	_production_section.add_child(queue_label)

	_queue_container = VBoxContainer.new()
	_queue_container.add_theme_constant_override("separation", 1)
	_production_section.add_child(_queue_container)

	# --- Bottom section: group selection thumbnails ---
	_build_group_section(main_vbox)


func _build_group_section(parent: VBoxContainer) -> void:
	_group_section = VBoxContainer.new()
	_group_section.name = "GroupSection"
	_group_section.add_theme_constant_override("separation", 4)
	_group_section.visible = false
	parent.add_child(_group_section)

	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 2)
	_group_section.add_child(sep)

	_group_title = Label.new()
	_group_title.text = "Selected (0)"
	_group_title.add_theme_font_size_override("font_size", 11)
	_group_title.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6))
	_group_section.add_child(_group_title)

	# Scrollable grid for thumbnails
	var group_scroll := ScrollContainer.new()
	group_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	group_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	group_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	group_scroll.custom_minimum_size = Vector2(0, 120)
	group_scroll.clip_contents = true
	_group_section.add_child(group_scroll)

	_group_grid = GridContainer.new()
	_group_grid.columns = 3
	_group_grid.add_theme_constant_override("h_separation", 3)
	_group_grid.add_theme_constant_override("v_separation", 3)
	_group_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	group_scroll.add_child(_group_grid)


func _connect_signals() -> void:
	GameBus.ui_info_panel_show.connect(_on_show)
	GameBus.ui_info_panel_hide.connect(_on_hide)
	GameBus.ui_group_selected.connect(_on_group_selected)
	GameBus.upgrade_completed.connect(_on_upgrade_completed)
	GameBus.resources_changed.connect(_on_resources_changed)
	GameBus.unit_production_started.connect(_on_production_started)
	GameBus.unit_production_completed.connect(_on_production_completed)


func _on_show(entity: Node) -> void:
	_entity = entity
	# If this entity is in the current group, just update focus without clearing group
	if entity in _group_entities:
		_populate_panel()
		_update_group_highlight()
	else:
		# New single selection, clear group
		_clear_group()
		_populate_panel()


func _on_hide() -> void:
	_entity = null
	_clear_panel()
	_hide_production()
	_clear_group()


func _on_group_selected(entities: Array) -> void:
	_group_entities = entities.duplicate()
	if not _group_entities.is_empty():
		_entity = _group_entities[0]
		_populate_panel()
		_populate_group_thumbnails()
		_group_section.visible = true
	else:
		_clear_group()


func _on_upgrade_completed(entity: Node, _upgrade_name: String) -> void:
	if entity == _entity and is_instance_valid(_entity):
		_populate_panel()


func _on_resources_changed(_energy: float, _materials: float) -> void:
	if _entity and is_instance_valid(_entity):
		var data: Dictionary = {}
		if _entity is EntityBase:
			data = _entity.data
		if data.is_empty():
			var eid: String = _entity.get("entity_id") if _entity.get("entity_id") else ""
			if not eid.is_empty():
				data = GameData.get_entity_data(eid)
		_populate_upgrades(data)


func _populate_panel() -> void:
	if not _entity or not is_instance_valid(_entity):
		_clear_panel()
		return

	var data: Dictionary = {}
	var entity_id: String = ""

	if _entity is EntityBase:
		data = _entity.data
		entity_id = _entity.entity_id
	elif _entity.has_method("get_data_value"):
		entity_id = _entity.get("entity_id")
		data = GameData.get_entity_data(entity_id)

	if data.is_empty() and not entity_id.is_empty():
		data = GameData.get_entity_data(entity_id)

	_empty_label.visible = false

	_populate_stats(data)
	_stats_container.visible = true
	_populate_buffs()

	_populate_upgrades(data)
	_populate_production(entity_id)


func _clear_panel() -> void:
	_empty_label.visible = true
	_stats_container.visible = false
	_upgrade_title.visible = false
	_upgrades_container.visible = false
	_production_section.visible = false

	for child in _stats_container.get_children():
		child.queue_free()
	for child in _upgrades_container.get_children():
		child.queue_free()


func _populate_stats(data: Dictionary) -> void:
	for child in _stats_container.get_children():
		child.queue_free()

	var stats_to_show: Array = []

	if data.has("damage") and int(data.get("damage", 0)) > 0:
		stats_to_show.append(["Damage", str(int(data.get("damage", 0)))])
	if data.has("attack_range") and int(data.get("attack_range", 0)) > 0:
		stats_to_show.append(["Range", str(int(data.get("attack_range", 0)))])
	if data.has("attack_rate") and float(data.get("attack_rate", 0)) > 0:
		stats_to_show.append(["Fire Rate", "%.1fs" % float(data.get("attack_rate", 0))])
	if data.has("speed"):
		stats_to_show.append(["Speed", str(int(data.get("speed", 0)))])

	# Support tower effect stats
	if data.has("effect_type"):
		var effect_type: String = data.get("effect_type", "")
		var effect_value: float = float(data.get("effect_value", 0))
		var effect_radius: float = float(data.get("effect_radius", 0))
		match effect_type:
			"heal":
				stats_to_show.append(["Healing", "%d HP/sec" % int(effect_value)])
			"damage_buff":
				stats_to_show.append(["Damage Buff", "+%d%%" % int(effect_value)])
			"range_buff":
				stats_to_show.append(["Range Buff", "+%d%%" % int(effect_value)])
			"armor_buff":
				stats_to_show.append(["Armor Buff", "+%d" % int(effect_value)])
			_:
				stats_to_show.append(["Effect", "%s: %d" % [effect_type, int(effect_value)]])
		if effect_radius > 0:
			stats_to_show.append(["Effect Radius", str(int(effect_radius))])

	var specials: Array = data.get("specials", [])
	for special: Dictionary in specials:
		stats_to_show.append(["*" + special.get("name", ""), ""])

	if stats_to_show.is_empty():
		_stats_container.visible = false
		return

	for stat: Array in stats_to_show:
		var row := HBoxContainer.new()
		_stats_container.add_child(row)

		var name_label := Label.new()
		name_label.text = stat[0]
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)

		if not stat[1].is_empty():
			var value_label := Label.new()
			value_label.text = stat[1]
			value_label.add_theme_font_size_override("font_size", 10)
			value_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
			row.add_child(value_label)


func _populate_buffs() -> void:
	if not _entity or not is_instance_valid(_entity):
		return

	var buff_comp: BuffDebuffComponent = null
	if _entity is EntityBase:
		buff_comp = _entity.buff_debuff_component

	if not buff_comp:
		return

	var has_effects: bool = not buff_comp.active_buffs.is_empty() or not buff_comp.active_debuffs.is_empty()
	if not has_effects:
		return

	var sep := HSeparator.new()
	_stats_container.add_child(sep)

	for buff_id: String in buff_comp.active_buffs:
		var buff: Dictionary = buff_comp.active_buffs[buff_id]
		var row := HBoxContainer.new()
		_stats_container.add_child(row)

		var icon := Label.new()
		icon.text = "+"
		icon.add_theme_font_size_override("font_size", 10)
		icon.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
		row.add_child(icon)

		var lbl := Label.new()
		lbl.text = " %s" % buff_id.replace("_", " ").capitalize()
		lbl.add_theme_font_size_override("font_size", 9)
		lbl.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)

		var val_lbl := Label.new()
		val_lbl.text = "%+.0f%%" % (buff.get("value", 0) * 100.0)
		val_lbl.add_theme_font_size_override("font_size", 9)
		val_lbl.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
		row.add_child(val_lbl)

	for debuff_id: String in buff_comp.active_debuffs:
		var debuff: Dictionary = buff_comp.active_debuffs[debuff_id]
		var row := HBoxContainer.new()
		_stats_container.add_child(row)

		var icon := Label.new()
		icon.text = "-"
		icon.add_theme_font_size_override("font_size", 10)
		icon.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
		row.add_child(icon)

		var lbl := Label.new()
		lbl.text = " %s" % debuff_id.replace("_", " ").capitalize()
		lbl.add_theme_font_size_override("font_size", 9)
		lbl.add_theme_color_override("font_color", Color(0.8, 0.5, 0.5))
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)

		var val_lbl := Label.new()
		val_lbl.text = "%+.0f%%" % (-debuff.get("value", 0) * 100.0)
		val_lbl.add_theme_font_size_override("font_size", 9)
		val_lbl.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
		row.add_child(val_lbl)


func _populate_upgrades(data: Dictionary) -> void:
	for child in _upgrades_container.get_children():
		child.queue_free()

	if _entity is CentralTower:
		_populate_central_tower_upgrades()
		return

	if _entity is TowerBase and (_entity as TowerBase).sequential_upgrades:
		_populate_sequential_tower_upgrades()
		return

	var upgrade_paths: Array = data.get("upgrade_paths", [])
	if upgrade_paths.is_empty():
		_upgrade_title.visible = false
		_upgrades_container.visible = false
		return

	_upgrade_title.visible = true
	_upgrades_container.visible = true

	for i in upgrade_paths.size():
		var upgrade: Dictionary = upgrade_paths[i]
		var btn := Button.new()

		var energy_cost: int = int(upgrade.get("cost_energy", 0))
		var material_cost: int = int(upgrade.get("cost_materials", 0))
		btn.text = "%s (E:%d M:%d)" % [upgrade.get("name", "Upgrade"), energy_cost, material_cost]
		btn.custom_minimum_size = Vector2(0, 22)
		btn.add_theme_font_size_override("font_size", 9)

		var can_afford := GameState.can_afford(energy_cost, material_cost)

		var btn_style := StyleBoxFlat.new()
		if can_afford:
			btn_style.bg_color = Color(0.1, 0.2, 0.15, 0.9)
			btn_style.border_color = Color(0.2, 0.6, 0.3)
		else:
			btn_style.bg_color = Color(0.15, 0.15, 0.15, 0.7)
			btn_style.border_color = Color(0.3, 0.3, 0.3)
		btn_style.set_border_width_all(1)
		btn_style.set_corner_radius_all(3)
		btn_style.set_content_margin_all(4)
		btn.add_theme_stylebox_override("normal", btn_style)

		if not can_afford:
			btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			btn.disabled = true

		btn.pressed.connect(_on_upgrade_pressed.bind(i))
		_upgrades_container.add_child(btn)


func _populate_sequential_tower_upgrades() -> void:
	var tower: TowerBase = _entity as TowerBase
	var upgrade: Dictionary = tower.get_next_sequential_upgrade()

	if upgrade.is_empty():
		_upgrade_title.text = "Fully Upgraded (Tier %d)" % (tower.current_tier + 1)
		_upgrade_title.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))
		_upgrade_title.visible = true
		_upgrades_container.visible = false
		return

	_upgrade_title.text = "Upgrade (Tier %d/%d)" % [tower.current_tier + 1, tower.upgrade_paths.size() + 1]
	_upgrade_title.add_theme_color_override("font_color", Color(0.8, 0.8, 0.3))
	_upgrade_title.visible = true
	_upgrades_container.visible = true

	var btn := Button.new()
	var energy_cost: int = int(upgrade.get("cost_energy", 0))
	var material_cost: int = int(upgrade.get("cost_materials", 0))
	btn.text = "%s (E:%d M:%d)" % [upgrade.get("name", "Upgrade"), energy_cost, material_cost]
	btn.custom_minimum_size = Vector2(0, 22)
	btn.add_theme_font_size_override("font_size", 9)

	var can_afford := GameState.can_afford(energy_cost, material_cost)

	var btn_style := StyleBoxFlat.new()
	if can_afford:
		btn_style.bg_color = Color(0.1, 0.2, 0.15, 0.9)
		btn_style.border_color = Color(0.2, 0.6, 0.3)
	else:
		btn_style.bg_color = Color(0.15, 0.15, 0.15, 0.7)
		btn_style.border_color = Color(0.3, 0.3, 0.3)
	btn_style.set_border_width_all(1)
	btn_style.set_corner_radius_all(3)
	btn_style.set_content_margin_all(4)
	btn.add_theme_stylebox_override("normal", btn_style)

	if not can_afford:
		btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		btn.disabled = true

	btn.pressed.connect(_on_upgrade_pressed.bind(tower.current_tier))
	_upgrades_container.add_child(btn)

	var desc: String = upgrade.get("stat_changes", "")
	if not desc.is_empty():
		var desc_label := Label.new()
		desc_label.text = desc
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_upgrades_container.add_child(desc_label)


func _populate_central_tower_upgrades() -> void:
	var central: CentralTower = _entity as CentralTower
	var upgrade: Dictionary = central.get_next_upgrade()

	if upgrade.is_empty():
		_upgrade_title.text = "Fully Upgraded (Tier %d)" % central.current_tier
		_upgrade_title.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))
		_upgrade_title.visible = true
		_upgrades_container.visible = false
		return

	_upgrade_title.text = "Tech Upgrade (Tier %d/%d)" % [central.current_tier, central.upgrade_paths.size()]
	_upgrade_title.add_theme_color_override("font_color", Color(0.8, 0.8, 0.3))
	_upgrade_title.visible = true
	_upgrades_container.visible = true

	var btn := Button.new()
	var energy_cost: int = int(upgrade.get("cost_energy", 0))
	var material_cost: int = int(upgrade.get("cost_materials", 0))
	var required_kills: int = int(upgrade.get("required_boss_kills", 0))
	var upgrade_name: String = upgrade.get("name", "Upgrade")

	btn.text = "%s (E:%d M:%d)" % [upgrade_name, energy_cost, material_cost]
	btn.custom_minimum_size = Vector2(0, 22)
	btn.add_theme_font_size_override("font_size", 9)

	var can_afford := GameState.can_afford(energy_cost, material_cost)
	var has_boss_kills := GameState.boss_kills >= required_kills
	var can_upgrade := can_afford and has_boss_kills

	var btn_style := StyleBoxFlat.new()
	if can_upgrade:
		btn_style.bg_color = Color(0.1, 0.2, 0.15, 0.9)
		btn_style.border_color = Color(0.2, 0.6, 0.3)
	else:
		btn_style.bg_color = Color(0.15, 0.15, 0.15, 0.7)
		btn_style.border_color = Color(0.3, 0.3, 0.3)
	btn_style.set_border_width_all(1)
	btn_style.set_corner_radius_all(3)
	btn_style.set_content_margin_all(4)
	btn.add_theme_stylebox_override("normal", btn_style)

	if not can_upgrade:
		btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		btn.disabled = true

	btn.pressed.connect(_on_upgrade_pressed.bind(central.current_tier))
	_upgrades_container.add_child(btn)

	var desc: String = upgrade.get("description", "")
	if not desc.is_empty():
		var desc_label := Label.new()
		desc_label.text = desc
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_upgrades_container.add_child(desc_label)

	if not has_boss_kills:
		var req_label := Label.new()
		req_label.text = "Requires: %d Boss Kills (have %d)" % [required_kills, GameState.boss_kills]
		req_label.add_theme_font_size_override("font_size", 9)
		req_label.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))
		_upgrades_container.add_child(req_label)


func _on_upgrade_pressed(upgrade_index: int) -> void:
	if _entity and is_instance_valid(_entity):
		GameBus.upgrade_requested.emit(_entity, upgrade_index)


# --- Production ---

func _populate_production(entity_id: String) -> void:
	var building_data := GameData.get_production_building(entity_id)
	if building_data.is_empty():
		_hide_production()
		return

	_building = _entity
	_building_data = building_data
	_production_title.text = _building_data.get("name", "Production")
	_sync_queue_from_building()
	_populate_unit_buttons()
	_update_queue_display()
	_production_section.visible = true


func _hide_production() -> void:
	_production_section.visible = false
	_building = null
	_building_data = {}
	_queue.clear()
	_build_progress = 0.0
	_current_build_time = 0.0


func _sync_queue_from_building() -> void:
	if not _building or not is_instance_valid(_building):
		return
	var bq: Variant = _building.get("_build_queue")
	if bq is Array:
		_queue = bq.duplicate()
	else:
		_queue.clear()
	# Sync progress
	var is_prod: Variant = _building.get("_is_producing")
	var bt: Variant = _building.get("_current_build_time")
	if is_prod and bt is float and bt > 0.0 and not _queue.is_empty():
		_current_build_time = bt
		var timer: Variant = _building.get("_build_timer")
		if timer and timer is Timer:
			_build_progress = bt - timer.time_left
		else:
			_build_progress = 0.0
	else:
		_build_progress = 0.0
		_current_build_time = 0.0


func _populate_unit_buttons() -> void:
	for child in _unit_buttons_container.get_children():
		child.queue_free()

	var produces: Array = _building_data.get("produces", [])

	for unit_id: String in produces:
		var unit_data := GameData.get_unit(unit_id)
		if unit_data.is_empty():
			continue

		var btn := Button.new()
		var display_name: String = unit_data.get("name", unit_id.capitalize())
		var energy_cost: int = int(unit_data.get("cost_energy", 0))
		var material_cost: int = int(unit_data.get("cost_materials", 0))
		var pop_cost: int = int(unit_data.get("pop_cost", 1))

		btn.text = "%s  [E:%d M:%d Pop:%d]" % [display_name, energy_cost, material_cost, pop_cost]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(0, 22)
		btn.add_theme_font_size_override("font_size", 9)

		var btn_style := StyleBoxFlat.new()
		btn_style.bg_color = Color(0.08, 0.12, 0.18, 0.9)
		btn_style.border_color = Color(0.2, 0.4, 0.5, 0.6)
		btn_style.set_border_width_all(1)
		btn_style.set_corner_radius_all(4)
		btn_style.set_content_margin_all(3)
		btn.add_theme_stylebox_override("normal", btn_style)

		var hover := btn_style.duplicate()
		hover.bg_color = Color(0.12, 0.18, 0.25, 0.95)
		hover.border_color = Color(0.3, 0.5, 0.7, 0.8)
		btn.add_theme_stylebox_override("hover", hover)

		var can_afford := GameState.can_afford(energy_cost, material_cost)
		if not can_afford:
			btn.disabled = true
			btn.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))
		else:
			btn.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))

		btn.pressed.connect(_on_unit_button_pressed.bind(unit_id))
		_unit_buttons_container.add_child(btn)


func _on_unit_button_pressed(unit_id: String) -> void:
	if not _building or not is_instance_valid(_building):
		return
	if not _building.has_method("queue_unit"):
		return
	var success: bool = _building.call("queue_unit", unit_id)
	if success:
		_sync_queue_from_building()
		_update_queue_display()
		GameBus.audio_play.emit("ui.production_queue")
		_populate_unit_buttons()


func _update_queue_display() -> void:
	for child in _queue_container.get_children():
		child.queue_free()

	if _queue.is_empty():
		_progress_bar.value = 0
		_progress_label.text = "Idle"
		var empty_label := Label.new()
		empty_label.text = "Queue empty"
		empty_label.add_theme_font_size_override("font_size", 9)
		empty_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		_queue_container.add_child(empty_label)
		return

	var QueueSlotScript := preload("res://ui/production_panel/queue_slot.gd")

	for i in _queue.size():
		var slot := PanelContainer.new()
		slot.set_script(QueueSlotScript)
		_queue_container.add_child(slot)

		var is_active: bool = (i == 0)
		var unit_data := GameData.get_unit(_queue[i])
		var build_time: float = float(unit_data.get("build_time", 5.0))
		var remaining: float = build_time if not is_active else max(0.0, build_time - _build_progress)

		slot.setup(i, _queue[i], remaining, is_active)
		slot.cancel_requested.connect(_on_cancel_slot)


func _on_cancel_slot(slot_index: int) -> void:
	if slot_index >= 0 and slot_index < _queue.size():
		if _building and is_instance_valid(_building) and _building.has_method("cancel_production"):
			_building.cancel_production(slot_index)
		_sync_queue_from_building()
		if slot_index == 0:
			_build_progress = 0.0
		_update_queue_display()
		_populate_unit_buttons()


func _on_production_started(building: Node, unit_id: String) -> void:
	if building == _building:
		_sync_queue_from_building()
		_build_progress = 0.0
		var unit_data := GameData.get_unit(unit_id)
		_current_build_time = float(unit_data.get("build_time", 5.0))
		_progress_label.text = "Building: %s" % unit_data.get("name", unit_id)
		_update_queue_display()


func _on_production_completed(building: Node, _unit_id: String, _unit: Node) -> void:
	if building == _building:
		_sync_queue_from_building()
		_build_progress = 0.0
		_update_queue_display()
		_populate_unit_buttons()


# --- Group Selection ---

func _populate_group_thumbnails() -> void:
	for child in _group_grid.get_children():
		child.queue_free()

	_group_title.text = "Selected (%d)" % _group_entities.size()

	for entity: Node in _group_entities:
		if not is_instance_valid(entity):
			continue
		var thumb := _create_thumbnail(entity)
		_group_grid.add_child(thumb)


func _create_thumbnail(entity: Node) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 32)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Get entity info
	var display_name: String = ""
	var entity_type: String = ""
	var border_color := Color(0.3, 0.3, 0.3)

	if entity is EntityBase:
		display_name = entity.data.get("name", entity.entity_id.capitalize())
		entity_type = entity.entity_type
	else:
		display_name = "Unknown"

	# Color-code by type
	match entity_type:
		"unit":
			border_color = Color(0.2, 0.6, 0.2)
		"tower":
			border_color = Color(0.2, 0.4, 0.8)
		"building":
			border_color = Color(0.7, 0.7, 0.2)
		_:
			border_color = Color(0.4, 0.4, 0.4)

	# Truncate long names
	if display_name.length() > 10:
		display_name = display_name.substr(0, 9) + "."

	btn.text = display_name
	btn.add_theme_font_size_override("font_size", 9)

	var is_focused: bool = (entity == _entity)

	var btn_style := StyleBoxFlat.new()
	if is_focused:
		btn_style.bg_color = Color(border_color.r * 0.4, border_color.g * 0.4, border_color.b * 0.4, 0.95)
		btn_style.border_color = Color(border_color.r + 0.3, border_color.g + 0.3, border_color.b + 0.3)
		btn_style.set_border_width_all(2)
	else:
		btn_style.bg_color = Color(0.08, 0.08, 0.12, 0.9)
		btn_style.border_color = border_color
		btn_style.set_border_width_all(1)
	btn_style.set_corner_radius_all(3)
	btn_style.set_content_margin_all(2)
	btn.add_theme_stylebox_override("normal", btn_style)

	var hover_style := btn_style.duplicate()
	hover_style.bg_color = Color(border_color.r * 0.3, border_color.g * 0.3, border_color.b * 0.3, 0.95)
	hover_style.border_color = Color(border_color.r + 0.2, border_color.g + 0.2, border_color.b + 0.2)
	btn.add_theme_stylebox_override("hover", hover_style)

	btn.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95))

	btn.pressed.connect(_on_thumbnail_pressed.bind(entity))
	return btn


func _on_thumbnail_pressed(entity: Node) -> void:
	if not is_instance_valid(entity):
		return
	_entity = entity
	_populate_panel()
	_update_group_highlight()


func _update_group_highlight() -> void:
	# Rebuild thumbnails to update highlight
	_populate_group_thumbnails()


func _clear_group() -> void:
	_group_entities.clear()
	_group_section.visible = false
	for child in _group_grid.get_children():
		child.queue_free()


func _process(_delta: float) -> void:
	if not _building or not is_instance_valid(_building):
		return
	if not _production_section.visible:
		return

	# Read build state directly from building
	var is_prod: bool = _building.get("_is_producing") == true
	var bt: float = float(_building.get("_current_build_time")) if _building.get("_current_build_time") else 0.0
	var timer: Variant = _building.get("_build_timer")

	if is_prod and bt > 0.0 and timer is Timer:
		var elapsed: float = bt - timer.time_left
		_progress_bar.max_value = bt
		_progress_bar.value = clampf(elapsed, 0.0, bt)
		_build_progress = elapsed
		_current_build_time = bt
		if _progress_label.text == "Idle" and not _queue.is_empty():
			var unit_data := GameData.get_unit(_queue[0])
			_progress_label.text = "Building: %s" % unit_data.get("name", _queue[0])
	else:
		_progress_bar.value = 0
