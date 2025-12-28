extends Control

@onready var hbox: HBoxContainer = HBoxContainer.new()
var hbox_width = Vector2(176, 0)

func _ready() -> void:
	hbox.custom_minimum_size = hbox_width
	hbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.clip_contents = true
	hbox.add_theme_constant_override("separation", 0)
	add_child(hbox)
	_rebuild_buttons()
	TimelineManager.saves_changed.connect(_rebuild_buttons)

func _rebuild_buttons() -> void:
	for child in hbox.get_children():
		child.queue_free()
	
	var count = TimelineManager.timeline_saves.size()
	if count == 0:
		return
	
	var btn_width = hbox_width.x / count
	var current_index = TimelineManager.current_wave_index  # Assumed property
	
	for i in count:
		var btn := Button.new()
		btn.text = " Wave %d" % (i + 1)
		btn.add_theme_font_size_override("font_size", 2)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_constant_override("v_separation", 0)
		btn.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		btn.custom_minimum_size = Vector2(btn_width, 2)
		btn.add_theme_color_override("font_color", Color.BLACK)
		btn.add_theme_color_override("font_hover_color", Color.BLACK)
		btn.add_theme_color_override("font_pressed_color", Color.BLACK)
		btn.add_theme_color_override("font_focus_color", Color.BLACK)
		
		btn.pressed.connect(func():
			TimelineManager.load_timeline(i)
			var lose_screen = get_tree().get_first_node_in_group("lose_screen")
			if lose_screen:
				lose_screen.queue_free()
		)
		
		btn.mouse_entered.connect(func():
			var times = TimelineManager.wave_replay_counts.get(i, 0)
			var penalty_text = ""
			if times > 0:
				penalty_text = "\n[color=red]-" + str(times) + " money per enemy[/color]"
			TooltipManager.show_tooltip(
				"Return to Wave " + str(i + 1),
				"Winds back time to a previously completed wave."
			)
		)
		btn.mouse_exited.connect(func():
			TooltipManager.hide_tooltip()
		)
		
		var font = btn.get_theme_font("font", "Button")
		var font_size = btn.get_theme_font_size("font_size", "Button")
		var text_width = font.get_string_size(btn.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var padding = btn.get_theme_constant("h_separation", "Button") * 2
		var available = btn_width - padding - 2
		if text_width > available:
			btn.text = "%d" % (i + 1)
			btn.clip_text = false
		
		var tint = GridController.random_tint
		var darkening = 0.5
		var sat_boost = -0.1
		
		var normal := StyleBoxFlat.new()
		var hover := StyleBoxFlat.new()
		var pressed := StyleBoxFlat.new()
		
		var normal_tint = tint
		normal_tint.s = clamp(tint.s + sat_boost, 0.0, 1.0)
		var hover_tint = tint.lightened(darkening - 0.1)
		hover_tint.s = clamp(tint.s + sat_boost + 0.05, 0.0, 1.0)
		var pressed_tint = tint.darkened(darkening + 0.1)
		
		if i == current_index:
			# Subtle hue shift highlight
			if i == current_index:
				darkening -= 0.3
				sat_boost += 0.1
			else:
				darkening -= 0.3
				sat_boost += -0.1
				
		# Normal styling
		normal.bg_color = normal_tint.darkened(darkening)
		normal.border_color = normal_tint.darkened(darkening + 0.2)
		normal.border_width_left = 1
		normal.border_width_right = 1
		normal.border_width_top = 1
		normal.border_width_bottom = 1
		
		hover.bg_color = hover_tint
		hover.border_color = normal_tint.darkened(darkening + 0.2)
		hover.border_width_left = 1
		hover.border_width_right = 1
		hover.border_width_top = 1
		hover.border_width_bottom = 1
		
		pressed.bg_color = pressed_tint
		pressed.border_color = normal_tint.darkened(darkening + 0.2)
		pressed.border_width_left = 1
		pressed.border_width_right = 1
		pressed.border_width_top = 1
		pressed.border_width_bottom = 1
		
		btn.add_theme_stylebox_override("normal", normal)
		btn.add_theme_stylebox_override("hover", hover)
		btn.add_theme_stylebox_override("pressed", pressed)
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		
		hbox.add_child(btn)
