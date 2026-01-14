extends Spine

var current_draw_state: int = 0 # Which part of the draw state we are at, basically to show the evolution of the spine

enum DrawStates {
	SPINE_ONLY, # Simply draw the line that basically acts as the spine.
	BODY_OUTLINES, # Circle outlines that make up the body.
	FINAL_SPINE # The final version of the spine with proper coloring
}

var spine_renders: Array[DrawStates] = [
	DrawStates.SPINE_ONLY,
	DrawStates.BODY_OUTLINES,
	DrawStates.FINAL_SPINE
]

func _ready():
	super._ready()

func _unhandled_input(event):
	if event.is_action_pressed("toggle_spine_draw_state"):
		current_draw_state += 1
		if current_draw_state >= spine_renders.size():
			current_draw_state = 0
		queue_redraw()

func _draw():

	var draw_state = spine_renders[current_draw_state]

	match draw_state:
		DrawStates.SPINE_ONLY:
			for i in range(1, segment_count):
				draw_line(pts[i - 1], pts[i], Color.RED)

		DrawStates.BODY_OUTLINES:
			for i in range(1, segment_count):
				draw_line(pts[i - 1], pts[i], Color.RED)
			for i in range(segment_count):
				draw_circle(pts[i], segment_widths[i], Color.WHITE, false)
		
		DrawStates.FINAL_SPINE:
			super._draw()
