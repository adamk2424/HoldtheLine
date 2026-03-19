extends Node
## GameState - Runtime state for the current game session.
## Tracks resources, tech levels, timers, population.

# --- Resources ---
var energy: float = 100.0
var materials: float = 100.0
var energy_rate: float = 5.0  # per second base
var material_rate: float = 5.0  # per second base
var energy_bonus_rate: float = 0.0  # from resource buildings
var material_bonus_rate: float = 0.0  # from resource buildings

# --- Population ---
var population_current: int = 0
var population_max: int = 100

# --- Game Time ---
var game_time: float = 0.0  # seconds since game start
var is_game_active: bool = false
var is_paused: bool = false
var game_speed: float = 1.0  # 0.75 / 1.0 / 1.25

# --- Stats ---
var enemies_killed: int = 0
var buildings_built: int = 0
var buildings_lost: int = 0

# --- Surge State ---
var is_surge_active: bool = false
var surge_count: int = 0

# --- Tech Levels (per production building) ---
var tech_levels: Dictionary = {
	"drone_printer": 0,
	"mech_bay": 0,
	"war_factory": 0
}

# --- Central Tower ---
var central_tower_alive: bool = true
var central_tower_tier: int = 0
var boss_kills: int = 0
var income_multiplier: float = 1.0

# --- Level System ---
var selected_level_id: String = ""
var current_level_data: Dictionary = {}
var level_objectives_completed: bool = false

# --- Resource tick timer ---
var _resource_tick_timer: float = 0.0
const RESOURCE_TICK_INTERVAL: float = 1.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameBus.game_started.connect(_on_game_started)
	GameBus.game_over.connect(_on_game_over)
	GameBus.game_speed_changed.connect(_on_game_speed_changed)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_KP_8:
		get_tree().quit()


func _process(delta: float) -> void:
	if not is_game_active or is_paused:
		return
	game_time += delta
	_resource_tick_timer += delta
	if _resource_tick_timer >= RESOURCE_TICK_INTERVAL:
		_resource_tick_timer -= RESOURCE_TICK_INTERVAL
		_tick_resources()


func _tick_resources() -> void:
	# Apply item multipliers to rates
	var item_multipliers := ItemSystem.get_resource_multipliers()
	var energy_multiplier := item_multipliers.get("energy_rate_multiplier", 1.0)
	var material_multiplier := item_multipliers.get("material_rate_multiplier", 1.0)
	
	var total_energy_rate := (energy_rate + energy_bonus_rate) * income_multiplier * energy_multiplier
	var total_material_rate := (material_rate + material_bonus_rate) * income_multiplier * material_multiplier
	
	energy += total_energy_rate
	materials += total_material_rate
	GameBus.resources_changed.emit(energy, materials)


# --- Public API ---

func can_afford(energy_cost: float, material_cost: float) -> bool:
	return energy >= energy_cost and materials >= material_cost


func spend_resources(energy_cost: float, material_cost: float) -> bool:
	if not can_afford(energy_cost, material_cost):
		GameBus.resources_insufficient.emit(energy_cost, material_cost)
		return false
	energy -= energy_cost
	materials -= material_cost
	GameBus.resources_changed.emit(energy, materials)
	return true


func refund_resources(energy_amount: float, material_amount: float) -> void:
	energy += energy_amount
	materials += material_amount
	GameBus.resources_changed.emit(energy, materials)


func add_income(energy_income: float, material_income: float) -> void:
	energy_bonus_rate += energy_income
	material_bonus_rate += material_income
	GameBus.resource_income_changed.emit(
		energy_rate + energy_bonus_rate,
		material_rate + material_bonus_rate
	)


func remove_income(energy_income: float, material_income: float) -> void:
	energy_bonus_rate = max(0.0, energy_bonus_rate - energy_income)
	material_bonus_rate = max(0.0, material_bonus_rate - material_income)
	GameBus.resource_income_changed.emit(
		energy_rate + energy_bonus_rate,
		material_rate + material_bonus_rate
	)


