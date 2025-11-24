@tool @abstract
class_name SimAbstract extends Node2D

func run_for_every_child(method: StringName, args: Array = []):
	for child in get_children():
		if child is SimNode:
			Callable(child, method).callv(args)

func run_for_every_neighbour(origin: Object, method: StringName, args: Array):
	for neighbour in get_children() + [get_parent()]:
		if neighbour is SimNode && neighbour != origin:
			var callable = Callable(neighbour, method)
			for i in args:
				callable = callable.bind(i)
			callable.call()
