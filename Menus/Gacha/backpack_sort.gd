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
	TooltipManager.show_tooltip("Sort by Rank", "Sorts the squad by rank, then by tower type")
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
	var inventory_size := TowerManager.get_inventory_size(is_squad)
	var offset := 1000 if is_squad else 0
	var towers: Array[Dictionary] = []
	
	for i in inventory_size:
		var index := i + offset
		var tower = TowerManager.get_tower_at(index)
		if !tower.is_empty():
			towers.append(tower)
	
	towers.sort_custom(func(a, b):
		if a.is_empty(): return false
		if b.is_empty(): return true
		var rank_a = a.get("rank", 1)
		var rank_b = b.get("rank", 1)
		if rank_a != rank_b:
			return rank_a > rank_b
		var id_a = a.get("id", "")
		var id_b = b.get("id", "")
		return id_a < id_b
	)
	
	for i in inventory_size:
		var index := i + offset
		if i < towers.size():
			TowerManager.set_tower_at(index, towers[i])
		else:
			TowerManager.set_tower_at(index, {})
