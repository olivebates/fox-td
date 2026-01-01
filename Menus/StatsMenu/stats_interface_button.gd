extends HBoxContainer

@export var title_label: String = ""
@export var description: String = ""

@onready var inc_button: Button = %IncreaseButton
@onready var stat_label: Label = %StatsLabel

func _ready() -> void:
	stat_label.text = title_label
	
	stat_label.add_theme_font_size_override("font_size", 4)
	
	inc_button.text = "+"
	inc_button.focus_mode = Control.FOCUS_NONE
	inc_button.add_theme_font_size_override("font_size", 4)
	inc_button.add_theme_color_override("font_outline_color", Color.BLACK)
	inc_button.add_theme_constant_override("outline_size", 1)
	
	var style_normal := StyleBoxFlat.new()
	style_normal.bg_color = Color(0.2, 0.2, 0.2)
	style_normal.content_margin_left = 2
	style_normal.content_margin_right = 2
	
	var style_hover = style_normal.duplicate()
	style_hover.bg_color = Color(0.3, 0.3, 0.3)
	style_hover.border_color = Color(0.7, 0.7, 0.7)
	
	var style_pressed = style_normal.duplicate()
	style_pressed.bg_color = Color(0.15, 0.15, 0.15)
	style_pressed.border_color = Color(0.8, 0.8, 0.8)
	
	var style_disabled = style_normal.duplicate()
	style_disabled.bg_color = Color(0.1, 0.1, 0.1)
	style_disabled.border_color = Color(0.3, 0.3, 0.3)
	
	inc_button.add_theme_stylebox_override("normal", style_normal)
	inc_button.add_theme_stylebox_override("hover", style_hover)
	inc_button.add_theme_stylebox_override("pressed", style_pressed)
	inc_button.add_theme_stylebox_override("disabled", style_disabled)
	
	stat_label.add_theme_font_size_override("font_size", 4)
	stat_label.add_theme_color_override("font_outline_color", Color.BLACK)
	stat_label.add_theme_constant_override("outline_size", 1)
	
	inc_button.mouse_entered.connect(_on_mouse_entered)
	inc_button.mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	TooltipManager.show_tooltip(title_label, description)

func _on_mouse_exited() -> void:
	TooltipManager.hide_tooltip()
