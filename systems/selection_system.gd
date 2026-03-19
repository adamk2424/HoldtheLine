class_name SelectionSystem
extends Node
## SelectionSystem - Mouse-based selection system for all entity types.
## Left click: select single entity (unit, building, tower, enemy, barrier, etc.)
## Left click + drag: box select multiple units and towers
## Right click on ground: move selected units
## Right click on enemy: attack-move selected units

var selected_units: Array = []
var selected_entities: Array = []  # All selected entities (units + towers)
var _selected_entity: Node = null
var _is_sell_mode: bool = false
var _sell_marker: MeshInstance3D = null
var _sell_hovered_entity: Node = null
var _sell_highlight_mat: StandardMaterial3D = null

# Box selection state
var _is_box_selecting: bool = false
var _box_start_screen: Vector2 = Vector2.ZERO
var _box_current_screen: Vector2 = Vector2.ZERO
var _box_select_threshold: float = 5.0  # Minimum drag pixels for box select

# Visual box overlay
var _box_overlay: Control = null

# Camera reference
var _camera: Camera3D = null

# All selectable entity types
const SELECTABLE_TYPES: Array[String] = [
	"unit", "building", "central_tower", "tower", "barrier", "enemy",
]

# Types that can be box-selected in groups
const BOX_SELECTABLE_TYPES: Array[String] = ["unit", "tower"]

# Screen-space click threshold in pixels
const CLICK_SCREEN_PX: float = 40.0

# Click radii per type (used for sell mode ground-plane checks)
const CLICK_RADIUS: Dictionary = {
	"unit": 2.0,
	"building": 3.0,
	"central_tower": 4.0,
	"tower": 3.0,
	"barrier": 1.5,
	"enemy": 2.5,
}


func _ready() -> void:
	_create_box_overlay()
	_create_sell_marker()
	GameBus.entity_removed.connect(_on_entity_removed)
	GameBus.ui_sell_mode_toggled.connect(_on_sell_mode_toggled)


func _unhandled_input(event: InputEvent) -> void:
	if not GameState.is_game_active:
		return

	_cache_camera()

	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE and _is_sell_mode:
			_exit_sell_mode()
			get_viewport().set_input_as_handled()


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_is_box_selecting = true
			_box_start_screen = event.position
			_box_current_screen = event.position
		else:
			if _is_box_selecting:
				var drag_dist: float = _box_start_screen.distance_to(event.position)
				if drag_dist < _box_select_threshold:
					_click_select(event.position)
				else:
					_box_select()
				_is_box_selecting = false
				if _box_overlay:
					_box_overlay.visible = false

	elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if _is_sell_mode:
			_exit_sell_mode()
			get_viewport().set_input_as_handled()
			return
		_handle_right_click(event.position)


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if _is_sell_mode:
		_update_sell_hover(event.position)
	if _is_box_selecting:
		_box_current_screen = event.position
		_update_box_overlay()


# --- Click Select (screen-space, handles tower height) ---

func _click_select(screen_pos: Vector2) -> void:
	if not _camera:
		return

	# Sell mode uses ground-plane distance
	if _is_sell_mode:
		var world_pos: Vector3 = _screen_to_world(screen_pos)
		_try_sell_at(world_pos)
		return

	var additive: bool = Input.is_key_pressed(KEY_SHIFT)

	# Find closest entity using screen-space distance to visual column
	var closest_entity: Node = null
	var closest_dist: float = INF

	for type in SELECTABLE_TYPES:
		var entities: Array = EntityRegistry.get_all(type)
		for entity: Node in entities:
			if not is_instance_valid(entity) or not entity.is_inside_tree():
				continue
			if _camera.is_position_behind(entity.global_position):
				continue
			var dist: float = _screen_distance_to_entity(screen_pos, entity)
			if dist < CLICK_SCREEN_PX and dist < closest_dist:
				closest_dist = dist
				closest_entity = entity

	if not additive:
		_deselect_all()

	if closest_entity:
		if additive and _is_entity_selected(closest_entity):
			_deselect_entity(closest_entity)
		else:
			_select_entity(closest_entity)
		_emit_selection_signals()
	else:
		if not additive:
			GameBus.units_selected.emit([])
			GameBus.ui_info_panel_hide.emit()


