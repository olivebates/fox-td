#StatsManager singleton
extends Node

var base_max_health = 200
var base_production_speed = 1 #/s
var base_kill_multiplier = 1
var starting_health = base_max_health/2
var health: float = starting_health
var max_health: float = base_max_health
var production_speed: float = base_production_speed #/s
var kill_multiplier: float = base_kill_multiplier
var money:int = 0
var level = 1
var current_save_name := "Unnamed Save"
const BACKPACK_MONEY_PER_POINT = 10
var backpack_money_accumulator = 0.0

var upgrade_base_cost = 100
var upgrade_increment_cost = 10

# Health level
var bonuses: Dictionary = {"production": 0.25, "multiplier": 0.2}

# Stats upgrade menu
const DEFAULT_PERSISTENT_UPGRADE_DATA = {
	"start_meat": {
		"title": "Starting Meat",
		"increment": 10,
		"base_cost": 100,
		"cost": 100,
		"desc": "Increases starting meat by 10",
		"level": 0
	},
	"kill_multiplier": {
		"title": "Meat Kill Bonus",
		"increment": 0.1,
		"base_cost": 100,
		"cost": 100,
		"desc": "Increases meat from kills by x0.1",
		"level": 0
	},
	"meat_production": {
		"title": "Meat Production",
		"increment": 0.1,
		"base_cost": 100,
		"cost": 100,
		"desc": "Increases meat production speed by 0.1/s",
		"level": 0
	},
	"meat_wave_clear": {
		"title": "Meat on Wave Clear",
		"increment": 10,
		"base_cost": 100,
		"cost": 100,
		"desc": "Gain +10 meat when a wave ends",
		"level": 0
	},
	"money_kill_bonus": {
		"title": "Money Kill Bonus",
		"increment": 0.1,
		"base_cost": 100,
		"cost": 100,
		"desc": "Increases money from kills by +10%",
		"level": 0
	},
	"gacha_cost_reduction": {
		"title": "Pull Cost Reduction",
		"increment": 0.05,
		"base_cost": 100,
		"cost": 100,
		"desc": "Reduces critter pull costs by 5%",
		"level": 0
	},
	"free_pulls_per_run": {
		"title": "Free Pull Per Win",
		"increment": 1,
		"base_cost": 100,
		"cost": 100,
		"desc": "Gain +1 free critter pull each win",
		"level": 0
	},
	"tower_placement_discount": {
		"title": "Tower Placement Discount",
		"increment": 0.05,
		"base_cost": 100,
		"cost": 100,
		"desc": "Reduces tower placement cost by 5%",
		"level": 0
	},
	"wall_placement_discount": {
		"title": "Wall Placement Discount",
		"increment": 0.05,
		"base_cost": 100,
		"cost": 100,
		"desc": "Reduces wall placement cost by 5%",
		"level": 0
	},
	"tower_move_cooldown_reduction": {
		"title": "Tower Move Cooldown",
		"increment": 0.05,
		"base_cost": 100,
		"cost": 100,
		"desc": "Reduces tower move cooldown by 5%",
		"level": 0
	},
	"global_tower_damage": {
		"title": "Global Tower Damage",
		"increment": 0.05,
		"base_cost": 100,
		"cost": 100,
		"desc": "Increases all tower damage by 5%",
		"level": 0
	},
	"global_tower_attack_speed": {
		"title": "Global Tower Attack Speed",
		"increment": 0.05,
		"base_cost": 100,
		"cost": 100,
		"desc": "Increases all tower attack speed by 5%",
		"level": 0
	},
	"global_tower_range": {
		"title": "Global Tower Range",
		"increment": 0.05,
		"base_cost": 100,
		"cost": 100,
		"desc": "Increases all tower range by 5%",
		"level": 0
	},
	"meat_on_hit": {
		"title": "Meat on Hit",
		"increment": 0.005,
		"base_cost": 100,
		"cost": 100,
		"desc": "Gain meat equal to 0.5% of tower damage per hit",
		"level": 0
	}
}
var persistent_upgrade_data = DEFAULT_PERSISTENT_UPGRADE_DATA.duplicate(true)

var meat_on_wave_clear_bonus: float = 0.0
var money_kill_multiplier: float = 1.0
var gacha_cost_reduction: float = 0.0
var free_pulls_per_run: int = 0
var free_pulls_remaining: int = 0
var tower_placement_discount: float = 0.0
var wall_placement_discount: float = 0.0
var tower_move_cooldown_reduction: float = 0.0
var global_tower_damage_bonus: float = 0.0
var global_tower_attack_speed_bonus: float = 0.0
var global_tower_range_bonus: float = 0.0
var meat_on_hit_ratio: float = 0.0

