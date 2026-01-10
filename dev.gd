extends Node

var dev = true
var unlock_all_towers_and_fill_inventory = true

var _unlock_all_applied = false

func _process(_delta: float) -> void:
	await get_tree().process_frame
	if !unlock_all_towers_and_fill_inventory:
		_unlock_all_applied = false
		return
	if _unlock_all_applied:
		return
	if InventoryManager.slots.is_empty():
		return
	_unlock_all_applied = true
	_apply_unlock_all()

func _apply_unlock_all() -> void:
	for tower_id in InventoryManager.items.keys():
		InventoryManager.items[tower_id]["unlocked"] = true
	InventoryManager.clear_inventory()
	var slot_index = 0
	for tower_id in InventoryManager.items.keys():
		if slot_index >= InventoryManager.slots.size():
			break
		var item = {
			"id": tower_id,
			"rank": 1,
			"colors": InventoryManager.roll_tower_colors(),
			"merge_children": []
		}
		InventoryManager.slots[slot_index].set_meta("item", item)
		InventoryManager._update_slot(InventoryManager.slots[slot_index])
		slot_index += 1
