# Full WaveSpawner.gd (singleton)
extends Node2D

@export var enemy_scene: PackedScene = preload("uid://csawtka1gfo5o")
@export var base_speed: float = 80.0
@export var speed_inc: float = 10.0
@export var base_health: int = 1
@export var start_pos: Vector2 = Vector2(88, -8)
@export var end_pos: Vector2 = Vector2(88, 136)
@export var grid_size: int = 16
@export var path_tile_uid: String = "uid://2wlflfus0jih"
@export var buildable_grid_size = 8
@export var path_buildable_uid: String = "uid://823ref1rao2h"
var special_scene: PackedScene = ResourceLoader.load("uid://71114a1asxv") # Wall tiles
@export var max_wave_spawn_time: float = 8.0
var game_paused: bool = false
var max_waves
var current_wave_base_reward: float = 0.0

var committed_wave_power: float = 1.0
var wave_locked: bool = false
var locked_base_wave_mult = 1.0
var locked_wave_accel = 1.0
var wave_seeds: Array[int] = []
var saved_wave_data: Array[Dictionary] = []

enum Difficulty { EASY, NORMAL, HARD }
@export var difficulty = Difficulty.NORMAL
@export var BASE_WAVE_POWER_MULT = 1.0
var WAVE_POWER_MULT = 1.0
var WAVE_ACCELERATION = 1.0
var MAX_WAVES = 1
var HEALTH_REWARD_FACTOR = 0.35
var HEALTH_REWARD_MULTIPLIER = 1.0
var COUNT_WEIGHT = 0.55
var HEALTH_WEIGHT = 0.45
var smoothed_power = 1.0
var _last_level_cached: int = -1
const WAVE_COLORS = ["red", "green", "blue"]
const WAVE_BASE_POWER = 6.0
const FIRST_WAVE_MULT = 0.3
const LEVEL_5_PLUS_FIRST_WAVE_MULT = 1.6
const LEVEL_POWER_GROWTH = 2.52
const LEVEL_1_POWER_SCALE = 2.01
const LEVEL_2_POWER_SCALE = 3.2928
const LEVEL_3_POWER_SCALE = 3.234
const LEVEL_4_PLUS_MULT = 1.015
const LEVEL_4_PLUS_HEALTH_MULT = 1.15
const LEVEL_4_PLUS_DIFFICULTY_ADJUST = 0.3708
const POST_LEVEL_GROWTH = 1.08
const POST_LEVEL_LINEAR = 0.01
const POST_LEVEL_HEALTH_GROWTH = 1.03
const POST_LEVEL_HEALTH_LINEAR = 0.01
const POST_LEVEL_6_PLUS_GROWTH = 1.12
const POST_LEVEL_6_PLUS_LINEAR = 0.02
const POST_LEVEL_6_PLUS_HEALTH_GROWTH = 1.05
const POST_LEVEL_6_PLUS_HEALTH_LINEAR = 0.02
const LEVEL_5_PLUS_POWER_MULT = 1.2
const BASE_MEAT_REWARD = 1.0
const SWARM_WAVE_INTERVAL = 4
const SWARM_START_WAVE = 3
const WAVE_POWER_GROWTH = 1.07
const EARLY_WAVE_GROWTH = 1.03
const EARLY_WAVE_COUNT = 3
const EARLY_WAVE_DIFFICULTY_ADJUST = 0.6
const EARLY_RAMP_TAPER_START = 6
const EARLY_RAMP_TAPER = 0.98
const PLAYER_POWER_BASELINE = 20.0
const PLAYER_POWER_EXP = 0.6
const POST_MAX_WAVE_GROWTH = 1.05
const POST_WAVE_4_MULT = 1.08
const POST_WAVE_5_DIFFICULTY_ADJUST = 0.3
const POST_LEVEL_6_PLUS_WAVE_GROWTH = 1.06
const HOARD_POWER_PER_RATIO = 0.25
const HOARD_RATIO_CAP = 2.0


func get_wave_power(level: int, wave: int) -> float:
	return get_wave_power_with_mult_and_player(level, wave, WAVE_POWER_MULT, committed_wave_power)

func get_wave_power_with_mult(level: int, wave: int, power_mult: float) -> float:
	return get_wave_power_with_mult_and_player(level, wave, power_mult, committed_wave_power)

func _get_wave_scale(level: int, wave: int) -> float:
	var early_waves = min(max(0, wave - 1), EARLY_WAVE_COUNT)
	var late_waves = max(0, wave - 1 - EARLY_WAVE_COUNT)
	var wave_scale = pow(EARLY_WAVE_GROWTH, early_waves) * pow(WAVE_POWER_GROWTH, late_waves)
	if wave >= EARLY_RAMP_TAPER_START:
		wave_scale *= pow(EARLY_RAMP_TAPER, wave - (EARLY_RAMP_TAPER_START - 1))
	if wave <= EARLY_WAVE_COUNT:
		wave_scale *= EARLY_WAVE_DIFFICULTY_ADJUST
	if wave > 4:
		wave_scale *= pow(POST_WAVE_4_MULT, wave - 4)
	if wave > 5:
		wave_scale *= POST_WAVE_5_DIFFICULTY_ADJUST
	if level >= 6 and wave > 5:
		var post_wave_steps = wave - 5
		wave_scale *= pow(POST_LEVEL_6_PLUS_WAVE_GROWTH, post_wave_steps)
	if wave == 1:
		wave_scale *= FIRST_WAVE_MULT
	if wave == 1 and level >= 5:
		wave_scale *= LEVEL_5_PLUS_FIRST_WAVE_MULT
	if level >= 5 and wave <= 5:
		wave_scale *= 0.7
	return wave_scale

func get_wave_power_with_mult_and_player(level: int, wave: int, power_mult: float, player_power: float) -> float:
	var level_scale = LEVEL_1_POWER_SCALE
	if level <= 1:
		level_scale = LEVEL_1_POWER_SCALE
	elif level == 2:
		level_scale = LEVEL_2_POWER_SCALE
	elif level == 3:
		level_scale = LEVEL_3_POWER_SCALE
	else:
		var base_scale = _get_level_4_base_scale()
		if level == 4:
			level_scale = base_scale
		elif level == 5:
			var post_mult = POST_LEVEL_GROWTH
			var post_soft = 1.0 + POST_LEVEL_LINEAR
			level_scale = base_scale * post_mult * post_soft
		else:
			var level_5_scale = base_scale * POST_LEVEL_GROWTH * (1.0 + POST_LEVEL_LINEAR)
			var post_steps = level - 5
			var post_mult = pow(POST_LEVEL_6_PLUS_GROWTH, post_steps)
			var post_soft = 1.0 + (post_steps * POST_LEVEL_6_PLUS_LINEAR)
			level_scale = level_5_scale * post_mult * post_soft
	if level >= 5:
		level_scale *= LEVEL_5_PLUS_POWER_MULT
	var wave_scale = _get_wave_scale(level, wave)
	if wave > 11 and wave <= MAX_WAVES:
		var base_scale = _get_wave_scale(level, 11)
		var prev_scale = _get_wave_scale(level, 10)
		var step = max(0.0, base_scale - prev_scale)
		wave_scale = (base_scale + step * float(wave - 11)) * 0.5
	var player_ratio = max(1.0, player_power) / PLAYER_POWER_BASELINE
	var player_scale = pow(player_ratio, PLAYER_POWER_EXP)
	player_scale = max(0.6, player_scale)
	var hoard_scale = _get_hoard_penalty_mult()
	return WAVE_BASE_POWER * level_scale * wave_scale * player_scale * power_mult * hoard_scale

func _get_field_dps() -> float:
	var inventory = get_node("/root/InventoryManager")
	return float(inventory.get_total_field_dps())

func _get_squad_dps() -> float:
	var inventory = get_node("/root/InventoryManager")
	var tower_manager = get_node("/root/TowerManager")
	var total := 0.0
	for tower in tower_manager.squad_slots:
		if tower.is_empty():
			continue
		var id = tower.get("id", "")
		if id == "":
			continue
		var rank = int(tower.get("rank", 1))
		var path = tower.get("path", [0, 0, 0])
		var stats = inventory.get_tower_stats(id, rank, path)
		var def = inventory.items.get(id, {})
		var dps := 0.0
		if def.get("is_guard", false):
			dps = stats.creature_damage * stats.creature_attack_speed * max(1, stats.creature_count)
		else:
			dps = stats.damage * stats.attack_speed * stats.bullets
		if def.has("dps_multiplier"):
			dps *= def.dps_multiplier
		total += dps
	return total

