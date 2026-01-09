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

var upgrade_base_cost = 40
var upgrade_increment_cost = 10

# Health level
var bonuses: Dictionary = {"production": 0.25, "multiplier": 0.2}

# Stats upgrade menu
var persistent_upgrade_data = {
	"start_meat": {
		"title": "Starting Meat",
		"increment": 10,
		"desc": "Increases starting meat by 10",
		"level": 0
	},
	"meat_production": {
		"title": "Meat Production",
		"increment": 0.1,
		"desc": "Increases meat production speed by 0.1/s",
		"level": 0
	},
	"kill_multiplier": {
		"title": "Kill Bonus",
		"increment": 0.1,
		"desc": "Increases health from kills by x0.1",
		"level": 0
	}
}

func update_persistant_upgrades():
	#max_health = base_max_health * pow(2, level-1)
	var base_starting = (base_max_health / 2) + (persistent_upgrade_data["start_meat"].level * persistent_upgrade_data["start_meat"].increment)
	starting_health = base_starting * DifficultyManager.get_starting_meat_multiplier()
	var base_production = (bonuses["production"]*(level-1)) + base_production_speed + persistent_upgrade_data["meat_production"].level*persistent_upgrade_data["meat_production"].increment
	production_speed = base_production * DifficultyManager.get_production_speed_multiplier()
	kill_multiplier = (bonuses["multiplier"]*(level-1)) + base_kill_multiplier + persistent_upgrade_data["kill_multiplier"].level*persistent_upgrade_data["kill_multiplier"].increment

func get_current_value(stat: String) -> float:
	match stat:
		"start_meat": return starting_health
		"meat_production": return production_speed
		"kill_multiplier": return kill_multiplier
	return -1.0

func set_upgrade_text(stat):
	match stat:
		"start_meat": return persistent_upgrade_data[stat].title + ": " + str(starting_health).trim_suffix(".0")
		"meat_production": return persistent_upgrade_data[stat].title + ": " + str(production_speed).trim_suffix(".0") + "/s"
		"kill_multiplier": return persistent_upgrade_data[stat].title + ": x" + str(kill_multiplier).trim_suffix(".0")
	return "-1"

@onready var backpack_inventory = get_tree().get_first_node_in_group("backpack_inventory")

signal health_changed(current: float, max: float)
signal max_health_changed(new_max: float)
signal production_speed_changed(new_speed: float)

func _ready():
	add_to_group("health_manager")
	update_persistant_upgrades()
var is_paused: bool = false

func get_upgrade_cost(stat: String) -> int:
	return upgrade_base_cost + persistent_upgrade_data[stat].level * upgrade_increment_cost

func upgrade_stat(stat: String) -> bool:
	var cost = get_upgrade_cost(stat)
	if money < cost: return false
	money -= cost
	persistent_upgrade_data[stat].level += 1
	#health_changed.emit(health, max_health)
	return true

var has_shown_start_tutorial = false

func _process(delta: float) -> void:
	if (WaveSpawner.current_level == 1 and WaveSpawner.current_wave > 6 and !has_shown_start_tutorial):
		has_shown_start_tutorial = true
		show_tutorial_end()
	
	update_persistant_upgrades()
	
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
