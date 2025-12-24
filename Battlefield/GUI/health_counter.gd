extends Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_theme_font_size_override("font_size", 3)
	add_theme_color_override("font_color", Color.PINK)
	add_theme_constant_override("outline_size", 1)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	text = "Meat: " #+ str(int(StatsManager.health))
