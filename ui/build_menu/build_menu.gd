extends CanvasLayer
## BuildMenu - Shows categories: Towers (Offensive, Resource, Support), Barriers, Buildings.
## Opened by pressing B key (open_build_menu input action).
## When item clicked: activate GridCursor with entity_id, close menu.
## When player clicks on valid grid position: emit GameBus.build_requested.

var _panel: PanelContainer
var _scroll: ScrollContainer
var _categories_vbox: VBoxContainer
var _close_button: Button
var _title_label: Label

var _is_open: bool = false
var _selected_entity_id: String = ""


func _ready() -> void:
	layer = 11
	_build_ui()
	_populate_categories()
	_connect_signals()
	_panel.visible = false


func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.name = "BuildMenuPanel"

	# Position on left side of screen
	_panel.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	_panel.offset_left = 10
	_panel.offset_right = 280
	_panel.offset_top = 60
	_panel.offset_bottom = -60

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.06, 0.08, 0.97)
	style.border_color = Color(0.15, 0.4, 0.25, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(10)
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 8)
	_panel.add_child(main_vbox)

	# Header
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	main_vbox.add_child(header)

	_title_label = Label.new()
	_title_label.text = "Build Menu"
	_title_label.add_theme_font_size_override("font_size", 22)
	_title_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.5))
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title_label)

	_close_button = Button.new()
	_close_button.text = "X"
	_close_button.custom_minimum_size = Vector2(30, 30)
	_close_button.add_theme_font_size_override("font_size", 16)

	var close_style := StyleBoxFlat.new()
	close_style.bg_color = Color(0.3, 0.1, 0.1, 0.9)
	close_style.border_color = Color(0.6, 0.2, 0.2)
	close_style.set_border_width_all(1)
	close_style.set_corner_radius_all(4)
	close_style.set_content_margin_all(2)
	_close_button.add_theme_stylebox_override("normal", close_style)
	_close_button.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	_close_button.pressed.connect(close_menu)
	header.add_child(_close_button)

	# Separator
	var sep := HSeparator.new()
	main_vbox.add_child(sep)

	# Scrollable categories area
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(_scroll)

	_categories_vbox = VBoxContainer.new()
	_categories_vbox.add_theme_constant_override("separation", 8)
	_categories_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_categories_vbox)


func _populate_categories() -> void:
	var CategoryScript := preload("res://ui/build_menu/build_category.gd")

	# Offensive Towers
	var offensive_towers := GameData.get_all_towers_offensive()
	if not offensive_towers.is_empty():
		var cat := VBoxContainer.new()
		cat.set_script(CategoryScript)
		_categories_vbox.add_child(cat)
		cat.setup("Offensive Towers", offensive_towers)
		cat.item_selected.connect(_on_item_selected)

	# Resource Towers
	var resource_towers := GameData.get_all_towers_resource()
	if not resource_towers.is_empty():
		var cat := VBoxContainer.new()
		cat.set_script(CategoryScript)
		_categories_vbox.add_child(cat)
		cat.setup("Resource Towers", resource_towers)
		cat.item_selected.connect(_on_item_selected)

	# Support Towers
	var support_towers := GameData.get_all_towers_support()
	if not support_towers.is_empty():
		var cat := VBoxContainer.new()
		cat.set_script(CategoryScript)
		_categories_vbox.add_child(cat)
		cat.setup("Support Towers", support_towers)
		cat.item_selected.connect(_on_item_selected)

	# Barriers
	var barriers := GameData.get_all_barriers()
	if not barriers.is_empty():
		var cat := VBoxContainer.new()
		cat.set_script(CategoryScript)
		_categories_vbox.add_child(cat)
		cat.setup("Barriers", barriers)
		cat.item_selected.connect(_on_item_selected)

	# Production Buildings
	var buildings := GameData.get_all_production_buildings()
	if not buildings.is_empty():
		var cat := VBoxContainer.new()
		cat.set_script(CategoryScript)
		_categories_vbox.add_child(cat)
		cat.setup("Production Buildings", buildings)
		cat.item_selected.connect(_on_item_selected)


