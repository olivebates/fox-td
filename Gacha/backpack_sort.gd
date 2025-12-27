# InventorySorter.gd (updated with matching style)

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
	
	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	TooltipManager.show_tooltip(
	"Sort by Power",
	#"[color=gray]————————————————[/color]\n" +
	"[font_size=2][color=dark_gray]Sorts your critters from strongest to weakest![/color][/font_size]"
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
	var inventory_size := TowerManager.get_inventory_size(is_squad_inventory)
	var offset := 1000 if is_squad_inventory else 0
	var towers: Array[Dictionary] = []
	
	for i in inventory_size:
		var index := i + offset
		var tower = TowerManager.get_tower_at(index)
		if !tower.is_empty():
			var id = tower.id
			var rank = tower.get("rank", 1)  # Fixed: use "rank"
			var damage = InventoryManager.get_damage_calculation(id, rank, 0)
			var attack_speed = tower.type.attack_speed
			tower.power_level = damage * attack_speed
			towers.append(tower)
	
	towers.sort_custom(func(a, b):
		if a.is_empty() and b.is_empty(): return false
		if a.is_empty(): return false
		if b.is_empty(): return true
		var pa = a.get("power_level", 0)
		var pb = b.get("power_level", 0)
		if pa != pb:
			return pa > pb
		var ta = a.type.get("texture", null)
		var tb = b.type.get("texture", null)
		if ta and tb:
			return ta.resource_path < tb.resource_path
		return false
	)
	
	for i in inventory_size:
		var index := i + offset
		if i < towers.size():
			TowerManager.set_tower_at(index, towers[i])
		else:
			TowerManager.set_tower_at(index, {})
	
	get_tree().call_group("backpack_inventory", "refresh_all_highlights")
	get_tree().call_group("squad_inventory", "refresh_all_highlights")