func _get_econ_score() -> float:
	var base_starting = max(1.0, StatsManager.base_max_health / 2.0)
	var base_production = max(0.1, StatsManager.base_production_speed)
	var base_kill = max(0.1, StatsManager.base_kill_multiplier)
	var econ := 0.0
	econ += ((StatsManager.starting_health / base_starting) - 1.0) * 0.25
	econ += ((StatsManager.production_speed / base_production) - 1.0) * 0.5
	econ += ((StatsManager.kill_multiplier / base_kill) - 1.0) * 0.25
	econ += (StatsManager.meat_on_wave_clear_bonus / 10.0) * 0.15
	econ += (StatsManager.meat_on_hit_ratio * 200.0) * 0.2
	econ += StatsManager.tower_placement_discount * 0.75
	econ += StatsManager.wall_placement_discount * 0.4
	econ += StatsManager.tower_move_cooldown_reduction * 0.4
	return clamp(econ, 0.0, 2.0)

func get_effective_player_power() -> float:
	var field_power = _get_field_dps()
	var squad_power = _get_squad_dps()
	var base_power = (field_power * 0.7) + (squad_power * 0.3)
	return max(1.0, base_power)

func _get_hoard_penalty_mult() -> float:
	var base_meat = max(1.0, StatsManager.starting_health)
	var current_meat = max(0.0, StatsManager.health)
	var hoard_ratio = max(0.0, (current_meat - base_meat) / base_meat)
	var hoard_scale = 1.0 + min(hoard_ratio, HOARD_RATIO_CAP) * HOARD_POWER_PER_RATIO
	return hoard_scale

func set_power_mult():
	
	BASE_WAVE_POWER_MULT = 1.6
	WAVE_ACCELERATION = 0.14
	if current_level >= 2:
		BASE_WAVE_POWER_MULT = 2.4
		WAVE_ACCELERATION = 0.22
	MAX_WAVES = 10 + floor(current_level / 2) * 2 if current_level > 1 else 6
	COUNT_WEIGHT = 0.65
	HEALTH_WEIGHT = 0.35
	HEALTH_REWARD_FACTOR = 0.3
	HEALTH_REWARD_MULTIPLIER = 0.8
	
	if (current_level == 1):
		WAVE_ACCELERATION = 0.45

var ENEMY_TYPES = {
	"normal": {
		"health": 1,
		"speed": 10.0,
		"damage": 10,
		"base_reward": 1.0,
		"count_mult": 1.0,
		"max_count": 8,
		"min_wave": 1,
		"label": "Normal",
		"abilities": []
	},
	"swarm": {
		"health": 0.3,
		"speed": 8.0,
		"damage": 5,
		"base_reward": 0.5,
		"count_mult": 0.77,
		"max_count": 60,
		"min_wave": 1,
		"label": "Swarm",
		"abilities": ["Smaller bodies, higher counts."]
	},
	"fast": {
		"health": 0.858,
		"speed": 25.0,
		"damage": 10,
		"base_reward": 0.75,
		"count_mult": 0.56,
		"max_count": 18,
		"min_wave": 3,
		"label": "Fast",
		"abilities": ["Moves much faster than normal."]
	},
	"splitter": {
		"health": 0.54,
		"speed": 9.0,
		"damage": 10,
		"base_reward": 0.8,
		"count_mult": 0.27,
		"max_count": 9,
		"min_wave": 5,
		"min_level": 5,
		"label": "Splitter",
		"abilities": ["Splits into 2 swarmlings on death."]
	},
	"phase": {
		"health": 0.8,
		"speed": 12.0,
		"damage": 10,
		"base_reward": 0.9,
		"count_mult": 0.95,
		"max_count": 30,
		"min_wave": 10,
		"min_level": 10,
		"label": "Phase",
		"abilities": ["Phases out when near towers, becoming untargetable."]
	},
	"regenerator": {
		"health": 0.78624,
		"speed": 9.0,
		"damage": 10,
		"base_reward": 1.0,
		"count_mult": 0.504,
		"max_count": 9,
		"min_wave": 4,
		"label": "Regenerator",
		"abilities": ["Regenerates health over time."]
	},
	"swarmling": {
		"health": 0.0066,
		"speed": 14.0,
		"damage": 6,
		"base_reward": 0.075,
		"count_mult": 2.6,
		"max_count": 20,
		"min_wave": 6,
		"min_level": 5,
		"label": "Swarmling",
		"abilities": ["Tiny and fast, spawns in large numbers."]
	},
	"hardened": {
		"health": 2.076,
		"speed": 7.0,
		"damage": 12,
		"base_reward": 1.2,
		"count_mult": 0.24,
		"max_count": 8,
		"min_wave": 5,
		"label": "Hardened",
		"abilities": ["Takes reduced damage."]
	},
	"stalker": {
		"health": 0.9,
		"speed": 11.0,
		"damage": 10,
		"base_reward": 1.0,
		"count_mult": 0.9,
		"max_count": 25,
		"min_wave": 6,
		"label": "Stalker",
		"abilities": ["Periodically becomes untargetable."]
	},
	"boss": {
		"health": 3.0,
		"speed": 5.0,
		"damage": 50,
		"base_reward": 7.0,
		"count_mult": 0.2,
		"max_count": 6,
		"min_wave": 1,
		"label": "Boss",
		"abilities": ["High health and damage."]
	}
}

func set_enemy_config():
	ENEMY_TYPES = {
		"normal": {
			"health": 1,
			"speed": 10.0,
			"damage": 10,
			"base_reward": 1.0,
			"count_mult": 1.0,
			"max_count": 8,
			"min_wave": 1,
			"label": "Normal",
			"abilities": []
		},
		"swarm": {
			"health": 0.18,
			"speed": 8.0,
			"damage": 5,
			"base_reward": 0.5,
			"count_mult": 0.77,
			"max_count": 60,
			"min_wave": 1,
			"label": "Swarm",
			"abilities": ["Smaller bodies, higher counts."]
		},
	"fast": {
		"health": 0.858,
		"speed": 25.0,
		"damage": 10,
		"base_reward": 0.75,
		"count_mult": 0.42,
		"max_count": 18,
		"min_wave": 3,
		"label": "Fast",
		"abilities": ["Moves much faster than normal."]
	},
		"splitter": {
			"health": 0.54,
			"speed": 9.0,
			"damage": 10,
			"base_reward": 0.8,
			"count_mult": 0.27,
			"max_count": 9,
			"min_wave": 5,
			"min_level": 5,
			"label": "Splitter",
			"abilities": ["Splits into 2 swarmlings on death."]
		},
		"phase": {
			"health": 0.8,
			"speed": 12.0,
			"damage": 10,
			"base_reward": 0.9,
			"count_mult": 0.95,
			"max_count": 30,
			"min_wave": 10,
			"min_level": 10,
			"label": "Phase",
			"abilities": ["Phases out when near towers, becoming untargetable."]
		},
		"regenerator": {
			"health": 0.78624,
			"speed": 9.0,
			"damage": 10,
			"base_reward": 1.0,
			"count_mult": 0.504,
			"max_count": 9,
			"min_wave": 4,
			"label": "Regenerator",
			"abilities": ["Regenerates health over time."]
		},
	"swarmling": {
		"health": 0.0066,
		"speed": 14.0,
		"damage": 6,
		"base_reward": 0.075,
		"count_mult": 2.6,
		"max_count": 20,
		"min_wave": 6,
		"min_level": 5,
		"label": "Swarmling",
		"abilities": ["Tiny and fast, spawns in large numbers."]
	},
		"hardened": {
			"health": 2.076,
			"speed": 7.0,
			"damage": 12,
			"base_reward": 1.2,
			"count_mult": 0.24,
			"max_count": 8,
			"min_wave": 5,
			"label": "Hardened",
			"abilities": ["Takes reduced damage."]
		},
		"stalker": {
			"health": 0.9,
			"speed": 11.0,
			"damage": 10,
			"base_reward": 1.0,
			"count_mult": 0.9,
			"max_count": 25,
			"min_wave": 6,
			"label": "Stalker",
			"abilities": ["Periodically becomes untargetable."]
		},
		"boss": {
			"health": 4.8,
			"speed": 5.0,
			"damage": 50,
			"base_reward": 1.0,
			"count_mult": 0.2,
			"max_count": 6,
			"min_wave": 1,
			"label": "Boss",
			"abilities": ["High health and damage."]
		}
	}


