# Utility.gd (Autoload singleton)
extends Node

var floating_text_duration: float = 1.5  # Controls total animation length (adjustable)

func spawn_floating_text(
	text: String,
	position: Vector2 = Vector2.ZERO,
	parent: Node = null,
	celebrate: bool = false,
	text_color: Color = Color.RED
) -> void:
	var use_position := position + Vector2(4, -4)
	var use_parent := parent
	if use_parent == null:
		use_parent = get_tree().current_scene
		use_position = use_parent.get_viewport().get_mouse_position() + Vector2(4, 4)
	
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 4)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 1)
	label.modulate = text_color
	label.position = Vector2(-500, -500)
	label.z_index = 4000
	
	use_parent.add_child(label)
	
	await get_tree().process_frame
	
	var viewport_size := get_viewport().get_visible_rect().size
	var label_size := label.size
	
	use_position.x = clamp(use_position.x, label_size.x / 2, viewport_size.x - label_size.x / 2)
	use_position.y = clamp(use_position.y, label_size.y / 2, viewport_size.y - label_size.y / 2)
	label.position = use_position - label_size / 2
	
	var tween := create_tween().set_parallel()
	label.scale = Vector2(0.5, 0.5)
	
	tween.tween_property(label, "scale", Vector2(1.2, 1.2), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), floating_text_duration * 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, floating_text_duration * 0.7).set_delay(floating_text_duration * 0.3).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	
	if celebrate:
		var hue_tween := create_tween().set_loops()
		hue_tween.tween_method(Callable(self, "_set_hue").bind(label), 0.0, 1.0, 1.0)
	
	await tween.finished
	label.queue_free()

func _set_hue(hue: float, label: Label) -> void:
	label.modulate = Color.from_hsv(hue, 1.0, 1.0, label.modulate.a)
