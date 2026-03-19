class_name ScoreSystem
extends Node
## ScoreSystem - Tracks kill and building stats during gameplay.
## Tracks boss kills separately and awards tech points.


func _ready() -> void:
	GameBus.entity_died.connect(_on_entity_died)
	GameBus.build_completed.connect(_on_build_completed)
	print("[ScoreSystem] Initialized")


# --- Signal handlers ---

func _on_entity_died(entity: Node, entity_type: String, _entity_id: String, _killer: Node) -> void:
	if entity_type != "enemy":
		return
	GameState.enemies_killed += 1
	GameBus.enemy_killed.emit(GameState.enemies_killed)

	# Track boss kills separately
	if entity is EnemyBase and entity.enemy_data.get("role", "") == "boss":
		GameState.boss_kills += 1
		MetaProgress.tech_points += 1
		GameBus.boss_killed.emit(GameState.boss_kills)
		print("[ScoreSystem] Boss killed! Total: %d, Tech points: %d" % [
			GameState.boss_kills, MetaProgress.tech_points
		])


func _on_build_completed(_entity: Node, _entity_id: String, _grid_position: Vector2i) -> void:
	GameState.buildings_built += 1
