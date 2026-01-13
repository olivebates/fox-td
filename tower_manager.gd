# TowerManager.gd (Singleton - Autoload)

extends Node

var tower_inventory: Array[Dictionary] = []
var squad_slots: Array[Dictionary] = []  # Size 18
var SQUAD_SIZE: int = 18
var BACKPACK_SIZE: int = 12*5
var pull_cost_base = 10
var pull_cost = pull_cost_base
var cost_increase = 10
const SQUAD_UNLOCK_DEFAULT = 6
const SQUAD_UNLOCK_COST_BASE = 300
const SQUAD_UNLOCK_COST_STEP = 300
var squad_unlocked_slots = SQUAD_UNLOCK_DEFAULT
@onready var inventory = get_node("/root/InventoryManager")
func _ready() -> void:
	tower_inventory.clear()
	tower_inventory.resize(BACKPACK_SIZE)
	for i in BACKPACK_SIZE:
		tower_inventory[i] = {}
	
	# Example: add test towers using updated function
	var backpack_tower = _create_tower("Fox", 1)
	backpack_tower["colors"] = ["red"]
	tower_inventory[0] = backpack_tower
	#add_all_towers_to_backpack()
	squad_slots.clear()
	squad_slots.resize(SQUAD_SIZE)
	for i in SQUAD_SIZE:
		squad_slots[i] = {}
	
	var squad_tower_a = _create_tower("Fox", 1)
	squad_tower_a["colors"] = ["blue"]
	squad_slots[0] = squad_tower_a
	var squad_tower_b = _create_tower("Fox", 1)
	squad_tower_b["colors"] = ["green"]
	squad_slots[1] = squad_tower_b
	_clamp_squad_unlocks()

func add_all_towers_to_backpack() -> void:
	var index = 1
	for id in inventory.items.keys():
		var tower1 = _create_tower(id, 1)
		var tower2 = _create_tower(id, 2)
		var tower3 = _create_tower(id, 3)
		var tower4 = _create_tower(id, 4)
		var tower5 = _create_tower(id, 5)
		while index < tower_inventory.size():
			if tower_inventory[index].is_empty():
				tower_inventory[index] = tower1
				index += 1
				tower_inventory[index] = tower2
				index += 1
				tower_inventory[index] = tower3
				index += 1
				tower_inventory[index] = tower4
				index += 1
				tower_inventory[index] = tower5
				index += 1
				break
			index += 1

func _create_tower(id: String, rank: int, path_levels: Array = [0, 0, 0]) -> Dictionary:
	var type_data = inventory.items.get(id, {})
	if type_data.is_empty():
		return {}
	
	var stats = inventory.get_tower_stats(id, rank, path_levels)
	var damage = stats.creature_damage if type_data.get("is_guard", false) else stats.damage
	var attack_speed = stats.creature_attack_speed if type_data.get("is_guard", false) else stats.attack_speed
	var dps = damage * attack_speed
	
	return {
		"type": type_data,
		"rank": rank,
		"path": path_levels.duplicate(),
		"power_level": dps,
		"id": id,
		"colors": inventory.roll_tower_colors(),
		"merge_children": []
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

func _clamp_squad_unlocks() -> void:
	var min_unlocked = min(SQUAD_UNLOCK_DEFAULT, SQUAD_SIZE)
	squad_unlocked_slots = int(clamp(squad_unlocked_slots, min_unlocked, SQUAD_SIZE))

func get_unlocked_squad_size() -> int:
	_clamp_squad_unlocks()
	return squad_unlocked_slots

func is_squad_slot_unlocked(index: int) -> bool:
	_clamp_squad_unlocks()
	return index >= 0 and index < squad_unlocked_slots

func can_unlock_squad_slot() -> bool:
	_clamp_squad_unlocks()
	return squad_unlocked_slots < SQUAD_SIZE

func get_next_squad_unlock_cost() -> int:
	if !can_unlock_squad_slot():
		return 0
	var steps = squad_unlocked_slots - SQUAD_UNLOCK_DEFAULT
	return SQUAD_UNLOCK_COST_BASE + (SQUAD_UNLOCK_COST_STEP * steps)

func unlock_next_squad_slot() -> bool:
	if !can_unlock_squad_slot():
		return false
	var cost = get_next_squad_unlock_cost()
	if StatsManager.money < cost:
		return false
	StatsManager.money -= cost
	squad_unlocked_slots += 1
	_clamp_squad_unlocks()
	return true

func ensure_squad_unlocks_for_existing_towers() -> void:
	var highest = -1
	for i in squad_slots.size():
		if !squad_slots[i].is_empty():
			highest = i
	if highest >= 0:
		squad_unlocked_slots = max(squad_unlocked_slots, highest + 1)
	_clamp_squad_unlocks()

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

func reset_all_tower_paths() -> void:
	for i in tower_inventory.size():
		var tower = tower_inventory[i]
		if tower.is_empty():
			continue
		tower["path"] = [0, 0, 0]
		tower_inventory[i] = tower
	for i in squad_slots.size():
		var tower = squad_slots[i]
		if tower.is_empty():
			continue
		tower["path"] = [0, 0, 0]
		squad_slots[i] = tower