var current_level = 1


#func get_level_config(level: int) -> Dictionary:
	#ENEMY_TYPES = {
		#"normal": {
			#"health": 1,
			#"speed": 10.0,
			#"damage": 10,
			#"base_reward": 1.0,
			#"count_mult": 1.0
		#},
		#"swarm": {
			#"health": 0.75,
			#"speed": 8.0,
			#"damage": 5,
			#"base_reward": 0.5,
			#"count_mult": 1.5
		#},
		#"fast": {
			#"health": 0.44,
			#"speed": 25.0,
			#"damage": 10,
			#"base_reward": 0.75,
			#"count_mult": 1.3
		#},
		#"boss": {
			#"health": 5.0,
			#"speed": 5.0,
			#"damage": 50,
			#"base_reward": 7.0,
			#"count_mult": 0.2
		#}
	#}
	# Hand-tuned early game
	#if level == 0:
		#return { base_health = 1.0, wave_growth = 1.08, waves = 6 }
	#if level == 1:
		#return { base_health = 3.0, wave_growth = 1.5, waves = 6 }
	#if level == 2:
		#return { base_health = 3.0, wave_growth = 1.4, waves = 7 }
	#if level == 3:
		#return { base_health = 2.2, wave_growth = 1.3, waves = 12 }
	##if level == 4:
		##return { base_health = 3.0, wave_growth = 1.4, waves = 14 }
#
	## Procedural scaling after level 4
	#var lvl = level - 3
#
	#var base_health = 3.0 * pow(1.35, lvl)
	#var wave_growth = (1.12 + lvl * 0.008 + (0.002 + current_wave * 0.012)/pow(current_wave, 0.7))/pow(current_wave, 0.02)
	#var waves = 12 + floor(lvl/3) * 2


	#return {
		#base_health = base_health,
		#wave_growth = wave_growth,
		#waves = waves
	#}

func get_smoothed_player_power() -> float:
	smoothed_power = lerp(smoothed_power, get_effective_player_power(), 0.25)
	return smoothed_power

func _get_level_4_base_scale() -> float:
	var level_steps = 1
	var level_scale = LEVEL_3_POWER_SCALE * pow(LEVEL_POWER_GROWTH, level_steps)
	level_scale *= pow(LEVEL_4_PLUS_MULT, level_steps)
	level_scale *= LEVEL_4_PLUS_DIFFICULTY_ADJUST
	return level_scale

func _get_wave_seed(wave: int) -> int:
	return current_level * 10000 + wave

func get_wave_color(wave: int) -> String:
	var rng = RandomNumberGenerator.new()
	rng.seed = _get_wave_seed(wave)
	_pick_enemy_type_for_wave(rng, wave)
	return WAVE_COLORS[rng.randi_range(0, WAVE_COLORS.size() - 1)]

func _get_enemy_pool_for_wave(wave: int) -> Array[String]:
	var keys: Array[String] = []
	for key in ENEMY_TYPES.keys():
		if key == "boss":
			continue
		if key == "swarm" and (wave < SWARM_START_WAVE or wave % SWARM_WAVE_INTERVAL != 0):
			continue
		if banned_enemy_types.has(key):
			continue
		var min_wave = int(ENEMY_TYPES[key].get("min_wave", 1))
		var min_level = int(ENEMY_TYPES[key].get("min_level", 1))
		if wave >= min_wave and current_level >= min_level:
			keys.append(key)
	if keys.is_empty():
		keys.append("normal")
	return keys

func _pick_enemy_type_for_wave(rng: RandomNumberGenerator, wave: int) -> String:
	if wave % 9 == 0:
		return "boss"
	var keys = _get_enemy_pool_for_wave(wave)
	return keys[rng.randi_range(0, keys.size() - 1)]

func _build_wave_data(wave_seed: int, wave: int) -> Dictionary:
	var rng = RandomNumberGenerator.new()
	rng.seed = wave_seed
	var enemy_type = _pick_enemy_type_for_wave(rng, wave)
	var wave_color = WAVE_COLORS[rng.randi_range(0, WAVE_COLORS.size() - 1)]
	var type_data = ENEMY_TYPES[enemy_type]
	var wave_power_mult = _calculate_wave_power_mult(wave)
	var player_power = get_effective_player_power()
	var power = get_wave_power_with_mult_and_player(current_level, wave, wave_power_mult, player_power)
	if wave > MAX_WAVES:
		power *= pow(POST_MAX_WAVE_GROWTH, wave - MAX_WAVES)
	var split = _split_wave_power(power)
	var count = int(ceil(float(split.count) * float(type_data.count_mult)))
	var health = int(max(1.0, round(float(split.health) * float(type_data.health))))
	var min_health = 1 + int(floor(float(wave - 1) / 2.0))
	if enemy_type != "swarmling":
		health = max(health, min_health)
	if current_level >= 4:
		var health_mult = LEVEL_4_PLUS_HEALTH_MULT
		if current_level == 5:
			health_mult *= POST_LEVEL_HEALTH_GROWTH
			health_mult *= 1.0 + POST_LEVEL_HEALTH_LINEAR
		elif current_level > 5:
			var level_5_mult = LEVEL_4_PLUS_HEALTH_MULT * POST_LEVEL_HEALTH_GROWTH * (1.0 + POST_LEVEL_HEALTH_LINEAR)
			var post_steps = current_level - 5
			health_mult = level_5_mult * pow(POST_LEVEL_6_PLUS_HEALTH_GROWTH, post_steps)
			health_mult *= 1.0 + (post_steps * POST_LEVEL_6_PLUS_HEALTH_LINEAR)
		health = int(max(1.0, round(float(health) * health_mult)))
	var capped = _apply_enemy_count_cap(enemy_type, count, health)
	count = capped.count
	health = capped.health
	var base_reward = type_data.base_reward * HEALTH_REWARD_MULTIPLIER
	var wave_base_reward = ceil(base_reward * (1.0 + wave * 0.1))
	return {
		"type": enemy_type,
		"color": wave_color,
		"health": health,
		"count": count,
		"power": power,
		"base_reward": wave_base_reward
	}

func get_enemy_type_data(enemy_type: String) -> Dictionary:
	return ENEMY_TYPES.get(enemy_type, {})

func record_tower_damage(tower_id: String, amount: int, wave: int) -> void:
	if tower_id == "" or amount <= 0 or wave <= 0:
		return
	if !wave_damage_by_tower.has(wave):
		wave_damage_by_tower[wave] = {}
	var wave_data: Dictionary = wave_damage_by_tower[wave]
	wave_data[tower_id] = int(wave_data.get(tower_id, 0)) + amount
	wave_damage_by_tower[wave] = wave_data

func _on_wave_completed(wave: int) -> void:
	if processed_wave_damage.has(wave):
		return
	processed_wave_damage[wave] = true
	var wave_data: Dictionary = wave_damage_by_tower.get(wave, {})
	recent_wave_damage.append(wave_data.duplicate(true))
	if recent_wave_damage.size() > 2:
		recent_wave_damage.pop_front()
	if wave == current_wave and !_is_spawning and get_tree().get_nodes_in_group("enemy").size() == 0:
		current_wave += 1
		wave_locked = false
		TimelineManager.save_timeline(current_wave)

func _get_unlocked_tower_ids() -> Array[String]:
	var unlocked_ids: Array[String] = []
	var inventory = get_node("/root/InventoryManager")
	for tower_id in inventory.items.keys():
		if inventory.items[tower_id].get("unlocked", false):
			unlocked_ids.append(tower_id)
	unlocked_ids.sort()
	return unlocked_ids

