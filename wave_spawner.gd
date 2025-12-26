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

const ENEMY_TYPES = {
	"normal": {
		"health": 1,
		"speed": 10.0,
		"damage": 10,
		"base_reward": 5.0,
		"count_mult": 1.0
	},
	"swarm": {
		"health": 1,
		"speed": 15.0,
		"damage": 5,
		"base_reward": 3.0,
		"count_mult": 2.0
	},
	"fast": {
		"health": 1,
		"speed": 25.0,
		"damage": 10,
		"base_reward": 5.0,
		"count_mult": 1.5
	},
	"boss": {
		"health": 10,
		"speed": 5.0,
		"damage": 50,
		"base_reward": 50.0,
		"count_mult": 0.2
	}
}

func calculate_enemy_damage(health, cycles):
	return pow(health + current_wave, cycles)
	

var types = ENEMY_TYPES.keys()

const MIN_X: int = 1
const MAX_X: int = 10
const MIN_Y: int = 1
const MAX_Y: int = 7
const BORDER_Y_MIN: int = 0
const BORDER_Y_MAX: int = 8

var active_waves := {} # wave_number -> remaining_enemies
var current_wave: int = 0
var spawn_delay: float = 1.0

signal wave_completed(wave: int)
signal wave_started(wave: int)

var path_node: Path2D
var path_tiles_container: Node2D

func _ready():
	add_to_group("wave_spawner")
	path_node = Path2D.new()
	add_child(path_node)
	path_tiles_container = Node2D.new()
	add_child(path_tiles_container)
	generate_path()
	

func set_game_paused(p: bool) -> void:
	game_paused = p

func await_delay(delay: float) -> void:
	var elapsed: float = 0.0
	while elapsed < delay:
		await get_tree().process_frame
		if not game_paused:
			elapsed += get_process_delta_time()

func get_enemy_type_for_wave(wave: int) -> String:
	var keys := ENEMY_TYPES.keys()
	return keys[(wave - 1) % keys.size()]

func start_next_wave():
	current_wave += 1
	var wave := current_wave

	var enemy_type := get_enemy_type_for_wave(wave)
	var type_data = ENEMY_TYPES[enemy_type]

	var wave_health := 1
	wave_health += ceil(floor((current_wave-2) + base_health * pow(1.25, current_wave - 1))/2)

	# Apply type health multiplier
	wave_health *= type_data.health

	var enemies_in_wave := int(7 * type_data.count_mult)
	enemies_in_wave = max(enemies_in_wave, 1)

	active_waves[wave] = enemies_in_wave
	wave_started.emit(wave)

	_spawn_wave_async(wave, enemy_type, wave_health, enemies_in_wave)

func _spawn_wave_async(wave: int, enemy_type: String, health: int, count: int) -> void:
	_is_spawning = true
	_remaining_enemies = count

	var delay: float = max_wave_spawn_time / max(count - 1, 1)

	while _remaining_enemies > 0 and _is_spawning:
		spawn_enemy(wave, enemy_type, health)
		_remaining_enemies -= 1
		if _remaining_enemies > 0:
			await await_delay(delay)

	_is_spawning = false
func spawn_enemy(wave: int, enemy_type: String, health: int):
	var enemy = enemy_scene.instantiate()
	var type_data = ENEMY_TYPES[enemy_type]
	enemy.position = start_pos + Vector2(0, 4)
	enemy.target_position = end_pos
	add_child(enemy)

	enemy.add_to_group("enemy")

	enemy.max_speed = base_speed + wave * speed_inc
	enemy.speed = type_data.speed
	#enemy.current_damage = type_data.damage

	enemy.health = health
	enemy.current_health = health

	enemy.tree_exited.connect(func():
		if not active_waves.has(wave):
			return

		active_waves[wave] -= 1
		if active_waves[wave] <= 0:
			active_waves.erase(wave)
			wave_completed.emit(wave)
	)


func generate_path():
	
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
	const MAX_ATTEMPTS := 100
	var attempts := 0
	
	while not found and attempts < MAX_ATTEMPTS:
		attempts += 1
		internal_path_cells = [internal_start]
		var visited := {internal_start: true}
		var current := internal_start
		var steps := 0
		const MAX_STEPS := 300
		const DIRS := [Vector2i(0,1), Vector2i(-1,0), Vector2i(1,0), Vector2i(0,-1)]
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
	current_wave = 0
