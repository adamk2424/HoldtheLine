class_name MechJuggernaut
extends UnitBase
## MechJuggernaut - Heavy melee mech with Fortify passive ability.
## Fortify: after standing still for stationary_delay seconds, gains armor and damage reduction.

var fortify_stationary_delay: float = 3.0
var fortify_armor_bonus: float = 3.0

var _stationary_timer: float = 0.0
var _is_fortified: bool = false
var _last_position: Vector3 = Vector3.ZERO


func initialize(p_entity_id: String, p_entity_type: String, p_data: Dictionary = {}) -> void:
	super.initialize(p_entity_id, p_entity_type, p_data)

	# Parse fortify special from data
	var specials: Array = data.get("specials", [])
	for special: Dictionary in specials:
		if special.get("type", "") == "fortify":
			fortify_stationary_delay = float(special.get("stationary_delay", 3.0))
			fortify_armor_bonus = float(special.get("armor_bonus", 3))

	_last_position = global_position
	add_to_group("mechs")


func _process(delta: float) -> void:
	super._process(delta)
	_process_fortify(delta)


func _process_fortify(delta: float) -> void:
	if health_component and health_component.is_dead:
		return

	var moved: bool = global_position.distance_squared_to(_last_position) > 0.01
	_last_position = global_position

	if moved:
		# Moving: reset timer and remove fortify if active
		_stationary_timer = 0.0
		if _is_fortified:
			_deactivate_fortify()
	else:
		# Stationary: accumulate timer
		if not _is_fortified:
			_stationary_timer += delta
			if _stationary_timer >= fortify_stationary_delay:
				_activate_fortify()


func _activate_fortify() -> void:
	_is_fortified = true

	if health_component:
		health_component.current_armor += fortify_armor_bonus

	GameBus.audio_play_3d.emit("unit.%s.fortify" % entity_id, global_position)


func _deactivate_fortify() -> void:
	_is_fortified = false

	if health_component:
		health_component.current_armor = max(0.0, health_component.current_armor - fortify_armor_bonus)
