extends Node2D

@onready var palette_material: ShaderMaterial = load("res://shaders/palette_swap.tres")

@export var palettes: Array[PackedColorArray] = []
var current_palette: int = 0

func _process(_delta):
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()
	
	if Input.is_action_just_pressed("swap_palette"):
		current_palette = (current_palette + 1) % len(palettes)
		palette_material.set_shader_parameter("palette", palettes[current_palette])
