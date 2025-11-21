extends CharacterBody2D

@export_group("Vertical")
@export var gravity: float = 1.0
@export var v_accel: float = 1.0

@export_group("Horisontal")
@export var h_accel: float = 10000.0
@export var h_deaccel: float = 10000.0
@export var h_target_velocity: float = 1000

var wanted_floor_distance = 40;
var wanted_velocity: Vector2
var is_grounded: bool = false
var is_touching_wall: bool = false

@onready var leg_right_near_3: SimNode = $SimRoot/LegRightNear1/LegRightNear2/LegRightNear3
@onready var leg_right_far_3: SimNode = $SimRoot/LegRightFar1/LegRightFar2/LegRightFar3
@onready var leg_left_far_3: SimNode = $SimRoot/LegLeftFar1/LegLeftFar2/LegLeftFar3
@onready var leg_left_near_3: SimNode = $SimRoot/LegLeftNear1/LegLeftNear2/LegLeftNear3
var legs: Array[SimNode]

func _ready() -> void:
	legs = [leg_right_near_3, leg_right_far_3, leg_left_near_3, leg_left_far_3]

func _process(delta: float) -> void:
	var input_axis = Input.get_vector("game_left", "game_right", "game_up", "game_down")
	
	# Vertical velocity
	if abs(input_axis.y) > 0.5:
		wanted_floor_distance += input_axis.y * v_accel * delta
	
	# Horizontal velocity
	wanted_velocity.x = input_axis.x * h_target_velocity
	var velocity_diff: float = wanted_velocity.x - velocity.x
	var is_speeding_up: bool = abs(wanted_velocity.x) > abs(velocity.x)
	velocity.x += sign(velocity_diff) * delta * (h_accel if is_speeding_up else h_deaccel)
	if -sign(velocity_diff) == sign(wanted_velocity.x - velocity.x):
		velocity.x = wanted_velocity.x
	move_and_slide()
	
	var predicted_position = global_position + velocity