func _normalize_persistent_upgrades() -> void:
	var defaults = DEFAULT_PERSISTENT_UPGRADE_DATA
	for key in defaults.keys():
		if !persistent_upgrade_data.has(key):
			persistent_upgrade_data[key] = defaults[key].duplicate(true)
		else:
			var default_entry = defaults[key]
			for field_key in default_entry.keys():
				if !persistent_upgrade_data[key].has(field_key):
					persistent_upgrade_data[key][field_key] = default_entry[field_key]
			var default_title = String(default_entry.get("title", ""))
			var current_title = String(persistent_upgrade_data[key].get("title", ""))
			if default_title.length() > 0:
				if current_title.is_empty() or current_title.find("?") != -1:
					persistent_upgrade_data[key]["title"] = default_title
			var default_desc = String(default_entry.get("desc", ""))
			var current_desc = String(persistent_upgrade_data[key].get("desc", ""))
			if !default_desc.is_empty() and (current_desc.is_empty() or current_desc.find("health") != -1):
				persistent_upgrade_data[key]["desc"] = default_desc
			if key == "free_pulls_per_run":
				if current_title == "Free Pulls Per Run":
					persistent_upgrade_data[key]["title"] = default_title
				if current_desc == "Gain +1 free gacha pull each run":
					persistent_upgrade_data[key]["desc"] = default_desc
				if current_desc == "Gain +1 free gacha pull each win":
					persistent_upgrade_data[key]["desc"] = default_desc
			if key == "tower_move_cooldown_reduction":
				if float(persistent_upgrade_data[key].get("increment", 0.0)) != float(default_entry.get("increment", 0.0)):
					persistent_upgrade_data[key]["increment"] = default_entry.get("increment", 0.0)
				if current_desc == "Reduces tower move cooldown by 10%":
					persistent_upgrade_data[key]["desc"] = default_desc
			if key == "gacha_cost_reduction":
				if current_title == "Gacha Cost Reduction":
					persistent_upgrade_data[key]["title"] = default_title
				if current_desc == "Reduces gacha pull costs by 5%":
					persistent_upgrade_data[key]["desc"] = default_desc
			if key in ["global_tower_damage", "global_tower_attack_speed", "global_tower_range"]:
				if int(persistent_upgrade_data[key].get("base_cost", 0)) != int(default_entry.get("base_cost", 0)):
					persistent_upgrade_data[key]["base_cost"] = default_entry.get("base_cost", 0)
	for key in persistent_upgrade_data.keys():
		if !persistent_upgrade_data[key].has("base_cost"):
			persistent_upgrade_data[key]["base_cost"] = upgrade_base_cost
		if !persistent_upgrade_data[key].has("cost"):
			var base_cost = int(persistent_upgrade_data[key].get("base_cost", upgrade_base_cost))
			var level = int(persistent_upgrade_data[key].get("level", 0))
			persistent_upgrade_data[key]["cost"] = base_cost * (level + 1)
		if !persistent_upgrade_data[key].has("increment"):
			persistent_upgrade_data[key]["increment"] = 1
		if !persistent_upgrade_data[key].has("level"):
			persistent_upgrade_data[key]["level"] = 0

