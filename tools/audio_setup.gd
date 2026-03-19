extends Control
## AudioSetup - Developer tool for mapping .wav files to entity sound cues.
## Run this scene directly (F6 in editor) to configure SFX assignments.
## Saves automatically to data/sfx_assignments.json.

const SAVE_PATH := "res://data/sfx_assignments.json"
const SFX_DIR := "res://audio/sfx"

# Cue definitions per entity type: [internal_id, display_label]
const CENTRAL_TOWER_CUES := [
	["upgrade", "Upgrade"],
	["hp_50", "HP Reaches 50%"],
	["hp_10", "HP Reaches 10%"],
	["death", "Death"],
]
const TOWER_CUES := [
	["placement", "Placement"],
	["upgrade", "Upgrade"],
	["attack", "Attack / Main Ability"],
	["death", "Death"],
	["sell", "Sell"],
]
const UNIT_CUES := [
	["spawn", "Spawn"],
	["order_received", "Order Received"],
	["attack", "Attack"],
	["ability_1", "Ability 1"],
	["ability_2", "Ability 2"],
	["ability_3", "Ability 3"],
	["death", "Death"],
]
const ENEMY_CUES := [
	["attack", "Attack"],
	["roar", "Roar"],
	["death", "Death"],
]
const PRODUCTION_CUES := [
	["placement", "Placement"],
	["death", "Death"],
	["sell", "Sell"],
]
const BARRIER_CUES := [
	["death", "Death"],
]

# ── Styling ────────────────────────────────────────────────────────

const COL_BG := Color(0.08, 0.09, 0.12)
const COL_ACCENT := Color(0.3, 0.9, 0.5)
const COL_SUBHEADER := Color(0.5, 0.7, 0.55)
const COL_TEXT := Color(0.8, 0.85, 0.8)
const COL_DIM := Color(0.45, 0.45, 0.45)
const COL_SELECTED := Color(0.12, 0.25, 0.16, 0.95)
const COL_CUE_BG := Color(0.07, 0.08, 0.11, 0.95)
const COL_BORDER := Color(0.15, 0.35, 0.22, 0.7)

# ── State ──────────────────────────────────────────────────────────

var _sfx_data: Dictionary = {}
var _wav_files: Array[String] = []
var _selected_entity: String = ""
var _entity_types: Dictionary = {}  # entity_id → type string
var _entity_buttons: Dictionary = {}  # entity_id → Button
var _categories: Array[Dictionary] = []
var _category_headers: Array[Label] = []
var _category_groups: Array[VBoxContainer] = []

# ── UI References ──────────────────────────────────────────────────

var _entity_filter: LineEdit
var _entity_list_vbox: VBoxContainer
var _cue_container: VBoxContainer
var _entity_title_label: Label
var _status_label: Label
var _wav_popup_overlay: ColorRect
var _wav_popup: PanelContainer
var _wav_search: LineEdit
var _wav_list: ItemList
var _wav_callback: Callable


# ── Lifecycle ──────────────────────────────────────────────────────


func _ready() -> void:
	print("[AudioSetup] _ready() started")
	_scan_wav_files()
	print("[AudioSetup] WAV scan complete: %d files" % _wav_files.size())
	_gather_entity_data()
	_build_default_data()
	_load_data()
	_build_ui()
	_populate_entity_list()
	if not _entity_buttons.is_empty():
		_on_entity_selected(_entity_buttons.keys()[0])


func _input(event: InputEvent) -> void:
	if _wav_popup.visible and event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			_close_wav_popup()
			get_viewport().set_input_as_handled()


# ── WAV File Scanning ──────────────────────────────────────────────


func _scan_wav_files() -> void:
	_wav_files.clear()
	_scan_dir(SFX_DIR)
	_wav_files.sort()


func _scan_dir(path: String) -> void:
	var dir := DirAccess.open(path)
	if not dir:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			if not file_name.begins_with("."):
				_scan_dir(path.path_join(file_name))
		elif file_name.get_extension().to_lower() == "wav":
			_wav_files.append(path.path_join(file_name))
		file_name = dir.get_next()


# ── Entity Data Gathering ─────────────────────────────────────────


