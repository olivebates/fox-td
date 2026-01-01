# SquadToInventoryButton.gd (fixed ID and rank)

extends Button

func _ready() -> void:
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
	style_hover.border_color = Color(0.7, 0.7, 0.7)
	
	var style_pressed = style_normal.duplicate()
	style_pressed.bg_color = Color(0.15, 0.15, 0.15)
	style_pressed.border_color = Color(0.8, 0.8, 0.8)
	
	add_theme_stylebox_override("normal", style_normal)
	add_theme_stylebox_override("hover", style_hover)
	add_theme_stylebox_override("pressed", style_pressed)
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	TooltipManager.show_tooltip(
	"Start Level: " +str(WaveSpawner.current_level),
	#"[color=gray]————————————————[/color]\n" +
	"[font_size=2][color=dark_gray]Starts a new round!\nMake sure you bring some low-tier towers for the first few waves :)[/color][/font_size]"
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

func _process(delta: float) -> void:
	text = "Start Level "+str(WaveSpawner.current_level)

func _on_pressed() -> void:
	const SQUAD_SIZE = 18
	
	
	var guards = get_tree().get_nodes_in_group("guard")
	for node in guards:
		node.queue_free()
		
	GridController.change_level_color()
	if WaveSpawner.hint_label:
		WaveSpawner.hint_label.queue_free()
	
	get_tree().get_first_node_in_group("game_area").visible = true
	InventoryManager.clear_inventory()
	
	for i in SQUAD_SIZE:
		var squad_tower = TowerManager.get_tower_at(1000 + i)
		if !squad_tower.is_empty():
			var type_data = squad_tower.type  # Full item definition
			var rank = squad_tower.get("rank", 1)
			
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
	var gacha_menu = get_tree().get_first_node_in_group("menu")
	gacha_menu.queue_free()
	
	# Refresh visuals
	InventoryManager.refresh_inventory_highlights()
	get_tree().call_group("backpack_inventory", "refresh_all_highlights")
	get_tree().call_group("squad_inventory", "refresh_all_highlights")
	WaveSpawner.current_wave = 1
	TimelineManager.save_timeline(0)
	
