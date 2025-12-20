extends Node
var health: float = 50.0
var max_health: float = 100.0
var production_speed: float = 1.0
var kill_multiplier: float = 1.0
signal health_changed(current: float, max: float)
signal max_health_changed(new_max: float)
func _ready():
	add_to_group("health_manager")
func _process(delta: float) -> void:
	if health < max_health:
		health += production_speed * delta
	if health > max_health:
		health = max_health
	health_changed.emit(health, max_health)
	if health >= max_health:
		max_health *= 2
		production_speed += 0.5
		kill_multiplier *= 1.25
		max_health_changed.emit(max_health)
		health_changed.emit(health, max_health)
func spend_health(amount: float) -> bool:
	if health >= amount:
		health -= amount
		health_changed.emit(health, max_health)
		return true
	return false
func gain_health_from_kill(base_reward: float) -> void:
	var reward = base_reward * kill_multiplier
	health = min(health + reward, max_health)
	health_changed.emit(health, max_health)
func take_damage(amount: float) -> void:
	health -= amount
	if health < 0:
		health = 0
	health_changed.emit(health, max_health)
