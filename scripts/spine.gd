extends Node2D

@export var segment_count = 20 # how many points make up the spine or chain
@export var segment_length = 10 # how far apart the points are
@export var follow_strength = 0.85 # for smoothing, how quickly each point moves toward its target position
@export var iterations = 3

var pts: Array[Vector2] = [] # store every point as 2d vector, [0] being the head
var segment_widths: Array[float] = []

func _ready():
	pts.resize(segment_count)
	for i in range(segment_count):
		pts[i] = Vector2(i * segment_length, 0)
	
	segment_widths.resize(segment_count)
	for i in range(segment_count):
		segment_widths[i] = lerp(20.0, 5.0, float(i) / (segment_count - 1))

func _process(delta):
	# we use FABRIK here, so forward and backwards reaching inverse kinematics, since we want to follow the head,
	# anchor point should be the head so we do a forward pass, better explaination on this video below 
	# https://www.youtube.com/watch?v=UNoX65PRehA
	# but for example a tail or something we use the backward pass starting at the tail point
	# for a bridge we can pin the start and the end points doing a forward and a backward pass

	for _iter in range(iterations): # we do 3 passes here for better calculations and reduce the stretchiness

		# Anchor point
		pts[0] = pts[0].lerp(to_local(get_global_mouse_position()), 0.2) # head follows the mouse 

		# TODO condense these 2 to methods
		# forward pass
		for i in range(1, segment_count): 
			var direction = pts[i] - pts[i - 1] # vector from the previous point to the current
			var distance = max(direction.length(), 0.001) # in case of overlapping, avoid division by 0 so we clamp it
			var target = pts[i - 1] + direction / distance * segment_length # where this point should be
			pts[i] = pts[i].lerp(target, follow_strength) # move toward target

		# backward pass
		for i in range (segment_count - 2, 0, -1): # head stays pinned
			var direction = pts[i] - pts[i + 1]
			var distance = max(direction.length(), 0.001)
			var target = pts[i + 1] + direction / distance * segment_length
			pts[i] = pts[i].lerp(target, follow_strength)

	queue_redraw()

func _draw():
	for i in range(segment_count):
		draw_circle(pts[i], segment_widths[i], Color.WHITE, false)
	
	for i in range(1, segment_count):
		draw_line(pts[i - 1], pts[i], Color.RED)
