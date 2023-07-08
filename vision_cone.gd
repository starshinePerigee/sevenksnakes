@tool
extends Area2D

@export var radius = 600
@export var angle = 45.0
var prev_params = [0, 0]

@export var angle_increment = 2.0

var debug = false
@export var debug_wall: PackedScene


func _ready():
	redraw_from_params()
	if get_parent() == get_tree().root:
		debug = true
		position = Vector2(200, 200)
		
		var wall = debug_wall.instantiate()
		get_parent().add_child.call_deferred(wall)
		wall.global_position = Vector2(400, 400)


func point_from_angle(angle) -> Vector2:
	return Vector2(
		cos(deg_to_rad(angle))*radius,
		sin(deg_to_rad(angle))*radius
	)


func redraw_from_params():
	var sub_angle = angle / 2.0
	for i in range(1, 6):
		$CollisionPolygon2D.polygon[i] = point_from_angle(sub_angle)
		sub_angle -= angle / 4
	$Polygon2D.polygon = $CollisionPolygon2D.polygon


func _process(delta):
	if prev_params != [radius, angle]:
		$RayCast2D.target_position = Vector2(radius, 0)
		$RayCast2D.rotation = 0
		if Engine.is_editor_hint():
				prev_params = [radius, angle]
				redraw_from_params()
				print("Arc updated.")


func get_point_at_ray(angle: float) -> Vector2:
	$RayCast2D.rotation_degrees = angle
	$RayCast2D.force_raycast_update()
	if not $RayCast2D.is_colliding():
		# we're not hitting anything
		return Vector2(radius, 0).rotated(deg_to_rad(angle))
	else:
		# we're hitting a wall
		return to_local($RayCast2D.get_collision_point())


func draw_cone():
	# This function actually does the drawing of the polygons based on LOS
	
	# at 2k pixels out, a 100x100 wall is 2.9 degs, so sweep in 2 deg increments
#	var last_wall_seen = null  # we only have to track the last wall because walls are all equal
	var current_angle = -angle/2
	var key_points = PackedVector2Array()
	key_points.append(Vector2(0, 0))
	
	while current_angle < angle/2:
		key_points.append(get_point_at_ray(current_angle))
		current_angle += angle_increment
	# shoot a last ray at the exact final in case degrees aren't a multiple of 2
	key_points.append(get_point_at_ray(angle/2))
	
	$CollisionPolygon2D.polygon = key_points
	$Polygon2D.polygon = key_points
	
	pass


func _physics_process(delta):
	if debug:
		global_rotation = (get_global_mouse_position() - global_position).angle()
	draw_cone()

