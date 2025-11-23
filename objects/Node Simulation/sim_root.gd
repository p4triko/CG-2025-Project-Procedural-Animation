@tool @icon("res://assets/images/SimRoot_icon.png")
class_name SimRoot extends SimAbstract

# Exports
@export_group("Debug")
@export_enum("All", "Debug", "None") var draw_debug_bones: int = 0
@export_enum("All", "Debug", "None") var draw_distance_constraint: int = 0
@export var simulate_in_debug: bool = false

@export var enable_physics_interpolation: bool = true

# Variables
var sim_root: SimRoot
var sim_nodes: Array[SimNode]

## Event setup # Maybe change to ready?
func _enter_tree() -> void:
	sim_root = self

func _ready() -> void:
	run_for_every_child("update_sim_root", [self])

func _physics_process(_delta: float) -> void:
	run_for_every_child("save_prev_position")
	run_for_every_child("chain_update")

func _process(_delta: float) -> void:
	run_for_every_child("interpolate_visuals")
	run_for_every_child("queue_redraws")
	sim_nodes.clear()
	run_for_every_child("update_node_list")
	queue_redraw()

func _draw() -> void:
	# Bone texture
	for sim_node in sim_nodes:
		if !sim_node.bone_texture: continue
		if sim_node.get_parent() is not SimNode: continue
		
		var tex: Texture2D = sim_node.bone_texture
		var self_pos: Vector2 = sim_node.global_position
		var parent_pos: Vector2 = sim_node.get_parent().global_position
		var distance = self_pos.distance_to(parent_pos)
		
		var x_axis = (self_pos - parent_pos).normalized()
		var y_axis = x_axis.rotated(deg_to_rad(90))
		var image_transform: Transform2D = Transform2D(
			x_axis/tex.get_size().x * distance, 
			y_axis * sim_node.bone_texture_y_scale, 
			parent_pos - y_axis/2*sim_node.bone_texture_y_scale*tex.get_size().y
		)
		draw_set_transform_matrix(global_transform.affine_inverse() * image_transform)
		draw_texture(tex, Vector2.ZERO, modulate)
	
	# Joint texture
	for sim_node in sim_nodes:
		if !sim_node.joint_texture: continue
		
		var parent_joint_exists = sim_node.get_parent() is SimNode
		var child_joint_exists = sim_node.get_children() != [] and sim_node.get_child(0) is SimNode
			
		var tex: Texture2D = sim_node.joint_texture
		var self_pos: Vector2 = sim_node.global_position
		var parent_pos: Vector2 = sim_node.get_parent().global_position if parent_joint_exists else self_pos
		var child_pos: Vector2 = sim_node.get_child(0).global_position if child_joint_exists else self_pos
		
		var x_axis = ((self_pos - parent_pos).normalized() + (child_pos - self_pos).normalized()).normalized()
		var y_axis = x_axis.rotated(deg_to_rad(90))
		var image_transform: Transform2D = Transform2D(
			x_axis/tex.get_size().x * sim_node.joint_texture_scale, 
			y_axis/tex.get_size().y * sim_node.joint_texture_scale, 
			self_pos - (x_axis + y_axis)*sim_node.joint_texture_scale/2
		)
		draw_set_transform_matrix(global_transform.affine_inverse() * image_transform)
		draw_texture(tex, Vector2.ZERO, modulate)
