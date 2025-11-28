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
var leg_rays: Array[Vector2] = [Vector2(-100, 200), Vector2(-50, 200), Vector2(50, 200), Vector2(100, 200)]

var debug_draw_surfaces: Array = []

func _ready() -> void:
	left_legs = [%LegLeft1, %LegLeft2]
	right_legs = [%LegRight1, %LegRight2]
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
	
	for leg in legs:
		var if_left_leg: float = (1.0 if leg in left_legs else -1.0)
		
		# Pick best surface
		var best_surface = surfaces[0]
		var best_surface_weight: float = 0
		for surface in surfaces:
			var weight = calculate_weight(surface[0]- leg.global_position, surface[1], 0.8, 1.1 * if_left_leg)
			if weight > best_surface_weight:
				best_surface = surface
				best_surface_weight = weight
		
		# If new surface is way better than current surface, then step
		var current_weight = calculate_weight(leg.current_position - leg.global_position, leg.current_normal, 0.8, 1.1 * if_left_leg)
		if best_surface_weight > current_weight + 0.2:
			leg.step(best_surface[0])
			leg.current_normal = best_surface[1]
	
	queue_redraw()

## Raycasts a bunch to find points where a leg could go
func get_potential_surfaces() -> Array:
	var all_collisions = []
	for raycast: RecursiveRayCast2D in $Raycasts.get_children():
		raycast.exclude = [self]
		all_collisions += raycast.get_collisions()
	return all_collisions

func calculate_weight(pos: Vector2, normal: Vector2, angle_width: float = 0.8, wanted_angle: float = 1.1, leg_length: float = 128) -> float:
	# Normal
	var normal_width = PI * 3/5
	var normal_sharpness = 4
	var normal_weight = clamp((1 - abs(normal.angle_to(Vector2.UP)) / normal_width) * normal_sharpness, 0, 1)
	
	# Distance
	var rest_distance_ratio = 0.7
	var dist_smoothing = 50.0
	var distance_weight = clamp(1 - abs(leg_length*rest_distance_ratio/dist_smoothing - pos.length()/dist_smoothing), 0, 1)
	
	# Angle
	var angle_sharpness = 4
	var angle_weight = clamp((1 - abs(pos.angle_to(Vector2.from_angle(wanted_angle + PI/2))) * angle_width) * angle_sharpness, 0, 1)
	
	# Max length
	var near_cap = 5
	var max_length_weight = int(leg_length > pos.length() && near_cap < pos.length())
	
	# Combine
	return distance_weight * angle_weight * max_length_weight * normal_weight

func _draw():
	## For surfaces, doesnt account for the angle
	for surface in debug_draw_surfaces:
		var pos = surface[0] - global_position
		var normal = surface[1]
		var weight = calculate_weight(pos, normal, 0)
		draw_circle(pos, 3, debug_gradient.gradient.sample(weight))
	
	## All positions, doesnt acco unt for normal or angle
	#for x in range(-128, 129, 8):
		#for y in range(-128, 129, 8):
			#var weight = calculate_weight(Vector2(x, y), Vector2.UP, 0)
			#draw_circle(Vector2(x, y), 3, debug_gradient.gradient.sample(weight))
	
