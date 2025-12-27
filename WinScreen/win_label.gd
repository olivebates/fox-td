extends Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	text = "You beat level " + str(WaveSpawner.current_level-1) + "!\nGood job!!!🥳"
	var color_rect = get_parent().get_node("ColorRect")
	color_rect.gui_input.connect(_on_color_rect_gui_input)
	TooltipManager.hide_tooltip()

var gachascreen = preload("uid://cgtxb5iesuex6")


func _on_color_rect_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		GridController.change_level_color()
		var g = gachascreen.instantiate()
		get_tree().root.add_child(g)
		get_parent().queue_free()
