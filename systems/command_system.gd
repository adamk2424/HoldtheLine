class_name CommandSystem
extends Node
## CommandSystem - Processes movement and attack commands for selected units.
## Listens to GameBus signals for move, attack, and attack-move commands.
## Distributes units in spread formation when moving as a group.

# Formation spread settings
const FORMATION_SPACING: float = 2.0
const MAX_UNITS_PER_ROW: int = 5


func _ready() -> void:
	GameBus.unit_command_move.connect(_on_command_move)
	GameBus.unit_command_attack.connect(_on_command_attack)
	GameBus.unit_command_attack_move.connect(_on_command_attack_move)


func _on_command_move(units: Array, target_position: Vector3) -> void:
	if units.is_empty():
		return

	var positions: Array = _calculate_formation_positions(target_position, units.size())

	for i in range(units.size()):
		var unit: Node = units[i]
		if not is_instance_valid(unit) or not unit.is_inside_tree():
			continue
		if unit is UnitBase:
			unit.move_to(positions[i])

	GameBus.audio_play.emit("ui.command_move")


func _on_command_attack(units: Array, target: Node) -> void:
	if units.is_empty():
		return

	if not is_instance_valid(target) or not target.is_inside_tree():
		return

	for unit: Node in units:
		if not is_instance_valid(unit) or not unit.is_inside_tree():
			continue
		if unit is UnitBase:
			unit.attack_command(target)

	GameBus.audio_play.emit("ui.command_attack")


func _on_command_attack_move(units: Array, target_position: Vector3) -> void:
	if units.is_empty():
		return

	var positions: Array = _calculate_formation_positions(target_position, units.size())

	for i in range(units.size()):
		var unit: Node = units[i]
		if not is_instance_valid(unit) or not unit.is_inside_tree():
			continue
		if unit is UnitBase:
			unit.attack_move_to(positions[i])

	GameBus.audio_play.emit("ui.command_attack_move")


func _calculate_formation_positions(center: Vector3, unit_count: int) -> Array:
	var positions: Array = []

	if unit_count <= 0:
		return positions

	if unit_count == 1:
		positions.append(center)
		return positions

	# Arrange units in rows centered on the target position
	var rows: int = ceili(float(unit_count) / float(MAX_UNITS_PER_ROW))
	var total_depth: float = (rows - 1) * FORMATION_SPACING
	var start_z: float = -total_depth / 2.0

	var placed: int = 0
	for row in range(rows):
		var units_in_row: int = mini(MAX_UNITS_PER_ROW, unit_count - placed)
		var row_width: float = (units_in_row - 1) * FORMATION_SPACING
		var start_x: float = -row_width / 2.0

		for col in range(units_in_row):
			var offset := Vector3(
				start_x + col * FORMATION_SPACING,
				0.0,
				start_z + row * FORMATION_SPACING
			)
			positions.append(center + offset)
			placed += 1

	return positions
