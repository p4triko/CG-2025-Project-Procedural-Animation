extends CharacterBody2D

@export var debug_gradient: GradientTexture1D
@export var debug_draw: bool = false

@export_group("Vertical")
@export var gravity: float = 3000.0
@export var v_accel: float = 100.0
@export var v_max_velocity: float = 2000.0
@export var coyote_time: float = 0.1
@export var jump_velocity: float = 1200.0

@export_group("Horisontal")
@export var h_accel: float = 2000.0
@export var h_deaccel: float = 4000.0
@export var h_target_velocity: float = 300
@export var sprint_multiplier: float = 1.5

var leg_reposition_speed: float = 0.15

var default_floor_distance: float = 80
var wanted_floor_distance: float
var wanted_velocity: Vector2
var is_grounded: bool = false
var is_touching_wall: bool = false
var velocity_offset: Vector2
var coyote_timer: float = 0
var jump_charge: float = 0
var jump_timer: float = 0

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

# Fall/dont take input when no legs are touching the ground
# Should try to maintain current y position if not moving left or right (dont predict slopes)
#
# Make legs go into PHYSICS state when cant stand anywhere (bug)

func _physics_process(delta: float) -> void:
	var input_axis: Vector2 = Vector2(Input.get_axis("game_left", "game_right"), Input.get_axis("game_down", "game_up"))
	var input_sprint: bool = Input.is_action_pressed("game_sprint")
	var input_jump: bool = Input.is_action_pressed("game_jump")
	
	## Raycasting for nearby surfaces/walls
	var surfaces = get_potential_surfaces()
	debug_draw_surfaces = surfaces
	
	## Vertical velocity
	jump_timer -= delta
	var left_legs_grounded = 0
	for leg: SpiderLeg in left_legs:
		if leg.state == leg.states.GROUNDED && leg.current_normal.dot(Vector2.UP) > 0.5:
			left_legs_grounded += 1
	var right_legs_grounded = 0
	for leg: SpiderLeg in right_legs:
		if leg.state == leg.states.GROUNDED && leg.current_normal.dot(Vector2.UP) > 0.5:
			right_legs_grounded += 1
	var legs_grounded = !(right_legs_grounded <= 0 || left_legs_grounded <= 0)
	if legs_grounded:
		coyote_timer = 0
	else:
		coyote_timer += delta
	var is_falling = jump_timer > 0.0 || coyote_timer > coyote_time
	
	# Jumping
	if is_falling:
		jump_charge = 0.0
	elif input_jump:
		jump_charge = min(1.0, jump_charge + 2.0 * delta)
		input_axis.y = -jump_charge
	elif jump_charge > 0.0:
		velocity.y = max(0.5, jump_charge) * -jump_velocity
		is_falling = true
		jump_timer = 0.2
		jump_charge = 0.0
	
	# Find floor, where spider will be
	#var prediction_time = leg_reposition_speed
	#var spider_predicted_positon = velocity * prediction_time
	var spider_predicted_positon = input_axis * 90.0
	floor_raycast.position.x = spider_predicted_positon.x
	floor_raycast.exclude = [self]
	var floor_points = floor_raycast.get_collisions()
	var current_floor = Vector2(0, wanted_floor_distance + global_position.y)
	var new_floor = current_floor if floor_points.is_empty() else floor_points[0][0]
	for floor_point in floor_points:
		body_raycast.target_positon = floor_point[0] - body_raycast.global_position + floor_point[1]
		if body_raycast.get_collisions().is_empty():
			if new_floor.distance_to(current_floor) > floor_point[0].distance_to(current_floor) :
				new_floor = floor_point[0]
	
	# Wanted velocity is the ideal direction/speed player wants to be moving at,
	# but it has to be interpolated for smoother movement
	wanted_floor_distance = input_axis.y * 40 + 80
	wanted_velocity.y = (new_floor.y - wanted_floor_distance - global_position.y) / 0.25
	
	
	
	if is_falling:
		velocity.y += gravity * delta
	else:
		var velocity_diff_y: float = -(wanted_velocity.y - velocity.y)
		velocity.y += sign(velocity_diff_y) * delta * min(h_accel, 1000)
		if -sign(velocity_diff_y) == sign(wanted_velocity.y - velocity.y):
			velocity.y = wanted_velocity.y
	velocity.y = clamp(velocity.y, -v_max_velocity, v_max_velocity)

	
	## Horizontal velocity
	wanted_velocity.x = input_axis.x * h_target_velocity * (sprint_multiplier if input_sprint else 1.0)
	var velocity_diff_h: float = wanted_velocity.x - velocity.x
	var is_speeding_up_h: bool = sign(velocity.x) * wanted_velocity.x > sign(velocity.x) * velocity.x
	velocity.x += sign(velocity_diff_h) * delta * (h_accel if is_speeding_up_h else h_deaccel)
	if -sign(velocity_diff_h) == sign(wanted_velocity.x - velocity.x):
		velocity.x = wanted_velocity.x
	move_and_slide()
	
	# Raycast where the spider is going to be
	# Where player will be in leg_reposition_speed seconds (time it takes for leg to move)
	velocity_offset = velocity * leg_reposition_speed
	body_raycast.target_positon = velocity_offset * 1.3
	var collision_prediction = body_raycast.get_collisions()
	if !collision_prediction.is_empty():
		var wall: Vector2 = ((collision_prediction[0][0] - global_position).length() - 15.0) * (collision_prediction[0][0] - global_position)
		if wall.length() < velocity_offset.length():
			velocity_offset = wall
	
	## Leg movement
	 # If no surfaces to step onto
	var leg_scores = []
	if !surfaces.is_empty():
		for leg_i in legs.size():
			var leg: SpiderLeg = legs[leg_i]
			# Pick best surface
			var best_surface = surfaces[0]
			var best_surface_score: float = 0
			for surface in surfaces:
				var score = calculate_score(surface[0] - leg.global_position - velocity_offset * 1.2, surface[1], leg_angles[leg_i])
				if score > best_surface_score:
					best_surface = surface
					best_surface_score = score
			
			var current_score = calculate_score(leg.current_position - leg.global_position, leg.current_normal, leg_angles[leg_i])
			leg_scores.append([leg_i, best_surface_score, current_score, best_surface])
		
		leg_scores.sort_custom(func(x, y): return x[1] - x[2] > y[1] - y[2])
	else:
		for leg_i in legs.size():
			var leg: SpiderLeg = legs[leg_i]
			var current_score = calculate_score(leg.current_position - leg.global_position, leg.current_normal, leg_angles[leg_i])
			leg_scores.append([leg_i, -10, current_score, [Vector2.ZERO, Vector2.ZERO]])
		
	var trigger_threshold = max(0.5 * velocity.length() / h_target_velocity, 0.2) ## First number is for fine tuning
	for data in leg_scores:
		var leg: SpiderLeg = legs[data[0]]
		var best_score = data[1]
		var current_score = data[2]
		var score_diff = best_score - current_score
		var best_surface = data[3]
		
		# if leg.name == "LegLeft1": print(leg.state)
		if leg.state == SpiderLeg.states.GROUNDED:
			if score_diff > trigger_threshold: # If new surface is way better than current surface, then step
				leg.step(best_surface[0], best_surface[1])
			if current_score < 0:
				leg.state = SpiderLeg.states.PHYSICS
		if leg.state == SpiderLeg.states.PHYSICS:
			if best_score > 0:

				if is_falling:
					leg.step(best_surface[0], best_surface[1], true, false)
				else:
					leg.step(best_surface[0], best_surface[1], true)
			else:
				leg.wanted_position = leg.default_positon + leg.global_position + (velocity + leg.global_position)/10
	
	queue_redraw()

