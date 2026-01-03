# TODO
# Fix angle constraint to use CCD IK. It will begin from root of the tree and try to get just one anchor child to its wanted position.
# 
# Additional constraints:
# - Makes angles even, will make an arch out of the chain (uses 3 previous node positions), uses curve for sahape
#
# Visualisation:
# - Creates Path2D from the nodes
#
# Implement this thing for anchors (interpolation, for smoother movement): https://www.youtube.com/watch?v=KPoeNZZ6H4s
# The nodes will update instantly, it only matters to make the anchors smooth
# Note: Visual interpolation is already implemented in _process

@tool @icon("res://assets/images/SimNode_icon.png")
class_name SimNode extends SimAbstract

@export var is_anchored: bool = false
@export var is_top_level: bool = true

## Works only if it has SimRoot parent
@export var distance_range: Vector2 = Vector2(10, 10);

## From -1 to 1
@export var target_angle: float = 0
## From 0 to 1
@export var angle_sway: float = 1

@export_enum("Both", "Right", "Left") var allowed_angle_polarity: int = 0 

@export var bone_texture: Texture
@export var joint_texture: Texture
@export var bone_texture_y_scale: float = 1
@export var joint_texture_scale: float = 1

var sim_root: SimRoot
var prev_global_position: Vector2 = Vector2.ZERO
var visual_position: Vector2 = Vector2.ZERO
var wanted_position = null
var length = 0

"""
Setup
"""
func _ready() -> void:
	visual_position = global_position

func _enter_tree() -> void:
	sim_root = get_parent().sim_root

func update_sim_root(root):
	sim_root = root
	run_for_every_child("update_sim_root", [root])

"""
Simulation
"""
func chain_update(prev_length = 0):
	# Updatig some variables
	length = max(prev_length + distance_range.x, distance_range.y)
	if Engine.is_editor_hint() && !sim_root.simulate_in_debug:
		top_level = false
	else:
		top_level = !is_anchored || is_top_level
		
	if wanted_position != null:
		global_position = wanted_position
		wanted_position = null
	run_for_every_child("chain_update", [length])
	
	if is_anchored && !(Engine.is_editor_hint() && !sim_root.simulate_in_debug):
		run_for_every_neighbour(null, "constraint_wave", [[self]])

func constraint_wave(history: Array):
	# Applying different constraints
	apply_angle_constraint()
	apply_polarity_constraint()
	apply_distance_constraint(history[-1])
	
	if is_anchored: return
	run_for_every_neighbour(history[-1], "constraint_wave", [history + [self]])

func get_neighbour_joint_data(joint: SimNode): 
	return self if get_parent() == joint else joint

func apply_distance_constraint(prev: SimNode):
	if !is_anchored:
		var distance = get_neighbour_joint_data(prev).distance_range
		var vector_to = global_position - prev.global_position
		var vector_length = vector_to.length()
		vector_to = vector_to.normalized()
		global_position = prev.global_position + vector_to * clampf(vector_length, min(distance.x, distance.y), max(distance.x, distance.y))

func apply_angle_constraint():
	if is_anchored: return
	if get_parent() is not SimNode: return
	
	var vec_main: Vector2 = self.global_position - get_parent() .global_position
	var vec_sec: Vector2
	if get_parent().get_parent() is not SimNode: vec_sec = Vector2.UP
	else: vec_sec = get_parent().global_position - get_parent().get_parent().global_position
	if vec_main.length() == 0 || vec_sec.length() == 0: return
	
	var angle: float = vec_sec.angle_to(vec_main)
	var clamped_angle = clamp(angle - target_angle*PI, -angle_sway*PI, angle_sway*PI) + target_angle*PI
	var new_vec = Vector2.from_angle(vec_sec.angle() + clamped_angle) * vec_main.length()
	global_position = get_parent().global_position + new_vec

func apply_polarity_constraint():
	if allowed_angle_polarity == 0: return
	if is_anchored: return
	if get_children() == []: return
	
	var vec_child = get_child(0).global_position - global_position
	var vec_parent: Vector2
	if get_parent() is not SimNode: vec_parent = Vector2.UP
	else: vec_parent = global_position - get_parent().global_position
	if vec_child.length() == 0 || vec_parent.length() == 0: return
	
	var angle = vec_parent.angle_to(vec_child)
	if angle <= 0 if allowed_angle_polarity == 1 else angle >= 0:
		global_position += 2 * ((get_parent().global_position + get_child(0).global_position)/2 - global_position)

"""
Rendering
"""
func interpolate_visuals():
	run_for_every_child("interpolate_visuals")
	# Linear interpolation for visuals
	if sim_root.enable_physics_interpolation:
		visual_position = lerp(prev_global_position, global_position, Engine.get_physics_interpolation_fraction())
	else:
		visual_position = global_position

func save_prev_position():
	prev_global_position = global_position
	run_for_every_child("save_prev_position")

func queue_redraws():
	run_for_every_child("queue_redraws")
	queue_redraw();

func update_node_list():
	if sim_root:
		sim_root.sim_nodes.append(self)
	run_for_every_child("update_node_list")

func _draw() -> void:
	# Debug draw
	var do_draw_bones = Utils.check_debug_enum(sim_root.draw_debug_bones)
	var do_draw_constraints = Utils.check_debug_enum(sim_root.draw_distance_constraint)
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
