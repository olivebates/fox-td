# CreateObjectButton.gd
extends Button

var has_been_unlocked = false
const UNLOCK_CHECK_INTERVAL := 0.2
var _unlock_accum: float = 0.0
const RETURN_TO_CAMP_SCENE := preload("uid://cda7be4lkl7n8")
func _process(delta: float) -> void:
	if has_been_unlocked:
		return
	_unlock_accum += delta
	if _unlock_accum < UNLOCK_CHECK_INTERVAL:
		return
	_unlock_accum = 0.0
	if WaveSpawner.current_wave > 6:
		has_been_unlocked = true
		visible = true

func _ready() -> void:
	text = "Return to Camp"
	focus_mode = Control.FOCUS_NONE
	disabled = false
	pressed.connect(_on_pressed)
	add_theme_font_size_override("font_size", 3)
	
	# Remove corner rounding
	add_theme_constant_override("corner_radius_top_left", 0)
	add_theme_constant_override("corner_radius_top_right", 0)
	add_theme_constant_override("corner_radius_bottom_right", 0)
	add_theme_constant_override("corner_radius_bottom_left", 0)
	
	# Minimal padding
	add_theme_constant_override("h_separation", 0)
	add_theme_color_override("font_outline_color", Color.BLACK)
	add_theme_constant_override("outline_size", 1)
	
	# Flat styleboxes
	var flat_normal := StyleBoxFlat.new()
	flat_normal.bg_color = Color(0.2, 0.2, 0.2)
	flat_normal.content_margin_left = 4
	flat_normal.content_margin_right = 4
	flat_normal.content_margin_top = 2
	flat_normal.content_margin_bottom = 2
	
	var flat_hover := StyleBoxFlat.new()
	flat_hover.bg_color = Color(0.3, 0.3, 0.3)
	flat_hover.content_margin_left = 4
	flat_hover.content_margin_right = 4
	flat_hover.content_margin_top = 2
	flat_hover.content_margin_bottom = 2
	
	var flat_pressed := StyleBoxFlat.new()
	flat_pressed.bg_color = Color(0.1, 0.1, 0.1)
	flat_pressed.content_margin_left = 4
	flat_pressed.content_margin_right = 4
	flat_pressed.content_margin_top = 2
	flat_pressed.content_margin_bottom = 2
	
	var flat_disabled := StyleBoxFlat.new()
	flat_disabled.bg_color = Color(0.15, 0.15, 0.15)
	flat_disabled.content_margin_left = 4
	flat_disabled.content_margin_right = 4
	flat_disabled.content_margin_top = 2
	flat_disabled.content_margin_bottom = 2
	
	add_theme_stylebox_override("normal", flat_normal)
	add_theme_stylebox_override("hover", flat_hover)
	add_theme_stylebox_override("pressed", flat_pressed)
	add_theme_stylebox_override("disabled", flat_disabled)
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			position += Vector2(1, 1)
			$ColorRect.visible = false
		else:
			position -= Vector2(1, 1)
			$ColorRect.visible = true

func _on_mouse_entered() -> void:
	TooltipManager.show_tooltip("Return to camp", "Ends the current round.")

func _on_mouse_exited() -> void:
	TooltipManager.hide_tooltip()

signal return_to_camp_pressed
func _on_pressed() -> void:
	return_to_camp_pressed.emit()
	if (WaveSpawner.current_wave > WaveSpawner.MAX_WAVES):
		WaveSpawner.current_level += 1
		WaveSpawner.current_wave = 1
		GridController.change_level_color()
		WaveSpawner.reset_wave_data()
		StatsManager.new_map()
	else:
		StatsManager.reset_current_map()
	var inst = RETURN_TO_CAMP_SCENE.instantiate()
	get_tree().current_scene.add_child(inst)
	TooltipManager.hide_tooltip()