#func get_grounded_legs(list: Array[SpiderLeg]) -> Array[SpiderLeg]:
	#var grounded_legs = []
	#for leg: SpiderLeg in list:
		#if leg.state == SpiderLeg.states.GROUNDED:
			#grounded_legs.append(leg)
	#return grounded_legs

## Raycasts a bunch to find points where a leg could go
func get_potential_surfaces() -> Array:
	var all_collisions = []
	$Raycasts.position = velocity_offset
	body_raycast.target_positon = velocity_offset
	var flip_normals: bool = body_raycast.get_collisions().size() % 2 == 1
	for raycast: RecursiveRayCast2D in $Raycasts.get_children():
		raycast.exclude = [self] + get_tree().get_nodes_in_group("ignored_by_legs")
		var collisions = raycast.get_collisions()
		if flip_normals:
			for point in collisions:
				point[1] = Vector2.ZERO - point[1]
		all_collisions += collisions
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
func calculate_score(pos: Vector2, normal: Vector2, wanted_angle: float = 1.1, angle_width: float = 0.6, leg_length: float = 128) -> float:
	# Normal
	var normal_width = PI * 3/5
	var normal_score = (1 - abs(normal.angle_to(Vector2.UP)) / normal_width)
	
	# Distance
	var rest_distance_ratio = 0.7
	var dist_smoothing = 100.0
	var distance_score = (1 - abs(leg_length*rest_distance_ratio/dist_smoothing - pos.length()/dist_smoothing))
	
	var length_score = -1 if pos.length() > leg_length else 0
	
	# Angle
	var angle_score = (1 - abs(pos.angle_to(Vector2.from_angle(wanted_angle + PI/2))) * angle_width)
	
	# Combine
	var normal_weight: float = 1.0
	var distance_weight: float = 3.0
	var angle_weight: float = 1.0
	#return length_score
	return combine_scores([normal_score*normal_weight, distance_score*distance_weight, angle_score*angle_weight, length_score]) \
			/ (normal_weight+distance_weight+angle_weight)

func _draw():
	## For surfaces, doesnt account for the angle

	if debug_draw:
		for surface in debug_draw_surfaces:
			var pos = surface[0] - global_position
			var normal = surface[1]
			var score = calculate_score(pos - velocity * leg_reposition_speed, normal, 0)
			draw_circle(pos, 3, debug_gradient.gradient.sample((score + 1)/2))
	
	## All positions, doesnt account for normal or angle
	#for x in range(-128, 129, 8):
		#for y in range(-128, 129, 8):
			#var score = calculate_score(Vector2(x, y), Vector2.UP, 1.1)
			#draw_circle(Vector2(x, y) + velocity * leg_reposition_speed, 3, debug_gradient.gradient.sample((score + 1)/2))
	
	pass
	
