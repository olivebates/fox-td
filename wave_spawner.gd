# Full WaveSpawner.gd (singleton)

extends Node2D

@export var enemy_scene: PackedScene = preload("uid://csawtka1gfo5o")
@export var base_speed: float = 80.0
@export var speed_inc: float = 10.0
@export var base_health: int = 50
@export var health_inc: int = 10

@export var start_pos: Vector2 = Vector2(88, -8)
@export var end_pos: Vector2 = Vector2(88, 136)
@export var grid_size: int = 16
@export var path_tile_uid: String = "uid://2wlflfus0jih"
@export var buildable_grid_size = 8
@export var path_buildable_uid: String = "uid://823ref1rao2h"

const MIN_X: int = 1
const MAX_X: int = 10
const MIN_Y: int = 1
const MAX_Y: int = 7
const BORDER_Y_MIN: int = 0
const BORDER_Y_MAX: int = 8

var current_wave: int = 0
var enemies_to_spawn: int = 0
var spawn_delay: float = 1.0
var spawn_timer: float = 0.0
var is_spawning: bool = false

signal wave_completed
signal wave_started

var path_node: Path2D
var path_tiles_container: Node2D
var buildable_tiles_container: Node2D

func _ready():
	path_node = Path2D.new()
	add_child(path_node)
	path_tiles_container = Node2D.new()
	add_child(path_tiles_container)
	generate_path()

func start_next_wave():
	if is_spawning: return
	current_wave += 1
	enemies_to_spawn = 5 + current_wave * 2
	is_spawning = true
	spawn_timer = 0.0
	wave_started.emit()

func _process(delta: float):
	if not is_spawning: return
	spawn_timer += delta
	if spawn_timer >= spawn_delay and enemies_to_spawn > 0:
		spawn_timer = 0.0
		spawn_enemy()
		enemies_to_spawn -= 1
		if enemies_to_spawn <= 0:
			is_spawning = false
			wave_completed.emit()

func spawn_enemy():
	var enemy = enemy_scene.instantiate()
	enemy.position = start_pos+Vector2(0,4)
	enemy.target_position = end_pos  # Add this variable in Enemy script: var target_position: Vector2
	add_child(enemy)
	#enemy.max_speed = base_speed + current_wave * speed_inc
	#enemy.health = base_health + current_wave * health_inc

func generate_path():
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
	
	# Fallback: vertical then horizontal at bottom
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
	
	# Full path cells (including border entry/exit)
	var full_path_cells := [entry_cell]
	full_path_cells.append_array(internal_path_cells)
	full_path_cells.append(exit_cell)
	
	# Build curve
	var off_top := Vector2(entry_x * grid_size + grid_size / 2.0, -8.0)
	curve.add_point(off_top)
	
	curve.add_point(Vector2(entry_cell) * grid_size + Vector2(grid_size / 2.0, grid_size / 2.0))
	
	for cell in internal_path_cells:
		curve.add_point(Vector2(cell) * grid_size + Vector2(grid_size / 2.0, grid_size / 2.0))
	
	var exit_point := Vector2(exit_cell) * grid_size + Vector2(grid_size / 2.0, grid_size / 2.0)
	curve.add_point(exit_point)
	
	path_node.curve = curve
	
	# Update exported positions for consistency
	start_pos.x = off_top.x
	end_pos.x = exit_point.x
	end_pos.y = exit_point.y
	
	# Place tiles (onscreen only, includes start border tile at y=8)
	var tile_scene := ResourceLoader.load(path_tile_uid) as PackedScene
	if tile_scene:
		for cell in full_path_cells:
			var pos := Vector2(cell) * grid_size + Vector2(grid_size / 2.0, grid_size / 2.0)
			var tile := tile_scene.instantiate()
			tile.position = pos
			path_tiles_container.add_child(tile)
	else:
		push_error("Invalid path_tile_uid")
	
		# Place buildable tiles on all 8x8 grid positions not occupied by path
	var buildable_scene := ResourceLoader.load(path_buildable_uid) as PackedScene
	if buildable_scene:
		# Calculate 8x8 grid bounds based on 16x16 grid
		# 16x16 grid goes from x=1-10, y=0-8
		# 8x8 grid needs to cover the same area (16-176 x, 0-144 y)
		var buildable_min_x := 1  # Starting at x=16 in world space
		var buildable_max_x := 22  # Ending at x=168 in world space
		var buildable_min_y := 1  # Starting at y=0
		var buildable_max_y := 15  # Ending at y=136
		
		for bx in range(buildable_min_x, buildable_max_x + 1):
			for by in range(buildable_min_y, buildable_max_y + 1):
				# Calculate world position
				var world_pos := Vector2(bx * buildable_grid_size + buildable_grid_size / 2.0,
										 by * buildable_grid_size + buildable_grid_size / 2.0)
				
				# Check if this 8x8 tile overlaps with any 16x16 path tile
				var overlaps_path := false
				for path_cell in full_path_cells:
					var path_pos := Vector2(path_cell) * grid_size + Vector2(grid_size / 2.0, grid_size / 2.0)
					# Check if centers are within range where tiles would overlap
					if abs(world_pos.x - path_pos.x) < (grid_size + buildable_grid_size) / 2.0 && \
					   abs(world_pos.y - path_pos.y) < (grid_size + buildable_grid_size) / 2.0:
						overlaps_path = true
						break
				
				# Only place buildable tile if it doesn't overlap with path
				if not overlaps_path:
					var buildable := buildable_scene.instantiate()
					buildable.position = world_pos
					add_child(buildable)
	else:
		push_error("Invalid path_buildable_uid")
	
