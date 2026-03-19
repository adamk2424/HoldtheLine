class_name VehicleSiegeWalker
extends UnitBase
## VehicleSiegeWalker - Long range siege vehicle with Deploy mode toggle.
## Deploy: stops moving, +damage_bonus, +range_bonus, deploy/undeploy times.

var deploy_damage_bonus: float = 0.2
var deploy_range_bonus: float = 4.0
var deploy_time: float = 2.0
var undeploy_time: float = 1.5

var is_deployed: bool = false
var is_deploying: bool = false
var is_undeploying: bool = false
var _deploy_timer: float = 0.0

var _base_damage: float = 0.0
var _base_attack_range: float = 0.0

# Shatter Shell tracking
var _shatter_shell_enabled: bool = false
var _shatter_shell_nth: int = 4
var _shatter_shell_dmg_bonus: float = 0.5
var _shatter_shell_armor_reduction: float = 2.0
var _shatter_shell_armor_duration: float = 8.0
var _shot_count: int = 0


func initialize(p_entity_id: String, p_entity_type: String, p_data: Dictionary = {}) -> void:
	super.initialize(p_entity_id, p_entity_type, p_data)

	# Parse specials from data
	var specials: Array = data.get("specials", [])
	for special: Dictionary in specials:
		match special.get("type", ""):
			"deploy":
				deploy_damage_bonus = float(special.get("damage_bonus", 0.2))
				deploy_range_bonus = float(special.get("range_bonus", 4))
				deploy_time = float(special.get("deploy_time", 2))
				undeploy_time = float(special.get("undeploy_time", 1.5))
			"shatter_shell":
				_shatter_shell_enabled = true
				_shatter_shell_nth = int(special.get("every_nth_shot", 4))
				_shatter_shell_dmg_bonus = float(special.get("damage_bonus", 0.5))
				_shatter_shell_armor_reduction = float(special.get("armor_reduction", 2))
				_shatter_shell_armor_duration = float(special.get("armor_duration", 8))

	# Store base combat values
	if combat_component:
		_base_damage = combat_component.damage
		_base_attack_range = combat_component.attack_range
		if _shatter_shell_enabled:
			combat_component.attack_fired.connect(_on_attack_fired)

	add_to_group("vehicles")


func _process(delta: float) -> void:
	super._process(delta)
	_process_deploy(delta)


func _process_deploy(delta: float) -> void:
	if is_deploying:
		_deploy_timer += delta
		if _deploy_timer >= deploy_time:
			_deploy_timer = 0.0
			is_deploying = false
			_activate_deploy()
	elif is_undeploying:
		_deploy_timer += delta
		if _deploy_timer >= undeploy_time:
			_deploy_timer = 0.0
			is_undeploying = false
			_deactivate_deploy()


# --- Public API ---

func toggle_deploy() -> void:
	if is_deploying or is_undeploying:
		return  # Already transitioning

	if is_deployed:
		# Start undeploying
		is_undeploying = true
		_deploy_timer = 0.0
		if combat_component:
			combat_component.is_active = false
		GameBus.audio_play_3d.emit("unit.%s.undeploy" % entity_id, global_position)
	else:
		# Start deploying
		is_deploying = true
		_deploy_timer = 0.0
		if movement_component:
			movement_component.stop()
		if combat_component:
			combat_component.is_active = false
		command_state = CommandState.IDLE
		GameBus.audio_play_3d.emit("unit.%s.deploy" % entity_id, global_position)


func _activate_deploy() -> void:
	is_deployed = true

	if combat_component:
		combat_component.damage = _base_damage * (1.0 + deploy_damage_bonus)
		combat_component.attack_range = _base_attack_range + deploy_range_bonus
		combat_component.is_active = true

	if movement_component:
		movement_component.stop()


func _deactivate_deploy() -> void:
	is_deployed = false

	if combat_component:
		combat_component.damage = _base_damage
		combat_component.attack_range = _base_attack_range
		combat_component.is_active = true


func _on_attack_fired(target: Node) -> void:
	_shot_count += 1
	if _shot_count >= _shatter_shell_nth:
		_shot_count = 0
		_apply_shatter_shell(target)


func _apply_shatter_shell(target: Node) -> void:
	if not is_instance_valid(target) or not target.is_inside_tree():
		return
	if target is EntityBase and target.has_node("BuffDebuffComponent"):
		var buff: BuffDebuffComponent = target.get_node("BuffDebuffComponent") as BuffDebuffComponent
		if buff:
			buff.apply_debuff("shatter_shell", "armor_reduction", _shatter_shell_armor_reduction, _shatter_shell_armor_duration, self)


# Override move_to: cannot move while deployed
func move_to(target_position: Vector3) -> void:
	if is_deployed or is_deploying:
		if is_deployed and not is_undeploying:
			toggle_deploy()
			await get_tree().create_timer(undeploy_time + 0.1).timeout
			if not is_deployed and not is_deploying and not is_undeploying:
				super.move_to(target_position)
		return
	super.move_to(target_position)


func attack_move_to(target_position: Vector3) -> void:
	if is_deployed or is_deploying:
		if is_deployed and not is_undeploying:
			toggle_deploy()
			await get_tree().create_timer(undeploy_time + 0.1).timeout
			if not is_deployed and not is_deploying and not is_undeploying:
				super.attack_move_to(target_position)
		return
	super.attack_move_to(target_position)
