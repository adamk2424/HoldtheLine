class_name EnemyAISpecial
extends Node
## EnemyAISpecial - AI for special enemies: clugg, terror_bringer, howler.
## Clugg: tank with threat_aura that forces towers to target it.
## Terror Bringer: charges at central tower, death_blast on death.
## Howler: support that buffs nearby enemies with war_cry.

var enemy: EnemyBase = null
var current_target: Node = null
var _retarget_timer: float = 0.0
const RETARGET_INTERVAL: float = 1.0

# Threat Aura state (Clugg)
var _has_threat_aura: bool = false
var _threat_radius: float = 4.0
var _threat_duration: float = 3.0
var _threat_cooldown: float = 10.0
var _threat_timer: float = 0.0

# Slam ability state (Clugg)
var _has_slam: bool = false
var _slam_damage: float = 50.0
var _slam_range: float = 2.0
var _slam_cooldown: float = 15.0
var _slam_timer: float = 0.0  # counts up; fires when >= cooldown
var _slam_ready: bool = true  # starts ready so first slam fires immediately

# Death Blast state (Terror Bringer)
var _has_death_blast: bool = false
var _death_blast_damage: float = 500.0
var _death_blast_radius: float = 3.0
var _death_blast_windup: float = 2.0
var _death_blast_building_reduction: float = 0.5

# War Cry state (Howler)
var _has_war_cry: bool = false
var _war_cry_radius: float = 4.0
var _war_cry_damage_bonus: float = 0.2
var _war_cry_speed_bonus: float = 0.15
var _war_cry_timer: float = 0.0
const WAR_CRY_TICK: float = 2.0
var _war_cry_buffed: Array = []


func _ready() -> void:
	enemy = get_parent() as EnemyBase
	if not enemy:
		push_warning("[EnemyAISpecial] Parent is not EnemyBase")
		return

	# Override CombatComponent auto-targeting
	if enemy.combat_component:
		enemy.combat_component.is_active = false

	# Parse specials
	var specials: Array = enemy.enemy_data.get("specials", [])
	for special: Dictionary in specials:
		var stype: String = special.get("type", "")
		match stype:
			"threat_aura":
				_has_threat_aura = true
				_threat_radius = float(special.get("radius", 4.0))
				_threat_duration = float(special.get("duration", 3.0))
				_threat_cooldown = float(special.get("cooldown", 10.0))
			"slam":
				_has_slam = true
				_slam_damage = float(special.get("damage", 50.0))
				_slam_range = float(special.get("range", 2.0))
				_slam_cooldown = float(special.get("cooldown", 15.0))
			"death_blast":
				_has_death_blast = true
				_death_blast_damage = float(special.get("damage", 500.0))
				_death_blast_radius = float(special.get("radius", 3.0))
				_death_blast_windup = float(special.get("windup", 2.0))
				_death_blast_building_reduction = float(special.get("building_reduction", 0.5))
			"war_cry":
				_has_war_cry = true
				_war_cry_radius = float(special.get("radius", 4.0))
				_war_cry_damage_bonus = float(special.get("damage_bonus", 0.2))
				_war_cry_speed_bonus = float(special.get("speed_bonus", 0.15))

	# Connect death for death_blast
	if _has_death_blast and enemy.health_component:
		enemy.health_component.died.connect(_on_died_death_blast)


func _process(delta: float) -> void:
	if not enemy or not enemy.is_initialized:
		return
	if enemy.health_component and enemy.health_component.is_dead:
		return
	if not GameState.is_game_active:
		return

	# Stagger expensive AI work across frames when enemy counts are high.
	if not enemy.should_process_ai():
		return

	if _has_threat_aura:
		_process_threat_aura(delta)
		_process_slam(delta)
	elif _has_war_cry:
		_process_war_cry(delta)

	# Terror Bringer and Clugg have attack behavior
	if _has_death_blast or _has_threat_aura:
		_retarget_timer += delta
		if _retarget_timer >= RETARGET_INTERVAL:
			_retarget_timer = 0.0
			_update_target()
		_update_charge_behavior(delta)
	elif _has_war_cry:
		_retarget_timer += delta
		if _retarget_timer >= RETARGET_INTERVAL:
			_retarget_timer = 0.0
			_update_howler_movement()


