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


func get_wave_power(level: int, wave: int) -> float:
	var base := 24.0  # was 10.0
	var level_scale := pow(1.3, level)  # stronger level scaling
	var wave_scale := pow(1.13, wave - 1)  # was 1.12
	var player_factor := pow(committed_wave_power / 20.0, 0.45)  # was 0.35
	return base * level_scale * wave_scale * player_factor * WAVE_POWER_MULT /5

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
		"count_mult": 1.0
	},
	"swarm": {
		"health": 1,
		"speed": 8.0,
		"damage": 5,
		"base_reward": 0.5,
		"count_mult": 1.4
	},
	"fast": {
		"health": 0.6,
		"speed": 25.0,
		"damage": 10,
		"base_reward": 0.75,
		"count_mult": 1.5
	},
	"boss": {
		"health": 2.5,
		"speed": 5.0,
		"damage": 50,
		"base_reward": 7.0,
		"count_mult": 0.2
	}
}

func set_enemy_config():
	ENEMY_TYPES = {
		"normal": {
			"health": 1,
			"speed": 10.0,
			"damage": 10,
			"base_reward": 1.0,
			"count_mult": 1.0
		},
		"swarm": {
			"health": 0.6,
			"speed": 8.0,
			"damage": 5,
			"base_reward": 0.5,
			"count_mult": 1.4
		},
		"fast": {
			"health": 0.6,
			"speed": 25.0,
			"damage": 10,
			"base_reward": 0.75,
			"count_mult": 1.0
		},
		"boss": {
			"health": 4.0,
			"speed": 5.0,
			"damage": 50,
			"base_reward": 1.0,
			"count_mult": 0.2
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
	smoothed_power = lerp(smoothed_power, InventoryManager.get_player_power_score(), 0.25)
	return smoothed_power


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
	smoothed_power = InventoryManager.get_player_power_score()
	add_to_group("wave_spawner")
	path_node = Path2D.new()
	add_child(path_node)
	path_tiles_container = Node2D.new()
	add_child(path_tiles_container)
	await get_tree().process_frame
	StatsManager.new_map()
	
	#await get_tree().process_frame#TEST
	#StatsManager.take_damage(99999)#TEST

var level_cleared = false
var winscreen = preload("uid://tv785ptmh83y")
var hint_label = null
var empty_towers_hint = null
var place_towers_hint = null
func _process(delta: float) -> void:
	set_power_mult()
	set_enemy_config()
	#var config = get_level_config(current_level)
		
	#max_waves = config.waves
	if current_wave > MAX_WAVES and !_is_spawning and get_tree().get_nodes_in_group("enemy").size() == 0:
		level_cleared = true

	#Upgrade Towers hint
	if current_level == 1 and current_wave == 3 and !hint_label and no_towers_upgraded() and get_tree().get_nodes_in_group("enemy").size() == 0 and !WaveSpawner._is_spawning:
		hint_label = Label.new()
		hint_label.text = "Click critters to upgrade them!"
		hint_label.position = Vector2(60, 60)
		hint_label.add_theme_font_size_override("font_size", 24)
		hint_label.add_theme_color_override("font_color", Color.WHITE)
		hint_label.add_theme_font_size_override("font_size", 8)
		hint_label.add_theme_color_override("font_outline_color", Color.BLACK)
		hint_label.add_theme_constant_override("outline_size", 1)
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(hint_label, "position:y", 82, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(hint_label, "position:y", 80, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		get_tree().current_scene.add_child(hint_label)
	
	if hint_label and (!no_towers_upgraded() or current_wave == 0):
		hint_label.queue_free()
		
	#Place Towers hint
	if current_level == 1 and get_tree().get_nodes_in_group("tower").size() == 0 and empty_towers_hint == null and WaveSpawner._is_spawning:
		empty_towers_hint = Label.new()
		empty_towers_hint.text = "Drag a critter onto the field! :)"
		empty_towers_hint.position = Vector2(60, 80)
		empty_towers_hint.add_theme_font_size_override("font_size", 8)
		empty_towers_hint.add_theme_color_override("font_color", Color.WHITE)
		empty_towers_hint.add_theme_color_override("font_outline_color", Color.BLACK)
		empty_towers_hint.add_theme_constant_override("outline_size", 1)
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(empty_towers_hint, "position:y", 82, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(empty_towers_hint, "position:y", 80, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		get_tree().current_scene.add_child(empty_towers_hint)
	
	if empty_towers_hint and get_tree().get_nodes_in_group("tower").size() > 0:
		empty_towers_hint.queue_free()
		empty_towers_hint = null
	
	if current_level == 1 and current_wave == 2 and get_tree().get_nodes_in_group("tower").size() <= 1 and place_towers_hint == null:
		place_towers_hint = Label.new()
		place_towers_hint.text = "Drag another critter onto the field! :)"
		place_towers_hint.position = Vector2(60, 80)
		place_towers_hint.add_theme_font_size_override("font_size", 8)
		place_towers_hint.add_theme_color_override("font_color", Color.WHITE)
		place_towers_hint.add_theme_color_override("font_outline_color", Color.BLACK)
		place_towers_hint.add_theme_constant_override("outline_size", 1)
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(place_towers_hint, "position:y", 82, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(place_towers_hint, "position:y", 80, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		get_tree().current_scene.add_child(place_towers_hint)
	
	if place_towers_hint and (current_wave != 2 or get_tree().get_nodes_in_group("tower").size() > 1):
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
	if wave % 9 == 0:
		return "boss"
	
	var keys := ENEMY_TYPES.keys()
	keys.erase("boss")
	return keys[randi() % keys.size()]




func start_next_wave() -> void:
	# Save seed and data for this wave if not already saved
	if current_wave > wave_seeds.size():
		var wave_seed = current_level * 10000 + current_wave
		wave_seeds.append(wave_seed)
		seed(wave_seed)
		wave_locked = true
		locked_base_wave_mult = BASE_WAVE_POWER_MULT
		locked_wave_accel = WAVE_ACCELERATION
		committed_wave_power = InventoryManager.get_player_power_score()
		var wave_power_mult := BASE_WAVE_POWER_MULT
		wave_power_mult *= 1.0 + (current_level - 1) * 0.04
		wave_power_mult *= 1.0 + (current_wave - 1) * WAVE_ACCELERATION
		match difficulty:
			Difficulty.EASY: wave_power_mult *= 0.75
			Difficulty.HARD: wave_power_mult *= 1.15
		WAVE_POWER_MULT = wave_power_mult
		var enemy_type = "boss" if current_wave % 9 == 0 else ["normal", "swarm", "fast"].pick_random()
		var type_data = ENEMY_TYPES[enemy_type]
		var power := get_wave_power(current_level, current_wave)
		var raw_count = round(pow(power, COUNT_WEIGHT))
		var raw_health = round(pow(power, HEALTH_WEIGHT))
		var count := ceil(raw_count * type_data.count_mult) as int
		var health := (raw_health * type_data.health) as int
		var base_reward = type_data.base_reward * HEALTH_REWARD_MULTIPLIER
		var wave_base_reward = ceil(base_reward * (1.0 + current_wave*0.1))
		saved_wave_data.append({
			"type": enemy_type,
			"health": health,
			"count": count,
			"power": power,
			"base_reward": wave_base_reward
		})
		
		active_waves[current_wave] = count
		wave_started.emit(current_wave)
		_spawn_wave_async(current_wave, enemy_type, health, count)
		print("Level %d Wave %d | %s | Power: %.1f | Count: %d | Health: %d" %
			[current_level, current_wave, enemy_type, power, count, health])
	else:
		# Replay saved wave
		seed(wave_seeds[current_wave - 1])
		var data = saved_wave_data[current_wave - 1]
		var enemy_type = data.type
		var health = data.health
		var count = data.count
		var power = data.power
		current_wave_base_reward = data.base_reward

		active_waves[current_wave] = count
		wave_started.emit(current_wave)
		_spawn_wave_async(current_wave, enemy_type, health, count)
		print("Level %d Wave %d | %s | Power: %.1f | Count: %d | Health: %d" %
			[current_level, current_wave, enemy_type, power, count, health])

func reset_wave_data() -> void:
	wave_seeds.clear()
	saved_wave_data.clear()
	current_wave = 1
	active_waves.clear()
	cancel_current_waves()
	
	

func _spawn_wave_async(wave: int, enemy_type: String, health: int, count: int) -> void:
	_is_spawning = true
	_remaining_enemies = count
	var delay = max_wave_spawn_time / max(count - 1, 1)
	
	while _remaining_enemies > 0 and _is_spawning:
		spawn_enemy(wave, enemy_type, health)
		_remaining_enemies -= 1
		if _remaining_enemies > 0:
			await await_delay(delay)
	
	_is_spawning = false
	


	_is_spawning = false
func spawn_enemy(wave: int, enemy_type: String, health: int) -> void:
	var enemy := enemy_scene.instantiate()
	var type_data = ENEMY_TYPES[enemy_type]
	
	enemy.position = start_pos + Vector2(0, 4)
	enemy.target_position = end_pos
	add_child(enemy)
	enemy.add_to_group("enemy")
	
	var power := get_wave_power(current_level, wave)
	enemy.max_speed = base_speed + pow(power, 0.25)
	enemy.speed = type_data.speed
	enemy.health = health
	enemy.current_health = health
	
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
