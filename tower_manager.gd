# TowerManager.gd (Singleton - Autoload)

extends Node

var tower_inventory: Array[Dictionary] = []
var squad_slots: Array[Dictionary] = []  # Size 18
var SQUAD_SIZE: int = 18
var BACKPACK_SIZE: int = 7*6
var pull_cost = 40
var cost_increase = 10
func _ready() -> void:
	tower_inventory.clear()
	tower_inventory.resize(BACKPACK_SIZE)
	for i in BACKPACK_SIZE:
		tower_inventory[i] = {}
	
	# Example: add 3 test towers
	tower_inventory[0] = _create_tower("Fox", 1)
	
	# Squad setup remains unchanged
	squad_slots.clear()
	squad_slots.resize(SQUAD_SIZE)
	for i in SQUAD_SIZE:
		squad_slots[i] = {}
	squad_slots[0] = _create_tower("Fox", 1)
	squad_slots[1] = _create_tower("Fox", 1)
	#squad_slots[2] = _create_tower("Fox", 1)

func _create_tower(id: String, rank: int) -> Dictionary:
	var type_data = InventoryManager.items.get(id, {})
	if type_data.is_empty():
		return {}
	var damage = InventoryManager.get_damage_calculation(id, rank, 0)  # path[0] = 0 initially
	var dps = damage * type_data.attack_speed
	return {
		"type": type_data,
		"rank": rank,
		"power_level": dps,
		"id": id
	}

func is_squad_index(index: int) -> bool:
	return index >= 1000

func get_tower_at(index: int) -> Dictionary:
	if is_squad_index(index):
		var squad_idx = index - 1000
		if squad_idx < squad_slots.size():
			return squad_slots[squad_idx]
	else:
		if index < tower_inventory.size():
			return tower_inventory[index]
	return {}

func set_tower_at(index: int, tower: Dictionary) -> void:
	if is_squad_index(index):
		var squad_idx = index - 1000
		if squad_idx < squad_slots.size():
			squad_slots[squad_idx] = tower
	else:
		if index < tower_inventory.size():
			tower_inventory[index] = tower
		else:
			while tower_inventory.size() <= index:
				tower_inventory.append({})
			tower_inventory[index] = tower

func get_inventory_size(is_squad: bool) -> int:
	if is_squad:
		return SQUAD_SIZE
	else:
		return BACKPACK_SIZE  # Fixed 28 slots