func _gather_entity_data() -> void:
	_categories.clear()
	_entity_types.clear()

	_add_category("CENTRAL TOWER", [{"id": "central_tower", "type": "central_tower"}])

	var off: Array[Dictionary] = []
	for id in GameData.get_all_towers_offensive():
		off.append({"id": id, "type": "tower"})
	_add_category("TOWERS - Offensive", off)

	var res_t: Array[Dictionary] = []
	for id in GameData.get_all_towers_resource():
		res_t.append({"id": id, "type": "tower"})
	_add_category("TOWERS - Resource", res_t)

	var sup: Array[Dictionary] = []
	for id in GameData.get_all_towers_support():
		sup.append({"id": id, "type": "tower"})
	_add_category("TOWERS - Support", sup)

	var drones: Array[Dictionary] = []
	for id in GameData.get_all_units_drone():
		drones.append({"id": id, "type": "unit"})
	_add_category("UNITS - Drone", drones)

	var mechs: Array[Dictionary] = []
	for id in GameData.get_all_units_mech():
		mechs.append({"id": id, "type": "unit"})
	_add_category("UNITS - Mech", mechs)

	var vehicles: Array[Dictionary] = []
	for id in GameData.get_all_units_war():
		vehicles.append({"id": id, "type": "unit"})
	_add_category("UNITS - Vehicle", vehicles)

	var enemies: Array[Dictionary] = []
	for id in GameData.get_all_enemies():
		enemies.append({"id": id, "type": "enemy"})
	_add_category("ENEMIES", enemies)

	var prod: Array[Dictionary] = []
	for id in GameData.get_all_production_buildings():
		prod.append({"id": id, "type": "production"})
	_add_category("PRODUCTION BUILDINGS", prod)

	var barriers: Array[Dictionary] = []
	for id in GameData.get_all_barriers():
		barriers.append({"id": id, "type": "barrier"})
	_add_category("BARRIERS", barriers)


func _add_category(label: String, entities: Array[Dictionary]) -> void:
	if entities.is_empty():
		return
	_categories.append({"label": label, "entities": entities})
	for e in entities:
		_entity_types[e["id"]] = e["type"]


# ── Default Data ───────────────────────────────────────────────────


func _build_default_data() -> void:
	for cat in _categories:
		for entity in cat["entities"]:
			var eid: String = entity["id"]
			var etype: String = entity["type"]
			if not _sfx_data.has(eid):
				_sfx_data[eid] = {}
			var cues: Array = _cues_for_type(etype)
			for cue in cues:
				var cid: String = cue[0]
				if not _sfx_data[eid].has(cid):
					_sfx_data[eid][cid] = _make_default_cue(cid)


func _make_default_cue(cue_id: String) -> Dictionary:
	var d := {"files": ["", "", ""], "pitch_randomize": false, "pitch_cents": 50}
	if cue_id == "roar":
		d["roar_chance"] = 10
		d["roar_interval"] = 10.0
	return d


func _cues_for_type(type: String) -> Array:
	match type:
		"central_tower": return CENTRAL_TOWER_CUES
		"tower": return TOWER_CUES
		"unit": return UNIT_CUES
		"enemy": return ENEMY_CUES
		"production": return PRODUCTION_CUES
		"barrier": return BARRIER_CUES
	return []


# ── Data Load / Save ──────────────────────────────────────────────


func _load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_warning("[AudioSetup] Failed to parse %s" % SAVE_PATH)
		return
	var loaded: Dictionary = json.data
	for eid in loaded:
		if not _sfx_data.has(eid):
			_sfx_data[eid] = {}
		var cues: Dictionary = loaded[eid]
		for cid in cues:
			_sfx_data[eid][cid] = cues[cid]


func _save_data() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		push_warning("[AudioSetup] Cannot write to %s" % SAVE_PATH)
		return
	file.store_string(JSON.stringify(_sfx_data, "\t"))
	_set_status("Saved")


func _set_status(text: String) -> void:
	_status_label.text = text
	get_tree().create_timer(2.0).timeout.connect(func():
		if is_instance_valid(_status_label):
			_status_label.text = "%d WAV files available" % _wav_files.size()
	)


# ── UI Building ───────────────────────────────────────────────────


