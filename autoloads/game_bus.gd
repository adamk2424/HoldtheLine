extends Node
## GameBus - Global signal bus for inter-system communication.
## All cross-system signals go through here. No direct cross-system references.

# --- Entity Lifecycle ---
signal entity_spawned(entity: Node, entity_type: String, entity_id: String)
signal entity_died(entity: Node, entity_type: String, entity_id: String, killer: Node)
signal entity_removed(entity: Node, entity_type: String)

# --- Combat ---
signal damage_dealt(target: Node, amount: float, source: Node)
signal projectile_fired(source: Node, target: Node, projectile_type: String)
signal aoe_triggered(position: Vector3, radius: float, damage: float, source: Node)
signal weapon_fired(position: Vector3, weapon_type: String, target_position: Vector3)

# --- Building / Placement ---
signal build_requested(entity_id: String, grid_position: Vector2i, size: int)
signal build_started(entity: Node, entity_id: String, grid_position: Vector2i)
signal build_completed(entity: Node, entity_id: String, grid_position: Vector2i)
signal build_canceled(entity_id: String, grid_position: Vector2i)
signal sell_requested(entity: Node)
signal sell_completed(entity: Node, energy_refund: float, material_refund: float)

# --- Upgrades ---
signal upgrade_requested(entity: Node, upgrade_index: int)
signal upgrade_started(entity: Node, upgrade_name: String)
signal upgrade_completed(entity: Node, upgrade_name: String)

# --- Resources ---
signal resources_changed(energy: float, materials: float)
signal resource_income_changed(energy_rate: float, material_rate: float)
signal resources_insufficient(energy_needed: float, materials_needed: float)

# --- Units / Production ---
signal unit_queued(building: Node, unit_id: String)
signal unit_production_started(building: Node, unit_id: String)
signal unit_production_completed(building: Node, unit_id: String, unit: Node)
signal unit_selected(unit: Node)
signal unit_deselected(unit: Node)
signal units_selected(units: Array)
signal unit_command_move(units: Array, target_position: Vector3)
signal unit_command_attack(units: Array, target: Node)
signal unit_command_attack_move(units: Array, target_position: Vector3)

# --- Population ---
signal population_changed(current: int, maximum: int)
signal population_limit_reached()

# --- Enemies / Spawning ---
signal enemy_spawned(enemy: Node, enemy_id: String, spawn_position: Vector3)
signal wave_started(wave_number: int)
signal surge_started()
signal surge_ended()
signal boss_spawned(boss: Node)
signal all_enemies_cleared()

# --- Game State ---
signal game_started()
signal game_paused()
signal game_resumed()
signal game_speed_changed(speed: float)
signal game_over(survival_time: float)
signal central_tower_damaged(current_hp: float, max_hp: float)
signal central_tower_destroyed()
signal central_tower_upgraded(tier: int)
signal boss_killed(total_boss_kills: int)

# --- Level System ---
signal level_modifiers_applied(modifiers: Dictionary)
signal level_objective_completed(objective_type: String)
signal level_completed(level_id: String, rewards: Dictionary)
signal level_failed(reason: String)

# --- Buffs / Debuffs ---
signal buff_applied(target: Node, buff_id: String, duration: float)
signal buff_removed(target: Node, buff_id: String)
signal debuff_applied(target: Node, debuff_id: String, duration: float)
signal debuff_removed(target: Node, debuff_id: String)

# --- Corpses ---
signal corpse_spawned(position: Vector3, entity_id: String)
signal corpse_expired(position: Vector3)

# --- Kills ---
signal enemy_killed(total_kills: int)

# --- UI ---
signal ui_build_menu_toggled(is_open: bool)
signal ui_sell_mode_toggled(is_active: bool)
signal ui_info_panel_show(entity: Node)
signal ui_info_panel_hide()
signal ui_group_selected(entities: Array)
signal ui_tooltip_show(text: String, position: Vector2)
signal ui_tooltip_hide()

# --- Save/Load ---
signal save_requested()
signal save_completed(success: bool)
signal load_requested()
signal load_completed(success: bool)

# --- Audio ---
signal audio_play(hook_id: String)
signal audio_play_3d(hook_id: String, world_position: Vector3)
signal audio_stop(hook_id: String)

# --- Navigation ---
signal navmesh_needs_rebake()
signal navmesh_rebaked()
