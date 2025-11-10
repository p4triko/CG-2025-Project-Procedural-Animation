# TODO
# Additional constraints:
# - Angle constraint, will make sure that angle between 2 bones is in some range, or side (uses 2 previous joint positions)
# - Middle angle constraint, will make sure that current bone is perpendicular to two other bones (uses 1 previous and 1 next joint positions)
# - Maybe, on that makes angles even, will make an arch out of the chain (uses 3 previous joint positions)
# - Maybe, one that positions point between parent and children
#
# Visualisation:
# - Ability to add sprites to follow the bones and joints
#
# System for non-linearly smoothing out actual movement in _physics_process:
# - Just interpolating node towards end position
# - Interpolating joing without changing distance - interpolating the angle
# For both of those there has to be some interpolation system like here https://www.youtube.com/watch?v=KPoeNZZ6H4s
# Note: It wont be just visual, just visual interpolation is already implemented in _process

@tool @icon("res://assets/images/SimNode_icon.png")
class_name SimNode extends SimAbstract

@export var is_anchored: bool = false

## Works only if it has SimRoot parent
@export var distance_range: Vector2 = Vector2(10, 10);


var sim_root: SimRoot
var prev_global_position: Vector2
var visual_position: Vector2

func _ready() -> void:
	top_level = true
	visual_position = global_position

func update_sim_root(root):
	sim_root = root
	run_for_every_child("update_sim_root", [root])

# Returns joint that has variables for constraints between some two neighbour joints
func get_neighbour_joint_data(joint: SimNode): 
	return self if get_parent() == joint else joint

func apply_distance_constraint(origin: SimNode):
	var distance = get_neighbour_joint_data(origin).distance_range
	var idk_vector = global_position - origin.global_position
	var idk_vector_length = idk_vector.length()
	idk_vector = idk_vector.normalized()
	global_position = origin.global_position + idk_vector * clampf(idk_vector_length, min(distance.x, distance.y), max(distance.x, distance.y))

func constraint_wave(origin):
	if !is_anchored: # If it is an node that can actually move
		# Applying different constraints
		apply_distance_constraint(origin)
	run_for_every_neighbour(origin, "constraint_wave", [self])

func interpolate_visuals():
	run_for_every_child("interpolate_visuals")
	# Linear interpolation for visuals
	visual_position = lerp(prev_global_position, global_position, Engine.get_physics_interpolation_fraction())

func queue_redraws():
	run_for_every_child("queue_redraws")
	queue_redraw();

func save_prev_position():
	prev_global_position = global_position
	run_for_every_child("save_prev_position")

func chain_update():
	run_for_every_child("chain_update")
	if is_anchored:
		constraint_wave(self)

func _draw() -> void:
	var do_draw_bones = check_debug_enum(sim_root.draw_debug_bones)
	var do_draw_constraints = check_debug_enum(sim_root.draw_distance_constraint)
	
	seed(hash(get_path()))
	var bone_color = Color(randf(), randf(), randf())
	
	var local_visual_position = visual_position - global_position
	if get_parent() is SimNode:
		var parent_local_visual_position = get_parent().visual_position - global_position
		if do_draw_constraints:
			draw_circle(parent_local_visual_position, lerpf(distance_range.y, distance_range.x, 0.5), Color(bone_color, 0.5), false, max(0.2, abs(distance_range.x - distance_range.y)), false)
			draw_circle(parent_local_visual_position, distance_range.y, bone_color, false, 0.2)
			draw_circle(parent_local_visual_position, distance_range.x, bone_color, false, 0.2)                            
		if do_draw_bones:
			draw_line(local_visual_position, parent_local_visual_position, bone_color, 0.2)
			draw_circle(local_visual_position, 0.75, bone_color, true)
	if do_draw_bones:
		if is_anchored:
			draw_circle(local_visual_position, 0.5, Color(0.918, 0.167, 0.0), true)
		else:
			draw_circle(local_visual_position, 0.5, Color(0.339, 0.584, 0.0), true)