func _build_ui() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = COL_BG
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 8)
	margin.add_child(root_vbox)

	# Title row
	var title_row := HBoxContainer.new()
	root_vbox.add_child(title_row)

	var title := Label.new()
	title.text = "AUDIO SETUP TOOL"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", COL_ACCENT)
	title_row.add_child(title)

	var spacer := Control.new()
	spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	title_row.add_child(spacer)

	_status_label = Label.new()
	_status_label.text = "%d WAV files available" % _wav_files.size()
	_status_label.add_theme_font_size_override("font_size", 13)
	_status_label.add_theme_color_override("font_color", COL_DIM)
	_status_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	title_row.add_child(_status_label)

	# Main horizontal split
	var hsplit := HSplitContainer.new()
	hsplit.size_flags_vertical = SIZE_EXPAND_FILL
	hsplit.split_offset = 260
	root_vbox.add_child(hsplit)

	# --- Left panel: entity list ---
	var left_vbox := VBoxContainer.new()
	left_vbox.custom_minimum_size = Vector2(220, 0)
	left_vbox.add_theme_constant_override("separation", 6)
	hsplit.add_child(left_vbox)

	_entity_filter = LineEdit.new()
	_entity_filter.placeholder_text = "Filter entities..."
	_entity_filter.add_theme_font_size_override("font_size", 14)
	_entity_filter.text_changed.connect(_on_filter_changed)
	left_vbox.add_child(_entity_filter)

	var left_scroll := ScrollContainer.new()
	left_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	left_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left_vbox.add_child(left_scroll)

	_entity_list_vbox = VBoxContainer.new()
	_entity_list_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	_entity_list_vbox.add_theme_constant_override("separation", 1)
	left_scroll.add_child(_entity_list_vbox)

	# --- Right panel: cue editor ---
	var right_vbox := VBoxContainer.new()
	right_vbox.add_theme_constant_override("separation", 6)
	hsplit.add_child(right_vbox)

	_entity_title_label = Label.new()
	_entity_title_label.text = "Select an entity"
	_entity_title_label.add_theme_font_size_override("font_size", 20)
	_entity_title_label.add_theme_color_override("font_color", COL_ACCENT)
	right_vbox.add_child(_entity_title_label)

	right_vbox.add_child(HSeparator.new())

	var right_scroll := ScrollContainer.new()
	right_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	right_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right_vbox.add_child(right_scroll)

	_cue_container = VBoxContainer.new()
	_cue_container.size_flags_horizontal = SIZE_EXPAND_FILL
	_cue_container.add_theme_constant_override("separation", 16)
	right_scroll.add_child(_cue_container)

	# WAV picker popup (hidden)
	_build_wav_popup()


# ── Entity List ────────────────────────────────────────────────────


func _populate_entity_list() -> void:
	for child in _entity_list_vbox.get_children():
		_entity_list_vbox.remove_child(child)
		child.queue_free()
	_entity_buttons.clear()
	_category_headers.clear()
	_category_groups.clear()

	for cat in _categories:
		var header := Label.new()
		header.text = cat["label"]
		header.add_theme_font_size_override("font_size", 13)
		header.add_theme_color_override("font_color", COL_SUBHEADER)
		_entity_list_vbox.add_child(header)
		_category_headers.append(header)

		var group := VBoxContainer.new()
		group.add_theme_constant_override("separation", 1)
		_entity_list_vbox.add_child(group)
		_category_groups.append(group)

		for entity in cat["entities"]:
			var eid: String = entity["id"]
			var btn := Button.new()
			btn.text = "  " + eid.replace("_", " ").capitalize()
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			btn.add_theme_font_size_override("font_size", 13)
			btn.add_theme_color_override("font_color", COL_TEXT)
			btn.add_theme_stylebox_override("normal", _make_transparent_stylebox())

			var hover_sb := StyleBoxFlat.new()
			hover_sb.bg_color = Color(0.12, 0.18, 0.14, 0.6)
			hover_sb.set_content_margin_all(3)
			btn.add_theme_stylebox_override("hover", hover_sb)

			btn.pressed.connect(_on_entity_selected.bind(eid))
			group.add_child(btn)
			_entity_buttons[eid] = btn

		var sp := Control.new()
		sp.custom_minimum_size = Vector2(0, 4)
		_entity_list_vbox.add_child(sp)


func _make_transparent_stylebox() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.set_content_margin_all(3)
	return sb


