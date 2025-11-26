extends CharacterBody2D

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
	for i in legs.size():
		var leg = legs[i]
		var leg_ray = leg_rays[i]
		
		var space_state = get_world_2d().direct_space_state
		var ray_start_pos = global_position + velocity * delta * 15
		var query = PhysicsRayQueryParameters2D.create(ray_start_pos, ray_start_pos + leg_ray + velocity/20)
		query.exclude = [self]
		var result = space_state.intersect_ray(query)
		if result:
			if result.position.distance_to(leg.current_position) > 100:
				leg.step(result.position)
	
