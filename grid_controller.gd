# GridController.gd (modified)
extends Node2D

const WIDTH: int = 22
const HEIGHT: int = 15
const CELL_SIZE: int = 8
var grid_offset: Vector2 = Vector2(8, 8)  # 8px margin
var grid: Array[Array] = []
var buildable_grid: Array[Array] = []

# Tower dragging
var dragged_tower: Node = null
var dragged_offset: Vector2 = Vector2.ZERO
var original_cell: Vector2i = Vector2i(-1, -1)
var potential_cell: Vector2i = Vector2i(-1, -1)
var highlight_mode := false

var wall_cost: float = 5.0
var cost_increment: float = 2.0
var walls_placed: int = 0
const WALL_PREFAB_UID := "uid://823ref1rao2h"
@onready var wall_prefab: PackedScene = ResourceLoader.load(WALL_PREFAB_UID)

var delete_mode: bool = false
@onready var HealthBarGUI = get_tree().get_first_node_in_group("HealthBarContainer")
@onready var inventory = get_node("/root/InventoryManager")
var original_slot: Panel = null

func _ready() -> void:
	# Initialize grid
	grid.resize(HEIGHT)
	for y in range(HEIGHT):
		grid[y] = Array()
		grid[y].resize(WIDTH)
		grid[y].fill(null)
	
	# Initialize buildable grid
	buildable_grid.resize(HEIGHT)
	for y in range(HEIGHT):
		buildable_grid[y] = Array()
		buildable_grid[y].resize(WIDTH)
		buildable_grid[y].fill(false)
	
	update_buildables()
	change_level_color()

func place_wall_at_cell(cell: Vector2i) -> bool:
	if cell == Vector2i(-1, -1):
		return false

	# Prevent duplicate walls
	for wall in get_tree().get_nodes_in_group("walls"):
		if get_cell_from_pos(wall.global_position) == cell:
			return false
	
	# Spawn wall TEMPORARILY (not added to grid_occupiers yet)
	var wall = wall_prefab.instantiate()
	wall.position = grid_offset + Vector2(
		cell.x * CELL_SIZE + CELL_SIZE / 2,
		cell.y * CELL_SIZE + CELL_SIZE / 2
	)
	wall.is_placed = true
	add_child(wall)
	wall.add_to_group("walls")
	
	# Now check if path is still valid WITH this wall
	var valid := AStarManager.update_grid_and_check_path(
		WaveSpawner.start_pos,
		WaveSpawner.end_pos
	)
	
	if !valid:
		wall.queue_free()
		Utilities.spawn_floating_text("Cannot block enemies...", get_global_mouse_position(), null, false)
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().process_frame
		AStarManager._update_grid(false)
		return false
	
	AStarManager._update_grid()
	# Path is valid - wall stays, grid already updated
	return true

func _input(event: InputEvent) -> void:
	if delete_mode:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var cell = get_cell_from_pos(get_global_mouse_position())
			var item = get_grid_item_at_cell(cell)
			if item and (item.is_in_group("walls") or item.is_in_group("placed_towers")):
				item.queue_free()
				if item.is_in_group("walls"):
					walls_placed -= 1
				grid[cell.y][cell.x] = null
				AStarManager._update_grid()
				queue_redraw()
	
	if !highlight_mode:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var cell = GridController.get_cell_from_pos(get_global_mouse_position())
			
		if get_tree().get_first_node_in_group("occupier_highlight_button").toggle_mode:
			var is_highlighted := false
			var offsets := [Vector2i(0,0), Vector2i(-1,0), Vector2i(0,-1), Vector2i(-1,-1)]
			for node in get_tree().get_nodes_in_group("grid_occupiers"):
				var base = GridController.get_cell_from_pos(node.global_position)
				if base == Vector2i(-1, -1):
					continue
				for off in offsets:
					if base + off == cell:
						is_highlighted = true
						break
				if is_highlighted:
					break
			
			if !is_highlighted:
				var button = get_tree().get_first_node_in_group("occupier_highlight_button")
				button._on_toggled(false)
				if !button.get_global_rect().has_point(get_global_mouse_position()):
					button.button_pressed = false
				return
		
		var current_cost: float = get_wall_cost()
		if !StatsManager.spend_health(current_cost):
			Utilities.spawn_floating_text("Not enough meat...", get_global_mouse_position(), null, false)
			return
		
		if await GridController.place_wall_at_cell(cell):
			walls_placed += 1
			GridController.queue_redraw()
		else:
			StatsManager.health += current_cost
			StatsManager.health_changed.emit(StatsManager.health, StatsManager.max_health)
	

func get_wall_cost():
	return wall_cost + (walls_placed * cost_increment)


func update_buildables():
	# Ensure grid is initialized
	if buildable_grid.size() != HEIGHT:
		return

	for y in range(HEIGHT):
		if buildable_grid[y].size() != WIDTH:
			continue
		for x in range(WIDTH):
			buildable_grid[y][x] = false

	# Rebuild from scene
	for node in get_tree().get_nodes_in_group("grid_buildable"):
		var cell := get_cell_from_pos(node.global_position)
		if cell != Vector2i(-1, -1):
			buildable_grid[cell.y][cell.x] = true


