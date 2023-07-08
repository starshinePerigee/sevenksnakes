@tool
extends Area2D


func _ready():
	$Polygon2D.polygon = $CollisionPolygon2D.polygon