## --- Threat Aura (Clugg) ---

func _process_threat_aura(delta: float) -> void:
	_threat_timer += delta
	if _threat_timer >= _threat_cooldown:
		_threat_timer = 0.0
		_pulse_threat_aura()


func _pulse_threat_aura() -> void:
	# Force all player towers in radius to target this Clugg
	var towers: Array = EntityRegistry.get_in_range(enemy.global_position, "tower", _threat_radius)
	for tower: Node in towers:
		if not is_instance_valid(tower) or not tower.is_inside_tree():
			continue
		if tower is EntityBase and tower.combat_component:
			tower.combat_component.forced_target = enemy
			tower.combat_component._forced_target_timer = _threat_duration

	GameBus.aoe_triggered.emit(enemy.global_position, _threat_radius, 0.0, enemy)
	GameBus.audio_play_3d.emit("enemy.clugg.threat_aura", enemy.global_position)


## --- Slam Ability (Clugg) ---

func _process_slam(delta: float) -> void:
	if not _has_slam:
		return

	# Cooldown ticks globally so it's always enforced
	if not _slam_ready:
		_slam_timer += delta
		if _slam_timer >= _slam_cooldown:
			_slam_timer = 0.0
			_slam_ready = true

	if _slam_ready:
		# Find nearest player entity in slam range
		var target: Node = _find_slam_target()
		if target:
			_execute_slam(target)


func _find_slam_target() -> Node:
	for etype: String in ["tower", "unit", "building", "barrier", "central_tower"]:
		var nearest: Node = EntityRegistry.get_nearest(enemy.global_position, etype, _slam_range)
		if nearest and is_instance_valid(nearest) and nearest.is_inside_tree():
			return nearest
	return null


func _execute_slam(target: Node) -> void:
	_slam_ready = false
	_slam_timer = 0.0

	if target is EntityBase and target.health_component:
		target.health_component.take_damage(_slam_damage, enemy)

	GameBus.audio_play_3d.emit("enemy.clugg.slam", enemy.global_position)


## --- Death Blast (Terror Bringer) ---

func _on_died_death_blast(_killer: Node) -> void:
	# Schedule death blast after windup delay
	if not enemy.is_inside_tree():
		return
	var timer := enemy.get_tree().create_timer(_death_blast_windup)
	timer.timeout.connect(_execute_death_blast)
	GameBus.audio_play_3d.emit("enemy.terror_bringer.death_blast_windup", enemy.global_position)


func _execute_death_blast() -> void:
	var pos: Vector3 = enemy.global_position
	for etype: String in ["tower", "building", "unit", "barrier", "central_tower"]:
		var targets: Array = EntityRegistry.get_in_range(pos, etype, _death_blast_radius)
		for target: Node in targets:
			if not is_instance_valid(target) or not target.is_inside_tree():
				continue
			if target is EntityBase and target.health_component:
				var dmg: float = _death_blast_damage
				# Reduced damage vs buildings
				if etype in ["tower", "building", "barrier", "central_tower"]:
					dmg *= _death_blast_building_reduction
				target.health_component.take_damage(dmg, enemy)

	GameBus.aoe_triggered.emit(pos, _death_blast_radius, _death_blast_damage, enemy)
	GameBus.audio_play_3d.emit("enemy.terror_bringer.death_blast", pos)


## --- War Cry (Howler) ---

func _process_war_cry(delta: float) -> void:
	_war_cry_timer += delta
	if _war_cry_timer >= WAR_CRY_TICK:
		_war_cry_timer = 0.0
		_apply_war_cry_buffs()


