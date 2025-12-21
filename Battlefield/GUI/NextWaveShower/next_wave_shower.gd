extends Label

func _ready():
	add_theme_font_size_override("font_size", 4)  # Font size 44 for visual "font 4" effect
	

func _process(d):
	text = "Next Wave Health: " + str(WaveSpawner.next_wave_health)
	
