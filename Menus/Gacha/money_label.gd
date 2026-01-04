extends Label

func _ready() -> void:
	add_theme_font_size_override("font_size", 8)
	add_theme_color_override("font_color", Color.YELLOW)
	text = "€" + str(StatsManager.money)
	add_theme_color_override("font_outline_color", Color.BLACK)
	add_theme_constant_override("outline_size", 1)

func _process(_delta: float) -> void:
	text = "🪙" + str(StatsManager.money)
