extends Node2D

class_name Spine

@export var segment_count: int = 20 # how many points make up the spine or chain
@export var segment_length: float = 10.0 # how far apart the points are
@export var follow_strength: float = 0.85 # for smoothing, how quickly each point moves toward its target position
@export var iterations: int = 3
@export var debug_draw: bool = false
@export var spine_color: Color = Color.from_rgba8(32, 34, 49) # The entire color of the spine
@export var follow_mouse: bool = false

var pts: Array[Vector2] = [] # store every point as 2d vector, [0] being the head
var segment_widths: Array[float] = []

var current_dist: float = 0.0

@export_group("Line Following")
@export var path_to_follow: Path2D
@export var speed: float = 150.0 # How fast the spline follows the curve or path.

@export_group("Z Scaling")
@export var layer1_scale_levels: Vector2 = Vector2(0.7, 0.7)
@export var layer2_scale_levels: Vector2 = Vector2(0.5, 0.5)
@export var layer3_scale_levels: Vector2 = Vector2(0.3, 0.3)

var curr_scale: Vector2 = scale	

func _ready():
	pts.resize(segment_count)
	for i in range(segment_count):
		pts[i] = Vector2(i * segment_length, 0)
	
	segment_widths.resize(segment_count)
	for i in range(segment_count):
		segment_widths[i] = lerp(20.0, 5.0, float(i) / (segment_count - 1))

	adjust_scaling(z_index)

func _process(delta):
	# We use FABRIK here, so forward and backwards reaching inverse kinematics, since we want to follow the head,
	# anchor point should be the head so we do a forward pass, better explaination on this video below 
	# https://www.youtube.com/watch?v=UNoX65PRehA
	# But for example a tail or something we use the backward pass starting at the tail point
	# For a bridge we can pin the start and the end points doing a forward and a backward pass

	move_along_path(delta)

	solve_ik()

	queue_redraw()

# Check z index ordering, based on that we scale the spine down or up to create a sense of distance
func adjust_scaling(index_of_z):
	if index_of_z == -3: # Last layer in the cave basically between layer 3 and layer 4
		scale = layer3_scale_levels
	elif index_of_z == -2: # Layer between 2 and 3
		scale = layer2_scale_levels
	elif index_of_z == -1: # Layer between 1 and 2
		scale = layer1_scale_levels

func move_along_path(delta):
	if path_to_follow == null:
		return
	
	var curve = path_to_follow.curve
	var path_length = curve.get_baked_length() # Returns the total length of the curve

	current_dist += speed * delta

	# We reached the end, so lets loop back
	if current_dist > path_length:
		current_dist = 0.0
	
	# Position on the curve
	var pos_path_local = curve.sample_baked(current_dist)

	var target_globab = path_to_follow.to_global(pos_path_local)
	pts[0] = to_local(target_globab)

func solve_ik():
	for _iter in range(iterations): # We do 3 passes here for better calculations and reduce the stretchiness

		# Anchor point
		if follow_mouse:
			pts[0] = pts[0].lerp(to_local(get_global_mouse_position()), 0.2) # head follows the mouse 

		# Forward pass
		for i in range(1, segment_count): 
			var direction = pts[i] - pts[i - 1] # Vector from the previous point to the current
			var distance = max(direction.length(), 0.001) # In case of overlapping, avoid division by 0 so we clamp it
			var target = pts[i - 1] + direction / distance * segment_length # Where this point should be
			pts[i] = pts[i].lerp(target, follow_strength) # Move toward target

		# Backward pass
		for i in range (segment_count - 2, 0, -1): # Head stays pinned
			var direction = pts[i] - pts[i + 1]
			var distance = max(direction.length(), 0.001)
			var target = pts[i + 1] + direction / distance * segment_length
			pts[i] = pts[i].lerp(target, follow_strength)


func _draw():
	for i in range(segment_count):
		draw_circle(pts[i], segment_widths[i], spine_color, true)

	for i in range(1, segment_count):
		draw_line(pts[i - 1], pts[i], spine_color, 10.0)
