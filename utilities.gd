# Utility.gd (Autoload singleton)

extends Node

func spawn_floating_text(text: String, position: Vector2 = Vector2.ZERO, parent: Node = null, celebrate: bool = false) -> void:
	var use_position := position
	var use_parent := parent
	
	if use_parent == null:
		use_parent = get_tree().current_scene
		if use_position == Vector2.ZERO:
			use_position = use_parent.get_viewport().get_mouse_position()
	
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = use_position
	label.add_theme_font_size_override("font_size", 4)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 1)
	label.z_index = 4000
	
	use_parent.add_child(label)
	
	var tween := create_tween().set_parallel()
	tween.tween_property(label, "position:y", use_position.y - 8, 3).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 3).set_delay(0.3).set_ease(Tween.EASE_IN)
	
	if celebrate:
		var hue_tween := create_tween().set_loops()
		hue_tween.tween_method(Callable(self, "_set_hue").bind(label), 0.0, 1.0, 1.0)
	
	await tween.finished
	label.queue_free()

func _set_hue(hue: float, label: Label) -> void:
	label.modulate = Color.from_hsv(hue, 1.0, 1.0, label.modulate.a)
