extends Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_theme_font_size_override("font_size", 6)
	add_theme_color_override("font_color", Color.WHITE)
	add_theme_color_override("font_outline_color", Color.BLACK)
	add_theme_constant_override("outline_size", 1)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if StatsManager:
		text = "Level "+str(WaveSpawner.current_level)+" - (Wave "+str(WaveSpawner.current_wave)+" / "+str(WaveSpawner.max_waves)+")"
