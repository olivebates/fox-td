# NextWaveButton.gd
extends Button

func _ready() -> void:
	if visible:
		get_tree().get_first_node_in_group("start_wave_button")._on_pressed() # Unpause the game
	add_theme_font_size_override("font_size", 4)
	text = "Next Wave"
	focus_mode = Control.FOCUS_NONE
	disabled = true
	pressed.connect(_on_pressed)
	# Remove corner rounding

	# Remove corner rounding
	add_theme_constant_override("corner_radius_top_left", 0)
	add_theme_constant_override("corner_radius_top_right", 0)
	add_theme_constant_override("corner_radius_bottom_right", 0)
	add_theme_constant_override("corner_radius_bottom_left", 0)
	
	# Minimal padding (no extra space around text)
	add_theme_constant_override("h_separation", 0)
	
	# Use flat styleboxes with minimal content margin
	var flat_normal := StyleBoxFlat.new()
	flat_normal.bg_color = Color(0.2, 0.2, 0.2)
	flat_normal.content_margin_left = 4
	flat_normal.content_margin_right = 4
	flat_normal.content_margin_top = 2
	flat_normal.content_margin_bottom = 2
	
	var flat_hover := StyleBoxFlat.new()
	flat_hover.bg_color = Color(0.3, 0.3, 0.3)
	flat_hover.content_margin_left = 4
	flat_hover.content_margin_right = 4
	flat_hover.content_margin_top = 2
	flat_hover.content_margin_bottom = 2
	
	var flat_pressed := StyleBoxFlat.new()
	flat_pressed.bg_color = Color(0.1, 0.1, 0.1)
	flat_pressed.content_margin_left = 4
	flat_pressed.content_margin_right = 4
	flat_pressed.content_margin_top = 2
	flat_pressed.content_margin_bottom = 2
	
	var flat_disabled := StyleBoxFlat.new()
	flat_disabled.bg_color = Color(0.15, 0.15, 0.15)
	flat_disabled.content_margin_left = 4
	flat_disabled.content_margin_right = 4
	flat_disabled.content_margin_top = 2
	flat_disabled.content_margin_bottom = 2
	
	add_theme_stylebox_override("normal", flat_normal)
	add_theme_stylebox_override("hover", flat_hover)
	add_theme_stylebox_override("pressed", flat_pressed)
	add_theme_stylebox_override("disabled", flat_disabled)
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	TooltipManager.show_tooltip(
		"Start wave!",
		"[font_size=3][color=cornflower_blue]Current Wave: " + str(int(WaveSpawner.current_wave)) + "[/color][/font_size]" + "
[color=gray]————————————————[/color]
[font_size=2][color=dark_gray]Click to start the next wave.[/color][/font_size]"
	)
	
func _on_mouse_exited() -> void:
	TooltipManager.hide_tooltip()

func _process(delta: float) -> void:
	disabled = get_tree().get_nodes_in_group("enemy").size() > 0

func _on_pressed() -> void:
	if !disabled:
		WaveSpawner.start_next_wave()
