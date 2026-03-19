class_name DroneRepair
extends UnitBase
## DroneRepair - Support drone that heals the nearest damaged friendly unit.
## No attack capability. Periodically heals 10 HP/sec to nearest damaged ally.

var heal_per_second: float = 10.0
var heal_range: float = 8.0
var _heal_target: Node = null
var _heal_tick_timer: float = 0.0

const HEAL_TICK_INTERVAL: float = 0.5  # Heal every 0.5s for smooth healing


func initialize(p_entity_id: String, p_entity_type: String, p_data: Dictionary = {}) -> void:
	super.initialize(p_entity_id, p_entity_type, p_data)

	# Disable combat (no attack)
	if combat_component:
		combat_component.is_active = false

	# Parse heal special from data
	var specials: Array = data.get("specials", [])
	for special: Dictionary in specials:
		if special.get("id", "") == "repair_beam":
			heal_per_second = float(special.get("heal_per_second", 10))
			heal_range = float(special.get("range", 8))

	add_to_group("drones")


func _process(delta: float) -> void:
	super._process(delta)
	_process_healing(delta)


func _process_healing(delta: float) -> void:
	_heal_tick_timer += delta
	if _heal_tick_timer < HEAL_TICK_INTERVAL:
		return
	_heal_tick_timer -= HEAL_TICK_INTERVAL

	# Find nearest damaged friendly unit or building
	_heal_target = _find_heal_target()
	if _heal_target:
		var health: HealthComponent = _heal_target.health_component
		if health and not health.is_dead:
			var heal_amount: float = heal_per_second * HEAL_TICK_INTERVAL
			health.heal(heal_amount)


func _find_heal_target() -> Node:
	# Search among units first, then buildings
	var best_target: Node = null
	var best_dist_sq: float = heal_range * heal_range

	# Check friendly units
	var units: Array = EntityRegistry.get_in_range(global_position, "unit", heal_range)
	for unit: Node in units:
		if unit == self:
			continue
		if not is_instance_valid(unit) or not unit.is_inside_tree():
			continue
		if unit is EntityBase and unit.health_component:
			var hc: HealthComponent = unit.health_component
			if not hc.is_dead and hc.current_hp < hc.max_hp:
				var dist_sq: float = global_position.distance_squared_to(unit.global_position)
				if dist_sq < best_dist_sq:
					best_dist_sq = dist_sq
					best_target = unit

	# Check buildings
	var buildings: Array = EntityRegistry.get_in_range(global_position, "building", heal_range)
	for bldg: Node in buildings:
		if not is_instance_valid(bldg) or not bldg.is_inside_tree():
			continue
		if bldg is EntityBase and bldg.health_component:
			var hc: HealthComponent = bldg.health_component
			if not hc.is_dead and hc.current_hp < hc.max_hp:
				var dist_sq: float = global_position.distance_squared_to(bldg.global_position)
				if dist_sq < best_dist_sq:
					best_dist_sq = dist_sq
					best_target = bldg

	# Check central tower
	var towers: Array = EntityRegistry.get_in_range(global_position, "central_tower", heal_range)
	for tower: Node in towers:
		if not is_instance_valid(tower) or not tower.is_inside_tree():
			continue
		if tower is EntityBase and tower.health_component:
			var hc: HealthComponent = tower.health_component
			if not hc.is_dead and hc.current_hp < hc.max_hp:
				var dist_sq: float = global_position.distance_squared_to(tower.global_position)
				if dist_sq < best_dist_sq:
					best_dist_sq = dist_sq
					best_target = tower

	return best_target
