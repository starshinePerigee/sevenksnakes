@tool
extends Area2D

@export var radius = 600
@export var angle = 45.0
var prev_params = [0, 0]

# at 2k pixels out, a 100x100 wall is 2.9 degs, so sweep in 2 deg increments
@export var angle_increment = 2.0

var debug = false
@export var debug_wall: PackedScene
var dindicators = {
}


func _ready():
	if Engine.is_editor_hint():
		redraw_from_params()
	if get_parent() == get_tree().root:
		debug = true
		position = Vector2(200, 200)
		dindicators = {
			1: $KeyOne,
			2: $KeyTwo,
			3: $KeyThree,
			4: $KeyFour
		}
		
		var wall = debug_wall.instantiate()
		get_parent().add_child.call_deferred(wall)
		wall.global_position = Vector2(400, 300)
		wall.z_index = -100
		
		var wall_2 = debug_wall.instantiate()
		get_parent().add_child.call_deferred(wall_2)
		wall_2.global_position = Vector2(700, 300)
		wall_2.z_index = -100
		


func point_from_angle(a) -> Vector2:
	return Vector2(
		cos(deg_to_rad(a))*radius,
		sin(deg_to_rad(a))*radius
	)


func redraw_from_params():
	var sub_angle = angle / 2.0
	var new_polygon = PackedVector2Array()
	new_polygon.append(Vector2(0, 0))
	for __ in range(1, 6):
		new_polygon.append(point_from_angle(sub_angle))
		sub_angle -= angle / 4
	$CollisionPolygon2D.polygon = new_polygon
	$Polygon2D.polygon = new_polygon


func _process(delta):
	if prev_params != [radius, angle]:
		$RayCast2D.target_position = Vector2(radius, 0)
		$RayCast2D.rotation = 0
		if Engine.is_editor_hint():
				prev_params = [radius, angle]
				redraw_from_params()
				print("Arc updated.")


func get_point_at_ray(ray_angle) -> Vector2:
	$RayCast2D.rotation = ray_angle
	$RayCast2D.force_raycast_update()
	if not $RayCast2D.is_colliding():
		# we're not hitting anything
		return Vector2(radius, 0).rotated($RayCast2D.rotation)
	else:
		# we're hitting a wall
		return to_local($RayCast2D.get_collision_point())


func get_vector_rays(hit_object) -> Array:
	# find the two far edges of the object
	# walls are always squares so we can do this logically
	var collider_shape = hit_object.get_node("CollisionPolygon2D").polygon
	var x0 = collider_shape[0].x + hit_object.position.x
	var x1 = collider_shape[2].x + hit_object.position.x
	var y0 = collider_shape[0].y + hit_object.position.y
	var y1 = collider_shape[2].y + hit_object.position.y
	
	var ny0 = 0.0
	var ny1 = 0.0
	var nx0 = 0.0
	var nx1 = 0.0
	if global_position.x < x0:
		ny0 = y0
		ny1 = y1
	elif global_position.x < x1:
		if global_position.y < y1:
			ny0 = y0
			ny1 = y0
		else:
			ny0 = y1
			ny1 = y1
	else:
		ny0 = y1
		ny1 = y0
		
	if global_position.y < y0:
		nx0 = x1
		nx1 = x0
	elif global_position.y < y1:
		if global_position.x < x1:
			nx0 = x0
			nx1 = x0
		else:
			nx0 = x1
			nx1 = x1
	else:
		nx0 = x0
		nx1 = x1
	
	var vertex_points = [Vector2(nx0, ny0), Vector2(nx1, ny1)]
	
	var key_rays = []
	var first = true
	for vertex in vertex_points:
		var aim_angle = to_local(vertex).angle()
		var fudge_angle = 0
		if first:
			fudge_angle = 0.001
			first = false
		else:
			fudge_angle = -0.001
		key_rays.append([rad_to_deg(aim_angle) + fudge_angle, get_point_at_ray(aim_angle)])
		$RayCast2D.add_exception(hit_object)
		key_rays.append([rad_to_deg(aim_angle), get_point_at_ray(aim_angle)])
		$RayCast2D.remove_exception(hit_object)
	return key_rays


func draw_cone():
	# This function actually does the drawing of the polygons based on LOS
	# this works in two passes:
	# first, raycast every angle_increment degrees to place points in the "typical arc"
	# second, if you hit something, add all of its vectors to the key list
	# third, sort that list and transform to polygon
	
	var key_points = []
	var hit_walls = []
	
	var current_angle = -angle/2
	key_points.append([current_angle, get_point_at_ray(deg_to_rad(current_angle))])
	current_angle += angle_increment
	
	while current_angle < angle/2:
		$RayCast2D.rotation_degrees = current_angle
		$RayCast2D.force_raycast_update()
		
		if $RayCast2D.is_colliding():
			if $RayCast2D.get_collider() not in hit_walls:
				hit_walls.append($RayCast2D.get_collider())
		else:
			key_points.append([current_angle, Vector2(radius, 0).rotated($RayCast2D.rotation)])
		current_angle += angle_increment
#		
	# shoot a last ray at the exact final
	key_points.append([angle/2, get_point_at_ray(deg_to_rad(angle/2))])
	
	# iterate through vectors of hit targets, getting additional point-angle pairs
	if debug:
		for dindicator in dindicators.values():
			dindicator.visible = false
	for wall in hit_walls:
		var i = 0
		for vertex_ray in get_vector_rays(wall):
			if debug:
				i += 1
				dindicators[i].position = vertex_ray[1]
				dindicators[i].visible = true
			if vertex_ray[0] > -angle/2 and vertex_ray[0] < angle/2:
				key_points.append(vertex_ray)
	
	key_points.sort()
	
	var new_polygon = PackedVector2Array()
	new_polygon.append(Vector2(0, 0))
	for key_point in key_points:
		new_polygon.append(key_point[1])
	
	$CollisionPolygon2D.polygon = new_polygon
	$Polygon2D.polygon = new_polygon



func _physics_process(delta):
	if debug:
		global_rotation = (get_global_mouse_position() - global_position).angle()
		if Input.is_key_pressed(KEY_W):
			position += Vector2(0, -3)
		if Input.is_key_pressed(KEY_S):
			position += Vector2(0, 3)
		if Input.is_key_pressed(KEY_A):
			position += Vector2(-3, 0)
		if Input.is_key_pressed(KEY_D):
			position += Vector2(3, 0)
	if not Engine.is_editor_hint():
		draw_cone()