func _make_selected_stylebox() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = COL_SELECTED
	sb.set_content_margin_all(3)
	sb.set_corner_radius_all(3)
	return sb


func _on_filter_changed(text: String) -> void:
	var lf := text.to_lower()
	for i in _category_groups.size():
		var any_visible := false
		for child in _category_groups[i].get_children():
			if child is Button:
				var visible_match: bool = lf.is_empty() or child.text.to_lower().contains(lf)
				child.visible = visible_match
				if visible_match:
					any_visible = true
		_category_headers[i].visible = any_visible
		_category_groups[i].visible = any_visible


# ── Entity Selection & Cue Editor ─────────────────────────────────


func _on_entity_selected(entity_id: String) -> void:
	# Unhighlight previous
	if _entity_buttons.has(_selected_entity):
		_entity_buttons[_selected_entity].add_theme_stylebox_override("normal", _make_transparent_stylebox())

	_selected_entity = entity_id

	# Highlight new
	if _entity_buttons.has(entity_id):
		_entity_buttons[entity_id].add_theme_stylebox_override("normal", _make_selected_stylebox())

	# Update title
	var type_str := _entity_types.get(entity_id, "unknown")
	_entity_title_label.text = "%s  (%s)" % [
		entity_id.replace("_", " ").capitalize(),
		type_str.replace("_", " ").capitalize()
	]

	_build_cue_editor(entity_id)


func _build_cue_editor(entity_id: String) -> void:
	for child in _cue_container.get_children():
		_cue_container.remove_child(child)
		child.queue_free()

	var type := _entity_types.get(entity_id, "")
	var cues: Array = _cues_for_type(type)

	if not _sfx_data.has(entity_id):
		_sfx_data[entity_id] = {}

	for cue in cues:
		var cue_id: String = cue[0]
		var cue_label: String = cue[1]
		if not _sfx_data[entity_id].has(cue_id):
			_sfx_data[entity_id][cue_id] = _make_default_cue(cue_id)
		_create_cue_section(entity_id, cue_id, cue_label)


func _create_cue_section(entity_id: String, cue_id: String, label: String) -> void:
	var cue_data: Dictionary = _sfx_data[entity_id][cue_id]

	var panel := PanelContainer.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color = COL_CUE_BG
	ps.border_color = COL_BORDER
	ps.set_border_width_all(1)
	ps.set_corner_radius_all(6)
	ps.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", ps)
	_cue_container.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	# Cue name header
	var name_label := Label.new()
	name_label.text = label
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", COL_ACCENT)
	vbox.add_child(name_label)

	# 3 WAV file slots
	var files: Array = cue_data.get("files", ["", "", ""])
	while files.size() < 3:
		files.append("")

	for i in 3:
		_create_wav_slot(vbox, entity_id, cue_id, i, files[i])

	# Pitch randomization controls
	_create_pitch_controls(vbox, entity_id, cue_id, cue_data)

	# Roar-specific controls
	if cue_id == "roar":
		_create_roar_controls(vbox, entity_id, cue_id, cue_data)


