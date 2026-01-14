@tool
class_name RecursiveRayCast2D extends Node2D

## In local space
@export var target_positon: Vector2 = Vector2(0, 50):
	set(v):
		target_positon = v
		queue_redraw()
@export var max_iterations: int = 20
@export var exclude: Array
@export var epsilon: float = 1.0
@export_enum("All", "Debug", "None") var draw_debug: int = 1

#@export_tool_button("Run") var a = func (): print(get_collisions())

var saved_hits: Array[Array] # For visualization

## Retturns [code]Array[[Vector2, Vector2]][/code] where vectors are [b]position[/b] and [b]normal[/b] vector of the collision.
func get_collisions() -> Array[Array]:
	var space_state := get_world_2d().direct_space_state
	
	var query := PhysicsRayQueryParameters2D.new()
	query.to = global_position + target_positon
	query.exclude = exclude
	var curr_pos: Vector2 = global_position
	
	var hits: Array[Array]
	var i: int = 0
	while true:
		query.from = curr_pos
		var result = space_state.intersect_ray(query)
		if result.is_empty(): break # Exit loop if no intersections
		i+=1; if i > max_iterations: break # Exit if too many iterations
		
		hits.append([result.position, result.normal])
		curr_pos = result.position + global_position.direction_to(global_position + target_positon).normalized() * epsilon
	saved_hits = hits
	#queue_redraw()
	return hits

func _draw() -> void:
	if Utils.check_debug_enum(draw_debug):
		draw_line(Vector2.ZERO, target_positon, Color(1, 0.2, 0.2, 0.7), 1.5)
		#for i in saved_hits:
			#draw_circle(i[0] - global_position, 2, Color(1, 0.2, 0.2, 0.7), false, 1)
