class_name SpawnManager
extends Node
## SpawnManager - Manages spawn positions along map edges.
## Provides spawn points for the spawn system to use.

const MAP_SIZE: float = 300.0
const SPAWN_MARGIN: float = 5.0  # Distance from edge
const POINTS_PER_EDGE: int = 5

var spawn_points: Array[Vector3] = []


func _ready() -> void:
	_generate_spawn_points()


func _generate_spawn_points() -> void:
	spawn_points.clear()
	var spacing: float = MAP_SIZE / (POINTS_PER_EDGE + 1)

	# North edge (z = SPAWN_MARGIN)
	for i in range(1, POINTS_PER_EDGE + 1):
		spawn_points.append(Vector3(i * spacing, 0, SPAWN_MARGIN))

	# South edge (z = MAP_SIZE - SPAWN_MARGIN)
	for i in range(1, POINTS_PER_EDGE + 1):
		spawn_points.append(Vector3(i * spacing, 0, MAP_SIZE - SPAWN_MARGIN))

	# East edge (x = MAP_SIZE - SPAWN_MARGIN)
	for i in range(1, POINTS_PER_EDGE + 1):
		spawn_points.append(Vector3(MAP_SIZE - SPAWN_MARGIN, 0, i * spacing))

	# West edge (x = SPAWN_MARGIN)
	for i in range(1, POINTS_PER_EDGE + 1):
		spawn_points.append(Vector3(SPAWN_MARGIN, 0, i * spacing))


func get_random_spawn_point() -> Vector3:
	if spawn_points.is_empty():
		return Vector3(0, 0, 0)
	return spawn_points[randi() % spawn_points.size()]


func get_spawn_points_on_edge(edge: int) -> Array[Vector3]:
	# edge: 0=North, 1=South, 2=East, 3=West
	var start := edge * POINTS_PER_EDGE
	var result: Array[Vector3] = []
	for i in range(start, start + POINTS_PER_EDGE):
		if i < spawn_points.size():
			result.append(spawn_points[i])
	return result