func _create_wav_slot(parent: VBoxContainer, entity_id: String, cue_id: String, slot_index: int, current_file: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	parent.add_child(row)

	var num := Label.new()
	num.text = "[%d]" % (slot_index + 1)
	num.custom_minimum_size = Vector2(28, 0)
	num.add_theme_font_size_override("font_size", 13)
	num.add_theme_color_override("font_color", COL_DIM)
	row.add_child(num)

	var file_btn := Button.new()
	file_btn.text = current_file.get_file() if not current_file.is_empty() else "-- None --"
	file_btn.size_flags_horizontal = SIZE_EXPAND_FILL
	file_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	file_btn.add_theme_font_size_override("font_size", 13)
	file_btn.add_theme_color_override("font_color", COL_TEXT if not current_file.is_empty() else COL_DIM)
	file_btn.clip_text = true

	var fbs := StyleBoxFlat.new()
	fbs.bg_color = Color(0.05, 0.06, 0.08, 0.9)
	fbs.border_color = Color(0.15, 0.2, 0.18, 0.5)
	fbs.set_border_width_all(1)
	fbs.set_corner_radius_all(3)
	fbs.set_content_margin_all(6)
	file_btn.add_theme_stylebox_override("normal", fbs)

	var fbh := fbs.duplicate()
	fbh.border_color = COL_ACCENT
	file_btn.add_theme_stylebox_override("hover", fbh)

	# Capture references for closure
	var eid := entity_id
	var cid := cue_id
	var idx := slot_index
	var btn_ref := file_btn

	file_btn.pressed.connect(func():
		_open_wav_popup(func(wav_path: String):
			_sfx_data[eid][cid]["files"][idx] = wav_path
			btn_ref.text = wav_path.get_file() if not wav_path.is_empty() else "-- None --"
			btn_ref.add_theme_color_override("font_color", COL_TEXT if not wav_path.is_empty() else COL_DIM)
			_save_data()
		)
	)
	row.add_child(file_btn)

	var clear_btn := Button.new()
	clear_btn.text = "x"
	clear_btn.custom_minimum_size = Vector2(28, 28)
	clear_btn.add_theme_font_size_override("font_size", 12)
	clear_btn.pressed.connect(func():
		_sfx_data[eid][cid]["files"][idx] = ""
		btn_ref.text = "-- None --"
		btn_ref.add_theme_color_override("font_color", COL_DIM)
		_save_data()
	)
	row.add_child(clear_btn)


func _create_pitch_controls(parent: VBoxContainer, entity_id: String, cue_id: String, cue_data: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	var check := CheckButton.new()
	check.text = "Pitch Randomize"
	check.button_pressed = cue_data.get("pitch_randomize", false)
	check.add_theme_font_size_override("font_size", 13)
	check.add_theme_color_override("font_color", COL_TEXT)
	var eid := entity_id
	var cid := cue_id
	check.toggled.connect(func(on: bool):
		_sfx_data[eid][cid]["pitch_randomize"] = on
		_save_data()
	)
	row.add_child(check)

	var pm := Label.new()
	pm.text = "  \u00b1"
	pm.add_theme_font_size_override("font_size", 14)
	pm.add_theme_color_override("font_color", COL_TEXT)
	row.add_child(pm)

	var spin := SpinBox.new()
	spin.min_value = 5
	spin.max_value = 200
	spin.step = 5
	spin.value = cue_data.get("pitch_cents", 50)
	spin.custom_minimum_size = Vector2(80, 0)
	spin.value_changed.connect(func(val: float):
		_sfx_data[eid][cid]["pitch_cents"] = int(val)
		_save_data()
	)
	row.add_child(spin)

	var cents := Label.new()
	cents.text = "cents"
	cents.add_theme_font_size_override("font_size", 13)
	cents.add_theme_color_override("font_color", COL_DIM)
	row.add_child(cents)


func _create_roar_controls(parent: VBoxContainer, entity_id: String, cue_id: String, cue_data: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	var eid := entity_id
	var cid := cue_id

	var chance_lbl := Label.new()
	chance_lbl.text = "Chance: 1 in"
	chance_lbl.add_theme_font_size_override("font_size", 13)
	chance_lbl.add_theme_color_override("font_color", COL_TEXT)
	row.add_child(chance_lbl)

	var chance_spin := SpinBox.new()
	chance_spin.min_value = 1
	chance_spin.max_value = 100
	chance_spin.step = 1
	chance_spin.value = cue_data.get("roar_chance", 10)
	chance_spin.custom_minimum_size = Vector2(70, 0)
	chance_spin.value_changed.connect(func(val: float):
		_sfx_data[eid][cid]["roar_chance"] = int(val)
		_save_data()
	)
	row.add_child(chance_spin)

	var every_lbl := Label.new()
	every_lbl.text = "  every"
	every_lbl.add_theme_font_size_override("font_size", 13)
	every_lbl.add_theme_color_override("font_color", COL_TEXT)
	row.add_child(every_lbl)

	var interval_spin := SpinBox.new()
	interval_spin.min_value = 1.0
	interval_spin.max_value = 60.0
	interval_spin.step = 1.0
	interval_spin.value = cue_data.get("roar_interval", 10.0)
	interval_spin.custom_minimum_size = Vector2(70, 0)
	interval_spin.suffix = "s"
	interval_spin.value_changed.connect(func(val: float):
		_sfx_data[eid][cid]["roar_interval"] = val
		_save_data()
	)
	row.add_child(interval_spin)


# ── WAV Picker Popup ──────────────────────────────────────────────


func _build_wav_popup() -> void:
	# Blocking overlay
	_wav_popup_overlay = ColorRect.new()
	_wav_popup_overlay.visible = false
	_wav_popup_overlay.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_wav_popup_overlay.color = Color(0, 0, 0, 0.5)
	_wav_popup_overlay.mouse_filter = MOUSE_FILTER_STOP
	_wav_popup_overlay.z_index = 99
	add_child(_wav_popup_overlay)

	_wav_popup = PanelContainer.new()
	_wav_popup.visible = false
	_wav_popup.set_anchors_preset(PRESET_CENTER)
	_wav_popup.offset_left = -250
	_wav_popup.offset_right = 250
	_wav_popup.offset_top = -280
	_wav_popup.offset_bottom = 280
	_wav_popup.z_index = 100

	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.04, 0.05, 0.07, 0.98)
	ps.border_color = COL_ACCENT
	ps.set_border_width_all(2)
	ps.set_corner_radius_all(8)
	ps.set_content_margin_all(14)
	_wav_popup.add_theme_stylebox_override("panel", ps)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_wav_popup.add_child(vbox)

	var popup_title := Label.new()
	popup_title.text = "Select WAV File"
	popup_title.add_theme_font_size_override("font_size", 16)
	popup_title.add_theme_color_override("font_color", COL_ACCENT)
	vbox.add_child(popup_title)

	_wav_search = LineEdit.new()
	_wav_search.placeholder_text = "Search .wav files..."
	_wav_search.add_theme_font_size_override("font_size", 14)
	_wav_search.text_changed.connect(_on_wav_search_changed)
	vbox.add_child(_wav_search)

	_wav_list = ItemList.new()
	_wav_list.size_flags_vertical = SIZE_EXPAND_FILL
	_wav_list.add_theme_font_size_override("font_size", 13)
	_wav_list.add_theme_color_override("font_color", COL_TEXT)
	_wav_list.item_activated.connect(_on_wav_item_activated)
	vbox.add_child(_wav_list)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 8)
	btn_row.alignment = BoxContainer.ALIGNMENT_END
	vbox.add_child(btn_row)

	var select_btn := Button.new()
	select_btn.text = "Select"
	select_btn.add_theme_font_size_override("font_size", 13)
	select_btn.pressed.connect(_on_wav_select_pressed)
	btn_row.add_child(select_btn)

	var none_btn := Button.new()
	none_btn.text = "Clear (None)"
	none_btn.add_theme_font_size_override("font_size", 13)
	none_btn.pressed.connect(func():
		_close_wav_popup()
		if _wav_callback:
			_wav_callback.call("")
	)
	btn_row.add_child(none_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.add_theme_font_size_override("font_size", 13)
	cancel_btn.pressed.connect(_close_wav_popup)
	btn_row.add_child(cancel_btn)

	add_child(_wav_popup)


func _open_wav_popup(callback: Callable) -> void:
	_wav_callback = callback
	_wav_search.text = ""
	_populate_wav_list("")
	_wav_popup_overlay.visible = true
	_wav_popup.visible = true
	_wav_search.grab_focus()


func _close_wav_popup() -> void:
	_wav_popup_overlay.visible = false
	_wav_popup.visible = false


func _populate_wav_list(filter: String) -> void:
	_wav_list.clear()
	var lf := filter.to_lower()
	for wav_path in _wav_files:
		var display := wav_path.replace(SFX_DIR + "/", "")
		if lf.is_empty() or display.to_lower().contains(lf):
			_wav_list.add_item(display)
			_wav_list.set_item_metadata(_wav_list.item_count - 1, wav_path)


func _on_wav_search_changed(text: String) -> void:
	_populate_wav_list(text)


func _on_wav_item_activated(index: int) -> void:
	var path: String = _wav_list.get_item_metadata(index)
	_close_wav_popup()
	if _wav_callback:
		_wav_callback.call(path)


func _on_wav_select_pressed() -> void:
	var selected := _wav_list.get_selected_items()
	if selected.is_empty():
		return
	var path: String = _wav_list.get_item_metadata(selected[0])
	_close_wav_popup()
	if _wav_callback:
		_wav_callback.call(path)
