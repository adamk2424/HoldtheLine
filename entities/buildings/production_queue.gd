class_name ProductionQueue
extends Node
## ProductionQueue - Simple timer-based unit production queue.
## Uses a Godot Timer node to delay spawning. No manual delta tracking.

signal production_started(unit_id: String)
signal production_completed(unit_id: String)
signal queue_changed(queue: Array)

# Queue state
var queue: Array = []  # Array of unit_id strings
var max_queue_size: int = 5
var is_producing: bool = false
var current_build_time: float = 0.0

# Speed multiplier (can be modified by upgrades)
var build_speed_multiplier: float = 1.0

# Reference to parent building
var building: Node = null

# The timer that drives production
var _timer: Timer = null

# Continuous production mode
var continuous_enabled: bool = false
var continuous_unit_ids: Array = []
var _continuous_index: int = 0


## Progress as a 0-1 fraction, derived from the Timer.
var current_build_progress: float:
	get:
		if not is_producing or current_build_time <= 0.0 or not _timer:
			return 0.0
		var elapsed: float = current_build_time - _timer.time_left
		return clampf(elapsed, 0.0, current_build_time)


func _ready() -> void:
	_timer = Timer.new()
	_timer.name = "BuildTimer"
	_timer.one_shot = true
	_timer.process_callback = Timer.TIMER_PROCESS_IDLE
	_timer.timeout.connect(_on_build_timer_timeout)
	add_child(_timer)


func initialize(p_building: Node, p_max_queue_size: int = 5) -> void:
	building = p_building
	max_queue_size = p_max_queue_size


func add_to_queue(unit_id: String) -> bool:
	if queue.size() >= max_queue_size:
		return false

	var unit_data: Dictionary = GameData.get_unit(unit_id)
	if unit_data.is_empty():
		push_warning("[ProductionQueue] Unknown unit_id: %s" % unit_id)
		return false

	var energy_cost: float = float(unit_data.get("cost_energy", 0))
	var material_cost: float = float(unit_data.get("cost_materials", 0))

	if not GameState.can_afford(energy_cost, material_cost):
		GameBus.resources_insufficient.emit(energy_cost, material_cost)
		return false

	var pop_cost: int = int(unit_data.get("pop_cost", 1))
	if not GameState.add_population(pop_cost):
		return false

	if not GameState.spend_resources(energy_cost, material_cost):
		GameState.free_population(pop_cost)
		return false

	queue.append(unit_id)
	queue_changed.emit(queue)
	GameBus.unit_queued.emit(building, unit_id)

	# Start production if idle
	if not is_producing:
		_start_next()

	return true


func cancel_from_queue(index: int) -> bool:
	if index < 0 or index >= queue.size():
		return false

	var unit_id: String = queue[index]
	var unit_data: Dictionary = GameData.get_unit(unit_id)

	# Refund resources
	if not unit_data.is_empty():
		var energy_cost: float = float(unit_data.get("cost_energy", 0))
		var material_cost: float = float(unit_data.get("cost_materials", 0))
		GameState.refund_resources(energy_cost, material_cost)
		var pop_cost: int = int(unit_data.get("pop_cost", 1))
		GameState.free_population(pop_cost)

	queue.remove_at(index)
	queue_changed.emit(queue)

	# If we canceled the currently building item (index 0), restart
	if index == 0:
		is_producing = false
		_timer.stop()
		current_build_time = 0.0
		if not queue.is_empty():
			_start_next()

	return true


func cancel_all() -> void:
	while not queue.is_empty():
		cancel_from_queue(queue.size() - 1)


func get_queue_size() -> int:
	return queue.size()


func get_current_progress_percent() -> float:
	if current_build_time <= 0.0:
		return 0.0
	return clampf(current_build_progress / current_build_time, 0.0, 1.0)


func _start_next() -> void:
	if queue.is_empty():
		is_producing = false
		return

	var unit_id: String = queue[0]
	var unit_data: Dictionary = GameData.get_unit(unit_id)
	current_build_time = float(unit_data.get("build_time", 5.0))
	is_producing = true

	# Start the timer
	var effective_time: float = current_build_time / build_speed_multiplier
	_timer.start(effective_time)

	production_started.emit(unit_id)
	GameBus.unit_production_started.emit(building, unit_id)


func _on_build_timer_timeout() -> void:
	_complete_current()


func _complete_current() -> void:
	if queue.is_empty():
		return

	var unit_id: String = queue[0]
	queue.remove_at(0)

	is_producing = false
	current_build_time = 0.0

	production_completed.emit(unit_id)
	queue_changed.emit(queue)

	# Start next in queue if available
	if not queue.is_empty():
		_start_next()
	elif continuous_enabled:
		_try_continuous_enqueue()


## Toggle a unit ID in/out of the continuous production rotation.
func toggle_continuous_unit(unit_id: String) -> void:
	if unit_id in continuous_unit_ids:
		continuous_unit_ids.erase(unit_id)
	else:
		continuous_unit_ids.append(unit_id)
	continuous_enabled = not continuous_unit_ids.is_empty()
	if continuous_enabled and queue.is_empty() and not is_producing:
		_try_continuous_enqueue()


func set_continuous(enabled: bool) -> void:
	continuous_enabled = enabled
	if not enabled:
		continuous_unit_ids.clear()
		_continuous_index = 0


func _try_continuous_enqueue() -> void:
	if continuous_unit_ids.is_empty():
		return
	if queue.size() >= max_queue_size:
		return

	var attempts: int = 0
	while attempts < continuous_unit_ids.size():
		_continuous_index = _continuous_index % continuous_unit_ids.size()
		var unit_id: String = continuous_unit_ids[_continuous_index]
		_continuous_index += 1
		attempts += 1

		var unit_data: Dictionary = GameData.get_unit(unit_id)
		if unit_data.is_empty():
			continue

		var ecost: float = float(unit_data.get("cost_energy", 0))
		var mcost: float = float(unit_data.get("cost_materials", 0))
		if not GameState.can_afford(ecost, mcost):
			continue

		var pop_cost: int = int(unit_data.get("pop_cost", 1))
		if GameState.population_current + pop_cost > GameState.population_max:
			continue

		if add_to_queue(unit_id):
			return
