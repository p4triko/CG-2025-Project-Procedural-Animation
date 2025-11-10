@tool @icon("res://assets/images/SimRoot_icon.png")
class_name SimRoot extends SimAbstract

## Event setup # Maybe change to ready?
#func _exit_tree() -> void:
	#run_for_every_child("root", [self])

func _physics_process(_delta: float) -> void:
	run_for_every_child("chain_update")
