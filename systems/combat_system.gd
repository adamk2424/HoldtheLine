class_name CombatSystem
extends Node
## CombatSystem - Global combat utility system.
## Added as a child of GameSession.
## Provides damage formula utilities and AoE helpers.
## Tracks combat statistics for the score system.

# Combat stats tracking
var total_damage_dealt: float = 0.0
var total_damage_taken: float = 0.0
var total_kills: int = 0
var total_shots_fired: int = 0
var total_aoe_triggered: int = 0


func _ready() -> void:
	GameBus.damage_dealt.connect(_on_damage_dealt)
	GameBus.entity_died.connect(_on_entity_died)
	GameBus.projectile_fired.connect(_on_projectile_fired)
	GameBus.aoe_triggered.connect(_on_aoe_triggered)


## Calculate effective damage after armor reduction.
## Formula: max(0, raw_damage - armor)
static func get_damage_after_armor(raw_damage: float, armor: float) -> float:
	return maxf(0.0, raw_damage - armor)


## Apply AoE damage to all entities of target_type within radius of position.
## Returns the number of entities hit.
func apply_aoe_damage(aoe_position: Vector3, radius: float, damage: float, source: Node = null, target_type: String = "enemy") -> int:
	var targets: Array = EntityRegistry.get_in_range(aoe_position, target_type, radius)
	var hit_count: int = 0

	for target: Node in targets:
		if not is_instance_valid(target):
			continue
		if target is EntityBase and target.health_component:
			target.health_component.take_damage(damage, source)
			hit_count += 1

	if hit_count > 0:
		GameBus.aoe_triggered.emit(aoe_position, radius, damage, source)

	return hit_count


## Apply damage to a single target with armor pierce support.
## Returns the actual damage dealt.
static func apply_damage_to_target(target: Node, damage: float, armor_pierce: float = 0.0, source: Node = null) -> float:
	if not is_instance_valid(target):
		return 0.0

	var health: HealthComponent = null
	if target is EntityBase:
		health = target.health_component

	if not health:
		return 0.0

	if armor_pierce > 0.0:
		var orig_armor: float = health.current_armor
		health.current_armor = maxf(0.0, health.current_armor - armor_pierce)
		var actual: float = health.take_damage(damage, source)
		health.current_armor = orig_armor
		return actual
	else:
		return health.take_damage(damage, source)


## Get all valid targets of a type within range, sorted by distance (nearest first).
static func get_targets_sorted_by_distance(origin: Vector3, target_type: String, max_range: float) -> Array:
	var targets: Array = EntityRegistry.get_in_range(origin, target_type, max_range)
	var valid: Array = []
	for target: Node in targets:
		if is_instance_valid(target) and target.is_inside_tree():
			valid.append(target)

	valid.sort_custom(func(a: Node, b: Node) -> bool:
		var dist_a: float = origin.distance_squared_to(a.global_position)
		var dist_b: float = origin.distance_squared_to(b.global_position)
		return dist_a < dist_b
	)

	return valid


## Returns a summary of combat stats for score/display purposes.
func get_combat_stats() -> Dictionary:
	return {
		"total_damage_dealt": total_damage_dealt,
		"total_damage_taken": total_damage_taken,
		"total_kills": total_kills,
		"total_shots_fired": total_shots_fired,
		"total_aoe_triggered": total_aoe_triggered
	}


## Reset all tracked combat stats.
func reset_stats() -> void:
	total_damage_dealt = 0.0
	total_damage_taken = 0.0
	total_kills = 0
	total_shots_fired = 0
	total_aoe_triggered = 0


# --- Signal handlers for stat tracking ---

func _on_damage_dealt(_target: Node, amount: float, source: Node) -> void:
	total_damage_dealt += amount
	# Track damage taken by friendly structures
	if _target is EntityBase:
		var target_type: String = _target.entity_type
		if target_type in ["tower", "building", "central_tower"]:
			total_damage_taken += amount


func _on_entity_died(_entity: Node, type: String, _entity_id: String, _killer: Node) -> void:
	if type == "enemy":
		total_kills += 1


func _on_projectile_fired(_source: Node, _target: Node, _projectile_type: String) -> void:
	total_shots_fired += 1


func _on_aoe_triggered(_position: Vector3, _radius: float, _damage: float, _source: Node) -> void:
	total_aoe_triggered += 1
