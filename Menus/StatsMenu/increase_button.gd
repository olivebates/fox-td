extends Button


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			position += Vector2(1, 1)
			$ColorRect.position -= Vector2(1, 1)
		else:
			position -= Vector2(1, 1)
			$ColorRect.position += Vector2(1, 1)
