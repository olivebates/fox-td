# TowerManager.gd (Singleton - Autoload)

extends Node

var tower_inventory: Array[Dictionary] = []
var squad_slots: Array[Dictionary] = []  # Size 18
var SQUAD_SIZE: int = 18
var BACKPACK_SIZE: int = 7*6
var pull_cost_base = 40
var pull_cost = pull_cost_base
var cost_increase = 10
func _ready() -> void:
	tower_inventory.clear()
	tower_inventory.resize(BACKPACK_SIZE)
	for i in BACKPACK_SIZE:
		tower_inventory[i] = {}
	
	# Example: add test towers using updated function
	tower_inventory[0] = _create_tower("Fox", 1)
	
	squad_slots.clear()
	squad_slots.resize(SQUAD_SIZE)
	for i in SQUAD_SIZE:
		squad_slots[i] = {}
	
	squad_slots[0] = _create_tower("Fox", 1)
	squad_slots[1] = _create_tower("Fox", 1)

func _create_tower(id: String, rank: int, path_levels: Array = [0, 0, 0]) -> Dictionary:
	var type_data = InventoryManager.items.get(id, {})
	if type_data.is_empty():
		return {}
	
	var stats = InventoryManager.get_tower_stats(id, rank, path_levels)
	var damage = stats.creature_damage if type_data.get("is_guard", false) else stats.damage
	var attack_speed = stats.creature_attack_speed if type_data.get("is_guard", false) else stats.attack_speed
	var dps = damage * attack_speed
	
	return {
		"type": type_data,
		"rank": rank,
		"path": path_levels.duplicate(),
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

func clear_backpack() -> void:
	tower_inventory.clear()
	tower_inventory.resize(BACKPACK_SIZE)
	for i in BACKPACK_SIZE:
		tower_inventory[i] = {}

func clear_squad() -> void:
	squad_slots.clear()
	squad_slots.resize(SQUAD_SIZE)
	for i in SQUAD_SIZE:
		squad_slots[i] = {}
