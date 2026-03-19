class_name MovementComponent
extends Node
## MovementComponent - Handles pathfinding and movement via NavigationAgent3D.
## Player units are clamped to the 120x120 buildable area.

signal destination_reached()
signal movement_started()
signal movement_stopped()

# Grid boundaries for player unit clamping (grid origin at 90,90 -> 90+120=210)
const GRID_ORIGIN: float = 90.0
const GRID_SIZE: float = 120.0
const GRID_MIN: float = GRID_ORIGIN
const GRID_MAX: float = GRID_ORIGIN + GRID_SIZE

var speed: float = 5.0
var base_speed: float = 5.0
var speed_multiplier: float = 1.0

var is_moving: bool = false
var has_destination: bool = false
var destination: Vector3 = Vector3.ZERO
var is_path_blocked: bool = false  # True when nav can't reach destination through barriers

var nav_agent: NavigationAgent3D = null
var is_flying: bool = false
var ignores_barriers: bool = false  # If true, uses direct movement through walls
var enforce_boundaries: bool = false  # True for player units

# March mode: cheap direct movement without nav agent, used while enemies are
# far from the base.  Saves expensive NavigationServer3D queries.
var march_mode: bool = false

# Combat zone: the build grid (90-210) with a 20-unit approach margin.
const COMBAT_ZONE_MIN: float = 70.0
const COMBAT_ZONE_MAX: float = 230.0

signal entered_combat_zone()

# Cached flag: when true, skip cosmetic look_at to save matrix ops at scale.
var _skip_facing: bool = false

@onready var entity: Node3D = get_parent() as Node3D


func initialize(data: Dictionary) -> void:
	base_speed = float(data.get("speed", 5.0))
	speed = base_speed
	ignores_barriers = data.get("ignores_barriers", false)

	# Check for flying (top-level flag or special)
	is_flying = data.get("flying", false)
	var specials: Array = data.get("specials", [])
	for special: Dictionary in specials:
		if special.get("type", "") == "flying":
			is_flying = true

	# Set up NavigationAgent3D
	if not is_flying:
		nav_agent = NavigationAgent3D.new()
		nav_agent.path_desired_distance = 1.0
		nav_agent.target_desired_distance = 1.5
		nav_agent.avoidance_enabled = true
		nav_agent.radius = 0.5
		entity.add_child(nav_agent)

	# Re-evaluate paths whenever the navmesh is rebuilt (e.g. structure destroyed).
	GameBus.navmesh_rebaked.connect(_on_navmesh_rebaked)


func _physics_process(delta: float) -> void:
	if not has_destination:
		return

	# Refresh facing flag once per physics frame (cheap int compare).
	_skip_facing = EntityRegistry.get_count("enemy") > 300

	var effective_speed: float = base_speed * speed_multiplier

	# March mode: cheap straight-line movement, no nav agent queries.
	if march_mode:
		if is_flying:
			_move_flying(delta, effective_speed)
		else:
			_move_direct(delta, effective_speed)
		_check_combat_zone()
		return

	if is_flying:
		_move_flying(delta, effective_speed)
	elif nav_agent:
		# Skip querying if the NavigationServer map has never synced yet.
		if NavigationServer3D.map_get_iteration_id(nav_agent.get_navigation_map()) == 0:
			return
		if nav_agent.is_navigation_finished():
			# Only arrive if we are actually close to the destination.
			var dist_to_dest: float = entity.global_position.distance_to(destination)
			if dist_to_dest < nav_agent.target_desired_distance + 1.0:
				is_path_blocked = false
				_arrive()
			elif ignores_barriers:
				# Units that ignore barriers use direct movement through walls.
				is_path_blocked = false
				_move_direct(delta, effective_speed)
			else:
				# Path blocked by barriers -- stop and let AI retarget.
				is_path_blocked = true
				if is_moving:
					is_moving = false
					movement_stopped.emit()
		else:
			is_path_blocked = false
			_move_navigated(delta, effective_speed)


func move_to(target_position: Vector3) -> void:
	destination = target_position
	has_destination = true
	is_path_blocked = false

	if is_flying:
		# Direct movement for flyers
		pass
	elif nav_agent:
		nav_agent.target_position = target_position

	if not is_moving:
		is_moving = true
		movement_started.emit()


func stop() -> void:
	has_destination = false
	is_moving = false
	movement_stopped.emit()


