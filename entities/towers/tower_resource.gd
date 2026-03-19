class_name TowerResource
extends TowerBase
## TowerResource - Handles the 2 resource tower types:
## leach_tower (corpse harvest for materials), thermal_siphon (energy drain from enemies).

# Leach Tower state
var is_leach_tower: bool = false
var _materials_per_hp: float = 0.1
var _harvest_time: float = 0.3
var _harvest_range: float = 10.0
var _is_harvesting: bool = false
var _harvest_timer: float = 0.0
var _current_corpse: Node = null

# Thermal Siphon state
var is_thermal_siphon: bool = false
var _drain_per_enemy_per_sec: float = 0.5
var _drain_damage_per_sec: float = 5.0
var _drain_range: float = 12.0
var _drain_timer: float = 0.0
const DRAIN_TICK: float = 1.0

# Solar Array state
var is_solar_array: bool = false
var _energy_per_sec: float = 1.0
var _income_registered: bool = false

# Recycler state
var is_recycler: bool = false
var _materials_per_sec: float = 1.0


func initialize(p_entity_id: String, p_entity_type: String, p_data: Dictionary = {}) -> void:
	if p_data.is_empty():
		p_data = GameData.get_tower_resource(p_entity_id)
	super.initialize(p_entity_id, p_entity_type, p_data)

	_parse_resource_type()
	build_completed_signal.connect(_on_build_completed)


func _parse_resource_type() -> void:
	is_leach_tower = false
	is_thermal_siphon = false
	is_solar_array = false
	is_recycler = false

	var effect_type: String = data.get("effect_type", "")
	_harvest_range = float(data.get("effect_radius", data.get("attack_range", 10)))
	_drain_range = float(data.get("effect_radius", data.get("attack_range", 12)))

	var specials: Array = data.get("specials", [])
	for special: Dictionary in specials:
		var stype: String = special.get("type", "")
		match stype:
			"corpse_beam":
				is_leach_tower = true
				_materials_per_hp = float(special.get("materials_per_hp", 0.1))
				_harvest_time = float(special.get("harvest_time", 0.3))
				_harvest_range = float(special.get("range", 10.0))
			"energy_drain":
				is_thermal_siphon = true
				_drain_per_enemy_per_sec = float(special.get("drain_per_enemy_per_sec", 0.5))
				_drain_damage_per_sec = float(special.get("damage_per_sec", 5.0))
			"solar_generation":
				is_solar_array = true
				_energy_per_sec = float(special.get("energy_per_sec", 1.0))
			"material_generation":
				is_recycler = true
				_materials_per_sec = float(special.get("materials_per_sec", 1.0))

	# Fallback: detect by effect_type
	if effect_type == "corpse_harvest" and not is_leach_tower:
		is_leach_tower = true
	elif effect_type == "energy_drain" and not is_thermal_siphon:
		is_thermal_siphon = true
	elif effect_type == "energy_generation" and not is_solar_array:
		is_solar_array = true
	elif effect_type == "material_generation" and not is_recycler:
		is_recycler = true


func _on_build_completed() -> void:
	# Apply item modifiers to resource generation
	_apply_item_modifiers()

	# Leach Tower: listen for corpse spawns
	if is_leach_tower:
		if not GameBus.corpse_spawned.is_connected(_on_corpse_spawned):
			GameBus.corpse_spawned.connect(_on_corpse_spawned)

	# Solar Array: register passive income
	if is_solar_array and not _income_registered:
		GameState.add_income(_energy_per_sec, 0.0)
		_income_registered = true

	# Recycler: register passive material income
	if is_recycler and not _income_registered:
		GameState.add_income(0.0, _materials_per_sec)
		_income_registered = true


func _process(delta: float) -> void:
	super._process(delta)

	if not is_built or is_building:
		return

	if is_leach_tower:
		_process_leach(delta)
	elif is_thermal_siphon:
		_process_drain(delta)


func _process_leach(delta: float) -> void:
	if _is_harvesting and _current_corpse:
		_harvest_timer += delta
		if _harvest_timer >= _harvest_time:
			_harvest_timer = 0.0
			_complete_harvest()
	elif not _is_harvesting:
		# Look for corpses in range
		_find_corpse()


