extends StaticBody2D

func _draw() -> void:
	if not has_meta("item_data"):
		return
	var data = get_meta("item_data")
	var rank = data.get("rank", 0)
	var border_color = InventoryManager.RANK_COLORS.get(rank, Color(1, 1, 1))
	draw_rect(Rect2(-4, -4, 8, 8), border_color, false, 1.0)

func _ready() -> void:
	input_pickable = false
