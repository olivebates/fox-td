extends Node

## --- Tuning ---
@export var step_y := 16
@export var step_x := 16
@export var horizontal_chance := 0.4

## --- State ---
var current_path: Array[Vector2] = []
var current_curve: Curve2D

## --- Public API ---

func generate_new_path() -> void:
	current_path.clear()

	var screen_size := get_viewport().get_visible_rect().size

	var current_pos := Vector2(
		randi_range(step_x, screen_size.x - step_x),
		0
	)

	current_path.append(current_pos)

	while current_pos.y < screen_size.y:
		var move := Vector2(0, step_y)

		if randf() < horizontal_chance:
			move.x = step_x * (randi() % 2 * 2 - 1)

		var next_pos := current_pos + move

		next_pos.x = clamp(next_pos.x, step_x, screen_size.x - step_x)
		next_pos.y = min(next_pos.y, screen_size.y)

		if next_pos != current_pos:
			current_path.append(next_pos)
			current_pos = next_pos

	_build_curve()


func get_path_points() -> Array[Vector2]:
	return current_path.duplicate()


func get_curve() -> Curve2D:
	return current_curve


## --- Internal ---

func _build_curve() -> void:
	current_curve = Curve2D.new()

	for point in current_path:
		current_curve.add_point(point)
