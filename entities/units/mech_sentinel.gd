class_name MechSentinel
extends UnitBase
## MechSentinel - Melee frontline mech with taunt ability.
## Taunt forces enemies within radius 8 to prefer targeting this unit.

var taunt_radius: float = 8.0
var _taunt_active: bool = false
var _taunt_tick_timer: float = 0.0
var _taunted_enemies: Array = []

const TAUNT_TICK_INTERVAL: float = 1.0  # Re-check taunt every second
const TAUNT_BUFF_ID_PREFIX: String = "taunt_target_"


func initialize(p_entity_id: String, p_entity_type: String, p_data: Dictionary = {}) -> void:
	super.initialize(p_entity_id, p_entity_type, p_data)

	# Parse taunt special from data
	var specials: Array = data.get("specials", [])
	for special: Dictionary in specials:
		if special.get("id", "") == "taunt":
			taunt_radius = float(special.get("radius", 8))

	add_to_group("mechs")

	# Auto-activate taunt
	_taunt_active = true


func _process(delta: float) -> void:
	super._process(delta)
	if _taunt_active:
		_process_taunt(delta)


func _process_taunt(delta: float) -> void:
	_taunt_tick_timer += delta
	if _taunt_tick_timer < TAUNT_TICK_INTERVAL:
		return
	_taunt_tick_timer -= TAUNT_TICK_INTERVAL

	if health_component and health_component.is_dead:
		_release_all_taunts()
		return

	# Find all enemies in taunt radius
	var enemies: Array = EntityRegistry.get_in_range(global_position, "enemy", taunt_radius)

	# Release taunts on enemies that left range
	var still_taunted: Array = []
	for enemy: Node in _taunted_enemies:
		if not is_instance_valid(enemy) or not enemy.is_inside_tree():
			continue
		if enemy in enemies:
			still_taunted.append(enemy)
		else:
			_release_taunt(enemy)
	_taunted_enemies = still_taunted

	# Apply taunt to new enemies in range
	for enemy: Node in enemies:
		if not is_instance_valid(enemy) or not enemy.is_inside_tree():
			continue
		if enemy not in _taunted_enemies:
			_apply_taunt(enemy)
			_taunted_enemies.append(enemy)


func _apply_taunt(enemy: Node) -> void:
	# Force enemy's combat component to target this sentinel
	if enemy is EntityBase and enemy.combat_component:
		enemy.combat_component.current_target = self
		enemy.combat_component.target_acquired.emit(self)


func _release_taunt(enemy: Node) -> void:
	# Only release if enemy is still targeting us
	if enemy is EntityBase and enemy.combat_component:
		if enemy.combat_component.current_target == self:
			enemy.combat_component.current_target = null
			enemy.combat_component.target_lost.emit()


func _release_all_taunts() -> void:
	for enemy: Node in _taunted_enemies:
		if is_instance_valid(enemy) and enemy.is_inside_tree():
			_release_taunt(enemy)
	_taunted_enemies.clear()
	_taunt_active = false


func _on_died(killer: Node) -> void:
	_release_all_taunts()
	super._on_died(killer)
