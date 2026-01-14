extends Area2D 

var velocity: Vector2 = Vector2.ZERO
var dragging_body: CharacterBody2D = null
var original_position: Vector2 = Vector2.ZERO

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _physics_process(delta: float):
	if original_position == Vector2.ZERO:
		return
	
	# Simulate dragging with friction
	var acceleration: Vector2 = 0.5 * (original_position - get_parent().global_position) - 2.0 * velocity
	if dragging_body:
		acceleration += 1.0 * dragging_body.velocity
	
	velocity += acceleration * delta
	get_parent().position += velocity * delta

func _on_body_entered(body: Node2D):
	if body is CharacterBody2D:
		if original_position == Vector2.ZERO:
			original_position = get_parent().global_position
		dragging_body = body

func _on_body_exited(body: Node2D):
	if dragging_body == body:
		dragging_body = null
