class_name PopulationSystem
extends Node
## PopulationSystem - Manages population cap tracking.
## Listens to unit spawn/death events and enforces population limits.
## Coordinates with GameState for population current/max values.


func _ready() -> void:
	GameBus.entity_spawned.connect(_on_entity_spawned)
	GameBus.entity_died.connect(_on_entity_died)
	GameBus.unit_production_completed.connect(_on_unit_production_completed)

	# Emit initial population state
	GameBus.population_changed.emit(GameState.population_current, GameState.population_max)


func _on_entity_spawned(_entity: Node, entity_type: String, _entity_id: String) -> void:
	if entity_type == "unit":
		# Population was already reserved when queued in ProductionQueue.
		# Just emit updated state for UI.
		GameBus.population_changed.emit(GameState.population_current, GameState.population_max)


func _on_entity_died(entity: Node, entity_type: String, _entity_id: String, _killer: Node) -> void:
	if entity_type == "unit":
		# Population is freed in UnitBase._on_died() via GameState.free_population().
		# Emit updated state for UI.
		GameBus.population_changed.emit(GameState.population_current, GameState.population_max)


func _on_unit_production_completed(_building: Node, _unit_id: String, _unit: Node) -> void:
	# Population was already reserved at queue time. Log for debugging.
	pass


# --- Public API ---

func can_afford_population(pop_cost: int) -> bool:
	return GameState.population_current + pop_cost <= GameState.population_max


func get_population_display() -> String:
	return "%d / %d" % [GameState.population_current, GameState.population_max]


func get_current_population() -> int:
	return GameState.population_current


func get_max_population() -> int:
	return GameState.population_max
