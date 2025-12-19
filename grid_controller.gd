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
	
	# Mark buildable cells from nodes in group "grid_buildable" (assume positioned at cell centers)
	for node in get_tree().get_nodes_in_group("grid_buildable"):
		var cell = get_cell_from_pos(node.global_position)
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

func get_grid_item_at_cell(cell: Vector2i) -> Node:
	if cell == Vector2i(-1, -1): return null
	if grid != null:
		return grid[cell.y][cell.x]
	else:
		return null

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
			var new_rank = existing_data.rank + 1
			var cost = (40.0 * pow(3.0, float(new_rank - 1))) / 3.0
			if StatsManager.spend_health(cost):
				existing_data.rank += 1
				existing.set_meta("item_data", existing_data)
				existing.queue_redraw()
				return true
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
	instance.connect("input_event", _on_tower_input_event.bind(instance))
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
					preview_cost = (40.0 * pow(3.0, float(new_rank - 1))) / 3.0
		if preview_cost == 0.0:
			var inv_slot = InventoryManager.get_closest_slot(mouse_pos, 8.0)
			if inv_slot:
				var slot_item = inv_slot.get_meta("item", {})
				if !slot_item.is_empty() and slot_item.id == dragged_data.id and slot_item.rank == dragged_data.rank:
					var new_rank = slot_item.rank + 1
					preview_cost = (40.0 * pow(3.0, float(new_rank - 1))) / 3.0
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

	# Inventory drop: empty or merge
	var inv_slot = InventoryManager.get_closest_slot(mouse_pos, 8.0)
	if inv_slot:
		var slot_item = inv_slot.get_meta("item", {})
		if slot_item.is_empty():
			inv_slot.set_meta("item", dragged_data.duplicate())
			InventoryManager._update_slot(inv_slot)
			dragged_tower.queue_free()
		elif slot_item.id == dragged_data.id and slot_item.rank == dragged_data.rank:
			var new_rank = slot_item.rank + 1
			var cost = (40.0 * pow(3.0, float(new_rank - 1))) / 3.0
			if StatsManager.spend_health(cost):
				slot_item.rank += 1
				inv_slot.set_meta("item", slot_item)
				InventoryManager._update_slot(inv_slot)
				dragged_tower.queue_free()
		# Invalid inventory drop falls through to grid handling

	else:
		# Grid merge/placement
		var valid = potential_cell != Vector2i(-1, -1) and is_valid_placement(potential_cell, dragged_data)
		if valid and grid[potential_cell.y][potential_cell.x] != null:
			var target = grid[potential_cell.y][potential_cell.x]
			var target_data = target.get_meta("item_data")
			var new_rank = target_data.rank + 1
			var cost = (40.0 * pow(3.0, float(new_rank - 1))) / 3.0
			if StatsManager.spend_health(cost):
				target_data.rank += 1
				target.set_meta("item_data", target_data)
				target.queue_redraw()
				dragged_tower.queue_free()
			else:
				valid = false  # revert if cannot afford
		if not valid:
			# Return to original cell
			var target_cell = original_cell
			dragged_tower.position = grid_offset + Vector2(target_cell.x * CELL_SIZE + CELL_SIZE / 2, target_cell.y * CELL_SIZE + CELL_SIZE / 2)
			grid[target_cell.y][target_cell.x] = dragged_tower
		else:
			# Valid new placement (non-merge)
			var target_cell = potential_cell
			dragged_tower.position = grid_offset + Vector2(target_cell.x * CELL_SIZE + CELL_SIZE / 2, target_cell.y * CELL_SIZE + CELL_SIZE / 2)
			grid[target_cell.y][target_cell.x] = dragged_tower
	InventoryManager.refresh_all_highlights()

	if dragged_tower:
		dragged_tower.z_index = 0
		dragged_tower.modulate.a = 1.0
	dragged_tower = null
	original_cell = Vector2i(-1, -1)
	potential_cell = Vector2i(-1, -1)
	queue_redraw()

# Optional: faint grid lines + drag highlight
func _draw() -> void:
	#var line_color = Color(0.3, 0.3, 0.3, 0.4)
	#for x in WIDTH + 1:
		#draw_line(grid_offset + Vector2(x * CELL_SIZE, 0), grid_offset + Vector2(x * CELL_SIZE, HEIGHT * CELL_SIZE), line_color, 1.0)
	#for y in HEIGHT + 1:
		#draw_line(grid_offset + Vector2(0, y * CELL_SIZE), grid_offset + Vector2(WIDTH * CELL_SIZE, y * CELL_SIZE), line_color, 1.0)
	
	if dragged_tower != null and potential_cell != Vector2i(-1, -1):
		var cell_pos = grid_offset + Vector2(potential_cell.x * CELL_SIZE, potential_cell.y * CELL_SIZE)
		var valid = is_valid_placement(potential_cell, dragged_tower.get_meta("item_data"))
		var fill_color = Color(0, 1, 0, 0.3) if valid else Color(1, 0, 0, 0.3)
		draw_rect(Rect2(cell_pos, Vector2(CELL_SIZE, CELL_SIZE)), fill_color, true)
