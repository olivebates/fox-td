extends Label

func _ready() -> void:pass

func _process(delta: float) -> void:
	var parent_node = get_parent()
	if not parent_node.has_meta("item_data"):
		visible = false
		parent_node.sprite.modulate = Color(1, 1, 1)
		return
	
	var data = parent_node.get_meta("item_data")
	var rank = data.get("rank", 1)
	
	var upgrade_mode_active = get_tree().get_first_node_in_group("upgrade_button").upgrade_mode
	
	var dragged_data = InventoryManager.get_current_dragged_data(parent_node)
	var is_matching = !dragged_data.is_empty() && data.id == dragged_data.id && data.rank == dragged_data.rank
	
	if is_matching:
		var merge_cost = InventoryManager.get_merge_cost(rank)
		var can_afford = StatsManager.health >= merge_cost
		text = "Costs\n" + str(int(merge_cost))
		visible = true
		parent_node.sprite.modulate = Color(2.0, 0.0, 0.0) if not can_afford else Color(1, 1, 1)
	elif upgrade_mode_active:
		var cost = InventoryManager.get_spawn_cost(rank)
		var can_afford = StatsManager.health >= cost
		text = "Costs\n" + str(int(cost))
		visible = true
		parent_node.sprite.modulate = Color(2.0, 0.0, 0.0) if not can_afford else Color(1, 1, 1)
	else:
		visible = false
		parent_node.sprite.modulate = Color(1, 1, 1)
