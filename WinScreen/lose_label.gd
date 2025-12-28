extends Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	text = "You ran out of meat!\n\nUse the timeline to go back in time\n            v            "
	add_theme_font_size_override("font_size", 8)
	
	var color_rect = get_parent().get_node("ColorRect")
	color_rect.gui_input.connect(_on_color_rect_gui_input)
	TooltipManager.hide_tooltip()
	
var gachascreen = preload("uid://cgtxb5iesuex6")

func _on_color_rect_gui_input(event: InputEvent) -> void: pass
	#if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		#
		#if WaveSpawner.current_level == 1:
			#StatsManager.reset_current_map()
			#InventoryManager.give_starter_towers()
			#get_parent().queue_free()
			#return
		#
		#var g = gachascreen.instantiate()
		#get_tree().root.add_child(g)
		#get_parent().queue_free()
