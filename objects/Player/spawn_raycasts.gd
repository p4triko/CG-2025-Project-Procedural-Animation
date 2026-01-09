@tool
extends Node2D

@export_tool_button("Respawn raycasts") var a = func(): create_raycasts()

func create_raycasts():
	# Removes children
	for i in get_children():
		remove_child(i)
		i.queue_free()
	
	# Spawns raycasts in a pattern
	spawn_bunch(Vector2(0, 0), 128, 128 + 64)
	spawn_bunch(Vector2(20, 20), 64, 128)
	spawn_bunch(Vector2(-20, 20), 64, 128)
	
func spawn_bunch(positon: Vector2, count: float, length: float, shift: float = 0):
	for i in range(0, count):
		var angle = float(i + shift) / count * 2.0 * PI
		var vec = Vector2(cos(angle), sin(angle))
		var raycast = RecursiveRayCast2D.new()
		raycast.position = positon
		raycast.target_positon = vec * length
		add_child(raycast)
		raycast.owner = get_tree().edited_scene_root 
