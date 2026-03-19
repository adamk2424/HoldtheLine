extends Node
## FrameBudget - Maintains a minimum frame rate by deferring non-critical work.
##
## How it works: at the start of each frame, the clock resets.  Components call
## has_budget() before expensive work (AI targeting, retargeting, path queries).
## If the frame's script-time budget is exceeded, has_budget() returns false and
## the work is deferred to the next frame.  Movement and rendering are unaffected
## so the game stays visually smooth even under heavy load.
##
## The existing per-entity frame stagger (EnemyBase._frame_slot) ensures that
## different entities are at different points in the processing queue each frame,
## so no single entity is permanently starved.

## Target minimum frame rate.
const MIN_FPS: float = 30.0

## Script budget: 70% of the frame, leaving 30% for rendering + engine overhead.
## At 30fps: frame = 33.3ms, script budget = ~23.3ms.
const FRAME_BUDGET_USEC: int = int(1_000_000.0 / MIN_FPS * 0.7)

var _frame_start_usec: int = 0
var budget_exceeded: bool = false


func _ready() -> void:
	# Prevent the physics death spiral: when FPS drops, Godot tries to run
	# extra physics iterations to catch up, which makes the frame even longer.
	# Cap at 4 iterations so physics can fall behind gracefully instead.
	Engine.max_physics_steps_per_frame = 4


func _process(_delta: float) -> void:
	# Reset at the top of each frame.
	_frame_start_usec = Time.get_ticks_usec()
	budget_exceeded = false


func has_budget() -> bool:
	## Returns true if there is still script-time budget remaining this frame.
	## Cheap to call: one branch, one subtraction, one comparison.
	if budget_exceeded:
		return false
	if Time.get_ticks_usec() - _frame_start_usec > FRAME_BUDGET_USEC:
		budget_exceeded = true
		return false
	return true
