extends CharacterBody2D

@export_group("Vertical")
@export var gravity: float = 1.0
@export var v_movement_accel: float = 1.0

@export_group("Horisontal")
@export var h_accel: float = 5000.0
@export var max_h_velocity: float = 100000
@export var h_velocity_drag: float = 0.01

var wanted_floor_distance = 40;
var wanted_velocity: Vector2
var is_grounded: bool = false
var is_touching_wall: bool = false

func _process(delta: float) -> void:
	var input_axis = Input.get_vector("game_left", "game_right", "game_up", "game_down")
	
	# Apply drag
	velocity.x = lerp(velocity.x, 0.0, h_velocity_drag)
	
	# Create temporary vewanted velocity
	wanted_velocity = velocity
	
	# Vertical velocity
	if abs(input_axis.y) > 0.5:
		wanted_floor_distance += input_axis.y * v_movement_accel * delta
	
	# Horizontal velocity
	wanted_velocity.x += input_axis.x * h_accel * delta
	
	# Applying wanted_velocity to the actual velocity
	var player_is_too_fast: bool = abs(wanted_velocity.x) > max_h_velocity
	var player_was_too_fast: bool = abs(velocity.x) > max_h_velocity
	var player_is_slowing_down: bool = abs(wanted_velocity.x) <= abs(velocity.x)
	if !player_is_too_fast || player_is_slowing_down:
		velocity.x = wanted_velocity.x
	if player_is_too_fast && !player_was_too_fast:
		velocity.x = sign(wanted_velocity.x) * max_h_velocity

	move_and_slide()
