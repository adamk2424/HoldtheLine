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
var accuracy_multiplier: float = 1.0
var attack_speed_multiplier: float = 1.0

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

	# Apply item system modifiers
	_apply_item_modifiers()

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

	# All towers deal instant direct damage
	if attack_type == "aoe":
		_spawn_aoe(current_target.global_position, final_damage)
	else:
		_deal_direct_damage(current_target, final_damage)

	# Draw attack line from tower to target
	var fire_pos: Vector3 = entity.global_position + Vector3(0, 1.5, 0)
	var hit_pos: Vector3 = current_target.global_position + Vector3(0, 0.5, 0)
	_create_attack_line(fire_pos, hit_pos)

	# Emit signals for audio
	var weapon_type := _get_weapon_type()
	GameBus.weapon_fired.emit(entity.global_position, weapon_type, current_target.global_position)
	attack_fired.emit(current_target)
	GameBus.audio_play_3d.emit("%s.%s.fire" % [entity.entity_type, entity.entity_id], entity.global_position)


func _deal_direct_damage(target: Node, amount: float) -> void:
	var health: Node = _get_health(target)
	if health:
		var effective_damage := amount
		
		# Apply item-based armor piercing
		var item_armor_pierce := 0.0
		if is_instance_valid(ItemSystem):
			var tower_mods := ItemSystem.get_tower_modifiers()
			item_armor_pierce = tower_mods.get("armor_pierce", 0.0)
		
		var total_armor_pierce := armor_pierce + item_armor_pierce
		
		if total_armor_pierce > 0.0:
			# Armor pierce: temporarily reduce target armor for this hit
			var orig_armor: float = health.current_armor
			health.current_armor = max(0.0, health.current_armor - total_armor_pierce)
			health.take_damage(effective_damage, entity)
			health.current_armor = orig_armor
		else:
			health.take_damage(effective_damage, entity)
		
		# Check for chain lightning from items
		_try_chain_lightning(target, amount)


func _create_attack_line(from_pos: Vector3, to_pos: Vector3) -> void:
	## Draw a quick flash line from tower to target showing where it's aiming.
	var scene_root: Node = entity.get_tree().current_scene
	if not scene_root:
		return

	var length: float = from_pos.distance_to(to_pos)
	if length < 0.1:
		return

	var mid: Vector3 = (from_pos + to_pos) / 2.0

	var line := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.04, 0.04, length)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.9, 0.3, 0.9)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.8, 0.2)
	mat.emission_energy_multiplier = 3.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	box.material = mat

	line.mesh = box
	line.position = mid
	line.look_at_from_position(mid, to_pos)

	scene_root.add_child(line)

	# Fade out and cleanup
	var tween: Tween = scene_root.create_tween()
	tween.tween_property(mat, "albedo_color", Color(1.0, 0.9, 0.3, 0.0), 0.12)
	tween.tween_callback(line.queue_free)


func _spawn_aoe(target_pos: Vector3, dmg: float) -> void:
	var aoe_scene := preload("res://core/aoe_effect.tscn")
	var aoe: Node3D = aoe_scene.instantiate()
	entity.get_tree().current_scene.add_child(aoe)
	aoe.global_position = target_pos
	var aoe_data: Dictionary = entity.data
	var radius: float = float(aoe_data.get("aoe_radius", 4.0))
	aoe.setup(dmg, radius, entity, target_type)
	GameBus.aoe_triggered.emit(target_pos, radius, dmg, entity)


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


