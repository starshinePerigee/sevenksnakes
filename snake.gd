extends Node2D

@export var walk_speed = 30
@export var alert_color = Color(255, 82, 116)

var debug = false


# Called when the node enters the scene tree for the first time.
func _ready():
	if get_parent() == get_tree().root:
		debug = true
		position = Vector2(400, 400)
		var timer = get_tree().create_timer(3)
		timer.timeout.connect(discover_and_remove)


func _process(delta):
	pass


func _physics_process(delta):
	pass


func discover_and_remove():
	$Area2D/Polygon2D.color = alert_color
	$CollisionPolygon2D.disabled = true
	var timer = get_tree().create_timer(0.3)
	timer.timeout.connect(queue_free)
