extends Label

func _ready() -> void:
	add_theme_font_size_override("font_size", 8)
	var color_rect = get_parent().get_node("ColorRect")
	color_rect.gui_input.connect(_on_color_rect_gui_input)
	TooltipManager.hide_tooltip()
	get_tree().get_first_node_in_group("timeline")._rebuild_buttons()
	
	# Find and connect to all leave buttons
	for button in get_tree().get_nodes_in_group("leave_button"):
		if button is Button:
			button.return_to_camp_pressed.connect(_on_return_to_camp_pressed)
	

func _process(delta: float) -> void:
	if WaveSpawner.current_level == 1:
		text = "               You beat the level ⬆️


                            
                                                                 Return to camp here ⬇️ "


func _on_color_rect_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var space_state = get_viewport().world_2d.direct_space_state
		var query = PhysicsPointQueryParameters2D.new()
		query.position = event.global_position
		query.collide_with_areas = true
		var results = space_state.intersect_point(query)
		
		for result in results:
			var node = result.collider
			if node.is_in_group("timeline"):
				get_parent().queue_free()
				return


func _on_return_to_camp_pressed() -> void:
	if WaveSpawner.current_wave > WaveSpawner.MAX_WAVES:
		WaveSpawner.current_level += 1
		WaveSpawner.current_wave = 1
		GridController.change_level_color()
		StatsManager.new_map()
	else:
		StatsManager.reset_current_map()
	
	get_parent().queue_free()
