# SquadToInventoryButton.gd (fixed ID and rank)

extends Button

func _ready() -> void:
	text = "New Game"
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
	style_hover.border_color = Color(0.7, 0.7, 0.7)
	
	var style_pressed = style_normal.duplicate()
	style_pressed.bg_color = Color(0.15, 0.15, 0.15)
	style_pressed.border_color = Color(0.8, 0.8, 0.8)
	
	add_theme_stylebox_override("normal", style_normal)
	add_theme_stylebox_override("hover", style_hover)
	add_theme_stylebox_override("pressed", style_pressed)
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	const SQUAD_SIZE = 18
	InventoryManager.clear_inventory()
	
	for i in SQUAD_SIZE:
		var squad_tower = TowerManager.get_tower_at(1000 + i)
		if !squad_tower.is_empty():
			var type_data = squad_tower.type  # Full item definition
			var rank = squad_tower.merged
			
			# Find matching id
			var tower_id = "Fox"
			for key in InventoryManager.items.keys():
				if InventoryManager.items[key].texture == type_data.texture:
					tower_id = key
					break
			
			var item = {
				"id": tower_id,
				"rank": rank
			}
			
			# Find empty slot in InventoryManager
			for slot in InventoryManager.slots:
				if slot.get_meta("item", {}).is_empty():
					slot.set_meta("item", item)
					InventoryManager._update_slot(slot)
					break
	
	# Hide gacha menu
	var gacha_menu = get_tree().get_first_node_in_group("gacha_menu")
	if gacha_menu:
		gacha_menu.visible = false
	
	# Refresh visuals
	InventoryManager.refresh_inventory_highlights()
	get_tree().call_group("backpack_inventory", "refresh_all_highlights")
	get_tree().call_group("squad_inventory", "refresh_all_highlights")
