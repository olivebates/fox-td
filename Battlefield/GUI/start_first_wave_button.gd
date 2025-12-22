# In Godot 4 (editor connection preferred, or code):

# Editor: Select Button node > Node tab > double-click "pressed" > connect to script > creates:
extends Button
func _on_button_pressed():
	my_function()

# Or connect in code (_ready()):
func _ready() -> void:
	text = "Start Waves"
	var sb = StyleBoxFlat.new()
	sb.set_content_margin_all(0)
	sb.bg_color = Color(0.333, 0.631, 0.325, 1.0)  # Default background
	focus_mode = Control.FOCUS_NONE
	add_theme_stylebox_override("normal", sb)

	var sb_hover = sb.duplicate()
	sb_hover.bg_color = Color(0.271, 0.686, 0.204, 1.0)  # Lighter on hover
	add_theme_stylebox_override("hover", sb_hover)

	var sb_pressed = sb.duplicate()
	sb_pressed.bg_color = Color(0.137, 0.349, 0.267, 1.0)  # Darker when pressed
	add_theme_stylebox_override("pressed", sb_pressed)

	var sb_focus = sb.duplicate()
	add_theme_stylebox_override("focus", sb_focus)
	
	add_theme_font_size_override("font_size", 5)
	
	sb.set_border_width_all(1)
	sb.border_color = Color.BLACK
	
	pressed.connect(my_function)
	get_tree().get_first_node_in_group("start_wave_button")._on_pressed()
	visible = true

func on_death():
	visible = true
	get_tree().get_first_node_in_group("start_wave_button")._on_pressed()
	
func my_function():
	get_tree().get_first_node_in_group("start_wave_button")._on_pressed()
	visible = false
