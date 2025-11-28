@tool
class_name SpiderLeg extends SimRoot

@export_tool_button("blah") var a = func(): 
	seed(Engine.get_physics_frames())
	wanted_position = Vector2(randf_range(0, 100 * (-1 if leg_polarity else 1)), randf_range(-100, 100));
	step()

# Exports
@export var wanted_position: Vector2 = Vector2.ZERO
@export var leg_polarity: bool = false

@export_group("Stepping")
@export var leg_reposition_speed: float = 0.3 ## In seconds
@export var step_weight: float = 0.5 ## Determines where between current and wanted pos the peak of step curve is
@export var step_curve_height: float = 10

# Refs
@onready var leg_node = $SimNode/SimNode2/SimNode3
@onready var middle_node: SimNode = $SimNode/SimNode2


enum states {
	GROUNDED, ## Attached to the ground at current_position
	STEPPING, ## In process of moving to wanted_position
	FOLLOW,   ## Follows wanted position immidiately, without exceeding max length
	PHYSICS}  ## Leg will just roughly follow some wanted point using spring simulation, usef when mid-air

var state = states.GROUNDED
var current_position: Vector2 = Vector2.ZERO
var current_normal: Vector2 = Vector2.DOWN
var wanted_normal: Vector2  = Vector2.DOWN
var intermediate_position: Vector2 ## For bezier curve
var stepping_progress: float = 0

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	middle_node.allowed_angle_polarity = int(leg_polarity) + 1
	if state == states.STEPPING:
		progress_step(delta)
	else:
		move_leg_closest_to(wanted_position)

func step(to: Vector2 = wanted_position, normal: Vector2 = wanted_normal):
	if state == states.GROUNDED:
		wanted_position = to
		wanted_normal = normal
		intermediate_position = Vector2(lerpf(current_position.x, wanted_position.x, step_weight), min(current_position.y, wanted_position.y) - step_curve_height)
		stepping_progress = 0
		state = states.STEPPING

func restep(to: Vector2 = wanted_position, normal: Vector2 = wanted_normal):
	if state == states.STEPPING:
		current_position = leg_node.wanted_position
		current_normal = wanted_normal
		wanted_position = to
		wanted_normal = normal
		intermediate_position = current_position.lerp(wanted_position, step_weight)
		stepping_progress = 0
		state = states.STEPPING

func progress_step(delta):
	stepping_progress = min(stepping_progress + delta / leg_reposition_speed, 1.0)
	
	var w1 = pow(1 - stepping_progress, 2)
	var w2 = 2 * stepping_progress * (1 - stepping_progress)
	var w3 = pow(stepping_progress, 2)
	move_leg_closest_to(w1*current_position + w2*intermediate_position + w3*wanted_position)
	
	if stepping_progress == 1.0:
		state = states.GROUNDED
		current_position = wanted_position
		current_normal = wanted_normal

func move_leg_closest_to(target_position: Vector2):
	var target_relative_position = target_position - global_position
	var target_relative_distance = target_relative_position.length()
	# Prevents the legs from stretching further then their length
	leg_node.wanted_position = target_relative_position.normalized() * min(leg_node.length, target_relative_distance) + global_position
