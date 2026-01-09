extends Label

const UPDATE_INTERVAL := 0.1
var _update_accum: float = 0.0
var _last_level: int = -1
var _last_wave: int = -1
var _last_max_waves: int = -1

func _update_text() -> void:
	if StatsManager == null:
		return
	var level = WaveSpawner.current_level
	var wave := WaveSpawner.current_wave
	var max_waves = WaveSpawner.MAX_WAVES
	if level == _last_level and wave == _last_wave and max_waves == _last_max_waves:
		return
	_last_level = level
	_last_wave = wave
	_last_max_waves = max_waves
	text = "Level " + str(level) + " - (Wave " + str(wave) + " / " + str(max_waves) + ")"
	if wave > max_waves:
		text += " Cleared!"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_theme_font_size_override("font_size", 6)
	add_theme_color_override("font_color", Color.WHITE)
	add_theme_color_override("font_outline_color", Color.BLACK)
	add_theme_constant_override("outline_size", 1)
	_update_text()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_update_accum += delta
	if _update_accum < UPDATE_INTERVAL:
		return
	_update_accum = 0.0
	_update_text()
