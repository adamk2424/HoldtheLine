class_name TowerOffensive
extends TowerBase
## TowerOffensive - Handles the 6 offensive tower types:
## autocannon, missile_battery, rail_gun, plasma_mortar, tesla_coil, inferno_tower.
## Special handling: tesla_coil chain lightning, inferno_tower heat ramp + armor melt.

# Chain lightning state (tesla_coil)
var _chain_targets_hit: Array = []

# Heat ramp state (inferno_tower)
var _has_heat_ramp: bool = false
var _heat_ramp_percent_per_sec: float = 10.0
var _heat_ramp_max_percent: float = 100.0
var _heat_ramp_current: float = 0.0
var _heat_ramp_target: Node = null
var _heat_ramp_armor_melt_delay: float = 3.0
var _heat_ramp_armor_melt_interval: float = 2.0
var _heat_ramp_armor_melt_amount: int = 1
var _heat_ramp_armor_melt_persist: float = 5.0
var _beam_on_target_time: float = 0.0
var _armor_melt_timer: float = 0.0


func initialize(p_entity_id: String, p_entity_type: String, p_data: Dictionary = {}) -> void:
	if p_data.is_empty():
		p_data = GameData.get_tower_offensive(p_entity_id)
	super.initialize(p_entity_id, p_entity_type, p_data)

	# Parse specials for heat_ramp
	var specials: Array = p_data.get("specials", [])
	for special: Dictionary in specials:
		if special.get("type", "") == "heat_ramp":
			_has_heat_ramp = true
			_heat_ramp_percent_per_sec = float(special.get("ramp_percent_per_sec", 10.0))
			_heat_ramp_max_percent = float(special.get("max_ramp_percent", 100.0))
			_heat_ramp_armor_melt_delay = float(special.get("armor_melt_delay", 3.0))
			_heat_ramp_armor_melt_interval = float(special.get("armor_melt_interval", 2.0))
			_heat_ramp_armor_melt_amount = int(special.get("armor_melt_amount", 1))
			_heat_ramp_armor_melt_persist = float(special.get("armor_melt_persist", 5.0))

	# Hook into combat for special attack handling
	if combat_component:
		combat_component.attack_fired.connect(_on_attack_fired)


func _process(delta: float) -> void:
	super._process(delta)

	if not _has_heat_ramp or not is_built or is_building:
		return

	# Track beam-on-target time for heat ramp
	if combat_component and combat_component.current_target:
		var target: Node = combat_component.current_target
		if target == _heat_ramp_target:
			_beam_on_target_time += delta
			# Ramp up damage
			_heat_ramp_current = min(
				_heat_ramp_max_percent,
				_beam_on_target_time * _heat_ramp_percent_per_sec
			)
			combat_component.damage_multiplier = 1.0 + (_heat_ramp_current / 100.0)

			# Armor melt after delay
			if _beam_on_target_time >= _heat_ramp_armor_melt_delay:
				_armor_melt_timer += delta
				if _armor_melt_timer >= _heat_ramp_armor_melt_interval:
					_armor_melt_timer = 0.0
					_apply_armor_melt(target)
		else:
			# Target changed, reset ramp
			_heat_ramp_target = target
			_heat_ramp_current = 0.0
			_beam_on_target_time = 0.0
			_armor_melt_timer = 0.0
			combat_component.damage_multiplier = 1.0
	else:
		# No target, reset
		_heat_ramp_target = null
		_heat_ramp_current = 0.0
		_beam_on_target_time = 0.0
		_armor_melt_timer = 0.0
		if combat_component:
			combat_component.damage_multiplier = 1.0


func _apply_armor_melt(target: Node) -> void:
	if not is_instance_valid(target):
		return
	if target is EntityBase and target.buff_debuff_component:
		var melt_id: String = "armor_melt_%d_%d" % [get_instance_id(), randi() % 10000]
		target.buff_debuff_component.apply_debuff(
			melt_id,
			"armor",
			float(_heat_ramp_armor_melt_amount),
			_heat_ramp_armor_melt_persist,
			self
		)


func _on_attack_fired(target: Node) -> void:
	if not is_instance_valid(target):
		return

	# Tesla coil: chain lightning after primary hit
	if entity_id == "tesla_coil" or _has_special("chain_lightning"):
		_perform_chain_lightning(target)


func _perform_chain_lightning(primary_target: Node) -> void:
	if not combat_component:
		return

	# Get chain params from specials or combat component
	var chain_count: int = 3
	var chain_falloff: float = 0.25
	var chain_range: float = 4.0

	var specials: Array = data.get("specials", [])
	for special: Dictionary in specials:
		if special.get("type", "") == "chain_lightning":
			chain_count = int(special.get("chain_count", 3))
			chain_falloff = float(special.get("chain_damage_falloff", 0.25))
			chain_range = float(special.get("chain_range", 4.0))

	if chain_count <= 0:
		return

	var base_damage: float = combat_component.get_effective_damage()
	var current_damage: float = base_damage
	var current_origin: Vector3 = primary_target.global_position
	_chain_targets_hit.clear()
	_chain_targets_hit.append(primary_target)

	for i in range(chain_count):
		current_damage *= (1.0 - chain_falloff)
		if current_damage < 0.1:
			break

		var next_target := _find_chain_target(current_origin, chain_range)
		if not next_target:
			break

		_chain_targets_hit.append(next_target)

		if next_target is EntityBase and next_target.health_component:
			next_target.health_component.take_damage(current_damage, self)

		_spawn_chain_visual(current_origin, next_target.global_position)
		current_origin = next_target.global_position

	_chain_targets_hit.clear()


func _find_chain_target(origin: Vector3, chain_range: float) -> Node:
	var candidates: Array = EntityRegistry.get_in_range(origin, "enemy", chain_range)
	var nearest: Node = null
	var nearest_dist_sq: float = INF

	for candidate: Node in candidates:
		if not is_instance_valid(candidate) or not candidate.is_inside_tree():
			continue
		if candidate in _chain_targets_hit:
			continue
		var dist_sq: float = origin.distance_squared_to(candidate.global_position)
		if dist_sq < nearest_dist_sq:
			nearest_dist_sq = dist_sq
			nearest = candidate

	return nearest


func _spawn_chain_visual(from_pos: Vector3, to_pos: Vector3) -> void:
	var beam := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	var dist: float = from_pos.distance_to(to_pos)
	cyl.top_radius = 0.05
	cyl.bottom_radius = 0.05
	cyl.height = dist

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.6, 0.4, 1.0, 0.8)
	mat.emission_enabled = true
	mat.emission = Color(0.6, 0.4, 1.0)
	mat.emission_energy_multiplier = 4.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cyl.material = mat

	beam.mesh = cyl

	var midpoint: Vector3 = (from_pos + to_pos) / 2.0
	beam.global_position = midpoint

	var direction: Vector3 = (to_pos - from_pos).normalized()
	if direction.length() > 0.001:
		beam.look_at(to_pos, Vector3.UP)
		beam.rotate_object_local(Vector3.RIGHT, PI / 2.0)

	get_tree().current_scene.add_child(beam)

	var timer := get_tree().create_timer(0.15)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(beam):
			beam.queue_free()
	)


func _has_special(special_type: String) -> bool:
	var specials: Array = data.get("specials", [])
	for special: Dictionary in specials:
		if special.get("type", "") == special_type:
			return true
	return false
