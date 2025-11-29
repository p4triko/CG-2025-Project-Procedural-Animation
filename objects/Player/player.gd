extends CharacterBody2D

@export var debug_gradient: GradientTexture1D

@export_group("Vertical")
@export var gravity: float = 1.0
@export var v_accel: float = 1.0

@export_group("Horisontal")
@export var h_accel: float = 2000.0
@export var h_deaccel: float = 4000.0
@export var h_target_velocity: float = 300
@export var sprint_multiplier: float = 1.5

var wanted_floor_distance = 40;
var wanted_velocity: Vector2
var is_grounded: bool = false
var is_touching_wall: bool = false

var left_legs: Array
var right_legs: Array
var legs: Array
var leg_angles: Array = [1.4, 1.2, 1.0, 0.8, -0.8, -1.0, -1.2, -1.4]

var debug_draw_surfaces: Array = []

func _ready() -> void:
	left_legs = [%LegLeft1, %LegLeft2, %LegLeft3, %LegLeft4]
	right_legs = [%LegRight1, %LegRight2, %LegRight3, %LegRight4]
	legs = left_legs + right_legs

func _physics_process(delta: float) -> void:
	var input_axis: Vector2 = Vector2(Input.get_axis("game_left", "game_right"), Input.get_axis("game_up", "game_down"))
	var input_sprint: bool = Input.is_action_pressed("game_sprint")
	
	# Vertical velocity
	if abs(input_axis.y) > 0.5:
		wanted_floor_distance += input_axis.y * v_accel * delta
	wanted_velocity.y = 0
	
	# Horizontal velocity
	wanted_velocity.x = input_axis.x * h_target_velocity * (sprint_multiplier if input_sprint else 1.0)
	var velocity_diff: float = wanted_velocity.x - velocity.x
	var is_speeding_up: bool = sign(velocity.x) * wanted_velocity.x > sign(velocity.x) * velocity.x
	velocity.x += sign(velocity_diff) * delta * (h_accel if is_speeding_up else h_deaccel)
	if -sign(velocity_diff) == sign(wanted_velocity.x - velocity.x):
		velocity.x = wanted_velocity.x
	move_and_slide()
	
	## Leg movement
	var surfaces = get_potential_surfaces()
	debug_draw_surfaces = surfaces
	
	var leg_weights = []
	for leg_i in legs.size():
		var leg: SpiderLeg = legs[leg_i]
		var velocity_offset = velocity * 0.3
		
		# Pick best surface
		var best_surface = surfaces[0]
		var best_surface_weight: float = 0
		for surface in surfaces:
			var weight = calculate_weight(surface[0] - leg.global_position - velocity_offset, surface[1], leg_angles[leg_i])
			if weight > best_surface_weight:
				best_surface = surface
				best_surface_weight = weight
		
		var current_weight = calculate_weight(leg.current_position - leg.global_position, leg.current_normal, leg_angles[leg_i])
		leg_weights.append([leg_i, best_surface_weight - current_weight, best_surface])
	
	leg_weights.sort_custom(func(x, y): return x[1] > y[1])
	
	var trigger_threshold = 0.2 * velocity.length() / h_target_velocity ## First number is for fine tuning
	for data in leg_weights:
		var leg: SpiderLeg = legs[data[0]]
		var weight_diff = data[1]
		var best_surface = data[2]
		print(weight_diff)
		
		if leg.state == leg.states.GROUNDED:
			if weight_diff > trigger_threshold: # If new surface is way better than current surface, then step
				leg.step(best_surface[0], best_surface[1])
	
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
	for raycast: RecursiveRayCast2D in $Raycasts.get_children():
		raycast.exclude = [self]
		all_collisions += raycast.get_collisions()
	return all_collisions

static func combine_weights(args):
	var mult = 1
	for arg in args:
		mult = abs(arg * mult) * (-1 if arg < 0 or mult < 0 else 1)
	return mult

func calculate_weight(pos: Vector2, normal: Vector2, wanted_angle: float = 1.1, angle_width: float = 0.8, leg_length: float = 128) -> float:
	# Normal
	var normal_width = PI * 3/5
	var normal_sharpness = 4
	var normal_weight = (1 - abs(normal.angle_to(Vector2.UP)) / normal_width) * normal_sharpness
	
	# Distance
	var rest_distance_ratio = 0.7
	var dist_smoothing = 50.0
	var distance_weight = 1 - abs(leg_length*rest_distance_ratio/dist_smoothing - pos.length()/dist_smoothing)
	
	# Angle
	var angle_sharpness = 4
	var angle_weight = (1 - abs(pos.angle_to(Vector2.from_angle(wanted_angle + PI/2))) * angle_width) * angle_sharpness
	
	# Max length
	var max_length_weight = int(leg_length - pos.length())
	
	# Combine
	return combine_weights([normal_weight, distance_weight, angle_weight, max_length_weight])

func _draw():
	## For surfaces, doesnt account for the angle
	for surface in debug_draw_surfaces:
		var pos = surface[0] - global_position
		var normal = surface[1]
		var weight = calculate_weight(pos, normal, 0)
		draw_circle(pos, 3, debug_gradient.gradient.sample((weight + 0.5)/2))
	
	## All positions, doesnt acco unt for normal or angle
	for x in range(-128, 129, 8):
		for y in range(-128, 129, 8):
			var weight = calculate_weight(Vector2(x, y), Vector2.UP, 0)
			draw_circle(Vector2(x, y), 3, debug_gradient.gradient.sample(weight))
	
