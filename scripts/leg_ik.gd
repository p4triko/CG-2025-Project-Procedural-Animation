extends Node2D

# Segment lengths
@export var len_a: float = 100.0 # Thigh
@export var len_b: float = 100.0 # Shin
@export var limb_speed: float = 20

@onready var thigh: Marker2D = $Thigh
@onready var shin: Marker2D = $Shin

@export var enableDebugDrawing: bool = true

var smoothed_target: Vector2 = Vector2.ZERO

func _process(delta):
	var target_pos = get_local_mouse_position()

	smoothed_target = smoothed_target.lerp(target_pos, limb_speed * delta)
	solve_ik(smoothed_target)

	queue_redraw()

func solve_ik(target: Vector2):
	var dist = target.length()

	# Check if we can even reach the target, otherwise clamp it
	if dist > len_a + len_b:
		dist = len_a + len_b
		target = target.normalized() * dist
	
	# Law of cosines
	# Alpha - Angle at the hip
	var cos_alpha = (len_a**2 + dist**2 - len_b**2) / (2 * len_a * dist)

	var alpha = acos(clamp(cos_alpha, -1.0, 1.0))

	# Thigh angle
	var angle_to_target = target.angle()
	var thigh_angle = angle_to_target - alpha

	var thigh_vec = Vector2.from_angle(thigh_angle) * len_a
	thigh.position = thigh_vec
	shin.position = target

func _draw():
	draw_circle(get_local_mouse_position(), 5, Color(1, 1, 1, 0.3))
	
	# Draw the Leg
	draw_line(Vector2.ZERO, thigh.position, Color.WHITE, 5.0)
	draw_line(thigh.position, shin.position, Color.WHITE, 5.0)
	draw_circle(Vector2.ZERO, 8, Color.RED)
	draw_circle(thigh.position, 8, Color.GREEN)
	draw_circle(shin.position, 8, Color.BLUE)


	if enableDebugDrawing:
		# The target vector (Hip to mouse)
		draw_dashed_line(Vector2.ZERO, shin.position, Color(1, 1, 0, 0.5), 2.0, 4.0)

		# Highlight the angle alpha
		var thigh_angle = thigh.position.angle()
		var target_angle = shin.position.angle()

		draw_arc(Vector2.ZERO, 30, target_angle, thigh_angle, 10, Color.CYAN, 2.0)
		draw_string(ThemeDB.fallback_font, Vector2(10, -10), "Alpha", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.CYAN)