func update_persistant_upgrades():
	_normalize_persistent_upgrades()
	#max_health = base_max_health * pow(2, level-1)
	var base_starting = (base_max_health / 2) + (persistent_upgrade_data["start_meat"].level * persistent_upgrade_data["start_meat"].increment)
	starting_health = base_starting * DifficultyManager.get_starting_meat_multiplier()
	var base_production = (bonuses["production"]*(level-1)) + base_production_speed + persistent_upgrade_data["meat_production"].level*persistent_upgrade_data["meat_production"].increment
	production_speed = base_production * DifficultyManager.get_production_speed_multiplier()
	kill_multiplier = (bonuses["multiplier"]*(level-1)) + base_kill_multiplier + persistent_upgrade_data["kill_multiplier"].level*persistent_upgrade_data["kill_multiplier"].increment
	meat_on_wave_clear_bonus = persistent_upgrade_data["meat_wave_clear"].level * persistent_upgrade_data["meat_wave_clear"].increment
	money_kill_multiplier = 1.0 + (persistent_upgrade_data["money_kill_bonus"].level * persistent_upgrade_data["money_kill_bonus"].increment)
	gacha_cost_reduction = min(0.5, persistent_upgrade_data["gacha_cost_reduction"].level * persistent_upgrade_data["gacha_cost_reduction"].increment)
	free_pulls_per_run = int(persistent_upgrade_data["free_pulls_per_run"].level * persistent_upgrade_data["free_pulls_per_run"].increment)
	tower_placement_discount = min(0.5, persistent_upgrade_data["tower_placement_discount"].level * persistent_upgrade_data["tower_placement_discount"].increment)
	wall_placement_discount = min(0.5, persistent_upgrade_data["wall_placement_discount"].level * persistent_upgrade_data["wall_placement_discount"].increment)
	tower_move_cooldown_reduction = min(0.5, persistent_upgrade_data["tower_move_cooldown_reduction"].level * persistent_upgrade_data["tower_move_cooldown_reduction"].increment)
	global_tower_damage_bonus = persistent_upgrade_data["global_tower_damage"].level * persistent_upgrade_data["global_tower_damage"].increment
	global_tower_attack_speed_bonus = persistent_upgrade_data["global_tower_attack_speed"].level * persistent_upgrade_data["global_tower_attack_speed"].increment
	global_tower_range_bonus = persistent_upgrade_data["global_tower_range"].level * persistent_upgrade_data["global_tower_range"].increment
	meat_on_hit_ratio = persistent_upgrade_data["meat_on_hit"].level * persistent_upgrade_data["meat_on_hit"].increment

func get_current_value(stat: String) -> float:
	match stat:
		"start_meat": return starting_health
		"meat_production": return production_speed
		"kill_multiplier": return kill_multiplier
		"meat_wave_clear": return meat_on_wave_clear_bonus
		"money_kill_bonus": return money_kill_multiplier
		"gacha_cost_reduction": return gacha_cost_reduction
		"free_pulls_per_run": return free_pulls_per_run
		"tower_placement_discount": return tower_placement_discount
		"wall_placement_discount": return wall_placement_discount
		"tower_move_cooldown_reduction": return tower_move_cooldown_reduction
		"global_tower_damage": return global_tower_damage_bonus
		"global_tower_attack_speed": return global_tower_attack_speed_bonus
		"global_tower_range": return global_tower_range_bonus
		"meat_on_hit": return meat_on_hit_ratio
	return -1.0

func set_upgrade_text(stat):
	var meat_on_hit_percent = float(int(round(meat_on_hit_ratio * 1000.0))) / 10.0
	match stat:
		"start_meat": return get_upgrade_display_title(stat) + ": " + str(starting_health).trim_suffix(".0")
		"meat_production": return get_upgrade_display_title(stat) + ": " + str(production_speed).trim_suffix(".0") + "/s"
		"kill_multiplier": return get_upgrade_display_title(stat) + ": x" + str(kill_multiplier).trim_suffix(".0")
		"meat_wave_clear": return get_upgrade_display_title(stat) + ": +" + str(meat_on_wave_clear_bonus).trim_suffix(".0")
		"money_kill_bonus": return get_upgrade_display_title(stat) + ": x" + str(money_kill_multiplier).trim_suffix(".0")
		"gacha_cost_reduction": return get_upgrade_display_title(stat) + ": " + str(int(round(gacha_cost_reduction * 100.0))) + "%"
		"free_pulls_per_run": return get_upgrade_display_title(stat) + ": " + str(free_pulls_per_run)
		"tower_placement_discount": return get_upgrade_display_title(stat) + ": " + str(int(round(tower_placement_discount * 100.0))) + "%"
		"wall_placement_discount": return get_upgrade_display_title(stat) + ": " + str(int(round(wall_placement_discount * 100.0))) + "%"
		"tower_move_cooldown_reduction": return get_upgrade_display_title(stat) + ": " + str(int(round(tower_move_cooldown_reduction * 100.0))) + "%"
		"global_tower_damage": return get_upgrade_display_title(stat) + ": " + str(int(round(global_tower_damage_bonus * 100.0))) + "%"
		"global_tower_attack_speed": return get_upgrade_display_title(stat) + ": " + str(int(round(global_tower_attack_speed_bonus * 100.0))) + "%"
		"global_tower_range": return get_upgrade_display_title(stat) + ": " + str(int(round(global_tower_range_bonus * 100.0))) + "%"
		"meat_on_hit": return get_upgrade_display_title(stat) + ": " + str(meat_on_hit_percent).trim_suffix(".0") + "%"
	return "-1"

func get_upgrade_display_title(stat: String) -> String:
	var title = String(persistent_upgrade_data.get(stat, {}).get("title", stat))
	var emoji = get_upgrade_emoji(stat)
	if emoji.is_empty():
		return title
	return emoji + " " + title