func set_speed_multiplier(multiplier: float) -> void:
	speed_multiplier = multiplier


func get_effective_speed() -> float:
	return base_speed * speed_multiplier


func _move_navigated(delta: float, effective_speed: float) -> void:
	var next_pos: Vector3 = nav_agent.get_next_path_position()
	var direction: Vector3 = entity.global_position.direction_to(next_pos)
	entity.global_position += direction * effective_speed * delta

	# Face movement direction (cosmetic — skipped at high entity counts).
	if not _skip_facing and direction.length_squared() > 0.01:
		var look_target := entity.global_position + direction
		look_target.y = entity.global_position.y
		if look_target.distance_to(entity.global_position) > 0.01:
			entity.look_at(look_target, Vector3.UP)
			entity.rotation.y += PI


func _move_direct(delta: float, effective_speed: float) -> void:
	# Straight-line fallback when NavigationAgent has no valid path.
	var direction: Vector3 = entity.global_position.direction_to(destination)
	direction.y = 0.0
	if direction.length_squared() < 0.001:
		return
	direction = direction.normalized()
	entity.global_position += direction * effective_speed * delta

	if not _skip_facing:
		var look_target := entity.global_position + direction
		look_target.y = entity.global_position.y
		if look_target.distance_to(entity.global_position) > 0.01:
			entity.look_at(look_target, Vector3.UP)
			entity.rotation.y += PI


func _move_flying(delta: float, effective_speed: float) -> void:
	var direction: Vector3 = entity.global_position.direction_to(destination)
	var fly_height: float = 5.0  # Flying units hover above ground
	var target_with_height := Vector3(destination.x, fly_height, destination.z)
	direction = entity.global_position.direction_to(target_with_height)

	if entity.global_position.distance_to(target_with_height) < 1.0:
		_arrive()
		return

	entity.global_position += direction * effective_speed * delta

	# Enforce boundaries for player units
	if enforce_boundaries:
		_clamp_to_grid()

	# Face movement direction (cosmetic — skipped at high entity counts).
	if not _skip_facing:
		var look_target := entity.global_position + direction
		look_target.y = entity.global_position.y
		if look_target.distance_to(entity.global_position) > 0.01:
			entity.look_at(look_target, Vector3.UP)
			entity.rotation.y += PI


func _check_combat_zone() -> void:
	## Check if we've entered the combat zone and should switch to full AI mode.
	var pos := entity.global_position
	if pos.x >= COMBAT_ZONE_MIN and pos.x <= COMBAT_ZONE_MAX \
			and pos.z >= COMBAT_ZONE_MIN and pos.z <= COMBAT_ZONE_MAX:
		march_mode = false
		# Hand off to nav agent for obstacle-aware pathing near structures.
		if nav_agent and has_destination:
			nav_agent.target_position = destination
		entered_combat_zone.emit()


func _clamp_to_grid() -> void:
	## Keep the entity inside the 120x120 buildable area.
	var pos := entity.global_position
	pos.x = clampf(pos.x, GRID_MIN, GRID_MAX)
	pos.z = clampf(pos.z, GRID_MIN, GRID_MAX)
	entity.global_position = pos


func _arrive() -> void:
	has_destination = false
	is_moving = false
	destination_reached.emit()
	movement_stopped.emit()


func _on_navmesh_rebaked() -> void:
	# When the navmesh changes (structure destroyed/built), force a path
	# recomputation so enemies don't stay stuck with stale blocked state.
	if has_destination and nav_agent and not is_flying and not march_mode:
		is_path_blocked = false
		nav_agent.target_position = destination
		if not is_moving:
			is_moving = true
			movement_started.emit()


## Check if a position is reachable via navmesh (no barriers blocking the full path).
func is_position_reachable(target_pos: Vector3) -> bool:
	if is_flying or ignores_barriers:
		return true
	if not nav_agent:
		return false
	var map_rid: RID = nav_agent.get_navigation_map()
	if not map_rid.is_valid():
		return false
	if NavigationServer3D.map_get_iteration_id(map_rid) == 0:
		return false
	var path: PackedVector3Array = NavigationServer3D.map_get_path(
		map_rid, entity.global_position, target_pos, true
	)
	if path.is_empty():
		return false
	var end_point: Vector3 = path[path.size() - 1]
	return end_point.distance_to(target_pos) < 3.0
