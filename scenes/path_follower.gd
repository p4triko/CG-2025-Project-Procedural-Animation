extends PathFollow2D

@export var speed: float = 5.0

func _process(delta: float) -> void:
	progress_ratio += speed * delta / 100.0
