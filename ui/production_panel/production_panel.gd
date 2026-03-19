extends CanvasLayer
## ProductionPanel - Shows when a production building is selected.
## Anchored to bottom-left, above/overlapping the left section of the bottom bar.
## Shows available units to produce (buttons), current queue, build progress bar.

var _panel: PanelContainer
var _title_label: Label
var _unit_buttons_container: VBoxContainer
var _queue_container: VBoxContainer
var _progress_bar: ProgressBar
var _progress_label: Label
var _close_button: Button

var _building: Node = null
var _building_data: Dictionary = {}
var _is_visible: bool = false

# Production state (tracked locally for display)
var _queue: Array = []  # Array of unit_id strings
var _build_progress: float = 0.0
var _current_build_time: float = 0.0

const PANEL_WIDTH := 260


func _ready() -> void:
	layer = 11
	_build_ui()
	_connect_signals()
	_panel.visible = false


func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.name = "ProductionPanelContainer"
	# Anchor to bottom-left
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_panel.offset_left = 0
	_panel.offset_right = PANEL_WIDTH
	_panel.offset_top = -480
	_panel.offset_bottom = 0
	add_child(_panel)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.04, 0.06, 0.97)
	style.border_color = Color(0.2, 0.4, 0.5, 0.9)
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 0
	style.border_width_left = 0
	style.set_content_margin_all(12)
	_panel.add_theme_stylebox_override("panel", style)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 8)
	_panel.add_child(main_vbox)

	# Header
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	main_vbox.add_child(header)

	_title_label = Label.new()
	_title_label.text = "Production"
	_title_label.add_theme_font_size_override("font_size", 18)
	_title_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title_label)

	_close_button = Button.new()
	_close_button.text = "X"
	_close_button.custom_minimum_size = Vector2(28, 28)
	_close_button.add_theme_font_size_override("font_size", 14)

	var close_style := StyleBoxFlat.new()
	close_style.bg_color = Color(0.3, 0.1, 0.1, 0.9)
	close_style.set_corner_radius_all(4)
	close_style.set_content_margin_all(2)
	_close_button.add_theme_stylebox_override("normal", close_style)
	_close_button.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	_close_button.pressed.connect(hide_panel)
	header.add_child(_close_button)

	# Separator
	var sep := HSeparator.new()
	main_vbox.add_child(sep)

	# Unit production buttons
	var units_label := Label.new()
	units_label.text = "Produce Units"
	units_label.add_theme_font_size_override("font_size", 14)
	units_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	main_vbox.add_child(units_label)

	_unit_buttons_container = VBoxContainer.new()
	_unit_buttons_container.add_theme_constant_override("separation", 4)
	main_vbox.add_child(_unit_buttons_container)

	# Separator
	var sep2 := HSeparator.new()
	main_vbox.add_child(sep2)

	# Build progress
	var progress_title := Label.new()
	progress_title.text = "Build Progress"
	progress_title.add_theme_font_size_override("font_size", 14)
	progress_title.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	main_vbox.add_child(progress_title)

	_progress_bar = ProgressBar.new()
	_progress_bar.custom_minimum_size = Vector2(0, 16)
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

	main_vbox.add_child(_progress_bar)

	_progress_label = Label.new()
	_progress_label.text = "Idle"
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_progress_label.add_theme_font_size_override("font_size", 12)
	_progress_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	main_vbox.add_child(_progress_label)

	# Queue section
	var sep3 := HSeparator.new()
	main_vbox.add_child(sep3)

	var queue_label := Label.new()
	queue_label.text = "Queue"
	queue_label.add_theme_font_size_override("font_size", 14)
	queue_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	main_vbox.add_child(queue_label)

	_queue_container = VBoxContainer.new()
	_queue_container.add_theme_constant_override("separation", 2)
	main_vbox.add_child(_queue_container)


func _connect_signals() -> void:
	GameBus.ui_info_panel_show.connect(_on_entity_selected)
	GameBus.ui_info_panel_hide.connect(_on_entity_deselected)
	GameBus.unit_production_started.connect(_on_production_started)
	GameBus.unit_production_completed.connect(_on_production_completed)


## Get the production queue from a building node using duck typing (no class check).
func _get_pq(node: Node) -> Variant:
	if node and is_instance_valid(node):
		return node.get("production_queue")
	return null


## Check if two nodes are the same entity by instance ID.
func _same_entity(a: Node, b: Node) -> bool:
	if not a or not b:
		return false
	if not is_instance_valid(a) or not is_instance_valid(b):
		return false
	return a.get_instance_id() == b.get_instance_id()


