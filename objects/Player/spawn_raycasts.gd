@tool
extends Node2D

@export_tool_button("Respawn raycasts") var a = func(): create_raycasts()

func create_raycasts():
	# Removes children
	for i in get_children():
		remove_child(i)
		i.queue_free()
	
	# Spawns raycasts in a pattern
	var ray_count: float = 90.0
	var ray_start: float = 25.0
	var ray_length: float = 250.0
	for i in range(0, ray_count):
		var angle = float(i) / ray_count * 2.0 * PI
		var vec = Vector2(cos(angle), sin(angle))
		var raycast = RecursiveRayCast2D.new()
		raycast.position = vec * ray_start
		raycast.target_positon = vec * ray_length
		add_child(raycast)
		raycast.owner = get_tree().edited_scene_root 
