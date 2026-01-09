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
var locked_base_wave_mult := 1.0
var locked_wave_accel := 1.0
var wave_seeds: Array[int] = []
var saved_wave_data: Array[Dictionary] = []

enum Difficulty { EASY, NORMAL, HARD }
@export var difficulty := Difficulty.NORMAL
@export var BASE_WAVE_POWER_MULT := 1.0
var WAVE_POWER_MULT := 1.0
var WAVE_ACCELERATION := 1.0
var MAX_WAVES = 1
var HEALTH_REWARD_FACTOR = 0.35
var HEALTH_REWARD_MULTIPLIER = 1.0
var COUNT_WEIGHT = 0.3
var HEALTH_WEIGHT = 0.7
var smoothed_power := 1.0
var _last_level_cached: int = -1
const WAVE_COLORS := ["red", "green", "blue"]


func get_wave_power(level: int, wave: int) -> float:
	return get_wave_power_with_mult_and_player(level, wave, WAVE_POWER_MULT, committed_wave_power)

func get_wave_power_with_mult(level: int, wave: int, power_mult: float) -> float:
	return get_wave_power_with_mult_and_player(level, wave, power_mult, committed_wave_power)

func get_wave_power_with_mult_and_player(level: int, wave: int, power_mult: float, player_power: float) -> float:
	var base := 75.0  # higher base to avoid too-easy early waves
	var level_scale := pow(1.3, level)  # stronger level scaling
	var early_waves = min(wave - 1, 9)
	var late_waves = max(0, wave - 10)
	var wave_scale := pow(1.04, early_waves) * pow(1.02, late_waves)  # soften after wave 10
	var player_factor = max(1.0, player_power) / 20.0  # linear tracking
	return base * level_scale * wave_scale * player_factor * power_mult / 5

func get_effective_player_power() -> float:
	var field_power := InventoryManager.get_total_field_dps()
	var roster_power := InventoryManager.get_player_power_score()
	return (field_power * 0.7) + (roster_power * 0.3)

