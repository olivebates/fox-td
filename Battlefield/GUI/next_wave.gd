extends Button

func _ready() -> void:
	pressed.connect(_on_pressed)
	disabled = false
	
	add_theme_font_size_override("font_size", 4)
	
	add_theme_constant_override("h_separation", 0)
	
	var normal = StyleBoxFlat.new()
	normal.bg_color = Color(0.2, 0.2, 0.2)
	add_theme_stylebox_override("normal", normal)
	
	var hover = StyleBoxFlat.new()
	hover.bg_color = Color(0.3, 0.3, 0.3)
	add_theme_stylebox_override("hover", hover)
	
	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = Color(0.15, 0.15, 0.15)
	add_theme_stylebox_override("pressed", pressed_style)
	
	var disabled_style = StyleBoxFlat.new()
	disabled_style.bg_color = Color(0.1, 0.1, 0.1)
	add_theme_stylebox_override("disabled", disabled_style)
	
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	focus_mode = Control.FOCUS_NONE
	
	# Force exact 24px size
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	custom_minimum_size = Vector2(32, 0)
	anchor_left = 0
	anchor_right = 0
	anchor_top = 0.5
	anchor_bottom = 0.5
	offset_left = 0
	offset_right = 0
	offset_top = 0
	offset_bottom = 0

#func _process(delta: float) -> void:
	#if get_tree().get_nodes_in_group("enemy").size() > 0 or WaveSpawner.enemies_to_spawn > 0:
		#disabled = true
	#else:
		#disabled = false

func _on_pressed():
	WaveSpawner.start_next_wave()
