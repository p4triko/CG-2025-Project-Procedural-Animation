extends Node2D

@onready var color_palette_swapper: ColorRect = $ShaderLayer/ColorPaletteSwapper
@onready var player: CharacterBody2D = $Player


func _process(_delta):
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()
	
	if Global.restart_queued:
		get_tree().reload_current_scene()
		Global.restart_queued = false
	
	color_palette_swapper.interpolation_weight = clamp(player.global_position.x/1000.0 - 1.5, 0, 1)