func _try_chain_lightning(primary_target: Node, damage: float) -> void:
	## Apply chain lightning from items to nearby enemies
	if not is_instance_valid(ItemSystem):
		return
		
	var tower_mods: Dictionary = ItemSystem.get_tower_modifiers()
	var chain_chance: float = tower_mods.get("chain_lightning_chance", 0.0)
	var max_bounces: int = int(tower_mods.get("chain_lightning_bounces", 0))
	
	if chain_chance <= 0.0 or max_bounces <= 0 or randf() > chain_chance:
		return
	
	# Only apply to energy weapons
	if not _is_energy_weapon():
		return
	
	var chain_damage := damage * 0.5  # Chain lightning does 50% damage
	var chain_range := attack_range * 0.6  # 60% of attack range
	var bounced := 0
	var hit_targets: Array[Node] = [primary_target]
	var current_pos: Vector3 = primary_target.global_position
	
	while bounced < max_bounces:
		var nearest_enemy := _find_nearest_chainable_enemy(current_pos, chain_range, hit_targets)
		if not nearest_enemy:
			break
			
		# Visual effect for chain lightning
		_create_chain_lightning_vfx(current_pos, nearest_enemy.global_position)
		
		# Deal damage
		var health := _get_health(nearest_enemy)
		if health:
			health.take_damage(chain_damage, entity)
		
		hit_targets.append(nearest_enemy)
		current_pos = nearest_enemy.global_position
		chain_damage *= 0.8  # Reduce damage with each bounce
		bounced += 1


func _is_energy_weapon() -> bool:
	## Check if this tower uses energy weapons for chain lightning
	var energy_weapons: Array[String] = ["laser_tower", "tesla_coil", "ion_cannon"]
	return entity.entity_id in energy_weapons


func _find_nearest_chainable_enemy(pos: Vector3, range: float, exclude: Array[Node]) -> Node:
	## Find nearest enemy within range that hasn't been hit by chain lightning
	var nearest: Node = null
	var nearest_dist := range
	
	var entities: Array = EntityRegistry.get_all(target_type)
	for target: Node in entities:
		if target in exclude or not is_instance_valid(target):
			continue
			
		var distance := pos.distance_to(target.global_position)
		if distance <= range and distance < nearest_dist:
			nearest = target
			nearest_dist = distance
	
	return nearest


func _create_chain_lightning_vfx(from_pos: Vector3, to_pos: Vector3) -> void:
	## Create visual effect for chain lightning
	# This would create a lightning bolt effect between positions
	# For now, just emit audio
	GameBus.audio_play_3d.emit("weapons.chain_lightning", from_pos)


func _apply_item_modifiers() -> void:
	if not ItemSystem:
		return
		
	var tower_mods := ItemSystem.get_tower_modifiers()
	
	# Apply multipliers
	range_multiplier = tower_mods.get("range_multiplier", 1.0)
	accuracy_multiplier = tower_mods.get("accuracy_multiplier", 1.0) 
	attack_speed_multiplier = tower_mods.get("attack_speed_multiplier", 1.0)
	
	# Apply additive bonuses
	armor_pierce += tower_mods.get("armor_pierce", 0.0)
	
	# Apply tower-specific abilities
	var chain_chance: float = tower_mods.get("chain_lightning_chance", 0.0)
	if chain_chance > 0.0:
		chain_count = max(chain_count, tower_mods.get("chain_lightning_bounces", 0))
	
	# Modify base stats with multipliers
	attack_range *= range_multiplier
	if attack_speed_multiplier != 1.0:
		attack_rate /= attack_speed_multiplier  # Lower rate = faster attacks


func get_effective_damage() -> float:
	var base_dmg := damage * damage_multiplier
	
	if not ItemSystem:
		return base_dmg
	
	# Apply time scaling bonuses
	var time_bonuses := ItemSystem.get_time_scaling_bonuses()
	if time_bonuses.has("damage_multiplier"):
		base_dmg *= time_bonuses["damage_multiplier"]
	
	# Apply adaptive bonuses
	var adaptive_bonuses := ItemSystem.get_adaptive_bonuses()
	if adaptive_bonuses.has("adaptive_damage"):
		base_dmg += adaptive_bonuses["adaptive_damage"]
	
	# Apply all damage multiplier from Omega Protocol
	if ItemSystem.has_effect("all_multiplier"):
		base_dmg *= ItemSystem.get_effect_value("all_multiplier", 1.0)
	
	return base_dmg
