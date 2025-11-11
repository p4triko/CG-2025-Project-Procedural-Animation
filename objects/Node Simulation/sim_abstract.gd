@tool @abstract
class_name SimAbstract extends Node2D

func _run_callable(object: Object, method: StringName, args: Array = []):
	var callable = Callable(object, method)
	for arg in args:
		callable = callable.bind(arg)
	callable.call()

func run_for_every_child(method: StringName, args: Array = []):
	for child in get_children():
		if child is SimNode:
			_run_callable(child, method, args)

func run_for_every_neighbour(origin: Object, method: StringName, args: Array):
	for neighbour in get_children() + [get_parent()]:
		if neighbour is SimNode && neighbour != origin:
			_run_callable(neighbour, method, args)

# Says if some action (for example rendering) should be visible right now
func check_debug_enum(value: int):
	match value:
		0: return true
		1: return Engine.is_editor_hint()
		2: return false
