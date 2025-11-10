extends Button

@export var scene: PackedScene

func _pressed():
	get_tree().change_scene_to_packed(scene)