# --- Box Select (units + towers) ---

func _box_select() -> void:
	if not _camera:
		return

	var additive: bool = Input.is_key_pressed(KEY_SHIFT)

	if not additive:
		_deselect_all()

	var rect := _get_box_rect()

	for type in BOX_SELECTABLE_TYPES:
		var entities: Array = EntityRegistry.get_all(type)
		for entity: Node in entities:
			if not is_instance_valid(entity) or not entity.is_inside_tree():
				continue
			if _camera.is_position_behind(entity.global_position):
				continue
			if _is_entity_in_screen_rect(entity, rect):
				_select_entity(entity)

	_emit_selection_signals()


# --- Entity Selection Helpers ---

func _select_entity(entity: Node) -> void:
	if entity in selected_entities:
		return
	selected_entities.append(entity)

	if entity is UnitBase:
		entity.select()
		if entity not in selected_units:
			selected_units.append(entity)
	elif entity is TowerBase:
		entity.select()


func _deselect_entity(entity: Node) -> void:
	selected_entities.erase(entity)

	if entity is UnitBase:
		entity.deselect()
		selected_units.erase(entity)
	elif entity is TowerBase:
		entity.deselect()


func _is_entity_selected(entity: Node) -> bool:
	return entity in selected_entities


func _emit_selection_signals() -> void:
	GameBus.units_selected.emit(selected_units.duplicate())

	if selected_entities.is_empty():
		GameBus.ui_info_panel_hide.emit()
	else:
		_selected_entity = selected_entities[0]
		GameBus.ui_info_panel_show.emit(selected_entities[0])
		if selected_entities.size() > 1:
			GameBus.ui_group_selected.emit(selected_entities.duplicate())


# --- Screen-Space Distance ---

func _screen_distance_to_entity(screen_pos: Vector2, entity: Node) -> float:
	## Distance from screen click to entity's screen-space visual column.
	var base_pos: Vector3 = entity.global_position
	var top_y: float = _get_entity_top_y(entity)
	var top_pos: Vector3 = base_pos + Vector3(0, top_y, 0)

	var screen_base: Vector2 = _camera.unproject_position(base_pos)
	var screen_top: Vector2 = _camera.unproject_position(top_pos)

	return _point_to_segment_distance_2d(screen_pos, screen_base, screen_top)


func _get_entity_top_y(entity: Node) -> float:
	## Get the visual top height of an entity for screen-space selection.
	if entity is TowerBase and entity.health_bar:
		return entity.health_bar.position.y
	if entity is UnitBase and entity.health_bar:
		return entity.health_bar.position.y
	if entity is EntityBase:
		var mesh_scale: Variant = entity.data.get("mesh_scale", [1.0, 1.0, 1.0])
		if mesh_scale is Array and mesh_scale.size() >= 2:
			return float(mesh_scale[1])
	return 1.0


func _point_to_segment_distance_2d(p: Vector2, a: Vector2, b: Vector2) -> float:
	## Closest distance from point p to line segment a-b in 2D.
	var ab: Vector2 = b - a
	var ap: Vector2 = p - a
	var ab_len_sq: float = ab.length_squared()
	if ab_len_sq < 0.001:
		return ap.length()
	var t: float = clampf(ap.dot(ab) / ab_len_sq, 0.0, 1.0)
	var closest: Vector2 = a + ab * t
	return (p - closest).length()


func _is_entity_in_screen_rect(entity: Node, rect: Rect2) -> bool:
	## Check if any part of the entity's visual column falls within the screen rect.
	var base_pos: Vector3 = entity.global_position
	var top_y: float = _get_entity_top_y(entity)

	for h: float in [0.0, top_y * 0.5, top_y]:
		var world_pos: Vector3 = base_pos + Vector3(0, h, 0)
		if not _camera.is_position_behind(world_pos):
			var screen_pos: Vector2 = _camera.unproject_position(world_pos)
			if rect.has_point(screen_pos):
				return true
	return false


