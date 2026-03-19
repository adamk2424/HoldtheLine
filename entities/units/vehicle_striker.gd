class_name VehicleStriker
extends UnitBase
## VehicleStriker - Fast ranged vehicle with Overdrive special ability.
## Overdrive: boosts move speed and attack speed for a duration, on cooldown.

var overdrive_duration: float = 8.0
var overdrive_cooldown: float = 30.0
var overdrive_move_speed_bonus: float = 0.5
var overdrive_attack_speed_bonus: float = 0.25

var _overdrive_timer: float = 0.0
var _overdrive_active: bool = false
var _overdrive_active_timer: float = 0.0
var _original_attack_rate: float = 0.333


func initialize(p_entity_id: String, p_entity_type: String, p_data: Dictionary = {}) -> void:
	super.initialize(p_entity_id, p_entity_type, p_data)

	# Parse overdrive special from data
	var specials: Array = data.get("specials", [])
	for special: Dictionary in specials:
		if special.get("type", "") == "overdrive":
			overdrive_duration = float(special.get("duration", 8))
			overdrive_cooldown = float(special.get("cooldown", 30))
			overdrive_move_speed_bonus = float(special.get("move_speed_bonus", 0.5))
			overdrive_attack_speed_bonus = float(special.get("attack_speed_bonus", 0.25))

	# Store original attack rate
	if combat_component:
		_original_attack_rate = combat_component.attack_rate

	add_to_group("vehicles")


func _process(delta: float) -> void:
	super._process(delta)
	_process_overdrive(delta)


func _process_overdrive(delta: float) -> void:
	if health_component and health_component.is_dead:
		return

	if _overdrive_active:
		# Active duration countdown
		_overdrive_active_timer += delta
		if _overdrive_active_timer >= overdrive_duration:
			_deactivate_overdrive()
	else:
		# Cooldown countdown
		_overdrive_timer += delta
		if _overdrive_timer >= overdrive_cooldown:
			# Only activate if we have a target (are in combat)
			if combat_component and combat_component.current_target:
				_activate_overdrive()


func _activate_overdrive() -> void:
	_overdrive_active = true
	_overdrive_active_timer = 0.0
	_overdrive_timer = 0.0

	# Boost attack speed (reduce attack_rate)
	if combat_component:
		combat_component.attack_rate = _original_attack_rate * (1.0 - overdrive_attack_speed_bonus)

	# Boost move speed
	if movement_component:
		movement_component.speed_multiplier = 1.0 + overdrive_move_speed_bonus

	GameBus.audio_play_3d.emit("unit.%s.overdrive" % entity_id, global_position)


func _deactivate_overdrive() -> void:
	_overdrive_active = false
	_overdrive_active_timer = 0.0

	if combat_component:
		combat_component.attack_rate = _original_attack_rate

	if movement_component:
		movement_component.speed_multiplier = 1.0