func _compare_ban_entries(a: Dictionary, b: Dictionary) -> bool:
	if a["percent"] == b["percent"]:
		return str(a["id"]) < str(b["id"])
	return a["percent"] > b["percent"]

func _compute_pending_bans() -> void:
	pending_banned_tower_types.clear()
	var unlocked_ids = _get_unlocked_tower_ids()
	if unlocked_ids.size() < 5:
		return
	var ban_count = int(floor(float(unlocked_ids.size()) * 0.25))
	if ban_count < 1:
		return
	var total_damage := 0.0
	var totals: Dictionary = {}
	for wave_data in recent_wave_damage:
		for tower_id in wave_data.keys():
			var dmg = int(wave_data[tower_id])
			totals[tower_id] = int(totals.get(tower_id, 0)) + dmg
			total_damage += dmg
	for tower_id in unlocked_ids:
		if !totals.has(tower_id):
			totals[tower_id] = 0
	if total_damage <= 0.0:
		return
	var entries: Array = []
	for tower_id in unlocked_ids:
		var dmg = int(totals.get(tower_id, 0))
		var percent = float(dmg) / total_damage
		entries.append({"id": tower_id, "percent": percent})
	entries.sort_custom(_compare_ban_entries)
	for i in range(min(ban_count, entries.size())):
		pending_banned_tower_types.append(entries[i]["id"])

func _compute_banned_enemy_types(tower_ids: Array[String]) -> Array[String]:
	var result: Array[String] = []
	for tower_id in tower_ids:
		var counters: Array = BANNED_ENEMY_BY_TOWER.get(tower_id, [])
		for enemy_type in counters:
			if !result.has(enemy_type):
				result.append(enemy_type)
	return result

func activate_pending_bans() -> void:
	banned_tower_types = pending_banned_tower_types.duplicate()
	pending_banned_tower_types.clear()
	banned_enemy_types = _compute_banned_enemy_types(banned_tower_types)

func is_tower_banned(tower_id: String) -> bool:
	return tower_id != "" and banned_tower_types.has(tower_id)

func get_banned_tower_names() -> Array[String]:
	var names: Array[String] = []
	var inventory = get_node("/root/InventoryManager")
	for tower_id in banned_tower_types:
		var def = inventory.items.get(tower_id, {})
		names.append(def.get("name", tower_id))
	names.sort()
	return names

const BANNED_ENEMY_BY_TOWER := {
	"Elephant": ["swarm", "swarmling", "splitter"],
	"Duck": ["swarm", "swarmling", "splitter"],
	"Snail": ["swarm", "swarmling", "splitter"],
	"Hawk": ["stalker"]
}

var pending_banned_tower_types: Array[String] = []
var banned_tower_types: Array[String] = []
var banned_enemy_types: Array[String] = []
var wave_damage_by_tower: Dictionary = {}
var recent_wave_damage: Array[Dictionary] = []
var processed_wave_damage: Dictionary = {}

func get_next_wave_index() -> int:
	if _is_spawning or active_waves.has(current_wave):
		return current_wave + 1
	return current_wave

func get_wave_preview(wave: int) -> Dictionary:
	if wave <= 0:
		return {}
	if wave <= saved_wave_data.size():
		var data = saved_wave_data[wave - 1]
		if not data.has("color"):
			data.color = get_wave_color(wave)
		return data
	var wave_seed = _get_wave_seed(wave)
	var data = _build_wave_data(wave_seed, wave)
	if not data.has("color"):
		data.color = get_wave_color(wave)
	return data

func get_next_wave_preview() -> Dictionary:
	var wave = get_next_wave_index()
	if wave > MAX_WAVES:
		return {}
	return get_wave_preview(wave)

func _calculate_wave_power_mult(wave: int) -> float:
	var wave_power_mult = BASE_WAVE_POWER_MULT
	wave_power_mult *= 1.0 + (current_level - 1) * 0.04
	wave_power_mult *= 1.0 + (wave - 1) * WAVE_ACCELERATION
	match difficulty:
		Difficulty.EASY: wave_power_mult *= 0.75
		Difficulty.HARD: wave_power_mult *= 1.15
	return wave_power_mult


func distribute_wave_power(power: float, type_data: Dictionary) -> Dictionary:
	# How much of the power budget goes to quantity vs durability
	var split = _split_wave_power(power)
	var count = split.count
	var health = split.health

	# Apply enemy-type modifiers AFTER distribution
	count = int(ceil(count * type_data.count_mult))
	health = int(health * type_data.health)

	return {
		"count": count,
		"health": health
	}

func _split_wave_power(power: float) -> Dictionary:
	var count = int(max(1, round(pow(power, COUNT_WEIGHT))))
	var health = int(max(1, round(pow(power, HEALTH_WEIGHT))))
	return {
		"count": count,
		"health": health
	}

func _apply_enemy_count_cap(enemy_type: String, count: int, health: int) -> Dictionary:
	if count <= 0:
		return {"count": 0, "health": health}
	var type_data = ENEMY_TYPES.get(enemy_type, {})
	var max_count = int(type_data.get("max_count", 0))
	if max_count <= 0 or count <= max_count:
		return {"count": count, "health": health}
	var total_hp = count * max(1, health)
	var capped_health = int(max(1, ceil(float(total_hp) / float(max_count))))
	return {"count": max_count, "health": capped_health}

func calculate_target_final_hp(level: int, final_wave: int) -> float:
	return 1000.0 * pow(5.0, level - 5)  # increased from 3.5

#func print_wave_info():
	##var config = get_level_config(current_level)
	#var final_wave = config.waves
	#var base = config.base_health * final_wave
	#var wave_health_base = floor(pow(base, config.health_scale))
	#var enemy_health = wave_health_base * 1.0 * 1.0  # normal type
	#var enemies = max(int(7 * 1.0), 1)
	#var total_hp = enemies * enemy_health
	#print("Level ", current_level, " final wave total HP: ", total_hp)

func get_enemy_death_money():
	var wave_step = 1 + int(floor(float(max(1, current_wave) - 1) / 15.0))
	var reward = floor(current_level / 3) + wave_step * current_wave_base_reward
	if current_level > 3:
		reward *= 0.4
	return int(max(1, reward))

func get_enemy_death_health_gain():
	return BASE_MEAT_REWARD

func calculate_enemy_damage(health, cycles):
	return pow(health + current_wave*3, cycles)

func no_towers_upgraded() -> bool:
	var towers = get_tree().get_nodes_in_group("tower")
	for tower in towers:
		if tower.path != [0, 0, 0]:
			return false
	return true

var types = ENEMY_TYPES.keys()

var MIN_X: int = 1
var  MAX_X: int = 10
var  MIN_Y: int = 1
var  MAX_Y: int = 7
var  BORDER_Y_MIN: int = 0
var  BORDER_Y_MAX: int = 8

var active_waves = {} # wave_number -> remaining_enemies
var current_wave: int = 1
var spawn_delay: float = 1.0

signal wave_completed(wave: int)
signal wave_started(wave: int)
signal level_completed(level: int)

var path_node: Path2D
var path_tiles_container: Node2D

const BASE_PATH_GRID_SIZE = 16
const _MIN_BENDS = 3
const _MAX_STRAIGHT_RUN = 4

func _ready():
	smoothed_power = get_effective_player_power()
	add_to_group("wave_spawner")
	wave_completed.connect(_on_wave_completed)
	path_node = Path2D.new()
	add_child(path_node)
	path_tiles_container = Node2D.new()
	add_child(path_tiles_container)
	set_power_mult()
	set_enemy_config()
	_last_level_cached = current_level
	await get_tree().process_frame
	StatsManager.new_map()
	
	#await get_tree().process_frame#TEST
	#StatsManager.take_damage(99999)#TEST

var level_cleared = false
var winscreen = preload("uid://tv785ptmh83y")
var hint_label = null
var empty_towers_hint = null
var place_towers_hint = null
var _wave_stall_timer: float = 0.0
const WAVE_STALL_GRACE := 2.0

func _is_valid_hint(label: Label) -> bool:
	return label != null and is_instance_valid(label)

func _clear_hint(label: Label) -> void:
	if label != null and is_instance_valid(label):
		label.queue_free()

