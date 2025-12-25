# GachaButton.gd
extends Button

@onready var backpack_inventory = get_tree().get_first_node_in_group("backpack_inventory")  # Adjust path if needed

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	add_theme_font_size_override("font_size", 4)
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.2, 0.2, 0.2)
	style_normal.border_width_left = 0
	style_normal.border_width_top = 0
	style_normal.border_width_right = 0
	style_normal.border_width_bottom = 0
	style_normal.corner_radius_top_left = 0
	style_normal.corner_radius_top_right = 0
	style_normal.corner_radius_bottom_left = 0
	style_normal.corner_radius_bottom_right = 0
	style_normal.content_margin_left = 3
	style_normal.content_margin_right = 3
	style_normal.content_margin_top = 0
	style_normal.content_margin_bottom = 1
	
	var style_hover = style_normal.duplicate()
	style_hover.bg_color = Color(0.3, 0.3, 0.3)
	style_hover.border_color = Color(0.7, 0.7, 0.7)
	
	var style_pressed = style_normal.duplicate()
	style_pressed.bg_color = Color(0.15, 0.15, 0.15)
	style_pressed.border_color = Color(0.8, 0.8, 0.8)
	
	add_theme_stylebox_override("normal", style_normal)
	add_theme_stylebox_override("hover", style_hover)
	add_theme_stylebox_override("pressed", style_pressed)
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	text = "Pull New Tower"
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	var keys = InventoryManager.items.keys()
	if keys.is_empty():
		return
	var random_id = keys[randi() % keys.size()]
	var tower_type = InventoryManager.items[random_id]
	var new_tower = {
		"type": tower_type,
		"merged": 1
	}
	
	var empty_index = -1
	for i in TowerManager.tower_inventory.size():
		if TowerManager.tower_inventory[i].is_empty():
			empty_index = i
			break
	
	if empty_index == -1:
		TowerManager.tower_inventory.append(new_tower)
	else:
		TowerManager.tower_inventory[empty_index] = new_tower
	
	backpack_inventory._rebuild_slots()
