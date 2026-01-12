extends Camera2D

@onready var player: CharacterBody2D = $".."

var pos_offset: Vector2 = Vector2(0, -32)

func _ready() -> void:
	global_position = player.global_position + pos_offset

func _physics_process(delta: float) -> void:
	var wanted_pos = player.global_position + pos_offset
	global_position = lerp(global_position, wanted_pos, 0.08)
