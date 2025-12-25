# AutoSquadButton.gd
extends Button

@export var is_squad_inventory: bool = false  # Not used, but matches style

func _ready() -> void:
	text = "Fill"
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
	# Collect all towers from both inventories
	var all_towers: Array[Dictionary] = []
	
	# Add backpack towers
	for i in TowerManager.BACKPACK_SIZE:
		var tower = TowerManager.get_tower_at(i)
		if !tower.is_empty():
			all_towers.append(tower)
	
	# Add squad towers
	for i in TowerManager.SQUAD_SIZE:
		var tower = TowerManager.get_tower_at(i + 1000)
		if !tower.is_empty():
			all_towers.append(tower)
	
	# Clear both inventories
	for i in TowerManager.BACKPACK_SIZE:
		TowerManager.set_tower_at(i, {})
	for i in TowerManager.SQUAD_SIZE:
		TowerManager.set_tower_at(i + 1000, {})
	
	# Calculate power_level for sorting
	for tower in all_towers:
		var id = tower.type.get("id", "Fox")
		var merged = tower.merged
		var damage = InventoryManager.get_stat_for_rank(id, "damage", merged)
		var final_damage = InventoryManager.get_damage_calculation(damage)
		var attack_speed = InventoryManager.get_stat_for_rank(id, "attack_speed", merged)
		tower.power_level = final_damage * attack_speed
	
	# Sort descending by power_level
	all_towers.sort_custom(func(a, b):
		var pa = a.get("power_level", 0)
		var pb = b.get("power_level", 0)
		if pa != pb:
			return pa > pb
		return false
	)
	
	# Fill squad with top towers
	for i in TowerManager.SQUAD_SIZE:
		if i < all_towers.size():
			TowerManager.set_tower_at(i + 1000, all_towers[i])
		else:
			TowerManager.set_tower_at(i + 1000, {})
	
	# Put remaining towers in backpack
	var remaining_start = TowerManager.SQUAD_SIZE
	for i in range(remaining_start, all_towers.size()):
		TowerManager.set_tower_at(i - remaining_start, all_towers[i])
	
	# Refresh UI
	get_tree().call_group("backpack_inventory", "refresh_all_highlights")
	get_tree().call_group("squad_inventory", "refresh_all_highlights")
