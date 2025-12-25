# ClearSquadButton.gd
extends Button

func _ready() -> void:
	text = "Clear Squad"
	focus_mode = Control.FOCUS_NONE
	add_theme_font_size_override("font_size", 4)
	
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
