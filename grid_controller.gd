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
const WALL_PREFAB_UID := "uid://71114a1asxv"
@onready var wall_prefab: PackedScene = ResourceLoader.load(WALL_PREFAB_UID)


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
	add_child(wall)
	wall.add_to_group("walls")
	
	# Now check if path is still valid WITH this wall
	var valid := AStarManager.update_grid_and_check_path(
		WaveSpawner.start_pos,
		WaveSpawner.end_pos
	)
	
	if !valid:
		wall.queue_free()
		AStarManager._update_grid()
		Utilities.spawn_floating_text("Cannot block enemies...", get_global_mouse_position(), null, false)
		return false
	
	# Path is valid - wall stays, grid already updated
	return true

func _input(event: InputEvent) -> void:
	if !highlight_mode:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var cell := GridController.get_cell_from_pos(get_global_mouse_position())
			
		if get_tree().get_first_node_in_group("occupier_highlight_button").toggle_mode:
			var is_highlighted := false
			var offsets := [Vector2i(0,0), Vector2i(-1,0), Vector2i(0,-1), Vector2i(-1,-1)]
			for node in get_tree().get_nodes_in_group("grid_occupiers"):
				var base := GridController.get_cell_from_pos(node.global_position)
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
		
		var current_cost: float = wall_cost + (walls_placed * cost_increment)
		if !StatsManager.spend_health(current_cost):
			Utilities.spawn_floating_text("Not enough meat...", get_global_mouse_position(), null, false)
			return
		
		if GridController.place_wall_at_cell(cell):
			walls_placed += 1
			GridController.queue_redraw()
		else:
			StatsManager.health += current_cost
			StatsManager.health_changed.emit(StatsManager.health, StatsManager.max_health)
	

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
	var existing = grid[cell.y][cell.x]
	if existing == null:
		return buildable_grid[cell.y][cell.x]
	# Allow merge if same id and rank
	if dragged_data.is_empty():
		return false
	var existing_data = existing.get_meta("item_data")
	return existing_data.id == dragged_data.id and existing_data.rank == dragged_data.rank

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

func place_item(item_data: Dictionary, cell: Vector2i) -> bool:
	var existing = get_grid_item_at_cell(cell)
	if existing != null:
		var existing_data = existing.get_meta("item_data")
		if existing_data.id == item_data.id and existing_data.rank == item_data.rank:
			var cost = InventoryManager.get_merge_cost(existing_data.rank)#base_spawn_cost * pow(3.0, float(new_rank - 1)) / 3.0
			if StatsManager.spend_health(cost):
				Utilities.spawn_floating_text("Rank up!", get_global_mouse_position(), null, true)
				existing_data.rank += 1
				existing.set_meta("item_data", existing_data)
				existing.queue_redraw()
				return true
			else:
				Utilities.spawn_floating_text("Not enough meat...", get_global_mouse_position(), null, false)
			return false
		return false

	if not buildable_grid[cell.y][cell.x]:
		return false

	var prefab = InventoryManager.items[item_data.id].prefab
	var instance = prefab.instantiate()
	instance.position = grid_offset + Vector2(cell.x * CELL_SIZE + CELL_SIZE / 2, cell.y * CELL_SIZE + CELL_SIZE / 2)
	instance.set_meta("item_data", item_data.duplicate())
	add_child(instance)
	grid[cell.y][cell.x] = instance
	instance.input_pickable = true
	
	print("Placed:", instance, "script:", instance.get_script())
	return true

func _on_tower_input_event(viewport: Viewport, event: InputEvent, shape_idx: int, tower: Node) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var offset = tower.global_position - get_global_mouse_position()
		start_tower_drag(tower, offset)
		get_viewport().set_input_as_handled()

func start_tower_drag(tower: Node, offset: Vector2) -> void:
	if dragged_tower != null: return
	HealthBarGUI.show_cost_preview(0.0)
	dragged_tower = tower
	dragged_offset = offset
	original_cell = get_cell_from_pos(tower.global_position)
	if original_cell == Vector2i(-1, -1):
		dragged_tower = null
		return
	grid[original_cell.y][original_cell.x] = null
	tower.z_index = 1000
	tower.modulate.a = 0.7
	queue_redraw()
	inventory.refresh_inventory_highlights()
	refresh_grid_highlights()

