class_name CorpseSystem
extends Node
## CorpseSystem - Spawns corpse visuals when enemies die.
## Listens to GameBus.entity_died where type == "enemy".
## Corpse fades over 10 seconds then removes itself.
## Emits GameBus.corpse_spawned when a corpse is created.

const CORPSE_FADE_DURATION: float = 10.0


func _ready() -> void:
	GameBus.entity_died.connect(_on_entity_died)


func _on_entity_died(entity: Node, type: String, entity_id: String, _killer: Node) -> void:
	if type != "enemy":
		return
	if not is_instance_valid(entity):
		return

	var death_position: Vector3 = entity.global_position
	_spawn_corpse(death_position, entity_id)


func _spawn_corpse(death_pos: Vector3, entity_id: String) -> void:
	var corpse := Node3D.new()
	corpse.name = "Corpse_%s" % entity_id

	# Create a small dark visual representing the corpse
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.6, 0.15, 0.6)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.3, 0.3, 1.0)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 1.0
	box.material = mat
	mesh.mesh = box
	mesh.position.y = 0.075  # Sit on ground
	corpse.add_child(mesh)

	corpse.global_position = death_pos

	# Add to scene tree
	var scene_root: Node = get_tree().current_scene
	if scene_root:
		scene_root.add_child(corpse)
	else:
		add_child(corpse)

	# Emit signal
	GameBus.corpse_spawned.emit(death_pos, entity_id)

	# Start fade and removal
	_fade_corpse(corpse, mesh, mat)


func _fade_corpse(corpse: Node3D, mesh: MeshInstance3D, mat: StandardMaterial3D) -> void:
	# Use a tween to fade the corpse over the duration
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_LINEAR)

	# Fade alpha from 1.0 to 0.0 over CORPSE_FADE_DURATION
	tween.tween_method(
		func(alpha: float) -> void:
			if is_instance_valid(mat):
				mat.albedo_color.a = alpha,
		1.0,
		0.0,
		CORPSE_FADE_DURATION
	)

	# Remove corpse when fade completes
	tween.tween_callback(func() -> void:
		if is_instance_valid(corpse):
			var pos: Vector3 = corpse.global_position
			GameBus.corpse_expired.emit(pos)
			corpse.queue_free()
	)
