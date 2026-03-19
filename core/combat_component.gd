class_name CombatComponent
extends Node
## CombatComponent - Handles targeting, attacking, and projectile creation.
## Acquires targets from EntityRegistry, fires at attack_rate intervals.

signal target_acquired(target: Node)
signal target_lost()
signal attack_fired(target: Node)

var damage: float = 0.0
var attack_rate: float = 1.0  # seconds between attacks
var attack_range: float = 10.0
var attack_type: String = "projectile"  # projectile, beam, melee, aoe
var can_target_air: bool = false
var target_type: String = "enemy"  # What entity type to target

var current_target: Node = null
var _attack_timer: float = 0.0
var is_active: bool = true
var damage_multiplier: float = 1.0
var range_multiplier: float = 1.0

# Retarget throttle: avoid scanning every frame when no target is found.
var _retarget_cooldown: float = 0.0
const RETARGET_INTERVAL: float = 0.25  # seconds between target searches

# Special combat modifiers
var armor_pierce: float = 0.0
var bonus_vs_air: float = 1.0
var bonus_vs_buildings: float = 1.0
var chain_count: int = 0
var chain_falloff: float = 0.3

# Forced target (e.g., from Clugg threat_aura)
var forced_target: Node = null
var _forced_target_timer: float = 0.0

@onready var entity: EntityBase = get_parent() as EntityBase


func initialize(data: Dictionary) -> void:
	damage = float(data.get("damage", 0))
	attack_rate = float(data.get("attack_rate", 1.0))
	attack_range = float(data.get("attack_range", 10.0))
	attack_type = data.get("attack_type", "projectile")
	can_target_air = data.get("can_target_air", false)

	# Stagger retarget timing so entities don't all search on the same frame
	_retarget_cooldown = randf() * RETARGET_INTERVAL

	# Parse specials (tower JSON uses "id" key, enemy JSON uses "type" key)
	var specials: Array = data.get("specials", [])
	for special: Dictionary in specials:
		var stype: String = special.get("type", special.get("id", ""))
		match stype:
			"armor_pierce":
				armor_pierce = float(special.get("amount", 5.0))
			"bonus_vs_air":
				bonus_vs_air = float(special.get("multiplier", 2.0))
			"bonus_vs_buildings":
				bonus_vs_buildings = float(special.get("multiplier", 2.0))
			"chain_lightning":
				chain_count = int(special.get("chain_count", special.get("targets", 3)))
				chain_falloff = float(special.get("chain_damage_falloff", special.get("falloff", 0.3)))


func _process(delta: float) -> void:
	if not is_active or damage <= 0.0:
		return

	_attack_timer += delta

	# Handle forced target (e.g., Clugg threat_aura)
	if _forced_target_timer > 0.0:
		_forced_target_timer -= delta
		if _forced_target_timer <= 0.0:
			forced_target = null
		elif forced_target and is_instance_valid(forced_target) and forced_target.is_inside_tree():
			current_target = forced_target

	if not _has_valid_target():
		_retarget_cooldown -= delta
		if _retarget_cooldown <= 0.0:
			if FrameBudget.has_budget():
				_find_target()
			_retarget_cooldown = RETARGET_INTERVAL
	else:
		# Reset cooldown so we search quickly after losing a target
		_retarget_cooldown = 0.0

	if current_target and _attack_timer >= attack_rate:
		_attack_timer = 0.0
		_perform_attack()


func _has_valid_target() -> bool:
	if not current_target:
		return false
	if not is_instance_valid(current_target):
		current_target = null
		target_lost.emit()
		return false
	if not current_target.is_inside_tree():
		current_target = null
		target_lost.emit()
		return false
	var dist: float = entity.global_position.distance_to(current_target.global_position)
	if dist > get_effective_range():
		current_target = null
		target_lost.emit()
		return false
	return true


func _find_target() -> void:
	var new_target := EntityRegistry.get_nearest(
		entity.global_position,
		target_type,
		get_effective_range()
	)
	if new_target and new_target != current_target:
		current_target = new_target
		target_acquired.emit(current_target)


func _perform_attack() -> void:
	if not current_target:
		return

	var final_damage := get_effective_damage()

	# Apply bonus multipliers
	if current_target.is_in_group("flying") and bonus_vs_air > 1.0:
		final_damage *= bonus_vs_air
	if current_target.is_in_group("building") and bonus_vs_buildings > 1.0:
		final_damage *= bonus_vs_buildings

	# Determine weapon type for VFX
	var weapon_type := _get_weapon_type()
	
	match attack_type:
		"melee", "beam":
			_deal_direct_damage(current_target, final_damage)
		"projectile":
			_spawn_projectile(current_target, final_damage)
			GameBus.projectile_fired.emit(entity, current_target, weapon_type)
		"aoe":
			_spawn_aoe(current_target.global_position, final_damage)

	# Emit weapon fire signal for VFX
	GameBus.weapon_fired.emit(entity.global_position, weapon_type, current_target.global_position)
	
	attack_fired.emit(current_target)
	GameBus.audio_play_3d.emit("%s.%s.fire" % [entity.entity_type, entity.entity_id], entity.global_position)


func _deal_direct_damage(target: Node, amount: float) -> void:
	var health: Node = _get_health(target)
	if health:
		var effective_damage := amount
		if armor_pierce > 0.0:
			# Armor pierce: temporarily reduce target armor for this hit
			var orig_armor: float = health.current_armor
			health.current_armor = max(0.0, health.current_armor - armor_pierce)
			health.take_damage(effective_damage, entity)
			health.current_armor = orig_armor
		else:
			health.take_damage(effective_damage, entity)


func _spawn_projectile(target: Node, dmg: float) -> void:
	var proj := Projectile.acquire(entity.get_tree().current_scene)
	proj.global_position = entity.global_position + Vector3(0, 1, 0)
	proj.setup(target, dmg, armor_pierce, entity)


func _spawn_aoe(target_pos: Vector3, dmg: float) -> void:
	var aoe_scene := preload("res://core/aoe_effect.tscn")
	var aoe: Node3D = aoe_scene.instantiate()
	entity.get_tree().current_scene.add_child(aoe)
	aoe.global_position = target_pos
	var aoe_data: Dictionary = entity.data
	var radius: float = float(aoe_data.get("aoe_radius", 4.0))
	aoe.setup(dmg, radius, entity, target_type)
	GameBus.aoe_triggered.emit(target_pos, radius, dmg, entity)


func get_effective_damage() -> float:
	return damage * damage_multiplier


func get_effective_range() -> float:
	return attack_range * range_multiplier


func _get_health(node: Node) -> Node:
	if node is EntityBase:
		return node.health_component
	for child in node.get_children():
		if child is HealthComponent:
			return child
	return null

func _get_weapon_type() -> String:
	if not entity:
		return "generic"
	
	var entity_id: String = entity.entity_id
	match entity_id:
		"autocannon":
			return "autocannon"
		"missile_battery":
			return "missile"
		"rail_gun":
			return "railgun"
		"plasma_mortar":
			return "plasma"
		"tesla_coil":
			return "tesla"
		"inferno_tower":
			return "flame"
		_:
			# Default based on attack type
			match attack_type:
				"projectile":
					return "autocannon"
				"beam":
					return "railgun"
				"aoe":
					return "plasma"
				_:
					return "generic"
