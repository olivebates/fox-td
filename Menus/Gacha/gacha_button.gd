# GachaButton.gd
extends Button

@onready var backpack_inventory = get_tree().get_first_node_in_group("backpack_inventory")
var hint_flag = false
var original_pos = position

func _ready() -> void:

	
	focus_mode = Control.FOCUS_NONE
	add_theme_font_size_override("font_size", 4)
	add_theme_color_override("font_outline_color", Color.BLACK)
	add_theme_constant_override("outline_size", 1)
	
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(1.0, 0.5, 0.0)  # Orange
	style_normal.content_margin_left = 3
	style_normal.content_margin_right = 3
	style_normal.content_margin_top = 0
	style_normal.content_margin_bottom = 1
	
	var style_hover = style_normal.duplicate()
	style_hover.bg_color = Color(1.0, 0.6, 0.2)   # Lighter orange
	
	var style_pressed = style_normal.duplicate()
	style_pressed.bg_color = Color(0.8, 0.4, 0.0) # Darker orange
	style_pressed.border_color = Color(0.9, 0.5, 0.1)
	
	add_theme_stylebox_override("normal", style_normal)
	add_theme_stylebox_override("hover", style_hover)
	add_theme_stylebox_override("pressed", style_pressed)
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	text = "Pull New Critter (🪙" + str(TowerManager.pull_cost) + ")"
	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _on_mouse_entered() -> void:
	TooltipManager.show_tooltip(
		"Pull Towers!",
        "[font_size=2][color=dark_gray]Costs 🪙 to create a new critter in your camp!\nDrag critters from the Camp to the Squad to use them![/color][/font_size]"
	)

func _on_mouse_exited() -> void:
	TooltipManager.hide_tooltip()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			position += Vector2(1, 1)
			$ColorRect.visible = false
		else:
			position -= Vector2(1, 1)
			$ColorRect.visible = true

func _on_pressed() -> void:
		
	if StatsManager.money < TowerManager.pull_cost:
		Utilities.spawn_floating_text("Not enough 🪙...", Vector2.ZERO, null)
		return
	StatsManager.money -= TowerManager.pull_cost
	TowerManager.pull_cost += TowerManager.cost_increase
	text = "Pull New Critter (🪙" + str(TowerManager.pull_cost) + ")"

	var rarity: int = 1 if randf() < 0.6 else 2
	var possible: Array[String] = []
	for id in InventoryManager.items.keys():
		if InventoryManager.items[id].rarity == rarity:
			possible.append(id)
	
	if possible.is_empty():
		return
	
	var random_id: String = possible[randi() % possible.size()]
	
	if (TowerManager.pull_cost == TowerManager.pull_cost_base + TowerManager.cost_increase):
		random_id = "Duck"
	if (TowerManager.pull_cost == TowerManager.pull_cost_base + TowerManager.cost_increase*2):
		random_id = "Hawk"
	var was_unlocked := false
	if InventoryManager.items.has(random_id):
		was_unlocked = bool(InventoryManager.items[random_id].get("unlocked", false))
		if !was_unlocked:
			InventoryManager.items[random_id]["unlocked"] = true
	var new_tower = TowerManager._create_tower(random_id, 1)
	
	var empty_index = -1
	for i in TowerManager.tower_inventory.size():
		if TowerManager.tower_inventory[i].is_empty():
			empty_index = i
			break
	if empty_index == -1:
		TowerManager.tower_inventory.append(new_tower)
	else:
		TowerManager.tower_inventory[empty_index] = new_tower
	
	if WaveSpawner.current_level > 3:
		hint_flag = true
	
	if !hint_flag:
		hint_flag = true
		for child in get_children():
			if child is Label:
				child.queue_free()
	
	backpack_inventory._rebuild_slots()
	var upgrade_menu = get_tree().get_first_node_in_group("upgrade_menu")
	if upgrade_menu:
		upgrade_menu.refresh_unlocked_towers()