func get_upgrade_emoji(stat: String) -> String:
	var vs = String.chr(0xFE0F)
	match stat:
		"start_meat": return String.chr(0x1F969)
		"kill_multiplier": return String.chr(0x1F480)
		"meat_production": return String.chr(0x1F356) + vs
		"meat_wave_clear": return String.chr(0x1F3C1)
		"money_kill_bonus": return String.chr(0x1F4B0)
		"gacha_cost_reduction": return String.chr(0x1F3B0)
		"free_pulls_per_run": return String.chr(0x1F39F) + vs
		"tower_placement_discount": return String.chr(0x1F3D7) + vs
		"wall_placement_discount": return String.chr(0x1F9F1)
		"tower_move_cooldown_reduction": return String.chr(0x23F1) + vs
		"global_tower_damage": return String.chr(0x1F525)
		"global_tower_attack_speed": return String.chr(0x26A1)
		"global_tower_range": return String.chr(0x1F3AF)
		"meat_on_hit": return String.chr(0x1F969)
	return ""

func get_coin_symbol() -> String:
	return String.chr(0x1FA99) + String.chr(0xFE0F)

@onready var backpack_inventory = get_tree().get_first_node_in_group("backpack_inventory")

signal health_changed(current: float, max: float)
signal max_health_changed(new_max: float)
signal production_speed_changed(new_speed: float)

func _ready():
	add_to_group("health_manager")
	update_persistant_upgrades()
	if WaveSpawner:
		WaveSpawner.wave_completed.connect(_on_wave_completed)
		WaveSpawner.level_completed.connect(_on_level_completed)
var is_paused: bool = false

func get_backpack_money_per_hour() -> int:
	var total = 0
	for tower in TowerManager.tower_inventory:
		if tower.is_empty():
			continue
		var rank = int(tower.get("rank", 1))
		var type_data = tower.get("type", {})
		var rarity = int(type_data.get("rarity", 0))
		total += (rank + rarity) * BACKPACK_MONEY_PER_POINT
	return total

func _update_backpack_money(delta: float) -> void:
	var rate_per_hour = get_backpack_money_per_hour()
	if rate_per_hour <= 0:
		return
	backpack_money_accumulator += (float(rate_per_hour) / 3600.0) * delta
	var add_amount = int(floor(backpack_money_accumulator))
	if add_amount > 0:
		money += add_amount
		backpack_money_accumulator -= add_amount

func get_upgrade_cost(stat: String) -> int:
	var data = persistent_upgrade_data.get(stat, {})
	var base_cost = int(data.get("base_cost", upgrade_base_cost))
	var cost = int(data.get("cost", base_cost))
	if cost <= 0:
		var level = int(data.get("level", 0))
		cost = base_cost * (level + 1)
	return cost

func upgrade_stat(stat: String) -> bool:
	var cost = get_upgrade_cost(stat)
	if money < cost: return false
	money -= cost
	persistent_upgrade_data[stat].level += 1
	var base_cost = int(persistent_upgrade_data[stat].get("base_cost", upgrade_base_cost))
	var next_cost = int(persistent_upgrade_data[stat].get("cost", base_cost)) + base_cost
	persistent_upgrade_data[stat]["cost"] = next_cost
	update_persistant_upgrades()
	#health_changed.emit(health, max_health)
	return true

var has_shown_start_tutorial = false

func _process(delta: float) -> void:
	if (WaveSpawner.current_level == 1 and WaveSpawner.current_wave > 6 and !has_shown_start_tutorial):
		has_shown_start_tutorial = true
		show_tutorial_end()
	
	update_persistant_upgrades()
	_update_backpack_money(delta)
	
	if is_paused:
		return
	if get_tree().get_nodes_in_group("enemy").size() > 0 or WaveSpawner._is_spawning:
		if health < max_health:
			health += production_speed * delta
			health = min(health, max_health)
			health_changed.emit(health, max_health)
	if health >= max_health:
		max_health *= 2
		production_speed_changed.emit(production_speed)
		max_health_changed.emit(max_health)
		health_changed.emit(health, max_health)

func spend_health(amount: float) -> bool:
	if health > amount+1:
		health -= amount
		health_changed.emit(health, max_health)
		if health <= 0:
			health = 0
		return true
	return false

func gain_health_from_kill(base_reward: float) -> void:
	var reward = base_reward * kill_multiplier
	health = min(health + reward, max_health)
	health_changed.emit(health, max_health)

