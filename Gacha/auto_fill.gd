# AutoSquadButton.gd
extends Button

@export var is_squad_inventory: bool = false  # Not used, but matches style

func _ready() -> void:
	text = "Fill"
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
	"Fill Squad",
	#"[color=gray]————————————————[/color]\n" +
	"[font_size=2][color=dark_gray]Moves your strongest critters in to the squad![/color][/font_size]"
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
	var all_towers: Array[Dictionary] = []
	
	# Backpack
	for i in TowerManager.BACKPACK_SIZE:
		var tower = TowerManager.get_tower_at(i)
		if !tower.is_empty():
			all_towers.append(tower)
	
	# Squad
	for i in TowerManager.SQUAD_SIZE:
		var tower = TowerManager.get_tower_at(i + 1000)
		if !tower.is_empty():
			all_towers.append(tower)
	
	# Clear inventories
	for i in TowerManager.BACKPACK_SIZE:
		TowerManager.set_tower_at(i, {})
	for i in TowerManager.SQUAD_SIZE:
		TowerManager.set_tower_at(i + 1000, {})
	
	# Calculate power_level
	for tower in all_towers:
		var id = tower.id
		var rank = tower.get("rank", 1)  # Fixed: use "rank"
		var damage = InventoryManager.get_damage_calculation(id, rank, 0)
		var attack_speed = tower.type.attack_speed
		tower.power_level = damage * attack_speed
	
	# Sort descending
	all_towers.sort_custom(func(a, b): return a.power_level > b.power_level)
	
	# Fill squad
	for i in TowerManager.SQUAD_SIZE:
		if i < all_towers.size():
			TowerManager.set_tower_at(i + 1000, all_towers[i])
		else:
			TowerManager.set_tower_at(i + 1000, {})
	
	# Remaining to backpack
	for i in range(TowerManager.SQUAD_SIZE, all_towers.size()):
		TowerManager.set_tower_at(i - TowerManager.SQUAD_SIZE, all_towers[i])
	
	# Refresh UI
	get_tree().call_group("backpack_inventory", "refresh_all_highlights")
	get_tree().call_group("squad_inventory", "refresh_all_highlights")
