extends Node2D

@onready var sim_node: SimNode = $SimRoot2/SimNode
var mouse_pos: Vector2

func _input(event):
	if event is InputEventMouseMotion:
		mouse_pos = event.position/10.0 - get_viewport().get_visible_rect().size/2/10.0

func _physics_process(_delta: float) -> void:
	sim_node.wanted_position = lerp(mouse_pos, sim_node.position, 0.0)