func _process(_delta: float) -> void:
	if dragged_tower != null:
		var mouse_pos = get_global_mouse_position()
		dragged_tower.global_position = mouse_pos + dragged_offset
		potential_cell = get_cell_from_pos(mouse_pos)
		var preview_cost: float = 0.0
		var dragged_data = dragged_tower.get_meta("item_data")
		if potential_cell != Vector2i(-1, -1):
			var existing = get_grid_item_at_cell(potential_cell)
			if existing:
				var target_data = existing.get_meta("item_data")
				if target_data.id == dragged_data.id and target_data.rank == dragged_data.rank:
					var new_rank = target_data.rank + 1
					preview_cost = InventoryManager.get_merge_cost(target_data.rank)#base_spawn_cost * pow(3.0, float(new_rank - 1)) / 3.0
		if preview_cost == 0.0:
			var inv_slot = InventoryManager.get_closest_slot(mouse_pos, 8.0)
			if inv_slot:
				var slot_item = inv_slot.get_meta("item", {})
				if !slot_item.is_empty() and slot_item.id == dragged_data.id and slot_item.rank == dragged_data.rank:
					var new_rank = slot_item.rank + 1
					preview_cost = InventoryManager.get_merge_cost(slot_item.rank)#base_spawn_cost * pow(3.0, float(new_rank - 1)) / 3.0
		HealthBarGUI.show_cost_preview(preview_cost)
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

func _perform_tower_drop() -> void:
	var mouse_pos = get_global_mouse_position()
	var dragged_data = dragged_tower.get_meta("item_data")
	var success = false
	
	# Inventory drop
	var inv_slot = InventoryManager.get_closest_slot(mouse_pos, 8.0)
	if inv_slot:
		var slot_item = inv_slot.get_meta("item", {})
		if slot_item.is_empty():
			inv_slot.set_meta("item", dragged_data.duplicate())
			InventoryManager._update_slot(inv_slot)
			dragged_tower.queue_free()
			success = true
		elif slot_item.id == dragged_data.id and slot_item.rank == dragged_data.rank:
			#var new_rank = slot_item.rank + 1
			var cost = InventoryManager.get_merge_cost(slot_item.rank)#InventoryManager.base_spawn_cost * pow(3.0, float(new_rank - 1)) / 3.0
			if StatsManager.spend_health(cost):
				Utilities.spawn_floating_text("Rank up!", get_global_mouse_position(), null, true)
				slot_item.rank += 1
				inv_slot.set_meta("item", slot_item)
				InventoryManager._update_slot(inv_slot)
				dragged_tower.queue_free()
				success = true
			else:
				Utilities.spawn_floating_text("Not enough meat...", get_global_mouse_position(), null, false)
	
	# Grid drop
	if not success and potential_cell != Vector2i(-1, -1):
		var valid = is_valid_placement(potential_cell, dragged_data)
		if valid and grid[potential_cell.y][potential_cell.x] == null:
			# Simple move/placement
			dragged_tower.position = grid_offset + Vector2(potential_cell.x * CELL_SIZE + CELL_SIZE / 2, potential_cell.y * CELL_SIZE + CELL_SIZE / 2)
			grid[potential_cell.y][potential_cell.x] = dragged_tower
			success = true
		elif valid and grid[potential_cell.y][potential_cell.x] != null:
			# Merge attempt
			var target = grid[potential_cell.y][potential_cell.x]
			var target_data = target.get_meta("item_data")
			if target_data.id == dragged_data.id and target_data.rank == dragged_data.rank:
				var new_rank = target_data.rank + 1
				var cost = InventoryManager. get_merge_cost(target_data.rank)#base_spawn_cost * pow(3.0, float(new_rank - 1)) / 3.0
				if StatsManager.spend_health(cost):
					Utilities.spawn_floating_text("Rank up!", get_global_mouse_position(), null, true)
					target_data.rank += 1
					target.set_meta("item_data", target_data)
					target.queue_redraw()
					dragged_tower.queue_free()
					success = true
				else:
					Utilities.spawn_floating_text("Not enough meat...", get_global_mouse_position(), null, false)
	
	# Revert if no success
	if not success:
		dragged_tower.position = grid_offset + Vector2(original_cell.x * CELL_SIZE + CELL_SIZE / 2, original_cell.y * CELL_SIZE + CELL_SIZE / 2)
		grid[original_cell.y][original_cell.x] = dragged_tower
	
	dragged_tower.z_index = 0
	dragged_tower.modulate.a = 1.0
	dragged_tower = null
	original_cell = Vector2i(-1, -1)
	potential_cell = Vector2i(-1, -1)
	InventoryManager.refresh_all_highlights()
	queue_redraw()

# Optional: faint grid lines + drag highlight
func _draw() -> void:
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
		var cell_pos = grid_offset + Vector2(potential_cell.x * CELL_SIZE, potential_cell.y * CELL_SIZE)
		var valid = is_valid_placement(potential_cell, dragged_tower.get_meta("item_data"))
		var fill_color = Color(0, 1, 0, 0.3) if valid else Color(1, 0, 0, 0.3)
		draw_rect(Rect2(cell_pos, Vector2(CELL_SIZE, CELL_SIZE)), fill_color, true)
