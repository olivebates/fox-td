extends StaticBody2D

var hovered: bool = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and get_global_mouse_position().distance_to(global_position) < 4:
		hovered = true
	else:
		hovered = false
	queue_redraw()

func _exit_tree() -> void:
	hovered = false

func _draw() -> void:
	if not has_meta("item_data"):
		return
	var data = get_meta("item_data")
	var rank = data.get("rank", 0)
	var border_color = InventoryManager.RANK_COLORS.get(rank, Color(1, 1, 1))
	var base_color = border_color * 0.3  # Darker version of rank color
	base_color.a = 1.0
	
	var brighten = 1.4 if hovered else 1.0
	var bg_color = base_color * brighten
	
	draw_rect(Rect2(-3.2, -3.2, 6.5, 6.5), border_color, false, 1.0 + (0.5 if hovered else 0.0))
	draw_rect(Rect2(-3, -3, 6, 6), bg_color, true)
	
	for child in get_children():
		if child is Sprite2D:
			child.modulate = Color(1.4, 1.4, 1.4) if hovered else Color(1, 1, 1)

func _ready() -> void:
	input_pickable = false