func _on_entity_selected(entity: Node) -> void:
	if not entity or not is_instance_valid(entity):
		return

	# Check if it's a production building
	var entity_id: String = str(entity.get("entity_id")) if entity.get("entity_id") else ""

	var building_data := GameData.get_production_building(entity_id)
	if building_data.is_empty():
		hide_panel()
		return

	_building = entity
	_building_data = building_data
	_show_for_building()


func _on_entity_deselected() -> void:
	hide_panel()


func _show_for_building() -> void:
	_title_label.text = _building_data.get("name", "Production")
	# Sync local queue directly from building
	_sync_queue_from_building()
	_populate_unit_buttons()
	_update_queue_display()
	_is_visible = true
	_panel.visible = true


func _sync_queue_from_building() -> void:
	if not _building or not is_instance_valid(_building):
		return
	# Try reading _build_queue directly from building
	var bq: Variant = _building.get("_build_queue")
	if bq is Array:
		_queue = bq.duplicate()
	else:
		# Fallback: try production_queue proxy
		var pq: Variant = _building.get("production_queue")
		if pq and pq.get("queue") is Array:
			_queue = pq.queue.duplicate()
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


func hide_panel() -> void:
	_is_visible = false
	_panel.visible = false
	_building = null
	_building_data = {}


func _populate_unit_buttons() -> void:
	# Clear existing buttons
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
		btn.custom_minimum_size = Vector2(0, 34)
		btn.add_theme_font_size_override("font_size", 12)

		var btn_style := StyleBoxFlat.new()
		btn_style.bg_color = Color(0.08, 0.12, 0.18, 0.9)
		btn_style.border_color = Color(0.2, 0.4, 0.5, 0.6)
		btn_style.set_border_width_all(1)
		btn_style.set_corner_radius_all(4)
		btn_style.set_content_margin_all(6)
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

	# Round-robin: find the building of the same type with the shortest queue
	var target_building: Node = _find_shortest_queue_building(unit_id)
	if not target_building:
		return

	# Call queue_unit directly - building handles all validation
	var success: bool = target_building.call("queue_unit", unit_id) if target_building.has_method("queue_unit") else false
	if success:
		# Read queue directly from building's _build_queue
		if _same_entity(target_building, _building):
			var bq: Variant = target_building.get("_build_queue")
			if bq is Array:
				_queue = bq.duplicate()
		_update_queue_display()
		GameBus.audio_play.emit("ui.production_queue")
		_populate_unit_buttons()


func _find_shortest_queue_building(unit_id: String) -> Node:
	## Find the building of same type with shortest queue that can produce this unit.
	var building_id: String = str(_building.get("entity_id")) if _building.get("entity_id") else ""

	if building_id.is_empty():
		return _building

	# Get all production buildings of the same type
	var all_buildings: Array = get_tree().get_nodes_in_group("production_buildings")
	var candidates: Array = []
	for b: Node in all_buildings:
		var b_id: String = str(b.get("entity_id")) if b.get("entity_id") else ""
		if b_id == building_id and b.has_method("can_produce"):
			if b.can_produce(unit_id):
				candidates.append(b)

	if candidates.is_empty():
		return _building

	# Find the one with the shortest queue
	var best: Node = candidates[0]
	var best_pq: Variant = _get_pq(best)
	var best_size: int = best_pq.get_queue_size() if best_pq else 0
	for b: Node in candidates:
		var bpq: Variant = _get_pq(b)
		if bpq:
			var qs: int = bpq.get_queue_size()
			if qs < best_size:
				best = b
				best_size = qs

	return best


func _update_queue_display() -> void:
	for child in _queue_container.get_children():
		child.queue_free()

	if _queue.is_empty():
		_progress_bar.value = 0
		_progress_label.text = "Idle"
		var empty_label := Label.new()
		empty_label.text = "Queue empty"
		empty_label.add_theme_font_size_override("font_size", 12)
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
		if _building and _building.has_method("cancel_production"):
			_building.cancel_production(slot_index)
		_sync_queue_from_building()
		if slot_index == 0:
			_build_progress = 0.0
		_update_queue_display()
		_populate_unit_buttons()


func _on_production_started(building: Node, unit_id: String) -> void:
	if _same_entity(building, _building):
		_build_progress = 0.0
		var unit_data := GameData.get_unit(unit_id)
		_current_build_time = float(unit_data.get("build_time", 5.0))
		_progress_label.text = "Building: %s" % unit_data.get("name", unit_id)


func _on_production_completed(building: Node, _unit_id: String, _unit: Variant) -> void:
	if _same_entity(building, _building):
		_sync_queue_from_building()
		_build_progress = 0.0
		_update_queue_display()
		_populate_unit_buttons()


func _process(_delta: float) -> void:
	if not _is_visible or not _building or not is_instance_valid(_building):
		return

	# Read build state directly from building properties
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
