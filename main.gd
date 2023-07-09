extends Node2D

var debug


func _ready():
	if get_parent() == get_tree().root:
		debug = true


func _physics_process(delta):
	if debug:
		$VisionCone.global_rotation = (get_global_mouse_position() - $VisionCone.global_position).angle()