func get_cell_from_pos(global_pos: Vector2) -> Vector2i:
	var local = global_pos - grid_offset
	var x = floori(local.x / CELL_SIZE)
	var y = floori(local.y / CELL_SIZE)
	if x >= 0 and x < WIDTH and y >= 0 and y < HEIGHT:
		return Vector2i(x, y)
	return Vector2i(-1, -1)

func is_valid_placement(cell: Vector2i, dragged_data: Dictionary = {}) -> bool:
	update_buildables()
	if cell.x < 0 or cell.x >= WIDTH or cell.y < 0 or cell.y >= HEIGHT:
		return false
	return grid[cell.y][cell.x] == null && buildable_grid[cell.y][cell.x]

func get_grid_item_at_cell(cell: Vector2i):
	if cell == Vector2i(-1, -1):
		return null
	if cell.x < 0 or cell.x >= WIDTH or cell.y < 0 or cell.y >= HEIGHT:
		return null
	var item = grid[cell.y][cell.x]
	return item if item != null else null  # optional, already null-safe

func refresh_grid_highlights() -> void:
	for y in range(HEIGHT):
		for x in range(WIDTH):
			var tower = grid[y][x]
			if tower != null:
				tower.queue_redraw()



func place_item(item: Dictionary, cell: Vector2i) -> bool:
	if !is_valid_placement(cell):
		return false
	var existing = get_grid_item_at_cell(cell)
	if existing:
		return false
	var item_def = InventoryManager.items[item.id]
	var tower_level = item_def.get("tower_level", 0)
	var cost = InventoryManager.get_placement_cost(item.id, tower_level, item.rank)
	if !StatsManager.spend_health(cost):
		Utilities.spawn_floating_text("Not enough meat...", Vector2.ZERO, null)
		return false
	var tower = item_def.prefab.instantiate()
	tower.set_meta("item_data", item.duplicate())
	tower.global_position = grid_offset + Vector2(cell.x * CELL_SIZE + 4, cell.y * CELL_SIZE + 4)
	add_child(tower)
	tower.add_to_group("placed_towers")
	grid[cell.y][cell.x] = tower
	tower.start_cooldown()  # new line
	return true

func _on_tower_input_event(viewport: Viewport, event: InputEvent, shape_idx: int, tower: Node) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var offset = tower.global_position - get_global_mouse_position()
		start_tower_drag(tower, offset)
		get_viewport().set_input_as_handled()

var random_tint: Color = Color.YELLOW
var hue
var saturation
var value
func change_level_color() -> void:
	seed(WaveSpawner.current_level)
	hue = randf()  # Random 0-1
	saturation = randf_range(0.5, 0.7)  # High saturation
	value = randf_range(0.8, 1.0)  # Bright
	random_tint = Color.from_hsv(hue, saturation, value, 1)

func start_tower_drag(tower: Node, offset: Vector2) -> void:
	if dragged_tower != null: return
	HealthBarGUI.show_cost_preview(0.0)
	dragged_tower = tower
	dragged_offset = offset
	original_cell = get_cell_from_pos(tower.global_position)
	if original_cell == Vector2i(-1, -1):
		dragged_tower = null
		return
	# Safe access with bounds check
	if original_cell.x >= 0 and original_cell.x < WIDTH and original_cell.y >= 0 and original_cell.y < HEIGHT:
		grid[original_cell.y][original_cell.x] = null
	tower.z_index = 1000
	tower.modulate.a = 0.7
	queue_redraw()
	inventory.refresh_inventory_highlights()
	refresh_grid_highlights()


func _process(_delta: float) -> void:
	
	if dragged_tower != null:
		TooltipManager.hide_tooltip()
		var mouse_pos = get_global_mouse_position()
		dragged_tower.global_position = mouse_pos + dragged_offset
		var raw_cell = get_cell_from_pos(mouse_pos)
		potential_cell = get_nearest_valid_cell(raw_cell) if raw_cell != Vector2i(-1, -1) else Vector2i(-1, -1)
		HealthBarGUI.show_cost_preview(0.0)
		for slot in InventoryManager.slots:
			if slot.get_meta("hovered", false):
				slot.set_meta("hovered", false)
				InventoryManager._update_hover(slot)
		var pot_inv_slot = InventoryManager.get_closest_slot(mouse_pos, 8.0)
		if pot_inv_slot:
			pot_inv_slot.set_meta("hovered", true)
			InventoryManager._update_hover(pot_inv_slot)
		queue_redraw()
		if !Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_perform_tower_drop()
			HealthBarGUI.show_cost_preview(0.0)



func get_nearest_valid_cell(base_cell: Vector2i) -> Vector2i:
	if base_cell.x < 0 or base_cell.x >= WIDTH or base_cell.y < 0 or base_cell.y >= HEIGHT:
		base_cell = Vector2i(clampi(base_cell.x, 0, WIDTH-1), clampi(base_cell.y, 0, HEIGHT-1))
	if is_valid_placement(base_cell):
		return base_cell
	var best: Vector2i = Vector2i(-1, -1)
	var best_dist: float = INF
	for y in range(HEIGHT):
		for x in range(WIDTH):
			var cell = Vector2i(x, y)
			if is_valid_placement(cell):
				var dist = base_cell.distance_squared_to(cell)
				if dist < best_dist:
					best_dist = dist
					best = cell
	return best

