extends Button

var delete_mode: bool = false

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	toggle_mode = true
	toggled.connect(_on_toggled)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	TooltipManager.show_tooltip(
		"Delete Buildables",
		"[font_size=3][color=red]Click on a wall or tower to remove it[/color][/font_size]\n[color=gray]————————————————[/color]\n[color=dark_gray]No refund. Permanent removal.[/color]"
	)

func _on_mouse_exited() -> void:
	TooltipManager.hide_tooltip()

func _on_toggled(pressed: bool) -> void:
	delete_mode = pressed
	GridController.delete_mode = pressed
	GridController.queue_redraw()