# --- Right Click Commands ---

func _handle_right_click(screen_pos: Vector2) -> void:
	if selected_units.is_empty():
		return

	if not _camera:
		return

	var world_pos: Vector3 = _screen_to_world(screen_pos)

	var target_enemy: Node = _find_entity_at_position(world_pos, "enemy", 2.5)

	if target_enemy:
		GameBus.unit_command_attack.emit(selected_units.duplicate(), target_enemy)
	else:
		GameBus.unit_command_move.emit(selected_units.duplicate(), world_pos)


# --- Utility ---

func _deselect_all() -> void:
	for entity: Node in selected_entities:
		if is_instance_valid(entity):
			if entity is UnitBase:
				entity.deselect()
			elif entity is TowerBase:
				entity.deselect()
	selected_entities.clear()
	selected_units.clear()
	_selected_entity = null
	GameBus.ui_info_panel_hide.emit()


func _find_entity_at_position(world_pos: Vector3, entity_type: String, max_radius: float) -> Node:
	var closest: Node = null
	var closest_dist: float = max_radius

	var entities: Array = EntityRegistry.get_all(entity_type)
	for entity: Node in entities:
		if not is_instance_valid(entity) or not entity.is_inside_tree():
			continue
		var dist: float = world_pos.distance_to(entity.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = entity

	return closest


func _screen_to_world(screen_pos: Vector2) -> Vector3:
	if not _camera:
		return Vector3.ZERO
	var from: Vector3 = _camera.project_ray_origin(screen_pos)
	var dir: Vector3 = _camera.project_ray_normal(screen_pos)
	if dir.y == 0:
		return Vector3.ZERO
	var t: float = -from.y / dir.y
	if t < 0:
		return Vector3.ZERO
	return from + dir * t


func _get_box_rect() -> Rect2:
	var top_left := Vector2(
		min(_box_start_screen.x, _box_current_screen.x),
		min(_box_start_screen.y, _box_current_screen.y)
	)
	var bottom_right := Vector2(
		max(_box_start_screen.x, _box_current_screen.x),
		max(_box_start_screen.y, _box_current_screen.y)
	)
	return Rect2(top_left, bottom_right - top_left)


func _cache_camera() -> void:
	if not _camera or not is_instance_valid(_camera):
		_camera = get_viewport().get_camera_3d()


func _on_entity_removed(entity: Node, _entity_type: String) -> void:
	if entity == _selected_entity:
		_selected_entity = null
	if entity == _sell_hovered_entity:
		_sell_hovered_entity = null
	var was_in_group: bool = entity in selected_entities
	selected_entities.erase(entity)
	selected_units.erase(entity)
	if was_in_group:
		if selected_entities.is_empty():
			GameBus.ui_info_panel_hide.emit()
		else:
			_emit_selection_signals()
	elif entity == _selected_entity:
		GameBus.ui_info_panel_hide.emit()


# --- Sell Mode ---

func _on_sell_mode_toggled(is_active: bool) -> void:
	_is_sell_mode = is_active
	if _is_sell_mode:
		_deselect_all()
		if _sell_marker:
			_sell_marker.visible = true
	else:
		_clear_sell_visuals()


func _exit_sell_mode() -> void:
	_is_sell_mode = false
	_clear_sell_visuals()
	GameBus.ui_sell_mode_toggled.emit(false)


func _clear_sell_visuals() -> void:
	if _sell_marker:
		_sell_marker.visible = false
	if _sell_hovered_entity and is_instance_valid(_sell_hovered_entity):
		_clear_sell_highlight(_sell_hovered_entity)
	_sell_hovered_entity = null


func _create_sell_marker() -> void:
	_sell_marker = MeshInstance3D.new()
	_sell_marker.name = "SellCursorMarker"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.5
	torus.outer_radius = 0.7
	torus.rings = 16
	torus.ring_segments = 12
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.15, 0.15, 0.8)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.no_depth_test = true
	torus.material = mat
	_sell_marker.mesh = torus
	_sell_marker.visible = false
	add_child(_sell_marker)

	_sell_highlight_mat = StandardMaterial3D.new()
	_sell_highlight_mat.albedo_color = Color(1.0, 0.15, 0.15, 0.7)
	_sell_highlight_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_sell_highlight_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_sell_highlight_mat.no_depth_test = true


