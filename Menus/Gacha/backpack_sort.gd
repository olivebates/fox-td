extends Button
@export var is_squad_inventory: bool = false
func _ready() -> void:
	text = "Sort"
	focus_mode = Control.FOCUS_NONE
	add_theme_font_size_override("font_size", 4)
	add_theme_color_override("font_outline_color", Color.BLACK)
	add_theme_constant_override("outline_size", 1)
	
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.2, 0.2, 0.2)
	style_normal.content_margin_left = 3
	style_normal.content_margin_right = 3
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
	TooltipManager.show_tooltip("Sort by Rarity", "Sorts by rarity, rank, then DPS (lower DPS first).")
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
	# Sort squad inventory (offset 1000)
	sort_inventory(true)
	# Sort backpack inventory (offset 0)
	sort_inventory(false)
	
	get_tree().call_group("backpack_inventory", "refresh_all_highlights")
	get_tree().call_group("squad_inventory", "refresh_all_highlights")

func sort_inventory(is_squad: bool) -> void:
	var inventory_size = TowerManager.get_inventory_size(is_squad)
	var offset = 1000 if is_squad else 0
	var unlocked_size = inventory_size
	if is_squad:
		unlocked_size = TowerManager.get_unlocked_squad_size()
	var towers: Array[Dictionary] = []
	
	for i in inventory_size:
		var index = i + offset
		var tower = TowerManager.get_tower_at(index)
		if !tower.is_empty():
			towers.append(tower)
	
	towers.sort_custom(_compare_towers)
	
	for i in inventory_size:
		var index = i + offset
		if i >= unlocked_size:
			TowerManager.set_tower_at(index, {})
			continue
		if i < towers.size():
			TowerManager.set_tower_at(index, towers[i])
		else:
			TowerManager.set_tower_at(index, {})

func _get_tower_rarity(tower: Dictionary) -> int:
	var type_data = tower.get("type", {})
	if !type_data.is_empty():
		return int(type_data.get("rarity", 0))
	var id = tower.get("id", "")
	if id == "":
		return 0
	return int(InventoryManager.items.get(id, {}).get("rarity", 0))

func _get_tower_dps(tower: Dictionary) -> float:
	var id = tower.get("id", "")
	if id == "":
		return INF
	var def = InventoryManager.items.get(id, {})
	if def.is_empty():
		return INF
	var path = tower.get("path", [0, 0, 0])
	var rank = int(tower.get("rank", 1))
	var stats = InventoryManager.get_tower_stats(id, rank, path)
	var dps = 0.0
	if id == "Turtle":
		dps = InventoryManager._get_turtle_effective_dps(stats, path)
	elif id == "Snail":
		dps = InventoryManager._get_snail_effective_dps(stats, path)
	elif id == "Snake":
		dps = InventoryManager._get_snake_effective_dps(stats, path)
	elif id == "Starfish":
		dps = InventoryManager._get_starfish_effective_dps(path)
	elif def.get("is_guard", false):
		var creature_damage = float(stats.get("creature_damage", 0.0))
		var creature_speed = float(stats.get("creature_attack_speed", 0.0))
		var creature_count = float(stats.get("creature_count", 0.0))
		dps = creature_damage * creature_speed * max(1.0, creature_count)
	else:
		var damage = float(stats.get("damage", 0.0))
		var attack_speed = float(stats.get("attack_speed", 0.0))
		var bullets = float(stats.get("bullets", 0.0))
		dps = damage * attack_speed * bullets
	if def.has("dps_multiplier"):
		dps *= float(def.get("dps_multiplier", 1.0))
	return dps

func _compare_towers(a: Dictionary, b: Dictionary) -> bool:
	if a.is_empty():
		return false
	if b.is_empty():
		return true
	var rarity_a = _get_tower_rarity(a)
	var rarity_b = _get_tower_rarity(b)
	if rarity_a != rarity_b:
		return rarity_a > rarity_b
	var rank_a = int(a.get("rank", 1))
	var rank_b = int(b.get("rank", 1))
	if rank_a != rank_b:
		return rank_a > rank_b
	var dps_a = _get_tower_dps(a)
	var dps_b = _get_tower_dps(b)
	if dps_a != dps_b:
		return dps_a < dps_b
	var id_a = a.get("id", "")
	var id_b = b.get("id", "")
	return id_a < id_b