func add_population(amount: int) -> bool:
	if population_current + amount > population_max:
		GameBus.population_limit_reached.emit()
		return false
	population_current += amount
	GameBus.population_changed.emit(population_current, population_max)
	return true


func free_population(amount: int) -> void:
	population_current = max(0, population_current - amount)
	GameBus.population_changed.emit(population_current, population_max)


func get_tech_level(building_id: String) -> int:
	return tech_levels.get(building_id, 0)


func set_tech_level(building_id: String, level: int) -> void:
	tech_levels[building_id] = level


func set_game_speed(speed: float) -> void:
	game_speed = speed
	Engine.time_scale = speed
	GameBus.game_speed_changed.emit(speed)


func get_total_energy_rate() -> float:
	var item_multiplier := ItemSystem.get_resource_multipliers().get("energy_rate_multiplier", 1.0)
	return (energy_rate + energy_bonus_rate) * income_multiplier * item_multiplier


func get_total_material_rate() -> float:
	var item_multiplier := ItemSystem.get_resource_multipliers().get("material_rate_multiplier", 1.0)
	return (material_rate + material_bonus_rate) * income_multiplier * item_multiplier


func get_game_time_formatted() -> String:
	var minutes := int(game_time) / 60
	var seconds := int(game_time) % 60
	return "%02d:%02d" % [minutes, seconds]


func reset_state() -> void:
	energy = 100.0
	materials = 100.0
	energy_rate = 5.0
	material_rate = 5.0
	energy_bonus_rate = 0.0
	material_bonus_rate = 0.0
	population_current = 0
	population_max = 100
	game_time = 0.0
	is_game_active = false
	is_paused = false
	game_speed = 1.0
	enemies_killed = 0
	buildings_built = 0
	buildings_lost = 0
	is_surge_active = false
	surge_count = 0
	central_tower_alive = true
	central_tower_tier = 0
	boss_kills = 0
	income_multiplier = 1.0
	selected_level_id = ""
	current_level_data = {}
	level_objectives_completed = false
	tech_levels = {
		"drone_printer": 0,
		"mech_bay": 0,
		"war_factory": 0
	}
	Engine.time_scale = 1.0


func _on_game_started() -> void:
	is_game_active = true
	
	# Apply starting resource bonuses from items
	if ItemSystem:
		var resource_mods := ItemSystem.get_resource_multipliers()
		energy += resource_mods.get("energy_bonus", 0.0)
		materials += resource_mods.get("materials_bonus", 0.0)
		population_max += int(resource_mods.get("population_cap_bonus", 0.0))
		
		# Apply income multipliers to base rates
		energy_rate *= resource_mods.get("energy_rate_multiplier", 1.0)
		material_rate *= resource_mods.get("material_rate_multiplier", 1.0)
	is_paused = false
	_apply_item_starting_bonuses()


func _apply_item_starting_bonuses() -> void:
	var item_multipliers := ItemSystem.get_resource_multipliers()
	
	# Apply starting resource bonuses
	var energy_bonus := item_multipliers.get("energy_bonus", 0.0)
	var material_bonus := item_multipliers.get("materials_bonus", 0.0)
	var population_bonus := int(item_multipliers.get("population_cap_bonus", 0.0))
	
	energy += energy_bonus
	materials += material_bonus
	population_max += population_bonus
	
	if energy_bonus > 0 or material_bonus > 0 or population_bonus > 0:
		print("[GameState] Applied item starting bonuses: +%.0f energy, +%.0f materials, +%d pop cap" % [
			energy_bonus, material_bonus, population_bonus
		])
		GameBus.resources_changed.emit(energy, materials)
		GameBus.population_changed.emit(population_current, population_max)


func _on_game_over(_survival_time: float) -> void:
	is_game_active = false


func _on_game_speed_changed(speed: float) -> void:
	game_speed = speed
	Engine.time_scale = speed
