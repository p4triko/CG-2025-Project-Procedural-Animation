extends CharacterBody2D

@export_group("Vertical")
@export var gravity: float = 1.0
@export var v_accel: float = 1.0

@export_group("Horisontal")
@export var h_accel: float = 1200.0
@export var h_deaccel: float = 1200.0
@export var h_target_velocity: float = 300

var wanted_floor_distance = 40;
var wanted_velocity: Vector2
var is_grounded: bool = false
var is_touching_wall: bool = false

@onready var leg_right_near_3: SimNode = $SimRoot/LegRightNear1/LegRightNear2/LegRightNear3
@onready var leg_right_far_3: SimNode = $SimRoot/LegRightFar1/LegRightFar2/LegRightFar3
@onready var leg_left_far_3: SimNode = $SimRoot/LegLeftFar1/LegLeftFar2/LegLeftFar3
@onready var leg_left_near_3: SimNode = $SimRoot/LegLeftNear1/LegLeftNear2/LegLeftNear3
var legs: Array[SimNode]
var leg_rays: Array[Vector2] = [Vector2(-100, 200), Vector2(-50, 200), Vector2(50, 200), Vector2(100, 200)]

func _ready() -> void:
	legs = [leg_left_far_3, leg_left_near_3, leg_right_near_3, leg_right_far_3]

func _physics_process(delta: float) -> void:
	var input_axis = Input.get_vector("game_left", "game_right", "game_up", "game_down")
	
	var avg_leg_pos: Vector2 = Vector2.ZERO
	for leg in legs: avg_leg_pos += leg.global_position
	avg_leg_pos /= legs.size()
	
	# Vertical velocity
	if abs(input_axis.y) > 0.5:
		wanted_floor_distance += input_axis.y * v_accel * delta
	wanted_velocity.y = 0
	
	# Horizontal velocity
	wanted_velocity.x = input_axis.x * h_target_velocity
	var velocity_diff: float = wanted_velocity.x - velocity.x
	var is_speeding_up: bool = abs(wanted_velocity.x) > abs(velocity.x)
	velocity.x += sign(velocity_diff) * delta * (h_accel if is_speeding_up else h_deaccel)
	if -sign(velocity_diff) == sign(wanted_velocity.x - velocity.x):
		velocity.x = wanted_velocity.x
	move_and_slide()
	
	## Leg movement
	for i in legs.size():
		var leg = legs[i]
		var leg_ray = leg_rays[i]
		
		var space_state = get_world_2d().direct_space_state
		var query = PhysicsRayQueryParameters2D.create(global_position, global_position + leg_ray + velocity/20)
		var result = space_state.intersect_ray(query)
		if result:
			if result.position.distance_to(leg.global_position) > 150:
				leg.wanted_position = result.position
		$SimRoot._physics_process(delta)
	
