@tool extends Node2D

@export var target: Node2D

func _physics_process(_delta: float):
	global_rotation = global_position.angle_to_point(target.global_position)
