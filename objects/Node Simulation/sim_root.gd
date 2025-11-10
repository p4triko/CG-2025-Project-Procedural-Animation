@tool @icon("res://assets/images/SimRoot_icon.png")
class_name SimRoot extends SimAbstract

@export_group("Debug")
@export_enum("All", "Debug", "None") var draw_debug_bones: int = 0
@export_enum("All", "Debug", "None") var draw_distance_constraint: int = 0

## Event setup # Maybe change to ready?
func _ready() -> void:
	run_for_every_child("update_sim_root", [self])

func _physics_process(_delta: float) -> void:
	run_for_every_child("save_prev_position")
	run_for_every_child("chain_update")

func _process(_delta: float) -> void:
	run_for_every_child("interpolate_visuals")
	run_for_every_child("queue_redraws")
