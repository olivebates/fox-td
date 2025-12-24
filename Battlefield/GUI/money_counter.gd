extends Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_theme_font_size_override("font_size", 4)
	add_theme_color_override("font_color", Color.YELLOW)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if StatsManager:
		text = "€"+str(StatsManager.money)