func clear_hints() -> void:
	_clear_hint(hint_label)
	_clear_hint(empty_towers_hint)
	_clear_hint(place_towers_hint)
	hint_label = null
	empty_towers_hint = null
	place_towers_hint = null

func _process(delta: float) -> void:
	if !_is_spawning and get_tree().get_nodes_in_group("enemy").size() == 0:
		if active_waves.has(current_wave):
			_wave_stall_timer += delta
			if _wave_stall_timer >= WAVE_STALL_GRACE:
				active_waves.erase(current_wave)
				wave_completed.emit(current_wave)
				_wave_stall_timer = 0.0
		else:
			_wave_stall_timer = 0.0
	else:
		_wave_stall_timer = 0.0

	if current_level != _last_level_cached:
		_last_level_cached = current_level
		set_power_mult()
		set_enemy_config()
		level_cleared = false
	#var config = get_level_config(current_level)
		
	#max_waves = config.waves
	if !level_cleared and current_wave > MAX_WAVES and !_is_spawning and get_tree().get_nodes_in_group("enemy").size() == 0:
		level_cleared = true
		_compute_pending_bans()
		level_completed.emit(current_level)

	#Upgrade Towers hint
	if current_level == 1 and current_wave == 3 and !_is_valid_hint(hint_label) and no_towers_upgraded() and get_tree().get_nodes_in_group("enemy").size() == 0 and !WaveSpawner._is_spawning:
		hint_label = Label.new()
		hint_label.text = "Click critters to upgrade them!"
		hint_label.position = Vector2(60, 60)
		hint_label.add_theme_font_size_override("font_size", 24)
		hint_label.add_theme_color_override("font_color", Color.WHITE)
		hint_label.add_theme_font_size_override("font_size", 8)
		hint_label.add_theme_color_override("font_outline_color", Color.BLACK)
		hint_label.add_theme_constant_override("outline_size", 1)
		var tween = create_tween()
		tween.bind_node(hint_label)
		tween.set_loops()
		tween.tween_property(hint_label, "position:y", 82, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(hint_label, "position:y", 80, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		get_tree().current_scene.add_child(hint_label)
	
	if _is_valid_hint(hint_label) and (!no_towers_upgraded() or current_wave == 0):
		hint_label.queue_free()
		hint_label = null
		
	#Place Towers hint
	if current_level == 1 and get_tree().get_nodes_in_group("tower").size() == 0 and !_is_valid_hint(empty_towers_hint) and WaveSpawner._is_spawning:
		empty_towers_hint = Label.new()
		empty_towers_hint.text = "Drag a critter onto the field! :)"
		empty_towers_hint.position = Vector2(60, 80)
		empty_towers_hint.add_theme_font_size_override("font_size", 8)
		empty_towers_hint.add_theme_color_override("font_color", Color.WHITE)
		empty_towers_hint.add_theme_color_override("font_outline_color", Color.BLACK)
		empty_towers_hint.add_theme_constant_override("outline_size", 1)
		var tween = create_tween()
		tween.bind_node(empty_towers_hint)
		tween.set_loops()
		tween.tween_property(empty_towers_hint, "position:y", 82, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(empty_towers_hint, "position:y", 80, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		get_tree().current_scene.add_child(empty_towers_hint)
	
	if _is_valid_hint(empty_towers_hint) and get_tree().get_nodes_in_group("tower").size() > 0:
		empty_towers_hint.queue_free()
		empty_towers_hint = null
	
	if current_level == 1 and current_wave == 2 and get_tree().get_nodes_in_group("tower").size() <= 1 and !_is_valid_hint(place_towers_hint):
		place_towers_hint = Label.new()
		place_towers_hint.text = "Drag another critter onto the field! :)"
		place_towers_hint.position = Vector2(60, 80)
		place_towers_hint.add_theme_font_size_override("font_size", 8)
		place_towers_hint.add_theme_color_override("font_color", Color.WHITE)
		place_towers_hint.add_theme_color_override("font_outline_color", Color.BLACK)
		place_towers_hint.add_theme_constant_override("outline_size", 1)
		var tween = create_tween()
		tween.bind_node(place_towers_hint)
		tween.set_loops()
		tween.tween_property(place_towers_hint, "position:y", 82, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(place_towers_hint, "position:y", 80, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		get_tree().current_scene.add_child(place_towers_hint)
	
	if _is_valid_hint(place_towers_hint) and (current_wave != 2 or get_tree().get_nodes_in_group("tower").size() > 1):
		place_towers_hint.queue_free()
		place_towers_hint = null


func _input(event: InputEvent) -> void:
	if Dev.dev and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_P:
		generate_path(true)
	

func set_game_paused(p: bool) -> void:
	game_paused = p

func await_delay(delay: float) -> void:
	var elapsed: float = 0.0
	while elapsed < delay:
		await get_tree().process_frame
		if not game_paused:
			elapsed += get_process_delta_time()

func get_enemy_type_for_wave(wave: int) -> String:
	# Boss only if exactly every 9th wave (average of 8-10)
	var rng = RandomNumberGenerator.new()
	rng.seed = _get_wave_seed(wave)
	return _pick_enemy_type_for_wave(rng, wave)




func start_next_wave() -> void:
	# Save seed and data for this wave if not already saved
	if current_wave > wave_seeds.size():
		var wave_seed = _get_wave_seed(current_wave)
		wave_seeds.append(wave_seed)
		wave_locked = true
		locked_base_wave_mult = BASE_WAVE_POWER_MULT
		locked_wave_accel = WAVE_ACCELERATION
		committed_wave_power = get_effective_player_power()
		WAVE_POWER_MULT = _calculate_wave_power_mult(current_wave)
		var wave_data = _build_wave_data(wave_seed, current_wave)
		saved_wave_data.append(wave_data)
		current_wave_base_reward = wave_data.base_reward
		active_waves[current_wave] = wave_data.count
		wave_started.emit(current_wave)
		_spawn_wave_async(current_wave, wave_data.type, wave_data.health, wave_data.count, wave_data.get("color", get_wave_color(current_wave)))
		print("Level %d Wave %d | %s | Power: %.1f | Count: %d | Health: %d" %
			[current_level, current_wave, wave_data.type, wave_data.power, wave_data.count, wave_data.health])
	else:
		# Replay saved wave
		var data = saved_wave_data[current_wave - 1]
		var enemy_type = data.type
		var health = data.health
		var count = data.count
		var power = data.power
		current_wave_base_reward = data.base_reward

		active_waves[current_wave] = count
		wave_started.emit(current_wave)
		var wave_color = data.get("color", get_wave_color(current_wave))
		_spawn_wave_async(current_wave, enemy_type, health, count, wave_color)
		print("Level %d Wave %d | %s | Power: %.1f | Count: %d | Health: %d" %
			[current_level, current_wave, enemy_type, power, count, health])

func reset_wave_data() -> void:
	wave_seeds.clear()
	saved_wave_data.clear()
	current_wave = 1
	active_waves.clear()
	wave_damage_by_tower.clear()
	recent_wave_damage.clear()
	processed_wave_damage.clear()
	cancel_current_waves()
	
	

func _spawn_wave_async(wave: int, enemy_type: String, health: int, count: int, wave_color: String) -> void:
	_is_spawning = true
	_remaining_enemies = count
	var delay = max_wave_spawn_time / max(count - 1, 1)
	
	while _remaining_enemies > 0 and _is_spawning:
		spawn_enemy(wave, enemy_type, health, wave_color)
		_remaining_enemies -= 1
		if _remaining_enemies > 0:
			await await_delay(delay)
	
	_is_spawning = false
	


	_is_spawning = false
func spawn_enemy(wave: int, enemy_type: String, health: int, wave_color: String) -> void:
	var enemy = enemy_scene.instantiate()
	var type_data = ENEMY_TYPES[enemy_type]
	
	enemy.position = start_pos + Vector2(0, 4)
	enemy.target_position = end_pos
	
	var power = get_wave_power(current_level, wave)
	var adjusted_health = DifficultyManager.get_enemy_spawn_health(health)
	enemy.max_speed = DifficultyManager.get_enemy_spawn_max_speed(base_speed + pow(power, 0.25))
	enemy.speed = DifficultyManager.get_enemy_spawn_speed(type_data.speed)
	enemy.health = adjusted_health
	enemy.current_health = adjusted_health
	enemy.enemy_type = enemy_type
	enemy.spawn_wave = wave
	enemy.wave_color = wave_color
	add_child(enemy)
	enemy.add_to_group("enemy")
	
	enemy.tree_exited.connect(func():
		if active_waves.has(wave):
			active_waves[wave] -= 1
			if active_waves[wave] <= 0:
				active_waves.erase(wave)
				wave_completed.emit(wave)
				# Force button update
				var button = get_tree().get_first_node_in_group("start_wave_button")
				if button: button.disabled = false
	)


func _pick_path_bounds(level: int, scale: int) -> Dictionary:
	var size_mode = _pick_size_mode(level)
	return _build_bounds_for_size_mode(size_mode, scale)

func _pick_path_bounds_any(scale: int) -> Dictionary:
	var modes = ["small", "large", "mixed"]
	return _build_bounds_for_size_mode(modes[randi_range(0, modes.size() - 1)], scale)

func _build_bounds_for_size_mode(size_mode: String, scale: int) -> Dictionary:
	var base_min_x = MIN_X * scale
	var base_max_x = MAX_X * scale
	var base_min_y = MIN_Y * scale
	var base_max_y = MAX_Y * scale
	var base_width = base_max_x - base_min_x + 1
	var base_height = base_max_y - base_min_y + 1
	var small_width = min(6 * scale, base_width)
	var small_height = min(5 * scale, base_height)
	var small_min_x = base_min_x + int(floor((base_width - small_width) / 2.0))
	var small_min_y = base_min_y + int(floor((base_height - small_height) / 2.0))
	var small_max_x = small_min_x + small_width - 1
	var small_max_y = small_min_y + small_height - 1

	var min_x = base_min_x
	var max_x = base_max_x
	var min_y = base_min_y
	var max_y = base_max_y
	if size_mode == "small":
		min_x = small_min_x
		max_x = small_max_x
		min_y = small_min_y
		max_y = small_max_y

	return {
		"min_x": min_x,
		"max_x": max_x,
		"min_y": min_y,
		"max_y": max_y,
		"border_y_min": BORDER_Y_MIN * scale,
		"border_y_max": BORDER_Y_MAX * scale,
		"size_mode": size_mode,
		"small_min_x": small_min_x,
		"small_max_x": small_max_x,
		"small_min_y": small_min_y,
		"small_max_y": small_max_y,
		"switch_y": small_max_y
	}


func _pick_path_tile_size(level: int, force_all_pools: bool) -> int:
	if force_all_pools:
		return 8 if randf() < 0.5 else 16
	var t = clamp((level - 1) / 12.0, 0.0, 1.0)
	var small_weight = lerp(0.1, 0.35, t)
	if randf() < small_weight:
		return 8
	return 16


func _pick_size_mode(level: int) -> String:
	var t = clamp((level - 1) / 12.0, 0.0, 1.0)
	var small_weight = lerp(0.55, 0.25, t)
	var large_weight = lerp(0.25, 0.45, t)
	var mixed_weight = 1.0 - small_weight - large_weight
	var roll = randf()
	if roll < small_weight:
		return "small"
	if roll < small_weight + large_weight:
		return "large"
	return "mixed"


func _pick_path_pattern(level: int) -> String:
	var t = clamp((level - 1) / 12.0, 0.0, 1.0)
	var simple_weight = lerp(0.6, 0.3, t)
	var medium_weight = lerp(0.3, 0.3, t)
	var complex_weight = 1.0 - simple_weight - medium_weight

	var roll = randf()
	if roll < simple_weight:
		return "zigzag"
	if roll < simple_weight + medium_weight:
		return "wander"
	return "detour"


func _pick_path_pattern_any() -> String:
	var patterns = ["zigzag", "wander", "detour"]
	return patterns[randi_range(0, patterns.size() - 1)]


func _get_x_bounds_for_y(bounds: Dictionary, y: int) -> Vector2i:
	if bounds["size_mode"] == "mixed" and y <= bounds["switch_y"]:
		return Vector2i(bounds["small_min_x"], bounds["small_max_x"])
	return Vector2i(bounds["min_x"], bounds["max_x"])


func _pick_x_away(bounds: Dictionary, y: int, avoid: int) -> int:
	var x_bounds = _get_x_bounds_for_y(bounds, y)
	var x = randi_range(x_bounds.x, x_bounds.y)
	var tries = 0
	while x == avoid and tries < 8:
		x = randi_range(x_bounds.x, x_bounds.y)
		tries += 1
	if x == avoid:
		if x == x_bounds.x:
			x = min(x_bounds.x + 1, x_bounds.y)
		else:
			x = max(x_bounds.x, x_bounds.y - 1)
	return x


func _append_line(path: Array[Vector2i], target: Vector2i) -> void:
	var current = path[path.size() - 1]
	while current != target:
		if current.x != target.x:
			current.x += signi(target.x - current.x)
		elif current.y != target.y:
			current.y += signi(target.y - current.y)
		path.append(current)


func _build_vertical_connector(from_cell: Vector2i, to_cell: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if from_cell.x != to_cell.x:
		return cells
	var step = signi(to_cell.y - from_cell.y)
	if step == 0:
		return cells
	var y = from_cell.y + step
	while y != to_cell.y:
		cells.append(Vector2i(from_cell.x, y))
		y += step
	return cells


func _build_zigzag_path(start: Vector2i, end: Vector2i, bounds: Dictionary, force_extra_bend = false) -> Array[Vector2i]:
	var path: Array[Vector2i] = [start]
	var height = end.y - start.y
	if height < 4:
		return [] as Array[Vector2i]

	var y1 = clampi(start.y + max(1, int(height * 0.33)), bounds["min_y"], bounds["max_y"] - 2)
	var y2 = clampi(start.y + max(2, int(height * 0.66)), y1 + 1, bounds["max_y"] - 1)
	if force_extra_bend:
		y1 = clampi(start.y + 1, bounds["min_y"], bounds["max_y"] - 3)
		y2 = clampi(start.y + max(2, int(height * 0.5)), y1 + 1, bounds["max_y"] - 2)

	var x1 = _pick_x_away(bounds, y1, start.x)
	var x2 = _pick_x_away(bounds, y2, x1)

	_append_line(path, Vector2i(start.x, y1))
	_append_line(path, Vector2i(x1, y1))
	_append_line(path, Vector2i(x1, y2))
	_append_line(path, Vector2i(x2, y2))
	_append_line(path, Vector2i(x2, end.y))
	_append_line(path, Vector2i(end.x, end.y))
	return path


func _build_detour_path(start: Vector2i, end: Vector2i, bounds: Dictionary) -> Array[Vector2i]:
	var path: Array[Vector2i] = [start]
	var height = end.y - start.y
	if height < 4:
		return [] as Array[Vector2i]

	var mid_y = clampi(start.y + int(height * 0.45), bounds["min_y"], bounds["max_y"] - 2)
	var detour_y = clampi(mid_y + max(1, int(height * 0.2)), mid_y + 1, bounds["max_y"] - 1)
	var detour_x = _pick_x_away(bounds, mid_y, start.x)

	_append_line(path, Vector2i(start.x, mid_y))
	_append_line(path, Vector2i(detour_x, mid_y))
	_append_line(path, Vector2i(detour_x, detour_y))
	_append_line(path, Vector2i(end.x, detour_y))
	_append_line(path, Vector2i(end.x, end.y))
	return path


func _build_wander_path(start: Vector2i, end: Vector2i, bounds: Dictionary) -> Array[Vector2i]:
	var path: Array[Vector2i] = [start]
	var visited = {start: true}
	var current = start
	var steps = 0
	var MAX_STEPS = 320
	var DIRS = [Vector2i(0,1), Vector2i(-1,0), Vector2i(1,0), Vector2i(0,-1)]
	var base_weights = [25.0, 10.0, 10.0, 4.0]
	var noise = FastNoiseLite.new()
	noise.seed = randi()
	var last_dir = Vector2i.ZERO
	var run_len = 0

	while steps < MAX_STEPS and current != end:
		steps += 1
		var possible: Array[Vector2i] = []
		var weights: Array[float] = []
		var horiz_dir = signi(end.x - current.x)
		var n = noise.get_noise_2d(current.x * 20.0, current.y * 20.0 + steps)

		for i in 4:
			var dir = DIRS[i]
			var nxt = current + dir
			var x_bounds = _get_x_bounds_for_y(bounds, nxt.y)
			if nxt.x >= x_bounds.x && nxt.x <= x_bounds.y \
			   && nxt.y >= bounds["min_y"] && nxt.y <= bounds["max_y"] \
			   && !visited.has(nxt):
				var w = base_weights[i]
				if i == 1 or i == 2:
					if (i == 1 && horiz_dir < 0) || (i == 2 && horiz_dir > 0):
						w += 12.0
				if dir == last_dir and run_len >= _MAX_STRAIGHT_RUN:
					w *= 0.2
				w += n * 15.0
				possible.append(dir)
				weights.append(max(w, 1.0))
		if possible.is_empty():
			break

		var total = 0.0
		for w in weights:
			total += w
		var roll = randf() * total
		var cum = 0.0
		var chosen = 0
		for i in weights.size():
			cum += weights[i]
			if roll < cum:
				chosen = i
				break

		var chosen_dir = possible[chosen]
		if chosen_dir == last_dir:
			run_len += 1
		else:
			run_len = 1
			last_dir = chosen_dir

		current += chosen_dir
		path.append(current)
		visited[current] = true

	if current == end:
		return path
	return [] as Array[Vector2i]


func _count_bends(path: Array[Vector2i]) -> int:
	if path.size() < 3:
		return 0
	var bends = 0
	var last_dir = Vector2i.ZERO
	for i in range(1, path.size()):
		var dir = path[i] - path[i - 1]
		if last_dir != Vector2i.ZERO and dir != last_dir:
			bends += 1
		last_dir = dir
	return bends


func _is_in_bounds(cell: Vector2i, bounds: Dictionary) -> bool:
	if cell.y < bounds["min_y"] or cell.y > bounds["max_y"]:
		return false
	var x_bounds = _get_x_bounds_for_y(bounds, cell.y)
	return cell.x >= x_bounds.x and cell.x <= x_bounds.y


func _buildable_overlaps_path(world_pos: Vector2, path_cells: Array[Vector2i]) -> bool:
	for path_cell in path_cells:
		var path_pos = Vector2(path_cell) * grid_size + Vector2(grid_size / 2.0, grid_size / 2.0)
		if abs(world_pos.x - path_pos.x) < (grid_size + buildable_grid_size) / 2.0 && \
		   abs(world_pos.y - path_pos.y) < (grid_size + buildable_grid_size) / 2.0:
			return true
	return false


func _apply_path_width(path_cells: Array[Vector2i], bounds: Dictionary, level: int) -> Array[Vector2i]:
	var t = clamp((level - 1) / 10.0, 0.0, 1.0)
	var widen_chance = lerp(0.45, 0.85, t)
	if grid_size <= 8:
		widen_chance = 1.0
	if randf() > widen_chance or path_cells.size() < 8:
		return path_cells

	var widened = path_cells.duplicate()
	var segments = 1
	if randf() < lerp(0.4, 0.7, t):
		segments = 2
	if randf() < lerp(0.2, 0.45, t):
		segments = 3
	if grid_size <= 8:
		segments = max(2, segments)
	for s in range(segments):
		var start_idx = int(path_cells.size() * randf_range(0.1, 0.6))
		var seg_len = int(path_cells.size() * randf_range(0.15, 0.35))
		var end_idx = min(path_cells.size() - 1, start_idx + seg_len)
		var side = -1 if randf() < 0.5 else 1
		var width_target = randi_range(2, 5)
		if grid_size <= 8:
			width_target = randi_range(3, 5)
		var add_other_side = randf() < 0.35
		for i in range(start_idx, end_idx):
			if i == 0:
				continue
			var prev = path_cells[i - 1]
			var cur = path_cells[i]
			var dir = cur - prev
			var axis = Vector2i.ZERO
			if dir.x != 0:
				axis = Vector2i(0, side)
			elif dir.y != 0:
				axis = Vector2i(side, 0)
			for w in range(1, width_target):
				var extra = cur + axis * w
				if _is_in_bounds(extra, bounds) and !widened.has(extra):
					widened.append(extra)
				if add_other_side:
					var extra_other = cur - axis * w
					if _is_in_bounds(extra_other, bounds) and !widened.has(extra_other):
						widened.append(extra_other)
	return widened


func _apply_branching(path_cells: Array[Vector2i], bounds: Dictionary, level: int, force_all_pools: bool) -> Array[Vector2i]:
	if path_cells.size() < 10:
		return []
	var t = clamp((level - 1) / 12.0, 0.0, 1.0)
	var branch_chance = lerp(0.85, 0.98, t)
	if force_all_pools:
		branch_chance = 0.95
	if randf() > branch_chance:
		return []

	var branches = 2
	if randf() < lerp(0.7, 0.9, t):
		branches = 3
	if randf() < lerp(0.35, 0.6, t):
		branches = 4
	if randf() < lerp(0.2, 0.4, t):
		branches = 5

	var extra: Array[Vector2i] = []
	var used_spans = []
	var attempts = 0
	while extra.size() < branches and attempts < branches * 4:
		attempts += 1
		var start_idx = randi_range(2, int(path_cells.size() * 0.4))
		var end_idx = randi_range(start_idx + 3, int(path_cells.size() * 0.75))
		var span_ok = true
		for span in used_spans:
			if start_idx <= span[1] and end_idx >= span[0]:
				span_ok = false
				break
		if not span_ok:
			continue
		used_spans.append([start_idx, end_idx])
		var branch = _build_branch_path(path_cells[start_idx], path_cells[end_idx], bounds)
		for cell in branch:
			if not extra.has(cell):
				extra.append(cell)
	return extra


func _build_branch_path(start: Vector2i, end: Vector2i, bounds: Dictionary) -> Array[Vector2i]:
	var path: Array[Vector2i] = [start]
	var height = end.y - start.y
	if height < 2:
		return []
	var detour_y = clampi(start.y + randi_range(1, max(1, int(height * 0.6))), bounds["min_y"], bounds["max_y"])
	var branch_x = _pick_x_away(bounds, detour_y, start.x)
	_append_line(path, Vector2i(start.x, detour_y))
	_append_line(path, Vector2i(branch_x, detour_y))
	_append_line(path, Vector2i(branch_x, end.y))
	_append_line(path, Vector2i(end.x, end.y))
	return path


func _prune_dead_ends(path_cells: Array[Vector2i], main_cells: Array[Vector2i]) -> Array[Vector2i]:
	var cells: Dictionary = {}
	for cell in path_cells:
		cells[cell] = true
	var main_set: Dictionary = {}
	for cell in main_cells:
		main_set[cell] = true

	var changed = true
	while changed:
		changed = false
		var to_remove: Array[Vector2i] = []
		for cell in cells.keys():
			if main_set.has(cell):
				continue
			var neighbors = 0
			var dirs = [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]
			for dir in dirs:
				if cells.has(cell + dir):
					neighbors += 1
			if neighbors <= 1:
				to_remove.append(cell)
		if to_remove.size() > 0:
			changed = true
			for cell in to_remove:
				cells.erase(cell)

	var pruned: Array[Vector2i] = []
	for cell in cells.keys():
		pruned.append(cell)
	return pruned


func generate_path(force_all_pools = false):

	if force_all_pools:
		randomize()
	else:
		seed(WaveSpawner.current_level + 6 + WaveSpawner.current_level * 2 - 2)
	for child in get_children():
		if child != path_node and child != path_tiles_container:
			child.queue_free()
	for child in path_tiles_container.get_children():
		child.queue_free()

	var is_simple_level = current_level == 1 and !force_all_pools
	grid_size = BASE_PATH_GRID_SIZE if is_simple_level else _pick_path_tile_size(current_level, force_all_pools)
	var scale = int(round(float(BASE_PATH_GRID_SIZE) / float(grid_size)))

	var curve = Curve2D.new()
	var bounds = _pick_path_bounds_any(scale) if force_all_pools else _pick_path_bounds(current_level, scale)
	if is_simple_level:
		bounds = _build_bounds_for_size_mode("small", scale)
	var entry_min_x = bounds["min_x"]
	var entry_max_x = bounds["max_x"]
	if bounds["size_mode"] == "mixed":
		entry_min_x = bounds["small_min_x"]
		entry_max_x = bounds["small_max_x"]
	var entry_x: int = randi_range(entry_min_x, entry_max_x)
	var exit_x: int = entry_x if is_simple_level else randi_range(bounds["min_x"], bounds["max_x"])
	var entry_cell = Vector2i(entry_x, bounds["border_y_min"])
	var exit_cell = Vector2i(exit_x, bounds["border_y_max"])
	var internal_start = Vector2i(entry_x, bounds["min_y"])
	var internal_end = Vector2i(exit_x, bounds["max_y"])
	var internal_path_cells: Array[Vector2i] = []
	var found = false
	var MAX_ATTEMPTS = 120
	var attempts = 0

	if is_simple_level:
		var height = internal_end.y - internal_start.y
		var y1 = clampi(internal_start.y + 1, bounds["min_y"], bounds["max_y"] - 3)
		var y2 = clampi(internal_start.y + int(round(height * 0.45)), y1 + 1, bounds["max_y"] - 2)
		var y3 = clampi(internal_start.y + int(round(height * 0.75)), y2 + 1, bounds["max_y"] - 1)
		var x1 = _pick_x_away(bounds, y1, entry_x)
		var x2 = _pick_x_away(bounds, y2, x1)
		if x2 == entry_x:
			x2 = _pick_x_away(bounds, y2, entry_x)
		var x3 = entry_x

		internal_path_cells = [internal_start]
		_append_line(internal_path_cells, Vector2i(entry_x, y1))
		_append_line(internal_path_cells, Vector2i(x1, y1))
		_append_line(internal_path_cells, Vector2i(x1, y2))
		_append_line(internal_path_cells, Vector2i(x2, y2))
		_append_line(internal_path_cells, Vector2i(x2, y3))
		_append_line(internal_path_cells, Vector2i(x3, y3))
		_append_line(internal_path_cells, internal_end)
		found = true
	else:
		while not found and attempts < MAX_ATTEMPTS:
			attempts += 1
			var pattern = _pick_path_pattern_any() if force_all_pools else _pick_path_pattern(current_level)
			if pattern == "zigzag":
				internal_path_cells = _build_zigzag_path(internal_start, internal_end, bounds)
			elif pattern == "detour":
				internal_path_cells = _build_detour_path(internal_start, internal_end, bounds)
			else:
				internal_path_cells = _build_wander_path(internal_start, internal_end, bounds)

			if internal_path_cells.is_empty():
				continue
			if _count_bends(internal_path_cells) < _MIN_BENDS:
				continue
			found = true

	if not found:
		internal_path_cells = _build_zigzag_path(internal_start, internal_end, bounds, true)

	var full_path_cells: Array[Vector2i] = [entry_cell]
	full_path_cells.append_array(_build_vertical_connector(entry_cell, internal_start))
	full_path_cells.append_array(internal_path_cells)
	full_path_cells.append_array(_build_vertical_connector(internal_end, exit_cell))
	full_path_cells.append(exit_cell)

	var main_path_cells = full_path_cells.duplicate()
	if not is_simple_level:
		var branch_cells = _apply_branching(internal_path_cells, bounds, current_level, force_all_pools)
		for cell in branch_cells:
			if not full_path_cells.has(cell):
				full_path_cells.append(cell)

		full_path_cells = _apply_path_width(full_path_cells, bounds, current_level)
		full_path_cells = _prune_dead_ends(full_path_cells, main_path_cells)
	
	var off_top = Vector2(entry_x * grid_size + grid_size / 2.0, -8.0)
	curve.add_point(off_top)
	curve.add_point(Vector2(entry_cell) * grid_size + Vector2(grid_size / 2.0, grid_size / 2.0))
	for cell in internal_path_cells:
		curve.add_point(Vector2(cell) * grid_size + Vector2(grid_size / 2.0, grid_size / 2.0))
	var exit_point = Vector2(exit_cell) * grid_size + Vector2(grid_size / 2.0, grid_size / 2.0)
	curve.add_point(exit_point)
	path_node.curve = curve
	
	start_pos.x = off_top.x
	end_pos.x = exit_point.x
	end_pos.y = exit_point.y
	
	var tile_scene = ResourceLoader.load(path_tile_uid) as PackedScene
	if tile_scene:
		for cell in full_path_cells:
			var pos = Vector2(cell) * grid_size + Vector2(grid_size / 2.0, grid_size / 2.0)
			var tile = tile_scene.instantiate()
			if tile.has_method("apply_cell_size"):
				var tile_size = grid_size
				if cell == entry_cell:
					tile_size = BASE_PATH_GRID_SIZE
				tile.apply_cell_size(tile_size)
			tile.position = pos
			path_tiles_container.add_child(tile)
	else:
		push_error("Invalid path_tile_uid")
	
	var buildable_scene = ResourceLoader.load(path_buildable_uid) as PackedScene
	if buildable_scene:
		var buildable_min_x = 1
		var buildable_max_x = 22
		var buildable_min_y = 1
		var buildable_max_y = 15
		for bx in range(buildable_min_x, buildable_max_x + 1):
			for by in range(buildable_min_y, buildable_max_y + 1):
				var world_pos = Vector2(bx * buildable_grid_size + buildable_grid_size / 2.0,
										 by * buildable_grid_size + buildable_grid_size / 2.0)
				var overlaps_path = false
				for path_cell in full_path_cells:
					var path_pos = Vector2(path_cell) * grid_size + Vector2(grid_size / 2.0, grid_size / 2.0)
					if abs(world_pos.x - path_pos.x) < (grid_size + buildable_grid_size) / 2.0 && \
					   abs(world_pos.y - path_pos.y) < (grid_size + buildable_grid_size) / 2.0:
						overlaps_path = true
						break
				if not overlaps_path:
					var buildable = buildable_scene.instantiate()
					buildable.position = world_pos
					add_child(buildable)
	else:
		push_error("Invalid path_buildable_uid")
	
	await get_tree().process_frame
	if special_scene:
		var buildables = get_tree().get_nodes_in_group("grid_buildable")
		var positions = buildables.map(func(b): return Vector2(b.position.x / buildable_grid_size, b.position.y / buildable_grid_size).round())
		var safe_positions: Dictionary = {}
		for i in buildables.size():
			if not _buildable_overlaps_path(buildables[i].position, full_path_cells):
				safe_positions[positions[i]] = true
		
		var cluster_min = 12 + int(floor(current_level * 0.35))
		var cluster_max = 20 + int(floor(current_level * 0.5))
		var clusters = randi_range(cluster_min, cluster_max)
		var special_grid: Dictionary = {}
		
		for i in clusters:
			seed(i+current_level)
			var size: int = randi_range(5, 15)
			if safe_positions.is_empty(): break
			var safe_list = safe_positions.keys()
			var start_pos = safe_list[randi() % safe_list.size()]
			var queue: Array[Vector2] = [start_pos]
			special_grid[start_pos] = true
			var placed: int = 1
			
			while placed < size and not queue.is_empty():
				var cur: Vector2 = queue.pop_back()
				var dirs: Array[Vector2i] = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1), Vector2i(1,1), Vector2i(1,-1), Vector2i(-1,1), Vector2i(-1,-1)]
				dirs.shuffle()
				for d in dirs:
					var nxt: Vector2 = Vector2(cur) + Vector2(d)
					if safe_positions.has(nxt) and not special_grid.has(nxt):
						special_grid[nxt] = true
						queue.append(nxt)
						placed += 1
						break
		
		
		for i in buildables.size():
			if special_grid.has(positions[i]):
				var old = buildables[i]
				var special = special_scene.instantiate()
				special.position = old.position
				add_child(special)
				old.queue_free()
	
	
	GridController.update_buildables()
	AStarManager._update_grid()	


var _is_spawning: bool = false
var _remaining_enemies: int = 0


func cancel_current_waves() -> void:
	_is_spawning = false
	_remaining_enemies = 0
	active_waves.clear()
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(enemy):
			enemy.queue_free()
	current_wave = 1
