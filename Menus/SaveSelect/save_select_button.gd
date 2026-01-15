extends Button

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	add_theme_font_size_override("font_size", 4)
	add_theme_color_override("font_outline_color", Color.BLACK)
	add_theme_constant_override("outline_size", 1)

	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.65, 0.54, 0.36)
	style_normal.border_width_left = 1
	style_normal.border_width_top = 1
	style_normal.border_width_right = 1
	style_normal.border_width_bottom = 1
	style_normal.border_color = Color(0.9, 0.84, 0.68)
	style_normal.content_margin_left = 3
	style_normal.content_margin_right = 3
	style_normal.content_margin_top = 0
	style_normal.content_margin_bottom = 1

	var style_hover = style_normal.duplicate()
	style_hover.bg_color = Color(0.72, 0.6, 0.4)
	style_hover.border_color = Color(1, 0.96, 0.8)

	var style_pressed = style_normal.duplicate()
	style_pressed.bg_color = Color(0.58, 0.48, 0.32)
	style_pressed.border_color = Color(1, 0.98, 0.85)

	var style_disabled = style_normal.duplicate()
	style_disabled.bg_color = Color(0.35, 0.3, 0.22)
	style_disabled.border_color = Color(0.72, 0.65, 0.5)

	add_theme_stylebox_override("normal", style_normal)
	add_theme_stylebox_override("hover", style_hover)
	add_theme_stylebox_override("pressed", style_pressed)
	add_theme_stylebox_override("disabled", style_disabled)
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
