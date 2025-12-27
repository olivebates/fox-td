# ClearSquadButton.gd
extends Button

func _ready() -> void:
	text = "Clear"
	focus_mode = Control.FOCUS_NONE
	add_theme_font_size_override("font_size", 4)
	add_theme_color_override("font_outline_color", Color.BLACK)
	add_theme_constant_override("outline_size", 1)
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.2, 0.2, 0.2)
	style_normal.content_margin_left = 3
	style_normal.content_margin_right = 3
	style_normal.content_margin_top = 0
	style_normal.content_margin_bottom = 1
	
	var style_hover = style_normal.duplicate()
	style_hover.bg_color = Color(0.3, 0.3, 0.3)
	
	var style_pressed = style_normal.duplicate()
	style_pressed.bg_color = Color(0.15, 0.15, 0.15)
	
	add_theme_stylebox_override("normal", style_normal)
	add_theme_stylebox_override("hover", style_hover)
	add_theme_stylebox_override("pressed", style_pressed)
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	TooltipManager.show_tooltip(
	"Clear Squad",
	#"[color=gray]————————————————[/color]\n" +
	"[font_size=2][color=dark_gray]Move all your critters from the squad into the camp![/color][/font_size]"
	)

func _on_mouse_exited() -> void:
	TooltipManager.hide_tooltip()

#Press into shadow
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			position += Vector2(1, 1)
			$ColorRect.visible = false
		else:
			position -= Vector2(1, 1)
			$ColorRect.visible = true

func _on_pressed() -> void:
	# Move all squad towers to backpack (append to first empty slots)
	var backpack_size = TowerManager.BACKPACK_SIZE
	var next_backpack_index = 0
	
	for i in TowerManager.SQUAD_SIZE:
		var tower = TowerManager.get_tower_at(i + 1000)
		if !tower.is_empty():
			# Find next empty backpack slot
			while next_backpack_index < backpack_size:
				if TowerManager.get_tower_at(next_backpack_index).is_empty():
					TowerManager.set_tower_at(next_backpack_index, tower)
					next_backpack_index += 1
					break
				next_backpack_index += 1
		# Clear squad slot
		TowerManager.set_tower_at(i + 1000, {})
	
	# Refresh UI
	get_tree().call_group("backpack_inventory", "refresh_all_highlights")
	get_tree().call_group("squad_inventory", "refresh_all_highlights")