func _connect_signals() -> void:
	GameBus.ui_build_menu_toggled.connect(_on_build_menu_toggled)
	GameBus.build_completed.connect(_on_build_completed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("open_build_menu"):
		if _is_open:
			close_menu()
		else:
			open_menu()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause_game") and _is_open:
		close_menu()
		get_viewport().set_input_as_handled()

	# Handle placement mode
	if _selected_entity_id != "":
		if event is InputEventMouseMotion:
			# Update grid cursor position
			var grid_cursor := _find_grid_cursor(get_tree().root)
			if grid_cursor and grid_cursor is GridCursor:
				var world_pos := _screen_to_world(event.position)
				if world_pos != Vector3.ZERO:
					grid_cursor.update_position(world_pos)

		elif event.is_action_pressed("select"):
			# Place building on left click
			_try_place_building()
			get_viewport().set_input_as_handled()

		elif event.is_action_pressed("command"):
			# Cancel placement on right-click
			_cancel_placement()
			get_viewport().set_input_as_handled()

		elif event.is_action_pressed("pause_game"):
			# Cancel placement on Escape instead of opening pause menu
			_cancel_placement()
			get_viewport().set_input_as_handled()


func open_menu() -> void:
	_is_open = true
	_panel.visible = true
	GameBus.ui_build_menu_toggled.emit(true)
	GameBus.audio_play.emit("ui.build_menu_open")


func close_menu() -> void:
	_is_open = false
	_panel.visible = false
	GameBus.ui_build_menu_toggled.emit(false)


func _on_build_menu_toggled(is_open: bool) -> void:
	_is_open = is_open
	_panel.visible = is_open


func _on_item_selected(entity_id: String) -> void:
	_selected_entity_id = entity_id
	close_menu()

	# Find and activate the GridCursor
	var cursors := get_tree().get_nodes_in_group("entities")
	var grid_cursor: Node = _find_grid_cursor(get_tree().root)
	if grid_cursor and grid_cursor is GridCursor:
		grid_cursor.activate(entity_id)

	GameBus.audio_play.emit("ui.item_select")


func _find_grid_cursor(node: Node) -> Node:
	if node is GridCursor:
		return node
	for child in node.get_children():
		var result := _find_grid_cursor(child)
		if result:
			return result
	return null


func _cancel_placement() -> void:
	_selected_entity_id = ""
	var grid_cursor := _find_grid_cursor(get_tree().root)
	if grid_cursor and grid_cursor is GridCursor:
		grid_cursor.deactivate()


func _try_place_building() -> void:
	var grid_cursor := _find_grid_cursor(get_tree().root)
	if not grid_cursor or not grid_cursor is GridCursor:
		return
	if not grid_cursor.is_valid_placement:
		GameBus.audio_play.emit("ui.build_denied")
		return

	# Check cost
	var cost := GameData.get_cost(_selected_entity_id)
	if not GameState.can_afford(cost["energy"], cost["materials"]):
		GameBus.resources_insufficient.emit(cost["energy"], cost["materials"])
		GameBus.audio_play.emit("ui.build_denied")
		return

	# Spend resources and emit build request
	GameState.spend_resources(cost["energy"], cost["materials"])
	GameBus.build_requested.emit(_selected_entity_id, grid_cursor.current_grid_pos, grid_cursor.current_size)
	GameBus.audio_play.emit("ui.build_confirm")


func _screen_to_world(screen_pos: Vector2) -> Vector3:
	var camera := get_viewport().get_camera_3d()
	if not camera:
		return Vector3.ZERO
	var from := camera.project_ray_origin(screen_pos)
	var dir := camera.project_ray_normal(screen_pos)
	if dir.y == 0:
		return Vector3.ZERO
	var t := -from.y / dir.y
	if t < 0:
		return Vector3.ZERO
	return from + dir * t


func _on_build_completed(_entity: Node, _entity_id: String, _grid_position: Vector2i) -> void:
	# Keep placement mode active so the player can place multiple of the same building
	if _selected_entity_id != "":
		var grid_cursor := _find_grid_cursor(get_tree().root)
		if grid_cursor and grid_cursor is GridCursor:
			grid_cursor.activate(_selected_entity_id)
