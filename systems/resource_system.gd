class_name ResourceSystem
extends Node
## ResourceSystem - Enhanced resource management for GameSession.
## Tracks per-building income, applies income scaling over time,
## and emits low-resource warnings.

# --- Income tracking ---
# Maps entity instance ID -> {entity_id, energy_rate, material_rate}
var _income_sources: Dictionary = {}

# --- Income scaling ---
const SCALING_INTERVAL: float = 300.0  # 5 minutes
const SCALING_FACTOR: float = 0.10  # 10% increase
var _scaling_timer: float = 0.0
var _scaling_multiplier: float = 1.0

# --- Low resource warning ---
const LOW_RESOURCE_THRESHOLD: float = 50.0
const LOW_RESOURCE_WARNING_INTERVAL: float = 30.0
var _warning_timer: float = 0.0


func _ready() -> void:
	GameBus.build_completed.connect(_on_build_completed)
	GameBus.entity_died.connect(_on_entity_died)
	print("[ResourceSystem] Initialized")


func _process(delta: float) -> void:
	if not GameState.is_game_active or GameState.is_paused:
		return

	# Income scaling timer
	_scaling_timer += delta
	if _scaling_timer >= SCALING_INTERVAL:
		_scaling_timer -= SCALING_INTERVAL
		_apply_income_scaling()

	# Low resource warning
	_warning_timer += delta
	if _warning_timer >= LOW_RESOURCE_WARNING_INTERVAL:
		_warning_timer -= LOW_RESOURCE_WARNING_INTERVAL
		_check_low_resources()


# --- Signal handlers ---

func _on_build_completed(entity: Node, entity_id: String, _grid_position: Vector2i) -> void:
	# Track income sources for reporting purposes.
	# Actual income registration is handled by TowerResource directly.
	var data := GameData.get_entity_data(entity_id)
	if data.is_empty():
		return

	var energy_income := 0.0
	var material_income := 0.0

	var specials: Array = data.get("specials", [])
	for special: Dictionary in specials:
		energy_income += special.get("energy_per_second", 0.0)
		material_income += special.get("materials_per_second", 0.0)

	if energy_income <= 0.0 and material_income <= 0.0:
		return

	var instance_id := entity.get_instance_id()
	_income_sources[instance_id] = {
		"entity_id": entity_id,
		"entity_name": data.get("name", entity_id),
		"base_energy_rate": energy_income,
		"base_material_rate": material_income,
	}


func _on_entity_died(entity: Node, entity_type: String, entity_id: String, _killer: Node) -> void:
	if entity_type == "enemy":
		return

	var instance_id := entity.get_instance_id()
	if not _income_sources.has(instance_id):
		return

	# Remove from tracking (actual income removal handled by TowerResource.die())
	_income_sources.erase(instance_id)
	print("[ResourceSystem] Income source destroyed: %s" % entity_id)


# --- Income scaling ---

func _apply_income_scaling() -> void:
	# Increase base income rates in GameState by the scaling factor
	_scaling_multiplier += SCALING_FACTOR
	var bonus_energy := GameState.energy_bonus_rate * SCALING_FACTOR
	var bonus_material := GameState.material_bonus_rate * SCALING_FACTOR
	GameState.add_income(bonus_energy, bonus_material)
	print("[ResourceSystem] Income scaling applied: %.0f%% multiplier (+%.1f energy, +%.1f materials)" % [
		_scaling_multiplier * 100.0, bonus_energy, bonus_material
	])


# --- Low resource warning ---

func _check_low_resources() -> void:
	if GameState.energy < LOW_RESOURCE_THRESHOLD or GameState.materials < LOW_RESOURCE_THRESHOLD:
		GameBus.audio_play.emit("ui.resource_warning")


# --- Public API ---

func get_income_breakdown() -> Dictionary:
	var breakdown: Dictionary = {}
	for key: int in _income_sources.keys():
		var source: Dictionary = _income_sources[key]
		var entity_id: String = source["entity_id"]
		if not breakdown.has(entity_id):
			breakdown[entity_id] = {
				"name": source["entity_name"],
				"count": 0,
				"total_energy_rate": 0.0,
				"total_material_rate": 0.0,
			}
		breakdown[entity_id]["count"] += 1
		breakdown[entity_id]["total_energy_rate"] += source["base_energy_rate"]
		breakdown[entity_id]["total_material_rate"] += source["base_material_rate"]
	return breakdown


func get_scaling_multiplier() -> float:
	return _scaling_multiplier
