# Gacha.gd (updated)
extends Node

var pull_cost: int = 10
var unlocked_levels: Dictionary = {}  # "tower1": 1, etc.
var items

signal item_pulled(id: String, is_new: bool)

func _ready() -> void:
	# Automatically populate from InventoryManager items
	var item_keys = InventoryManager.items.keys()
	items = item_keys.duplicate()

func pull() -> bool:
	if StatsManager.money < pull_cost:
		return false
	StatsManager.money -= pull_cost
	pull_cost += 10
	
	if items.is_empty():
		return false
	
	var id: String = items[randi() % items.size()]
	
	var was_unlocked: bool = InventoryManager.items[id].unlocked
	var is_new: bool = !was_unlocked
	
	if is_new:
		InventoryManager.items[id].unlocked = true
	
	if !unlocked_levels.has(id):
		unlocked_levels[id] = 1
	else:
		unlocked_levels[id] += 1
	
	item_pulled.emit(id, is_new)
	return true
