# UnmergeButton.gd
extends Button

var unmerge_mode: bool = false
var original_position
func _ready() -> void:
	text = "Unmerge"
	focus_mode = Control.FOCUS_NONE
	toggle_mode = true
	toggled.connect(_on_toggled)
	add_theme_font_size_override("font_size", 4)
	add_theme_color_override("font_outline_color", Color.BLACK)
	add_theme_constant_override("outline_size", 1)
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.2, 0.2, 0.2)
	style_normal.content_margin_left = 3
	style_normal.content_margin_right = 3
	style_normal.content_margin_top = 0
	style_normal.content_margin_bottom = 1
	
	var style_hover = style_normal.duplicate()
	style_hover.bg_color = Color(0.3, 0.3, 0.3)
	
	var style_pressed = style_normal.duplicate()
	style_pressed.bg_color = Color(0.15, 0.15, 0.15)
	
	add_theme_stylebox_override("normal", style_normal)
	add_theme_stylebox_override("hover", style_hover)
	add_theme_stylebox_override("pressed", style_pressed)
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	button_down.connect(_on_button_down)



func _on_button_down() -> void:
	if !unmerge_mode:
		position += Vector2(1, 1)
		$ColorRect.visible = false

func _on_mouse_entered() -> void:
	TooltipManager.show_tooltip(
		"Unmerge Towers",
		"[font_size=3][color=orange]Click a merged tower to split it[/color][/font_size]\n" +
		"[font_size=2][color=dark_gray]Splits into two lower-rank towers[/color][/font_size]"
	)

func _on_mouse_exited() -> void:
	TooltipManager.hide_tooltip()

func _on_toggled(pressed: bool) -> void:
	unmerge_mode = pressed
	
	var base = StyleBoxFlat.new()
	base.content_margin_left = 3
	base.content_margin_right = 3
	base.content_margin_top = 0
	base.content_margin_bottom = 1
	
	var hover_style: StyleBoxFlat
	var pressed_style: StyleBoxFlat
	
	if pressed:
		base.bg_color = Color(1.0, 0.5, 0.2)
		hover_style = base.duplicate()
		hover_style.bg_color = Color(1.0, 0.6, 0.3)
		pressed_style = base.duplicate()
		pressed_style.bg_color = Color(0.9, 0.4, 0.1)
		$ColorRect.visible = false
	else:
		base.bg_color = Color(0.2, 0.2, 0.2)
		hover_style = base.duplicate()
		hover_style.bg_color = Color(0.3, 0.3, 0.3)
		pressed_style = base.duplicate()
		pressed_style.bg_color = Color(0.15, 0.15, 0.15)
		position -= Vector2(1,1)
		$ColorRect.visible = true
	
	add_theme_stylebox_override("normal", base)
	add_theme_stylebox_override("hover", hover_style)
	add_theme_stylebox_override("pressed", pressed_style)
	
	get_tree().call_group("backpack_inventory", "refresh_all_highlights")
	get_tree().call_group("squad_inventory", "refresh_all_highlights")
