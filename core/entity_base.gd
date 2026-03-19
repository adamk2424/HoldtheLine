class_name EntityBase
extends Node3D
## EntityBase - Root class for all game entities.
## Uses composition: attach HealthComponent, CombatComponent, etc. as children.

@export var entity_id: String = ""
@export var entity_type: String = ""  # "tower", "enemy", "unit", "barrier", "building", "central_tower"
@export var grid_position: Vector2i = Vector2i.ZERO
@export var grid_size: int = 1  # NxN grid cells

var data: Dictionary = {}  # Loaded from GameData
var is_initialized: bool = false

# Component references (cached on init)
var health_component: Node = null
var combat_component: Node = null
var movement_component: Node = null
var buff_debuff_component: Node = null
var visual_node: Node3D = null


func _ready() -> void:
	add_to_group("entities")
	add_to_group(entity_type) if not entity_type.is_empty() else null


func initialize(p_entity_id: String, p_entity_type: String, p_data: Dictionary = {}) -> void:
	entity_id = p_entity_id
	entity_type = p_entity_type

	if p_data.is_empty():
		data = GameData.get_entity_data(entity_id)
	else:
		data = p_data

	var raw_grid_size: Variant = data.get("grid_size", 1)
	if raw_grid_size is Array:
		grid_size = int(raw_grid_size[0])
	else:
		grid_size = int(raw_grid_size)

	# Cache component references
	health_component = _find_component("HealthComponent")
	combat_component = _find_component("CombatComponent")
	movement_component = _find_component("MovementComponent")
	buff_debuff_component = _find_component("BuffDebuffComponent")

	# Initialize components with data
	if health_component:
		health_component.initialize(data)
	if combat_component:
		combat_component.initialize(data)
	if movement_component:
		movement_component.initialize(data)
	if buff_debuff_component:
		buff_debuff_component.initialize(data)

	# Generate placeholder visual
	_setup_visual()

	is_initialized = true

	# Register with EntityRegistry
	EntityRegistry.register(self, entity_type)
	GameBus.entity_spawned.emit(self, entity_type, entity_id)


func _setup_visual() -> void:
	if visual_node:
		return
	# Try entity-specific detailed visual first
	var color_hex: String = data.get("mesh_color", "#888888")
	visual_node = VisualGenerator.create_entity_visual(entity_id, Color.html(color_hex))
	if not visual_node:
		# Fallback to simple mesh for unknown entity types
		visual_node = VisualGenerator.create_mesh(
			data.get("mesh_shape", "box"),
			color_hex,
			data.get("mesh_scale", [1.0, 1.0, 1.0])
		)
	if visual_node:
		add_child(visual_node)


func get_data_value(key: String, default: Variant = null) -> Variant:
	return data.get(key, default)


func die(killer: Node = null) -> void:
	GameBus.entity_died.emit(self, entity_type, entity_id, killer)
	EntityRegistry.unregister(self, entity_type)
	GameBus.entity_removed.emit(self, entity_type)
	queue_free()


func _find_component(component_name: String) -> Node:
	for child in get_children():
		if child.name == component_name or child.get_script() and child.get_script().get_global_name() == component_name:
			return child
	return null
