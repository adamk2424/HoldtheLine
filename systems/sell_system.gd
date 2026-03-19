class_name SellSystem
extends Node
## SellSystem - Handles selling buildings/towers.
## Connects to GameBus.sell_requested.
## Refunds 75% of total invested cost via GameState.refund_resources().
## Frees grid cells via BuildGrid, then removes the entity.

var build_grid: BuildGrid = null


func _ready() -> void:
	GameBus.sell_requested.connect(_on_sell_requested)


## Set the build grid reference. Called by GameSession during setup.
func set_build_grid(grid: BuildGrid) -> void:
	build_grid = grid


func _on_sell_requested(entity: Node) -> void:
	if not is_instance_valid(entity):
		push_warning("[SellSystem] Sell requested for invalid entity.")
		return

	if not entity is TowerBase:
		push_warning("[SellSystem] Sell requested for non-tower entity: %s" % entity.name)
		return

	var tower: TowerBase = entity as TowerBase

	# Don't allow selling the central tower
	if tower is CentralTower:
		push_warning("[SellSystem] Cannot sell the Central Tower!")
		return

	# Don't allow selling while under construction
	if tower.is_building and not tower.is_built:
		push_warning("[SellSystem] Cannot sell tower while under construction: %s" % tower.entity_id)
		return

	_sell_tower(tower)


func _sell_tower(tower: TowerBase) -> void:
	# Calculate refund (75% of total invested)
	var refund: Dictionary = tower.get_sell_refund()
	var energy_refund: float = refund.get("energy", 0.0)
	var material_refund: float = refund.get("materials", 0.0)

	# Notify subclass-specific cleanup (income removal, buff removal, etc.)
	if tower is TowerResource:
		(tower as TowerResource).on_sold()
	elif tower is TowerSupport:
		(tower as TowerSupport).on_sold()

	# Free grid cells
	if build_grid:
		build_grid.free_cells(tower.grid_position, tower.grid_size)
	elif tower.build_grid:
		tower.build_grid.free_cells(tower.grid_position, tower.grid_size)

	# Refund resources
	GameState.refund_resources(energy_refund, material_refund)

	# Emit sell completed signal
	GameBus.sell_completed.emit(tower, energy_refund, material_refund)
	GameBus.audio_play_3d.emit("tower.%s.sold" % tower.entity_id, tower.global_position)

	# Unregister and remove entity
	EntityRegistry.unregister(tower, tower.entity_type)
	GameBus.entity_removed.emit(tower, tower.entity_type)
	tower.queue_free()
