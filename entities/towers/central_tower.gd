class_name CentralTower
extends TowerBase
## CentralTower - The main building that must survive.
## 3x3 grid, sequential tier upgrades (0→3) with visual progression.
## Looks like a 12-story tower building with antenna on top.
## Each tier: taller building, more lit windows, enhanced antenna array.
## On death: emits GameBus.central_tower_destroyed.


func initialize(p_entity_id: String, p_entity_type: String, p_data: Dictionary = {}) -> void:
	if p_data.is_empty():
		p_data = GameData.get_central_tower()
	super.initialize(p_entity_id, p_entity_type, p_data)

	entity_type = "central_tower"

	# Map JSON "upgrades" to upgrade_paths for the upgrade system
	if data.has("upgrades") and upgrade_paths.is_empty():
		upgrade_paths = data.get("upgrades", [])

	# Central tower starts fully built (no construction delay)
	is_building = false
	is_built = true
	build_timer = build_time

	if visual_node:
		visual_node.scale = Vector3.ONE

	if combat_component:
		combat_component.is_active = true
		combat_component.target_type = "enemy"

	if health_component:
		health_component.is_invulnerable = false
		if not health_component.health_changed.is_connected(_on_central_hp_changed):
			health_component.health_changed.connect(_on_central_hp_changed)
	
	# Apply central tower specific item effects
	_apply_central_tower_item_effects()


func _ready() -> void:
	super._ready()
	add_to_group("central_tower")


func _setup_visual() -> void:
	# Build the detailed tower model instead of a simple cylinder
	if visual_node:
		return
	visual_node = VisualGenerator.create_central_tower_visual(current_tier)
	if visual_node:
		add_child(visual_node)


func _setup_health_bar() -> void:
	# Central tower does NOT show a floating health bar - HP is shown in the HUD.
	# We still create a hidden one to keep the health_changed/died connections working.
	health_bar_width = 3.0
	health_bar = VisualGenerator.create_health_bar(health_bar_width)
	_update_health_bar_position()
	add_child(health_bar)
	health_bar.visible = false

	if health_component:
		health_component.health_changed.connect(_on_health_changed)
		health_component.died.connect(_on_died)


func _update_health_bar_position() -> void:
	if health_bar:
		health_bar.position.y = VisualGenerator.get_central_tower_top_y(current_tier)


# --- Tier Upgrade API ---

func get_next_upgrade() -> Dictionary:
	## Returns the next available tier upgrade, or empty dict if fully upgraded.
	if current_tier >= upgrade_paths.size():
		return {}
	return upgrade_paths[current_tier]


func can_upgrade_tier() -> bool:
	## Check if the next tier upgrade is available (cost + boss kills).
	var upgrade: Dictionary = get_next_upgrade()
	if upgrade.is_empty():
		return false
	var cost_e: float = float(upgrade.get("cost_energy", 0))
	var cost_m: float = float(upgrade.get("cost_materials", 0))
	if not GameState.can_afford(cost_e, cost_m):
		return false
	var required_kills: int = int(upgrade.get("required_boss_kills", 0))
	if GameState.boss_kills < required_kills:
		return false
	return true


func apply_tier_upgrade() -> bool:
	## Apply the next tier upgrade. Returns true on success.
	var upgrade: Dictionary = get_next_upgrade()
	if upgrade.is_empty():
		return false

	var cost_e: float = float(upgrade.get("cost_energy", 0))
	var cost_m: float = float(upgrade.get("cost_materials", 0))

	# Check boss kills requirement
	var required_kills: int = int(upgrade.get("required_boss_kills", 0))
	if GameState.boss_kills < required_kills:
		push_warning("[CentralTower] Need %d boss kills, have %d" % [required_kills, GameState.boss_kills])
		return false

	# Spend resources
	if not GameState.spend_resources(cost_e, cost_m):
		return false

	# Advance tier
	current_tier += 1
	GameState.central_tower_tier = current_tier

	# Apply HP bonus
	var hp_bonus: float = float(upgrade.get("hp_bonus", 0))
	if hp_bonus > 0.0 and health_component:
		health_component.max_hp += hp_bonus
		health_component.current_hp += hp_bonus
		health_component.health_changed.emit(health_component.current_hp, health_component.max_hp)

	# Apply armor bonus
	var armor_bonus: float = float(upgrade.get("armor_bonus", 0))
	if armor_bonus > 0.0 and health_component:
		health_component.base_armor += armor_bonus
		health_component.current_armor += armor_bonus

	# Apply income multiplier
	var income_mult: float = float(upgrade.get("income_multiplier", 1))
	GameState.income_multiplier = income_mult

	# Track investment for sell value
	total_invested_energy += cost_e
	total_invested_materials += cost_m

	# Rebuild visual for new tier
	_rebuild_visual()

	var upgrade_name: String = upgrade.get("name", "Tier %d" % current_tier)
	GameBus.upgrade_completed.emit(self, upgrade_name)
	GameBus.central_tower_upgraded.emit(current_tier)
	GameBus.audio_play_3d.emit("tower.central_tower.upgraded", global_position)

	return true


func _rebuild_visual() -> void:
	## Destroy and recreate the tower visual for the current tier.
	if visual_node:
		visual_node.queue_free()
		visual_node = null

	visual_node = VisualGenerator.create_central_tower_visual(current_tier)
	if visual_node:
		add_child(visual_node)

	_update_health_bar_position()


# --- Signals ---

func _on_central_hp_changed(current_hp: float, max_hp: float) -> void:
	GameBus.central_tower_damaged.emit(current_hp, max_hp)


func _on_died(killer: Node) -> void:
	_free_grid_cells()
	GameState.central_tower_alive = false
	GameBus.central_tower_destroyed.emit()
	GameBus.audio_play_3d.emit("tower.central_tower.destroyed", global_position)


func die(killer: Node = null) -> void:
	GameState.central_tower_alive = false
	GameBus.central_tower_destroyed.emit()
	_free_grid_cells()
	# Call EntityBase.die directly, not TowerBase, to avoid double grid free
	GameBus.entity_died.emit(self, entity_type, entity_id, killer)
	EntityRegistry.unregister(self, entity_type)
	GameBus.entity_removed.emit(self, entity_type)
	queue_free()


func _apply_central_tower_item_effects() -> void:
	if not ItemSystem:
		return
		
	var effects := ItemSystem._active_effects
	
	# Apply central tower health multiplier
	if health_component and effects.has("central_tower_health_multiplier"):
		var multiplier: float = effects["central_tower_health_multiplier"]
		health_component.max_hp *= multiplier
		health_component.current_hp = health_component.max_hp
		print("[CentralTower] Applied health multiplier: x%.1f" % multiplier)
	
	# Apply energy regeneration
	if effects.has("central_tower_energy_regen"):
		var regen_rate: float = effects["central_tower_energy_regen"]
		var regen_timer := Timer.new()
		regen_timer.wait_time = 1.0
		regen_timer.autostart = true
		regen_timer.timeout.connect(_central_tower_energy_regen.bind(regen_rate))
		add_child(regen_timer)
		print("[CentralTower] Applied energy regen: +%.1f/sec" % regen_rate)


func _central_tower_energy_regen(amount: float) -> void:
	if is_built and not is_building:
		GameState.energy += amount