func set_power_mult():
	
	BASE_WAVE_POWER_MULT = 1.6
	WAVE_ACCELERATION = 0.14
	MAX_WAVES = 10 + floor(current_level / 2) * 2 if current_level > 1 else 6
	COUNT_WEIGHT = 0.45
	HEALTH_WEIGHT = 0.55
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
		"min_wave": 1,
		"label": "Normal",
		"abilities": []
	},
	"swarm": {
		"health": 1,
		"speed": 8.0,
		"damage": 5,
		"base_reward": 0.5,
		"count_mult": 1.4,
		"min_wave": 1,
		"label": "Swarm",
		"abilities": ["Smaller bodies, higher counts."]
	},
	"fast": {
		"health": 0.6,
		"speed": 25.0,
		"damage": 10,
		"base_reward": 0.75,
		"count_mult": 1.5,
		"min_wave": 1,
		"label": "Fast",
		"abilities": ["Moves much faster than normal."]
	},
	"splitter": {
		"health": 0.9,
		"speed": 9.0,
		"damage": 10,
		"base_reward": 0.8,
		"count_mult": 0.9,
		"min_wave": 3,
		"label": "Splitter",
		"abilities": ["Splits into 2 swarmlings on death."]
	},
	"spirit_fox": {
		"health": 0.8,
		"speed": 12.0,
		"damage": 10,
		"base_reward": 0.9,
		"count_mult": 0.95,
		"min_wave": 4,
		"label": "Spirit Fox",
		"abilities": ["Phases out, becoming untargetable briefly."]
	},
	"regenerator": {
		"health": 1.0,
		"speed": 9.0,
		"damage": 10,
		"base_reward": 1.0,
		"count_mult": 0.9,
		"min_wave": 4,
		"label": "Regenerator",
		"abilities": ["Regenerates health over time."]
	},
	"revenant": {
		"health": 1.1,
		"speed": 8.0,
		"damage": 12,
		"base_reward": 1.1,
		"count_mult": 0.8,
		"min_wave": 5,
		"label": "Revenant",
		"abilities": ["Revives once at half health."]
	},
	"swarmling": {
		"health": 0.4,
		"speed": 14.0,
		"damage": 6,
		"base_reward": 0.3,
		"count_mult": 2.0,
		"min_wave": 2,
		"label": "Swarmling",
		"abilities": ["Tiny and fast, spawns in large numbers."]
	},
	"hardened": {
		"health": 1.3,
		"speed": 7.0,
		"damage": 12,
		"base_reward": 1.2,
		"count_mult": 0.8,
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
		"min_wave": 6,
		"label": "Stalker",
		"abilities": ["Periodically becomes untargetable."]
	},
	"boss": {
		"health": 2.5,
		"speed": 5.0,
		"damage": 50,
		"base_reward": 7.0,
		"count_mult": 0.2,
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
			"min_wave": 1,
			"label": "Normal",
			"abilities": []
		},
		"swarm": {
			"health": 0.6,
			"speed": 8.0,
			"damage": 5,
			"base_reward": 0.5,
			"count_mult": 1.4,
			"min_wave": 1,
			"label": "Swarm",
			"abilities": ["Smaller bodies, higher counts."]
		},
		"fast": {
			"health": 0.6,
			"speed": 25.0,
			"damage": 10,
			"base_reward": 0.75,
			"count_mult": 1.0,
			"min_wave": 1,
			"label": "Fast",
			"abilities": ["Moves much faster than normal."]
		},
		"splitter": {
			"health": 0.9,
			"speed": 9.0,
			"damage": 10,
			"base_reward": 0.8,
			"count_mult": 0.9,
			"min_wave": 3,
			"label": "Splitter",
			"abilities": ["Splits into 2 swarmlings on death."]
		},
		"spirit_fox": {
			"health": 0.8,
			"speed": 12.0,
			"damage": 10,
			"base_reward": 0.9,
			"count_mult": 0.95,
			"min_wave": 4,
			"label": "Spirit Fox",
			"abilities": ["Phases out, becoming untargetable briefly."]
		},
		"regenerator": {
			"health": 1.0,
			"speed": 9.0,
			"damage": 10,
			"base_reward": 1.0,
			"count_mult": 0.9,
			"min_wave": 4,
			"label": "Regenerator",
			"abilities": ["Regenerates health over time."]
		},
		"revenant": {
			"health": 1.1,
			"speed": 8.0,
			"damage": 12,
			"base_reward": 1.1,
			"count_mult": 0.8,
			"min_wave": 5,
			"label": "Revenant",
			"abilities": ["Revives once at half health."]
		},
		"swarmling": {
			"health": 0.4,
			"speed": 14.0,
			"damage": 6,
			"base_reward": 0.3,
			"count_mult": 2.0,
			"min_wave": 2,
			"label": "Swarmling",
			"abilities": ["Tiny and fast, spawns in large numbers."]
		},
		"hardened": {
			"health": 1.3,
			"speed": 7.0,
			"damage": 12,
			"base_reward": 1.2,
			"count_mult": 0.8,
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
			"min_wave": 6,
			"label": "Stalker",
			"abilities": ["Periodically becomes untargetable."]
		},
		"boss": {
			"health": 4.0,
			"speed": 5.0,
			"damage": 50,
			"base_reward": 1.0,
			"count_mult": 0.2,
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
	#var lvl := level - 3
#
	#var base_health := 3.0 * pow(1.35, lvl)
	#var wave_growth := (1.12 + lvl * 0.008 + (0.002 + current_wave * 0.012)/pow(current_wave, 0.7))/pow(current_wave, 0.02)
	#var waves = 12 + floor(lvl/3) * 2


	#return {
		#base_health = base_health,
		#wave_growth = wave_growth,
		#waves = waves
	#}

func get_smoothed_player_power() -> float:
	smoothed_power = lerp(smoothed_power, get_effective_player_power(), 0.25)
	return smoothed_power

func _get_wave_seed(wave: int) -> int:
	return current_level * 10000 + wave

func get_wave_color(wave: int) -> String:
	var rng := RandomNumberGenerator.new()
	rng.seed = _get_wave_seed(wave)
	_pick_enemy_type_for_wave(rng, wave)
	return WAVE_COLORS[rng.randi_range(0, WAVE_COLORS.size() - 1)]

func _get_enemy_pool_for_wave(wave: int) -> Array[String]:
	var keys: Array[String] = []
	for key in ENEMY_TYPES.keys():
		if key == "boss":
			continue
		var min_wave = int(ENEMY_TYPES[key].get("min_wave", 1))
		if wave >= min_wave:
			keys.append(key)
	if keys.is_empty():
		keys.append("normal")
	return keys

func _pick_enemy_type_for_wave(rng: RandomNumberGenerator, wave: int) -> String:
	if wave % 9 == 0:
		return "boss"
	var keys := _get_enemy_pool_for_wave(wave)
	return keys[rng.randi_range(0, keys.size() - 1)]

func _build_wave_data(wave_seed: int, wave: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = wave_seed
	var enemy_type = _pick_enemy_type_for_wave(rng, wave)
	var wave_color = WAVE_COLORS[rng.randi_range(0, WAVE_COLORS.size() - 1)]
	var type_data = ENEMY_TYPES[enemy_type]
	var wave_power_mult := _calculate_wave_power_mult(wave)
	var player_power := get_effective_player_power()
	var power := get_wave_power_with_mult_and_player(current_level, wave, wave_power_mult, player_power)
	var raw_count = round(pow(power, COUNT_WEIGHT))
	var raw_health = round(pow(power, HEALTH_WEIGHT))
	var count := ceil(raw_count * type_data.count_mult) as int
	var health := (raw_health * type_data.health) as int
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
	var wave_power_mult := BASE_WAVE_POWER_MULT
	wave_power_mult *= 1.0 + (current_level - 1) * 0.04
	wave_power_mult *= 1.0 + (wave - 1) * WAVE_ACCELERATION
	match difficulty:
		Difficulty.EASY: wave_power_mult *= 0.75
		Difficulty.HARD: wave_power_mult *= 1.15
	return wave_power_mult


func distribute_wave_power(power: float, type_data: Dictionary) -> Dictionary:
	# How much of the power budget goes to quantity vs durability

	var count := int(max(1, round(pow(power, COUNT_WEIGHT))))
	var health := int(max(1, round(pow(power, HEALTH_WEIGHT))))

	# Apply enemy-type modifiers AFTER distribution
	count = int(ceil(count * type_data.count_mult))
	health = int(health * type_data.health)

	return {
		"count": count,
		"health": health
	}

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
	return int(max(1, floor(current_level/3) + ceil(current_wave/5)*current_wave_base_reward))

func get_enemy_death_health_gain():
	return int(max(1, current_wave_base_reward))

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

var active_waves := {} # wave_number -> remaining_enemies
var current_wave: int = 1
var spawn_delay: float = 1.0

signal wave_completed(wave: int)
signal wave_started(wave: int)

var path_node: Path2D
var path_tiles_container: Node2D

func _ready():
	smoothed_power = get_effective_player_power()
	add_to_group("wave_spawner")
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
	if current_level != _last_level_cached:
		_last_level_cached = current_level
		set_power_mult()
		set_enemy_config()
	#var config = get_level_config(current_level)
		
	#max_waves = config.waves
	if current_wave > MAX_WAVES and !_is_spawning and get_tree().get_nodes_in_group("enemy").size() == 0:
		level_cleared = true

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
	var rng := RandomNumberGenerator.new()
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
	var enemy := enemy_scene.instantiate()
	var type_data = ENEMY_TYPES[enemy_type]
	
	enemy.position = start_pos + Vector2(0, 4)
	enemy.target_position = end_pos
	
	var power := get_wave_power(current_level, wave)
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


func generate_path():
	
	seed(WaveSpawner.current_level+6 + WaveSpawner.current_level*2-2)
	for child in get_children():
		if child != path_node and child != path_tiles_container:
			child.queue_free()
	for child in path_tiles_container.get_children():
		child.queue_free()
	
	var curve := Curve2D.new()
	var entry_x: int = randi_range(MIN_X, MAX_X)
	var exit_x: int = randi_range(MIN_X, MAX_X)
	var entry_cell := Vector2i(entry_x, BORDER_Y_MIN)
	var exit_cell := Vector2i(exit_x, BORDER_Y_MAX)
	var internal_start := Vector2i(entry_x, MIN_Y)
	var internal_end := Vector2i(exit_x, MAX_Y)
	var internal_path_cells: Array[Vector2i] = []
	var found := false
	var MAX_ATTEMPTS := 100
	var attempts := 0
	
	while not found and attempts < MAX_ATTEMPTS:
		attempts += 1
		internal_path_cells = [internal_start]
		var visited := {internal_start: true}
		var current := internal_start
		var steps := 0
		var MAX_STEPS := 300
		var DIRS := [Vector2i(0,1), Vector2i(-1,0), Vector2i(1,0), Vector2i(0,-1)]
		var base_weights := [25.0, 10.0, 10.0, 4.0]
		var noise := FastNoiseLite.new()
		noise.seed = randi()
		
		while steps < MAX_STEPS and current != internal_end:
			steps += 1
			var possible: Array[Vector2i] = []
			var weights: Array[float] = []
			var horiz_dir := signi(internal_end.x - current.x)
			var n := noise.get_noise_2d(current.x * 20.0, current.y * 20.0 + steps)
			for i in 4:
				var dir = DIRS[i]
				var nxt = current + dir
				if nxt.x >= MIN_X && nxt.x <= MAX_X \
				   && nxt.y >= MIN_Y && nxt.y <= MAX_Y \
				   && !visited.has(nxt):
					var w = base_weights[i]
					if i == 1 or i == 2:
						if (i == 1 && horiz_dir < 0) || (i == 2 && horiz_dir > 0):
							w += 12.0
					w += n * 15.0
					possible.append(dir)
					weights.append(max(w, 1.0))
			if possible.is_empty(): break
			var total := 0.0
			for w in weights: total += w
			var roll := randf() * total
			var cum := 0.0
			var chosen := 0
			for i in weights.size():
				cum += weights[i]
				if roll < cum:
					chosen = i
					break
			current += possible[chosen]
			internal_path_cells.append(current)
			visited[current] = true
			if current == internal_end:
				found = true
	
	if not found:
		internal_path_cells = []
		var cx := entry_x
		for y in range(MIN_Y, MAX_Y + 1):
			internal_path_cells.append(Vector2i(cx, y))
		var horiz_dir := signi(exit_x - cx)
		if horiz_dir != 0:
			cx += horiz_dir
			while cx != exit_x:
				internal_path_cells.append(Vector2i(cx, MAX_Y))
				cx += horiz_dir
	
	var full_path_cells := [entry_cell]
	full_path_cells.append_array(internal_path_cells)
	full_path_cells.append(exit_cell)
	
	var off_top := Vector2(entry_x * grid_size + grid_size / 2.0, -8.0)
	curve.add_point(off_top)
	curve.add_point(Vector2(entry_cell) * grid_size + Vector2(grid_size / 2.0, grid_size / 2.0))
	for cell in internal_path_cells:
		curve.add_point(Vector2(cell) * grid_size + Vector2(grid_size / 2.0, grid_size / 2.0))
	var exit_point := Vector2(exit_cell) * grid_size + Vector2(grid_size / 2.0, grid_size / 2.0)
	curve.add_point(exit_point)
	path_node.curve = curve
	
	start_pos.x = off_top.x
	end_pos.x = exit_point.x
	end_pos.y = exit_point.y
	
	var tile_scene := ResourceLoader.load(path_tile_uid) as PackedScene
	if tile_scene:
		for cell in full_path_cells:
			var pos := Vector2(cell) * grid_size + Vector2(grid_size / 2.0, grid_size / 2.0)
			var tile := tile_scene.instantiate()
			tile.position = pos
			path_tiles_container.add_child(tile)
	else:
		push_error("Invalid path_tile_uid")
	
	var buildable_scene := ResourceLoader.load(path_buildable_uid) as PackedScene
	if buildable_scene:
		var buildable_min_x := 1
		var buildable_max_x := 22
		var buildable_min_y := 1
		var buildable_max_y := 15
		for bx in range(buildable_min_x, buildable_max_x + 1):
			for by in range(buildable_min_y, buildable_max_y + 1):
				var world_pos := Vector2(bx * buildable_grid_size + buildable_grid_size / 2.0,
										 by * buildable_grid_size + buildable_grid_size / 2.0)
				var overlaps_path := false
				for path_cell in full_path_cells:
					var path_pos := Vector2(path_cell) * grid_size + Vector2(grid_size / 2.0, grid_size / 2.0)
					if abs(world_pos.x - path_pos.x) < (grid_size + buildable_grid_size) / 2.0 && \
					   abs(world_pos.y - path_pos.y) < (grid_size + buildable_grid_size) / 2.0:
						overlaps_path = true
						break
				if not overlaps_path:
					var buildable := buildable_scene.instantiate()
					buildable.position = world_pos
					add_child(buildable)
	else:
		push_error("Invalid path_buildable_uid")
	
	await get_tree().process_frame
	if special_scene:
		var buildables := get_tree().get_nodes_in_group("grid_buildable")
		var positions := buildables.map(func(b): return Vector2(b.position.x / buildable_grid_size, b.position.y / buildable_grid_size).round())
		
		var clusters: int = randi_range(8, 14)
		var special_grid: Dictionary = {}
		
		for i in clusters:
			seed(i+current_level)
			var size: int = randi_range(5, 15)
			if buildables.is_empty(): break
			var start_idx: int = randi() % buildables.size()
			var queue: Array[Vector2] = [positions[start_idx]]
			special_grid[positions[start_idx]] = true
			var placed: int = 1
			
			while placed < size and not queue.is_empty():
				var cur: Vector2 = queue.pop_back()
				var dirs: Array[Vector2i] = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1), Vector2i(1,1), Vector2i(1,-1), Vector2i(-1,1), Vector2i(-1,-1)]
				dirs.shuffle()
				for d in dirs:
					var nxt: Vector2 = Vector2(cur) + Vector2(d)
					var idx: int = positions.find(nxt)
					if idx != -1 and not special_grid.has(nxt):
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
