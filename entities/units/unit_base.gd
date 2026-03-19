class_name UnitBase
extends EntityBase
## UnitBase - Base class for all player-controlled units.
## Extends EntityBase with selection, move/attack commands, health bar, and population tracking.

signal selected()
signal deselected()

# Selection state
var is_selected: bool = false
var selection_ring: MeshInstance3D = null

# Health bar
var health_bar: Node3D = null
var _health_bar_width: float = 1.0

# Command state
enum CommandState { IDLE, MOVING, ATTACKING, ATTACK_MOVING }
var command_state: int = CommandState.IDLE

# Attack-move
var attack_move_destination: Vector3 = Vector3.ZERO
var attack_target: Node = null

# Population cost (from JSON data)
var pop_cost: int = 1


func _ready() -> void:
	super._ready()
	add_to_group("units")
	add_to_group("selectable")


func initialize(p_entity_id: String, p_entity_type: String, p_data: Dictionary = {}) -> void:
	super.initialize(p_entity_id, p_entity_type, p_data)

	# Set combat target type to enemy
	if combat_component:
		combat_component.target_type = "enemy"

	# Read pop cost from data
	pop_cost = int(data.get("pop_cost", 1))

	# Create selection ring (hidden by default)
	_create_selection_ring()

	# Create health bar above unit
	_create_health_bar()

	# Connect health updates
	if health_component:
		health_component.health_changed.connect(_on_health_changed)
		health_component.died.connect(_on_died)

	# Connect movement signals
	if movement_component:
		movement_component.destination_reached.connect(_on_destination_reached)


func _process(delta: float) -> void:
	_update_command_state(delta)
	_update_health_bar_rotation()


func _update_command_state(_delta: float) -> void:
	match command_state:
		CommandState.IDLE:
			pass
		CommandState.MOVING:
			# Pure move: just let MovementComponent handle it
			pass
		CommandState.ATTACKING:
			_process_attack_command()
		CommandState.ATTACK_MOVING:
			_process_attack_move()


func _process_attack_command() -> void:
	# Move toward attack target, attack when in range
	if not _is_valid_node(attack_target):
		command_state = CommandState.IDLE
		attack_target = null
		if combat_component:
			combat_component.current_target = null
		return

	if combat_component:
		var dist: float = global_position.distance_to(attack_target.global_position)
		if dist <= combat_component.get_effective_range():
			# In range, stop moving and let combat component handle it
			if movement_component and movement_component.is_moving:
				movement_component.stop()
			combat_component.current_target = attack_target
		else:
			# Move toward target
			if movement_component:
				movement_component.move_to(attack_target.global_position)


func _process_attack_move() -> void:
	# Move toward destination, but engage enemies along the way
	if combat_component and combat_component.current_target:
		# Currently fighting something, pause movement
		if movement_component and movement_component.is_moving:
			movement_component.stop()
		return

	# No current target, check for enemies in range
	if combat_component and combat_component.damage > 0.0:
		var enemy: Node = EntityRegistry.get_nearest(
			global_position, "enemy", combat_component.get_effective_range()
		)
		if enemy:
			combat_component.current_target = enemy
			if movement_component and movement_component.is_moving:
				movement_component.stop()
			return

	# No enemies nearby, continue moving
	if movement_component and not movement_component.is_moving and not movement_component.has_destination:
		var dist_to_dest: float = global_position.distance_to(attack_move_destination)
		if dist_to_dest > 2.0:
			movement_component.move_to(attack_move_destination)
		else:
			command_state = CommandState.IDLE


# --- Public Command API ---

func move_to(target_position: Vector3) -> void:
	command_state = CommandState.MOVING
	attack_target = null
	if combat_component:
		combat_component.current_target = null
	if movement_component:
		movement_component.move_to(target_position)


func attack_command(target: Node) -> void:
	if not _is_valid_node(target):
		return
	command_state = CommandState.ATTACKING
	attack_target = target
	if combat_component:
		combat_component.current_target = target


func attack_move_to(target_position: Vector3) -> void:
	command_state = CommandState.ATTACK_MOVING
	attack_move_destination = target_position
	attack_target = null
	if combat_component:
		combat_component.current_target = null
	if movement_component:
		movement_component.move_to(target_position)


func stop_command() -> void:
	command_state = CommandState.IDLE
	attack_target = null
	if combat_component:
		combat_component.current_target = null
	if movement_component:
		movement_component.stop()


# --- Selection ---

func select() -> void:
	if is_selected:
		return
	is_selected = true
	if selection_ring:
		selection_ring.visible = true
	selected.emit()
	GameBus.unit_selected.emit(self)


func deselect() -> void:
	if not is_selected:
		return
	is_selected = false
	if selection_ring:
		selection_ring.visible = false
	deselected.emit()
	GameBus.unit_deselected.emit(self)


# --- Visuals ---

func _create_selection_ring() -> void:
	selection_ring = MeshInstance3D.new()
	selection_ring.name = "SelectionRing"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.6
	torus.outer_radius = 0.8
	torus.rings = 16
	torus.ring_segments = 12
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 1.0, 0.2, 0.8)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.no_depth_test = true
	torus.material = mat
	selection_ring.mesh = torus
	selection_ring.position.y = 0.05
	selection_ring.visible = false
	add_child(selection_ring)


func _create_health_bar() -> void:
	var mesh_scale: Array = data.get("mesh_scale", [1.0, 1.0, 1.0])
	var height: float = 1.0
	if mesh_scale.size() >= 2:
		height = float(mesh_scale[1])
	_health_bar_width = max(0.6, float(mesh_scale[0]) if mesh_scale.size() >= 1 else 1.0)

	health_bar = VisualGenerator.create_health_bar(_health_bar_width)
	health_bar.position.y = height + 0.4
	add_child(health_bar)


func _on_health_changed(current_hp: float, max_hp: float) -> void:
	if health_bar and max_hp > 0.0:
		VisualGenerator.update_health_bar(health_bar, current_hp / max_hp, _health_bar_width)


func _update_health_bar_rotation() -> void:
	# Keep health bar facing camera
	if health_bar:
		var cam := get_viewport().get_camera_3d()
		if cam:
			health_bar.global_rotation = cam.global_rotation


# --- Death ---

func _on_died(_killer: Node) -> void:
	# Free population when unit dies
	GameState.free_population(pop_cost)


func _on_destination_reached() -> void:
	if command_state == CommandState.MOVING:
		command_state = CommandState.IDLE
	elif command_state == CommandState.ATTACK_MOVING:
		command_state = CommandState.IDLE


func _is_valid_node(node: Node) -> bool:
	return node != null and is_instance_valid(node) and node.is_inside_tree()