func _perform_tower_drop() -> void:
	var success = false
	if potential_cell != Vector2i(-1, -1):
		var place_cell = get_nearest_valid_cell(potential_cell)
		if place_cell != Vector2i(-1, -1) && get_grid_item_at_cell(place_cell) == null && is_valid_placement(place_cell, dragged_tower.get_meta("item_data")):
			dragged_tower.global_position = grid_offset + Vector2(place_cell.x * CELL_SIZE + CELL_SIZE / 2, place_cell.y * CELL_SIZE + CELL_SIZE / 2)
			grid[place_cell.y][place_cell.x] = dragged_tower
			dragged_tower.start_cooldown()  # new line
			success = true
	if not success:
		dragged_tower.global_position = grid_offset + Vector2(original_cell.x * CELL_SIZE + CELL_SIZE / 2, original_cell.y * CELL_SIZE + CELL_SIZE / 2)
		grid[original_cell.y][original_cell.x] = dragged_tower
	dragged_tower.z_index = 0
	dragged_tower.modulate.a = 1.0
	dragged_tower = null
	original_cell = Vector2i(-1, -1)
	potential_cell = Vector2i(-1, -1)
	InventoryManager.refresh_all_highlights()
	queue_redraw()
	
	#if not success:
		#dragged_tower.global_position = grid_offset + Vector2(original_cell.x * CELL_SIZE + CELL_SIZE / 2, original_cell.y * CELL_SIZE + CELL_SIZE / 2)
		#if original_cell.x >= 0 and original_cell.x < WIDTH and original_cell.y >= 0 and original_cell.y < HEIGHT:
			#grid[original_cell.y][original_cell.x] = dragged_tower

# Optional: faint grid lines + drag highlight
func _draw() -> void:
	if delete_mode:
		for y in range(HEIGHT):
			for x in range(WIDTH):
				var item = grid[y][x]
				if item and (item.is_in_group("walls") or item.is_in_group("placed_towers")):
					var pos = grid_offset + Vector2(x * CELL_SIZE, y * CELL_SIZE)
					draw_rect(Rect2(pos, Vector2(CELL_SIZE, CELL_SIZE)), Color(1, 0, 0, 0.4), true)
	
	#var line_color = Color(0.3, 0.3, 0.3, 0.4)
	#for x in WIDTH + 1:
		#draw_line(grid_offset + Vector2(x * CELL_SIZE, 0), grid_offset + Vector2(x * CELL_SIZE, HEIGHT * CELL_SIZE), line_color, 1.0)
	#for y in HEIGHT + 1:
		#draw_line(grid_offset + Vector2(0, y * CELL_SIZE), grid_offset + Vector2(WIDTH * CELL_SIZE, y * CELL_SIZE), line_color, 1.0)
	#Wall placement
	if highlight_mode:
		var wall_cells := {}
		for wall in get_tree().get_nodes_in_group("walls"):
			var wc = get_cell_from_pos(wall.global_position)
			if wc != Vector2i(-1, -1):
				wall_cells[wc] = true

		var offsets := [
			Vector2i(0, 0),     # self
			Vector2i(-1, 0),    # left
			Vector2i(0, -1),    # up
			Vector2i(-1, -1),   # up-left
		]

		for node in get_tree().get_nodes_in_group("grid_occupiers"):
			if !node.is_in_group("walls"):
				var base_cell = get_cell_from_pos(node.global_position)
				if base_cell == Vector2i(-1, -1):
					continue

				for offset in offsets:
					var cell = base_cell + offset

					# bounds check
					if cell.x < 0 or cell.x >= WIDTH or cell.y < 0 or cell.y >= HEIGHT:
						continue

					# skip if wall exists
					if wall_cells.has(cell):
						continue

					var pos := grid_offset + Vector2(
						cell.x * CELL_SIZE,
						cell.y * CELL_SIZE
					)

					draw_rect(
						Rect2(pos, Vector2(CELL_SIZE, CELL_SIZE)),
						Color(1, 0.5, 0, 0.4),
						true
					)

	
	if dragged_tower != null and potential_cell != Vector2i(-1, -1):
		var nearest_cell = get_nearest_valid_cell(potential_cell)
		var cell_pos = grid_offset + Vector2(nearest_cell.x * CELL_SIZE, nearest_cell.y * CELL_SIZE)
		var valid = nearest_cell != Vector2i(-1, -1) && get_grid_item_at_cell(nearest_cell) == null && is_valid_placement(nearest_cell, dragged_tower.get_meta("item_data"))
		var fill_color = Color(0, 1, 0, 0.3) if valid else Color(1, 0, 0, 0.3)
		draw_rect(Rect2(cell_pos, Vector2(CELL_SIZE, CELL_SIZE)), fill_color, true)
	
