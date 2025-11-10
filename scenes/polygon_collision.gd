extends PhysicsBody2D

func _ready():
	# Automatically create collision shapes for all Polygon2D child nodes
	for child in get_children():
		if child is Polygon2D:
			var collision_polygon := CollisionPolygon2D.new()
			collision_polygon.polygon = child.polygon
			add_child(collision_polygon)