func _update_sell_hover(screen_pos: Vector2) -> void:
	_cache_camera()
	if not _camera:
		return

	var world_pos := _screen_to_world(screen_pos)

	if _sell_marker:
		_sell_marker.global_position = Vector3(world_pos.x, 0.1, world_pos.z)

	var hovered: Node = _find_sellable_at(world_pos)

	if hovered != _sell_hovered_entity:
		if _sell_hovered_entity and is_instance_valid(_sell_hovered_entity):
			_clear_sell_highlight(_sell_hovered_entity)
		_sell_hovered_entity = hovered
		if _sell_hovered_entity:
			_apply_sell_highlight(_sell_hovered_entity)


func _find_sellable_at(world_pos: Vector3) -> Node:
	var sellable_types: Array[String] = ["tower", "building", "barrier"]
	var closest_entity: Node = null
	var closest_dist: float = INF

	for type in sellable_types:
		var radius: float = CLICK_RADIUS.get(type, 3.0)
		var entities: Array = EntityRegistry.get_all(type)
		for entity: Node in entities:
			if not is_instance_valid(entity) or not entity.is_inside_tree():
				continue
			var dist: float = world_pos.distance_to(entity.global_position)
			if dist < radius and dist < closest_dist:
				closest_dist = dist
				closest_entity = entity

	return closest_entity


func _try_sell_at(world_pos: Vector3) -> void:
	var entity := _find_sellable_at(world_pos)
	if entity:
		if entity == _sell_hovered_entity:
			_clear_sell_highlight(entity)
			_sell_hovered_entity = null
		GameBus.sell_requested.emit(entity)


func _apply_sell_highlight(entity: Node) -> void:
	if not entity is EntityBase:
		return
	var visual: Node3D = (entity as EntityBase).visual_node
	if not visual:
		return
	_set_material_override_recursive(visual, _sell_highlight_mat)


func _clear_sell_highlight(entity: Node) -> void:
	if not entity is EntityBase:
		return
	var visual: Node3D = (entity as EntityBase).visual_node
	if not visual:
		return
	_set_material_override_recursive(visual, null)


func _set_material_override_recursive(node: Node, mat: Material) -> void:
	if node is MeshInstance3D:
		(node as MeshInstance3D).material_override = mat
	for child in node.get_children():
		_set_material_override_recursive(child, mat)


# --- Box Overlay ---

func _create_box_overlay() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "SelectionBoxCanvas"
	canvas.layer = 10
	add_child(canvas)

	_box_overlay = Control.new()
	_box_overlay.name = "SelectionBoxOverlay"
	_box_overlay.visible = false
	_box_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_box_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box_overlay.draw.connect(_draw_box_overlay)
	canvas.add_child(_box_overlay)


func _update_box_overlay() -> void:
	if not _box_overlay:
		return
	var drag_dist: float = _box_start_screen.distance_to(_box_current_screen)
	if drag_dist >= _box_select_threshold:
		_box_overlay.visible = true
		_box_overlay.queue_redraw()
	else:
		_box_overlay.visible = false


func _draw_box_overlay() -> void:
	if not _box_overlay or not _is_box_selecting:
		return
	var rect := _get_box_rect()
	_box_overlay.draw_rect(rect, Color(0.2, 1.0, 0.2, 0.15), true)
	_box_overlay.draw_rect(rect, Color(0.2, 1.0, 0.2, 0.6), false, 1.5)


# --- Cleanup ---

func _exit_tree() -> void:
	_deselect_all()