func _find_corpse() -> void:
	var corpses := get_tree().get_nodes_in_group("corpse")
	var best: Node = null
	var best_dist: float = _harvest_range * _harvest_range

	for corpse: Node in corpses:
		if not is_instance_valid(corpse) or not corpse.is_inside_tree():
			continue
		var dist_sq: float = global_position.distance_squared_to(corpse.global_position)
		if dist_sq < best_dist:
			best_dist = dist_sq
			best = corpse

	if best:
		_current_corpse = best
		_is_harvesting = true
		_harvest_timer = 0.0


func _complete_harvest() -> void:
	if not is_instance_valid(_current_corpse):
		_is_harvesting = false
		_current_corpse = null
		return

	# Calculate materials from corpse HP
	var corpse_hp: float = 100.0
	if _current_corpse.has_method("get_original_hp"):
		corpse_hp = _current_corpse.get_original_hp()
	elif _current_corpse.has_meta("original_hp"):
		corpse_hp = float(_current_corpse.get_meta("original_hp"))

	var materials: float = corpse_hp * _materials_per_hp
	GameState.refund_resources(0, materials)

	# Remove corpse
	_current_corpse.queue_free()
	_current_corpse = null
	_is_harvesting = false

	GameBus.audio_play_3d.emit("tower.leach_tower.harvest", global_position)


func _on_corpse_spawned(_pos: Vector3, _enemy_id: String) -> void:
	# Notification that a corpse appeared; we'll find it in _find_corpse
	pass


func _process_drain(delta: float) -> void:
	_drain_timer += delta
	if _drain_timer >= DRAIN_TICK:
		_drain_timer -= DRAIN_TICK
		_tick_energy_drain()


func _tick_energy_drain() -> void:
	var enemies: Array = EntityRegistry.get_in_range(global_position, "enemy", _drain_range)
	var drain_total: float = 0.0
	var primary_target: Node = null
	var primary_dist: float = INF

	for enemy_node: Node in enemies:
		if not is_instance_valid(enemy_node) or not enemy_node.is_inside_tree():
			continue
		if enemy_node is EntityBase and enemy_node.health_component:
			if enemy_node.health_component.is_dead:
				continue
			drain_total += _drain_per_enemy_per_sec * DRAIN_TICK

			# Track nearest for damage dealing
			var d: float = global_position.distance_squared_to(enemy_node.global_position)
			if d < primary_dist:
				primary_dist = d
				primary_target = enemy_node

	# Apply energy income
	if drain_total > 0.0:
		GameState.refund_resources(drain_total, 0)

	# Deal damage to primary target
	if primary_target and is_instance_valid(primary_target):
		if primary_target is EntityBase and primary_target.health_component:
			primary_target.health_component.take_damage(_drain_damage_per_sec * DRAIN_TICK, self)


func die(killer: Node = null) -> void:
	_remove_income()
	_disconnect_signals()
	super.die(killer)


func on_sold() -> void:
	_remove_income()
	_disconnect_signals()


func _remove_income() -> void:
	if is_solar_array and _income_registered:
		GameState.remove_income(_energy_per_sec, 0.0)
		_income_registered = false
	if is_recycler and _income_registered:
		GameState.remove_income(0.0, _materials_per_sec)
		_income_registered = false


func _disconnect_signals() -> void:
	if is_leach_tower and GameBus.corpse_spawned.is_connected(_on_corpse_spawned):
		GameBus.corpse_spawned.disconnect(_on_corpse_spawned)


func apply_upgrade_modifications(modifications: Dictionary) -> void:
	_remove_income()
	super.apply_upgrade_modifications(modifications)
	_disconnect_signals()
	_parse_resource_type()
	if is_built:
		_on_build_completed()


func _apply_item_modifiers() -> void:
	if not ItemSystem:
		return
		
	var resource_mods := ItemSystem.get_resource_multipliers()
	
	# Apply energy generation multipliers
	if is_solar_array or is_thermal_siphon:
		var multiplier: float = resource_mods.get("energy_rate_multiplier", 1.0)
		_energy_per_sec *= multiplier
		_drain_per_enemy_per_sec *= multiplier
	
	# Apply material generation multipliers  
	if is_recycler or is_leach_tower:
		var multiplier: float = resource_mods.get("material_rate_multiplier", 1.0)
		_materials_per_sec *= multiplier
		_materials_per_hp *= multiplier
