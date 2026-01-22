extends CanvasLayer

@onready var start_button: CheckBox = $"MarginContainer/VBoxContainer/Draw Surfaces"
func _ready() -> void:
	hide()
	start_button.grab_focus.call_deferred()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_menu"):
		visible = !visible 
		start_button.grab_focus.call_deferred()

## Buttons
func _on_draw_surfaces_pressed() -> void:
	Global.draw_surfaces = !Global.draw_surfaces

func _on_draw_bones_pressed() -> void:
	Global.draw_bones = !Global.draw_bones

func _on_draw_nodes_pressed() -> void:
	Global.draw_nodes = !Global.draw_nodes

func _on_restart_button_pressed() -> void:
	Global.restart_queued = true


func _on_palette_swap_pressed() -> void:
	Global.palette_enabled = !Global.palette_enabled
