@tool @icon("res://assets/images/SimRoot_icon.png")
class_name SimRoot extends SimAbstract

@export_group("Debug")
@export_enum("All", "Debug", "None") var draw_debug_bones: int = 0
@export_enum("All", "Debug", "None") var draw_distance_constraint: int = 0

@export var enable_interpolation: bool = true

var sim_root: SimRoot
var sim_nodes: Array[SimNode]

## Event setup # Maybe change to ready?
func _enter_tree() -> void:
	sim_root = self
	top_level = true

func _ready() -> void:
	run_for_every_child("update_sim_root", [self])
	top_level = true

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
	transform = Transform2D()
	for sim_node in sim_nodes:
		if sim_node.get_parent() is not SimRoot and sim_node.bone_texture:
			var tex: Texture2D = sim_node.bone_texture
			var self_pos: Vector2 = (sim_node.global_position)
			var parent_pos: Vector2 = (sim_node.get_parent().global_position)
			var distance = self_pos.distance_to(parent_pos)
			
			var x_axis = (self_pos - parent_pos).normalized()
			var y_axis = x_axis.rotated(deg_to_rad(90))
			var image_transform: Transform2D = Transform2D(
				x_axis/tex.get_size() * distance, 
				y_axis/tex.get_size() * sim_node.texture_y_scale, 
				(parent_pos - y_axis/2*sim_node.texture_y_scale)
			)
			draw_set_transform_matrix(image_transform)
			draw_texture(sim_node.bone_texture, Vector2.ZERO, modulate)
