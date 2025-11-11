# TODO
# Additional constraints:
# - Distance constraint should addidionally check if it even can reach the anchor (by calculating closest anchor, excluding origin)
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

@export var target_angle: float = 0 # From -1 to 1
@export var angle_sway: float = 1 # From 0 to 1

var sim_root: SimRoot
var prev_global_position: Vector2
var visual_position: Vector2

"""
Setup
"""
func _ready() -> void:
	top_level = true
	visual_position = global_position

func update_sim_root(root):
	sim_root = root
	run_for_every_child("update_sim_root", [root])

"""
Simulation
"""
# Returns joint that has variables for constraints between some two neighbour joints
func chain_update():
	run_for_every_child("chain_update")
	if is_anchored:
		run_for_every_neighbour(null, "constraint_wave", [[self]])
		return
	apply_angle_constraint()

func constraint_wave(history: Array):
	if is_anchored: return
	# If it is an node that can actually move
	# Applying different constraints
	apply_distance_constraint(history[-1])
	run_for_every_neighbour(history[-1], "constraint_wave", [history + [self]])

func get_neighbour_joint_data(joint: SimNode): 
	return self if get_parent() == joint else joint

func apply_distance_constraint(prev: SimNode):
	var distance = get_neighbour_joint_data(prev).distance_range
	var vector_to = global_position - prev.global_position
	var vector_length = vector_to.length()
	vector_to = vector_to.normalized()
	global_position = prev.global_position + vector_to * clampf(vector_length, min(distance.x, distance.y), max(distance.x, distance.y))

func apply_angle_constraint():
	if get_parent().get_parent() is not SimNode: return
	var vec_main: Vector2 = self.global_position - get_parent() .global_position
	var vec_sec: Vector2 = get_parent().global_position - get_parent().get_parent().global_position
	var angle: float = vec_sec.angle_to(vec_main)
	var clamped_angle = clamp(angle - target_angle*PI, -angle_sway*PI, angle_sway*PI) + target_angle*PI
	var new_vec = Vector2.from_angle(vec_sec.angle() + clamped_angle) * vec_main.length()
	global_position = get_parent().global_position + new_vec
	

"""
Rendering
"""
func interpolate_visuals():
	run_for_every_child("interpolate_visuals")
	# Linear interpolation for visuals
	if sim_root.enable_interpolation:
		visual_position = lerp(prev_global_position, global_position, Engine.get_physics_interpolation_fraction())
	else:
		visual_position = global_position

func save_prev_position():
	prev_global_position = global_position
	run_for_every_child("save_prev_position")

func queue_redraws():
	run_for_every_child("queue_redraws")
	queue_redraw();

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
