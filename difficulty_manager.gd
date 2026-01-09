extends Node
class_name TraitData

signal trait_changed(trait_name: String, new_value: int)

# Trait name -> level
var traits := {
	"Speed": 0, #Increases enemy movement speed by 15%
	"Health": 0, #Increases enemy HP by 30% per level
	"Splitting": 0, #Killed monsters spawn 2 new enemies, with each spawnling having (15% * n) of the host monster's max HP, and giving no extra meat
	"Dodge": 0, #(5% * n) chance to evade tower shots.
	"Armor": 0, #Enemies take 7%*n less damage
	"Regeneration": 0, #Enemies regenerate 5% of their max HP per second
	"Revive": 0, #Enemies have a 10% * n chance of reviving once upon being killed, second kill gives no extra meat
	"Meat Drain": 0, #Kills give 10%*n less meat
	"Production Jam": 0, #Passive health production reduced by 10%*n
	"Food Shortage": 0, #Reduced starting meat by 7%*n
}

const MIN_LEVEL := 0
const MAX_LEVEL := 10
const MONEY_GAIN_PER_POINT := 0.1
const SPEED_PER_LEVEL := 0.15
const HEALTH_MULT_PER_LEVEL := 0.30
const SPLIT_COUNT := 2
const SPLIT_HEALTH_PER_LEVEL := 0.15
const DODGE_CHANCE_PER_LEVEL := 0.05
const ARMOR_DAMAGE_REDUCTION_PER_LEVEL := 0.07
const REGEN_MAX_HP_PER_LEVEL := 0.05
const REVIVE_CHANCE_PER_LEVEL := 0.10
const REVIVE_HEALTH_RATIO := 0.5
const MEAT_DRAIN_PER_LEVEL := 0.10
const PRODUCTION_JAM_PER_LEVEL := 0.10
const FOOD_SHORTAGE_PER_LEVEL := 0.07

func get_trait(trait_name: String) -> int:
	return traits.get(trait_name, 0)

func increase_trait(trait_name: String) -> void:
	if traits.has(trait_name) and traits[trait_name] < MAX_LEVEL:
		traits[trait_name] += 1
		trait_changed.emit(trait_name, traits[trait_name])

func decrease_trait(trait_name: String) -> void:
	if traits.has(trait_name) and traits[trait_name] > MIN_LEVEL:
		traits[trait_name] -= 1
		trait_changed.emit(trait_name, traits[trait_name])

func get_total_trait_points() -> int:
	var total := 0
	for value in traits.values():
		total += int(value)
	return total

func get_money_multiplier() -> float:
	return 1.0 + float(get_total_trait_points()) * MONEY_GAIN_PER_POINT

func get_enemy_speed_multiplier() -> float:
	return 1.0 + float(get_trait("Speed")) * SPEED_PER_LEVEL

func get_enemy_health_multiplier() -> float:
	return 1.0 + HEALTH_MULT_PER_LEVEL * float(get_trait("Health"))

func get_enemy_dodge_chance() -> float:
	return clamp(float(get_trait("Dodge")) * DODGE_CHANCE_PER_LEVEL, 0.0, 0.95)

func get_enemy_damage_taken_multiplier() -> float:
	return max(0.0, 1.0 - float(get_trait("Armor")) * ARMOR_DAMAGE_REDUCTION_PER_LEVEL)

func get_enemy_regen_per_second(max_health: int) -> float:
	return float(max_health) * float(get_trait("Regeneration")) * REGEN_MAX_HP_PER_LEVEL

func get_enemy_revive_chance() -> float:
	return clamp(float(get_trait("Revive")) * REVIVE_CHANCE_PER_LEVEL, 0.0, 1.0)

func get_enemy_revive_health_ratio() -> float:
	return REVIVE_HEALTH_RATIO

func get_split_count() -> int:
	return SPLIT_COUNT if get_trait("Splitting") > 0 else 0

func get_split_health_ratio() -> float:
	return float(get_trait("Splitting")) * SPLIT_HEALTH_PER_LEVEL

func get_meat_gain_multiplier() -> float:
	return max(0.0, 1.0 - float(get_trait("Meat Drain")) * MEAT_DRAIN_PER_LEVEL)

func get_production_speed_multiplier() -> float:
	return max(0.0, 1.0 - float(get_trait("Production Jam")) * PRODUCTION_JAM_PER_LEVEL)

func get_starting_meat_multiplier() -> float:
	return max(0.0, 1.0 - float(get_trait("Food Shortage")) * FOOD_SHORTAGE_PER_LEVEL)

func should_enemy_dodge() -> bool:
	return randf() < get_enemy_dodge_chance()

func should_enemy_revive() -> bool:
	return randf() < get_enemy_revive_chance()

func apply_enemy_damage_taken(amount: int) -> int:
	if amount <= 0:
		return 0
	var scaled := float(amount) * get_enemy_damage_taken_multiplier()
	return int(max(1.0, ceil(scaled)))

func apply_meat_gain(base_reward: float) -> float:
	return base_reward * get_meat_gain_multiplier()

func get_enemy_spawn_health(base_health: int) -> int:
	return int(max(1.0, round(float(base_health) * get_enemy_health_multiplier())))

func get_enemy_spawn_speed(base_speed: float) -> float:
	return base_speed * get_enemy_speed_multiplier()

func get_enemy_spawn_max_speed(base_speed: float) -> float:
	return base_speed * get_enemy_speed_multiplier()

func get_split_spawn_health(base_health: int) -> int:
	return int(max(1.0, round(float(base_health) * get_split_health_ratio())))

func spawn_split_enemies(source_enemy: Node2D, split_count: int, split_health: int) -> void:
	if split_count <= 0 or split_health <= 0:
		return
	var parent = source_enemy.get_parent()
	if parent == null:
		return
	var wave = source_enemy.spawn_wave
	if not WaveSpawner.active_waves.has(wave):
		WaveSpawner.active_waves[wave] = 0
	WaveSpawner.active_waves[wave] += split_count
	for i in split_count:
		var enemy := WaveSpawner.enemy_scene.instantiate()
		enemy.position = source_enemy.position + Vector2(randf_range(-2.0, 2.0), randf_range(-2.0, 2.0))
		enemy.target_position = source_enemy.target_position
		parent.add_child(enemy)
		enemy.add_to_group("enemy")
		enemy.enemy_type = source_enemy.enemy_type
		enemy.spawn_wave = wave
		enemy.can_split = false
		enemy.no_meat_reward = true
		enemy.max_speed = source_enemy.max_speed
		enemy.speed = source_enemy.speed
		enemy.health = split_health
		enemy.current_health = split_health
		enemy.tree_exited.connect(func():
			if WaveSpawner.active_waves.has(wave):
				WaveSpawner.active_waves[wave] -= 1
				if WaveSpawner.active_waves[wave] <= 0:
					WaveSpawner.active_waves.erase(wave)
					WaveSpawner.wave_completed.emit(wave)
					var button = get_tree().get_first_node_in_group("start_wave_button")
					if button: button.disabled = false
		)

func get_all_traits():
	return traits.keys()
