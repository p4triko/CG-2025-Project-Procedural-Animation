extends CharacterBody2D

@export var debug_gradient: GradientTexture1D

@export_group("Vertical")
@export var gravity: float = 1.0
@export var v_accel: float = 200.0

@export_group("Horisontal")
@export var h_accel: float = 2000.0
@export var h_deaccel: float = 4000.0
@export var h_target_velocity: float = 300
@export var sprint_multiplier: float = 1.5

var wanted_floor_distance = 100;
var wanted_velocity: Vector2
var is_grounded: bool = false
var is_touching_wall: bool = false

var left_legs: Array
var right_legs: Array
var legs: Array
var leg_angles: Array = [1.4, 1.2, 1.0, 0.8, -0.8, -1.0, -1.2, -1.4]

var debug_draw_surfaces: Array = []

@onready var floor_raycast: RecursiveRayCast2D = $FloorRayCast
@onready var body_raycast: RecursiveRayCast2D = $BodyRayCast

func _ready() -> void:
	left_legs = [%LegLeft1, %LegLeft2, %LegLeft3, %LegLeft4]
	right_legs = [%LegRight1, %LegRight2, %LegRight3, %LegRight4]
	legs = left_legs + right_legs

func _physics_process(delta: float) -> void:
	var input_axis: Vector2 = Vector2(Input.get_axis("game_left", "game_right"), Input.get_axis("game_down", "game_up"))
	var input_sprint: bool = Input.is_action_pressed("game_sprint")
	
	## Raycasting for nearby surfaces/walls
	var surfaces = get_potential_surfaces()
	debug_draw_surfaces = surfaces
	
	## Vertical velocity
	var left_legs_grounded = 0
	for i: SpiderLeg in left_legs:
		left_legs_grounded += 1 if i.state == i.states.GROUNDED else 0
	
	# Find floor, where spider will be
	var prediction_time = 0.25
	var spider_predicted_positon = velocity * prediction_time
	floor_raycast.position.x = spider_predicted_positon.x
	floor_raycast.exclude = [self]
	var floor_points = floor_raycast.get_collisions()
	var new_floor: Vector2 = null if floor_points.is_empty() else floor_points[0][0]
	var current_floor = Vector2(0, wanted_floor_distance)
	for floor_point in floor_points:
		body_raycast.target_positon = floor_point[0] - body_raycast.global_position + floor_point[1]
		if body_raycast.get_collisions().is_empty():
			if new_floor.distance_to(current_floor) > floor_point[0].distance_to(current_floor) :
				new_floor = floor_point[0]
	body_raycast.target_positon = new_floor - body_raycast.global_position - Vector2(0, wanted_floor_distance) #Just for visualization
	
	# Wanted velocity is the ideal direction/speed player wants to be moving at,
	# but it has to be interpolated for smoother movement
	if abs(input_axis.y) > 0.5:
		wanted_floor_distance += input_axis.y * v_accel * delta
		wanted_floor_distance = clamp(wanted_floor_distance, 50, 128)
	#print(wanted_floor_distance)
	wanted_velocity.y = 0
	
	velocity.y = wanted_velocity.y
	
	## Horizontal velocity
	wanted_velocity.x = input_axis.x * h_target_velocity * (sprint_multiplier if input_sprint else 1.0)
	var velocity_diff: float = wanted_velocity.x - velocity.x
	var is_speeding_up: bool = sign(velocity.x) * wanted_velocity.x > sign(velocity.x) * velocity.x
	velocity.x += sign(velocity_diff) * delta * (h_accel if is_speeding_up else h_deaccel)
	if -sign(velocity_diff) == sign(wanted_velocity.x - velocity.x):
		velocity.x = wanted_velocity.x
	move_and_slide()
	
	## Leg movement
	var leg_scores = []
	for leg_i in legs.size():
		var leg: SpiderLeg = legs[leg_i]
		# Where player will be in 0.25 seconds (time it takes for leg to move)
		var velocity_offset = velocity * 0.25 * 1.2  # Second number resembles anticipation
		
		# Pick best surface
		var best_surface = surfaces[0]
		var best_surface_score: float = 0
		for surface in surfaces:
			var score = calculate_score(surface[0] - leg.global_position - velocity_offset, surface[1], leg_angles[leg_i])
			if score > best_surface_score:
				best_surface = surface
				best_surface_score = score
		
		var current_score = calculate_score(leg.current_position - leg.global_position, leg.current_normal, leg_angles[leg_i])
		leg_scores.append([leg_i, best_surface_score, current_score, best_surface])
	
	leg_scores.sort_custom(func(x, y): return x[1] - x[2] > y[1] - y[2])
	
	var trigger_threshold = max(0.2 * velocity.length() / h_target_velocity, 0.2) ## First number is for fine tuning
	for data in leg_scores:
		var leg: SpiderLeg = legs[data[0]]
		var best_surface_score = data[1]
		var current_score = data[2]
		var score_diff = best_surface_score - current_score
		var best_surface = data[3]
		
		if leg.state == leg.states.GROUNDED:
			if score_diff > trigger_threshold: # If new surface is way better than current surface, then step
				leg.step(best_surface[0], best_surface[1])
		if current_score < 0:
			leg.step(best_surface[0], best_surface[1], true)
	
	queue_redraw()

