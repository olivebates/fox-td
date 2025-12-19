extends Button

func _ready():
	pressed.connect(_on_pressed)
	WaveSpawner.wave_completed.connect(func(): disabled = false)
	disabled = false

func _on_pressed():
	WaveSpawner.start_next_wave()
	disabled = true
