# DragPreview.gd (updated for +1 pixel growth)
extends Control

func _ready() -> void:
	custom_minimum_size = Vector2(10, 10)  # 8 + 2

func _draw() -> void:
	if InventoryManager.original_slot == null:
		return
	var item = InventoryManager.dragged_item
	if item.is_empty():
		return
	
	var rank = item.get("rank", 0)
	var border_color = InventoryManager.RANK_COLORS.get(rank, Color(1, 1, 1))
	
	# Larger rank border (1px around 10x10)
	draw_rect(Rect2(0.5, 0.5, 9, 9), border_color, false, 1.0)
	
	# Dark background (8x8 centered)
	draw_rect(Rect2(1, 1, 8, 8), Color(0.1, 0.1, 0.1), true)
	
	# Icon centered (original 8x8 size)
	var tex = InventoryManager.items[item.id].texture
	if tex:
		draw_texture(tex, Vector2(1, 1))