func get_grounded_legs(list: Array[SpiderLeg]) -> Array[SpiderLeg]:
	var grounded_legs = []
	for leg: SpiderLeg in list:
		if leg.state == SpiderLeg.states.GROUNDED:
			grounded_legs.append(leg)
	return grounded_legs

## Raycasts a bunch to find points where a leg could go
func get_potential_surfaces() -> Array:
	var all_collisions = []
	var velocity_offset = velocity * 0.25 # Where player will be in 0.3 seconds (time it takes for leg to move)
	$Raycasts.position = velocity_offset
	for raycast: RecursiveRayCast2D in $Raycasts.get_children():
		raycast.exclude = [self]
		all_collisions += raycast.get_collisions()
	return all_collisions

static func combine_scores(args):
	var pos: float = 0
	var neg: float = 0
	for arg in args:
		if arg < 0:
			neg += arg
		pos += arg
	return pos if neg == 0.0 else neg

## Score negative means that leg position is bad, if leg is there, it has to be moved. score positive means it is a viable position
func calculate_score(pos: Vector2, normal: Vector2, wanted_angle: float = 1.1, angle_width: float = 0.8, leg_length: float = 128) -> float:
	# Normal
	var normal_width = PI * 3/5
	var normal_score = (1 - abs(normal.angle_to(Vector2.UP)) / normal_width)
	
	# Distance
	var rest_distance_ratio = 0.7
	var dist_smoothing = 50.0
	var distance_score = 1 - abs(leg_length*rest_distance_ratio/dist_smoothing - pos.length()/dist_smoothing)
	
	# Angle
	var angle_score = (1 - abs(pos.angle_to(Vector2.from_angle(wanted_angle + PI/2))) * angle_width)
	
	# Combine
	var normal_weight: float = 1.0
	var distance_weight: float = 1.0
	var angle_weight: float = 1.0
	return combine_scores([normal_score*normal_weight, distance_score*distance_weight, angle_score*angle_weight]) \
			/ (normal_weight+distance_weight+angle_weight)

func _draw():
	## For surfaces, doesnt account for the angle
	#for surface in debug_draw_surfaces:
		#var pos = surface[0] - global_position
		#var normal = surface[1]
		#var score = calculate_score(pos - velocity * 0.25, normal, 0)
		#draw_circle(pos, 3, debug_gradient.gradient.sample((score + 1)/2))
	
	## All positions, doesnt account for normal or angle
	#for x in range(-128, 129, 8):
		#for y in range(-128, 129, 8):
			#var score = calculate_score(Vector2(x, y), Vector2.UP, 1.1)
			#draw_circle(Vector2(x, y) + velocity * 0.25, 3, debug_gradient.gradient.sample((score + 1)/2))
	
	pass
	
