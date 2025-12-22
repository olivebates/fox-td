extends Node

var health: float = 50.0
var max_health: float = 100.0
var production_speed: float = 1.0
var kill_multiplier: float = 1.0
var level = 1

signal health_changed(current: float, max: float)
signal max_health_changed(new_max: float)

func _ready():
	add_to_group("health_manager")

func _process(delta: float) -> void:
	if get_tree().get_nodes_in_group("enemy").size() > 0:
		if health < max_health:
			health += production_speed * delta
			health = min(health, max_health)
			health_changed.emit(health, max_health)
	
	if health >= max_health:
		max_health *= 2
		production_speed += 0.5
		kill_multiplier *= 1.25
		max_health_changed.emit(max_health)
		health_changed.emit(health, max_health)

func spend_health(amount: float) -> bool:
	if health > amount:
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
		level = 1
		health = 50
		max_health = 100
		production_speed = 1.0
		kill_multiplier = 1.0
		WaveSpawner.cancel_current_waves()
		WaveShower.reset_preview()
		
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
		
		
		#WaveSpawner.generate_path()  # Regenerates path and clears tiles
