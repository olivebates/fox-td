extends Button

var fast_mode: bool = false
@export var x10: bool = false

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	toggle_mode = true
	toggled.connect(_on_toggled)
	custom_minimum_size = Vector2(10,10)
	add_theme_font_size_override("font_size", 4)
	text = "»"
	if x10:
		text = "↠"
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
	style_hover.border_color = Color(0.7, 0.7, 0.7)
	
	var style_pressed = style_normal.duplicate()
	style_pressed.bg_color = Color(0.15, 0.15, 0.15)
	style_pressed.border_color = Color(0.8, 0.8, 0.8)
	
	add_theme_stylebox_override("normal", style_normal)
	add_theme_stylebox_override("hover", style_hover)
	add_theme_stylebox_override("pressed", style_pressed)
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			position += Vector2(1, 1)
			$ColorRect.visible = false
		else:
			position -= Vector2(1, 1)
			$ColorRect.visible = true

func _on_mouse_entered() -> void:
	var speed = 6 if x10 else 3
	var display_speed = speed if fast_mode else 3
	TooltipManager.show_tooltip(
		"Fast Forward",
		"[font_size=3][color=cornflower_blue]Game speed: x" + str(display_speed) + "[/color][/font_size]\n" +
		"[color=gray]————————————————[/color]\n" +
        "[font_size=2][color=dark_gray]Toggle to enable/disable fast mode[/color][/font_size]"
	)

func _process(delta: float) -> void:
	if (get_tree().get_nodes_in_group("gacha_menu").size() != 0 and fast_mode):
		_on_toggled(false)

func _on_mouse_exited() -> void:
	TooltipManager.hide_tooltip()

func _on_toggled(pressed: bool) -> void:
	fast_mode = pressed
	_on_mouse_entered()
	
	var speed = 6.0 if x10 else 3.0
	Engine.time_scale = speed if pressed else 1.0
	
	var base = StyleBoxFlat.new()
	base.content_margin_left = 3
	base.content_margin_right = 3
	base.content_margin_top = 0
	base.content_margin_bottom = 1
	
	var hover_style: StyleBoxFlat
	var pressed_style: StyleBoxFlat
	
	if pressed:
		base.bg_color = Color(0.2, 0.8, 0.2)
		base.border_color = Color(0.5, 1.0, 0.5)
		hover_style = base.duplicate()
		hover_style.bg_color = Color(0.3, 0.9, 0.3)
		pressed_style = base.duplicate()
		pressed_style.bg_color = Color(0.1, 0.7, 0.1)
	else:
		base.bg_color = Color(0.2, 0.2, 0.2)
		base.border_color = Color(0.5, 0.5, 0.5)
		hover_style = base.duplicate()
		hover_style.bg_color = Color(0.3, 0.3, 0.3)
		hover_style.border_color = Color(0.7, 0.7, 0.7)
		pressed_style = base.duplicate()
		pressed_style.bg_color = Color(0.15, 0.15, 0.15)
		pressed_style.border_color = Color(0.8, 0.8, 0.8)
	
	add_theme_stylebox_override("normal", base)
	add_theme_stylebox_override("hover", hover_style)
	add_theme_stylebox_override("pressed", pressed_style)
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
