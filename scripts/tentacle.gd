extends Line2D


var base_position: Vector2 = global_position
var max_length = 300.0

var _segments: Array[Vector2] = []
var _segment_lengths: Array[float] = []

@export var ik_iterations: int = 3
@export var num__segments: int = 30

func _ready():
	clear_points()
	var segment_len = max_length / num__segments 

	for i in range(num__segments + 1):
		_segments.append(base_position)
		
		add_point(to_local(base_position)) 
		
		if i < num__segments:
			_segment_lengths.append(segment_len)


func _process(_delta: float) -> void:
	var mouse_pos: Vector2 = get_global_mouse_position()

	var direction: Vector2 = mouse_pos - base_position  
	var dist: float = direction.length()

	if dist > max_length:
		mouse_pos = base_position + direction.normalized() * max_length
	
	solve_ik(mouse_pos)
	
	for i in range(_segments.size()):
		set_point_position(i, to_local(_segments[i]))

func solve_ik(target_pos: Vector2) -> void:
	_segments[-1] = target_pos

	for _iter in range(ik_iterations):
		for i in range(num__segments - 1, -1, -1):
			var vec: Vector2 = _segments[i] - _segments[i + 1]
			var direction: Vector2 = vec.normalized()
			_segments[i] = _segments[i + 1] + direction * _segment_lengths[i]

	_segments[0] = base_position
	for i in range(num__segments):
		var vec: Vector2 = _segments[i + 1] - _segments[i]
		var direction: Vector2 = vec.normalized()
		_segments[i + 1] = _segments[i] + direction * _segment_lengths[i]
