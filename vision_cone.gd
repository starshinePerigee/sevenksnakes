@tool
extends Area2D

@export var radius = 600
@export var angle = 45.0
var prev_params = [0, 0]

var debug = false


func _ready():
	redraw_from_params()
	if get_parent() == get_tree().root:
		debug = true
		position = Vector2(200, 200)


func point_from_angle(angle) -> Vector2:
	return Vector2(
		cos(deg_to_rad(angle))*radius,
		sin(deg_to_rad(angle))*radius
	)


func redraw_from_params():
	var sub_angle = angle / 2.0
	for i in range(1, 6):
		var sub_point = point_from_angle(sub_angle)
		$CollisionPolygon2D.polygon[i] = sub_point
		$Polygon2D.polygon[i] = sub_point
		sub_angle -= angle / 4


func _process(delta):
	if Engine.is_editor_hint():
		if prev_params != [radius, angle]:
			prev_params = [radius, angle]
			redraw_from_params()
			print("Arc updated.")
	if debug:
		global_rotation = (get_global_mouse_position() - global_position).angle()


func draw_cone():
	pass


func _physics_process(delta):
	draw_cone()
