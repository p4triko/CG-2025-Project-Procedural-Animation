@tool
class_name RecursiveRayCast2D
extends Node2D

@export var target_positon: Vector2:
	set(v):
		target_positon = v
		queue_redraw()
@export var max_iterations: int = 20

@export_tool_button("Run") var a = func (): print(get_collisions())

var saved_hits: Array[Array]

func get_collisions() -> Array[Array]:
	var space_state := get_world_2d().direct_space_state
	
	var query := PhysicsRayQueryParameters2D.new()
	query.hit_from_inside = true
	query.to = target_positon
	var curr_pos: Vector2 = global_position
	
	var hits: Array[Array]
	var i: int = 0
	while true:
		query.from = curr_pos
		var result = space_state.intersect_ray(query)
		if result.is_empty(): break # Exit loop if no intersections
		i+=1; if i > max_iterations: break # Exit if too many iterations
		
		hits.append([result.position, result.normal])
		curr_pos = result.position
	saved_hits = hits
	queue_redraw()
	return hits

func _draw() -> void:
	draw_line(Vector2.ZERO, target_positon - global_position, Color(1, 0.2, 0.2, 0.7), 1.5)
	for i in saved_hits:
		draw_circle(i[0] - global_position, 2, Color(1, 0.2, 0.2, 0.7), false, 1)
