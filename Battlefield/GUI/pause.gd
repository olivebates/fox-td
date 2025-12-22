extends Button
var is_paused: bool = false
func _ready():
	text = "Pause"
	pressed.connect(_on_pressed)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.1, 0.2)  # dark blue
	sb.corner_radius_top_left = 0
	sb.corner_radius_top_right = 0
	sb.corner_radius_bottom_left = 0
	sb.corner_radius_bottom_right = 0

	add_theme_stylebox_override("normal", sb)
	add_theme_stylebox_override("hover", sb)
	add_theme_stylebox_override("pressed", sb)
	add_theme_stylebox_override("focus", sb)
	add_theme_font_size_override("font_size", 4)
	# Remove all padding/margins
	add_theme_constant_override("h_separation", 0)
	add_theme_constant_override("outline_size", 0)
	for side in ["left", "top", "right", "bottom"]:
		add_theme_constant_override("margin_" + side, 0)
	# Minimal size
	custom_minimum_size = Vector2(16, 8)
	focus_mode = Control.FOCUS_NONE
	
func _on_pressed():
	is_paused = !is_paused
	text = "Resume" if is_paused else "Pause"
	var enabled = !is_paused
	get_tree().call_group("enemy", "set_process", enabled)
	get_tree().call_group("enemy", "set_physics_process", enabled)
	get_tree().call_group("tower", "set_process", enabled)
	get_tree().call_group("bullet", "set_physics_process", enabled)
	get_tree().call_group("bullet", "set_process", enabled)
	get_tree().call_group("next_wave_shower", "set_process", enabled)
	get_tree().call_group("wave_spawner", "set_game_paused", is_paused)
	get_tree().call_group("health_manager", "set", "is_paused", is_paused)
	get_tree().get_first_node_in_group("start_first_wave_button").visible = false
