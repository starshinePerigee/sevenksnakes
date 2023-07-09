@tool
extends Node2D

@export var grid_size = 64
var grid = []  # x than y, x+ is right, y+ is down

@export var indicator: PackedScene
var indicators = []
var x_indexes = 0
var y_indexes = 0

var debug = false
@export var guard_scene: PackedScene
var debug_guard = null


func indexes_to_position(x, y) -> Vector2:
	return Vector2(
		x * grid_size + grid_size/2,
		y * grid_size + grid_size/2
	)


func position_to_indexes(position_: Vector2) -> Array[int]:
	return [
		int((position_.x - grid_size/2) / grid_size),
		int((position_.y - grid_size/2) / grid_size),
	]


func recalculate_grid():
	var grid_corner = position_to_indexes(get_viewport_rect().end)
	x_indexes = grid_corner[0]
	y_indexes = grid_corner[1]
	grid = []
	
	for x_index in range(x_indexes + 1):
		grid.append([])
		for y_index in range(y_indexes + 1):
			$PointFinder.position = indexes_to_position(x_index, y_index)
			$PointFinder.force_raycast_update()
			grid[x_index].append($PointFinder.is_colliding())
			
			var new_indicator = indicator.instantiate()
			new_indicator.position = indexes_to_position(x_index, y_index)
			new_indicator.z_index = 100
			add_child(new_indicator)
			if $PointFinder.is_colliding():
				new_indicator.color = Color(1, 0, 0, 0.7)
			else:
				new_indicator.color = Color(0, 1, 0, 0.7)


func _ready():
	recalculate_grid()
	if get_parent() == get_tree().root:
		debug = true
		debug_guard = guard_scene.instantiate()
		add_child(debug_guard)


func _process(delta):
	if debug:
		var mouse_pos = (get_global_mouse_position() + Vector2(grid_size/2, grid_size/2))
		var guard_pos = mouse_pos.snapped(Vector2(grid_size, grid_size))- Vector2(grid_size/2, grid_size/2)
		debug_guard.global_position = guard_pos
		var guard_index = Vector2(position_to_indexes(guard_pos)[0], position_to_indexes(guard_pos)[1])
		
		var guard_path = build_back_forth_path(guard_index, Vector2(-1, 0))
		
		$Line2D.clear_points()
		for point in guard_path:
			$Line2D.add_point(indexes_to_position(point.x, point.y))
		if Input.is_key_pressed(KEY_P):
			print("break")

func build_snake_path():
	# step 1: build a hecked randomized a*
	pass


func check_vector(index_vector: Vector2) -> bool:
	return grid[int(index_vector.x)][int(index_vector.y)]


func grid_cast(start_index_vector, direction) -> Vector2:
	var i = 99
	while i > 0:
		if start_index_vector.x > x_indexes:
			break
		if start_index_vector.x < 0:
			break
		if start_index_vector.y > y_indexes:
			break
		if start_index_vector.y < 0:
			break
		if check_vector(start_index_vector):
			break
		start_index_vector += direction
		i -= 1
	if i == 0:
		printerr("gridcast failure!")
	return start_index_vector - direction


func build_back_forth_path(start_index_vector, direction) -> Array:
	var path_indexes = [start_index_vector]
	var forward_index = grid_cast(start_index_vector, direction)
	if forward_index != start_index_vector:
		path_indexes.append(forward_index)
	var back_index = grid_cast(forward_index, -direction)
	if back_index != forward_index:
		path_indexes.append(back_index)
	if back_index != start_index_vector:
		path_indexes.append(start_index_vector)
	if len(path_indexes) <= 1:
		path_indexes.append(start_index_vector)
	return path_indexes


func build_loop_path():
	pass
