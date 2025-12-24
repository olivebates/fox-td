#StatsManager singleton
extends Node

var health: float = 50.0
var max_health: float = 100.0
var production_speed: float = 1.0
var kill_multiplier: float = 1.0
var money = 0
var level = 1

signal health_changed(current: float, max: float)
signal max_health_changed(new_max: float)
signal production_speed_changed(new_speed: float)

func _ready():
	add_to_group("health_manager")
var is_paused: bool = false
func _process(delta: float) -> void:
	
	if is_paused:
		return
	if get_tree().get_nodes_in_group("enemy").size() > 0 or WaveSpawner._is_spawning:
		if health < max_health:
			health += production_speed * delta
			health = min(health, max_health)
			health_changed.emit(health, max_health)
		if health >= max_health:
			max_health *= 2
			production_speed += 0.5
			production_speed_changed.emit(production_speed)
			kill_multiplier *= 1.25
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

func take_damage(amount: float) -> void:
	health -= amount
	health_changed.emit(health, max_health)
	if health <= 0:
		get_tree().get_first_node_in_group("game_over_screen").visible = true
		
		InventoryManager.cost_to_spawn = 50
		
		WaveSpawner.cancel_current_waves()
		WaveShower.reset_preview()
		
		for i in get_tree().get_nodes_in_group("grid_buildable"):
			i.queue_free()
		for i in get_tree().get_nodes_in_group("grid_occupiers"):
			i.queue_free()
		for i in get_tree().get_nodes_in_group("walls"):
			i.queue_free()
		WaveSpawner.generate_path()
		AStarManager._update_grid()
		GridController.update_buildables()
		
			
		#get_tree().get_first_node_in_group("start_first_wave_button").on_death()
		
		#WaveSpawner.is_spawning = false
		#WaveSpawner.enemies_to_spawn = 0
		get_tree().call_group("start_wave_button", "set_disabled", false)
		var enemies = get_tree().get_nodes_in_group("enemy")
		for node in enemies:
			node.queue_free()
		

		var towers = get_tree().get_nodes_in_group("tower")
		for node in towers:
			node.queue_free()

		var bullets = get_tree().get_nodes_in_group("bullet")
		for node in bullets:
			node.queue_free()
			
		InventoryManager.clear_inventory()
		InventoryManager.slots[0].set_meta("item", {"id": "tower1", "rank": 1})
		
		max_health = 100
		level = 1
		health = 50
		production_speed = 1.0
		production_speed_changed.emit(production_speed)
		kill_multiplier = 1.0
		health_changed.emit(health, max_health)
		max_health_changed.emit(max_health)
		
		#WaveSpawner.generate_path()  # Regenerates path and clears tiles