func reset_current_map():


	WaveSpawner.cancel_current_waves()
	WaveShower.reset_preview()

	for i in get_tree().get_nodes_in_group("placed_walls"):
		i.queue_free()
	AStarManager._update_grid()

		
	#get_tree().get_first_node_in_group("start_first_wave_button").on_death()

	#WaveSpawner.is_spawning = false
	#WaveSpawner.enemies_to_spawn = 0
	get_tree().call_group("start_wave_button", "set_disabled", false)

	var towers = get_tree().get_nodes_in_group("tower")
	for node in towers:
		node.queue_free()
	
	
	var guards = get_tree().get_nodes_in_group("guard")
	for node in guards:
		node.queue_free()

	var bullets = get_tree().get_nodes_in_group("bullet")
	for node in bullets:
		node.queue_free()
		
	InventoryManager.clear_inventory()

	level = 1
	health = starting_health
	max_health = base_max_health
	production_speed_changed.emit(production_speed)
	health_changed.emit(health, max_health)
	max_health_changed.emit(max_health)
	GridController.walls_placed = 0

func new_map():
	

	WaveSpawner.cancel_current_waves()
	WaveShower.reset_preview()

	for i in get_tree().get_nodes_in_group("grid_buildable"):
		i.queue_free()
	for i in get_tree().get_nodes_in_group("grid_occupiers"):
		i.queue_free()
	for i in get_tree().get_nodes_in_group("walls"):
		i.queue_free()
		
	WaveSpawner.generate_path()

		
	#get_tree().get_first_node_in_group("start_first_wave_button").on_death()

	#WaveSpawner.is_spawning = false
	#WaveSpawner.enemies_to_spawn = 0
	get_tree().call_group("start_wave_button", "set_disabled", false)


	var towers = get_tree().get_nodes_in_group("tower")
	for node in towers:
		node.queue_free()
		
		
	var guards = get_tree().get_nodes_in_group("guard")
	for node in guards:
		node.queue_free()

	var bullets = get_tree().get_nodes_in_group("bullet")
	for node in bullets:
		node.queue_free()
		
	InventoryManager.clear_inventory()
	InventoryManager.slots[0].set_meta("item", {"id": "Fox", "rank": 1})

	level = 1
	health = starting_health
	max_health = base_max_health
	production_speed_changed.emit(production_speed)
	health_changed.emit(health, max_health)
	max_health_changed.emit(max_health)

	GridController.walls_placed = 0


func show_tutorial_end():
	var inst = load("uid://bd1wnetphuwc1").instantiate()
	get_tree().current_scene.add_child(inst)
	
func take_damage(amount: float) -> void:
	health -= amount
	health_changed.emit(health, max_health)
	if health <= 0:
		var i = load("uid://cw0bhvjm3ukdv").instantiate()
		get_tree().root.add_child(i)
		
		var x = WaveSpawner.current_wave
		reset_current_map()
		WaveSpawner.current_wave = x
		
		
		#WaveSpawner.generate_path()  # Regenerates path and clears tiles

func _on_wave_completed(_wave: int) -> void:
	if meat_on_wave_clear_bonus <= 0:
		return
	health = min(health + meat_on_wave_clear_bonus, max_health)
	health_changed.emit(health, max_health)

func _on_level_completed(_level: int) -> void:
	free_pulls_remaining = free_pulls_per_run

func get_tower_placement_cost_multiplier() -> float:
	return 1.0 - tower_placement_discount

func get_wall_cost_multiplier() -> float:
	return 1.0 - wall_placement_discount

func get_tower_move_cooldown_multiplier() -> float:
	return max(0.5, 1.0 - tower_move_cooldown_reduction)

func get_global_damage_multiplier() -> float:
	return 1.0 + global_tower_damage_bonus

func get_global_attack_speed_multiplier() -> float:
	return 1.0 + global_tower_attack_speed_bonus

func get_global_range_multiplier() -> float:
	return 1.0 + global_tower_range_bonus

func get_money_kill_multiplier() -> float:
	return money_kill_multiplier

func get_meat_on_hit_ratio() -> float:
	return meat_on_hit_ratio

func gain_meat_on_hit(damage_amount: int) -> void:
	if meat_on_hit_ratio <= 0.0:
		return
	var reward = float(damage_amount) * meat_on_hit_ratio
	if reward <= 0.0:
		return
	reward = DifficultyManager.apply_meat_gain(reward)
	health = min(health + reward, max_health)
	health_changed.emit(health, max_health)

func get_gacha_pull_cost(raw_cost: int) -> int:
	var mult = max(0.1, 1.0 - gacha_cost_reduction)
	return max(1, int(round(raw_cost * mult)))