func _apply_war_cry_buffs() -> void:
	# Buff all enemy allies in radius
	var allies: Array = EntityRegistry.get_in_range(enemy.global_position, "enemy", _war_cry_radius)
	for ally: Node in allies:
		if ally == enemy or not is_instance_valid(ally) or not ally.is_inside_tree():
			continue
		if ally is EntityBase and ally.buff_debuff_component:
			if ally.health_component and ally.health_component.is_dead:
				continue
			var buff_id: String = "war_cry_%d" % enemy.get_instance_id()
			ally.buff_debuff_component.apply_buff(buff_id, "damage", _war_cry_damage_bonus, WAR_CRY_TICK + 0.5, enemy)
			var speed_id: String = "war_cry_spd_%d" % enemy.get_instance_id()
			ally.buff_debuff_component.apply_buff(speed_id, "speed", _war_cry_speed_bonus, WAR_CRY_TICK + 0.5, enemy)


func _update_howler_movement() -> void:
	if not enemy.movement_component:
		return

	# Stay with the pack: follow nearest damaged ally or nearest ally
	var damaged_ally := enemy.find_nearest_damaged_ally(_war_cry_radius * 2.0)
	if damaged_ally and is_instance_valid(damaged_ally):
		var dist: float = enemy.global_position.distance_to(damaged_ally.global_position)
		if dist > _war_cry_radius * 0.5:
			enemy.movement_component.move_to(damaged_ally.global_position)
		elif enemy.movement_component.is_moving:
			enemy.movement_component.stop()
	else:
		var nearest_ally := EntityRegistry.get_nearest(enemy.global_position, "enemy", 30.0)
		if nearest_ally and nearest_ally != enemy and is_instance_valid(nearest_ally):
			enemy.movement_component.move_to(nearest_ally.global_position)
		else:
			enemy.movement_component.move_to(EnemyBase.BASE_CENTER)


## --- Charge behavior (Clugg moves toward towers, Terror Bringer charges central tower) ---

func _update_target() -> void:
	if current_target and (not is_instance_valid(current_target) or not current_target.is_inside_tree()):
		current_target = null

	if current_target and current_target is EntityBase:
		if current_target.health_component and current_target.health_component.is_dead:
			current_target = null

	if not current_target:
		var target_priority: String = enemy.enemy_data.get("target_priority", "nearest")
		if target_priority == "central_tower":
			# Terror Bringer: charge at central tower
			var ct: Array = EntityRegistry.get_all("central_tower")
			if not ct.is_empty() and is_instance_valid(ct[0]):
				current_target = ct[0]
			else:
				current_target = enemy.find_nearest_player_entity()
		elif target_priority == "towers":
			# Clugg: move toward tower clusters
			current_target = EntityRegistry.get_nearest(enemy.global_position, "tower")
			if not current_target:
				current_target = enemy.find_nearest_player_entity()
		else:
			current_target = enemy.find_nearest_player_entity()

	# If path to target is blocked, try to find a reachable target through gaps first
	if current_target and enemy.movement_component and enemy.movement_component.is_path_blocked:
		var reachable := enemy.find_nearest_reachable_player_entity()
		if reachable:
			current_target = reachable
			return
		var barrier := EntityRegistry.get_nearest(enemy.global_position, "barrier")
		if barrier and is_instance_valid(barrier) and barrier.is_inside_tree():
			current_target = barrier


func _update_charge_behavior(delta: float) -> void:
	if not enemy.movement_component:
		return

	if current_target and is_instance_valid(current_target) and current_target.is_inside_tree():
		# Clugg: just move toward towers, slam is handled separately
		if _has_threat_aura and not _has_death_blast:
			enemy.movement_component.move_to(current_target.global_position)
			return

		# Terror Bringer: attack things in path
		if enemy.combat_component:
			var dist: float = enemy.global_position.distance_to(current_target.global_position)
			var attack_range: float = enemy.combat_component.get_effective_range()

			if dist <= attack_range:
				if enemy.movement_component.is_moving:
					enemy.movement_component.stop()
				_perform_attack(delta)
			else:
				enemy.movement_component.move_to(current_target.global_position)
	else:
		if not enemy.movement_component.is_moving:
			enemy.movement_component.move_to(EnemyBase.BASE_CENTER)


func _perform_attack(delta: float) -> void:
	if not current_target or not is_instance_valid(current_target):
		return

	var combat := enemy.combat_component
	combat._attack_timer += delta
	if combat._attack_timer >= combat.attack_rate:
		combat._attack_timer = 0.0
		combat.current_target = current_target
		combat._perform_attack()
