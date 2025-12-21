# Autoload: InventoryManager.gd
extends Control

const RANK_COLORS = {
	0: Color(1, 1, 1),
	1: Color(0.847, 0.847, 0.847, 1.0),
	2: Color(0.535, 0.813, 0.0, 1.0),
	3: Color(0, 0.5, 1),
	4: Color(0.627, 0.125, 0.941),
	5: Color(0.855, 0.551, 0.0, 1.0),
	6: Color(0.997, 0.0, 0.442),
	7: Color(0, 0, 0),
	8: Color(1.0, 1.0, 0.812),
	9: Color(0.0, 1.0, 1.0),
	10: Color(1.0, 0.531, 0.986),
	11: Color(0.565, 0.0, 0.18),
}
var base_spawn_cost = 50.0
@onready var HealthBarGUI = get_tree().get_first_node_in_group("HealthBarContainer")
@onready var grid_controller: Node2D = get_node("/root/GridController")
var _merge_blink_timer: float = 0.0
var _merge_blink_state: bool = false

var items: Dictionary = {
	"tower1": {
		"texture": preload("uid://cs2ic8oeq6fc0"),
		"prefab": preload("uid://dfx5piisk4epn"),
	},
	"tower2": {
		"texture": preload("uid://cqgl3igwvfat8"),
		"prefab": preload("uid://bp8y13cyubdho"),
	},
}

# Runtime state
var slots: Array[Panel] = []
var dragged_item: Dictionary = {}
var original_slot: Panel = null
var drag_preview: Control = null
var drag_preview_item: Dictionary = {}
var potential_cell: Vector2i = Vector2i(-1, -1)

func register_inventory(grid: GridContainer, spawner_grid: GridContainer, preview: Control) -> void:
	slots.clear()
	for i in 18:
		var slot = Panel.new()
		slot.custom_minimum_size = Vector2(8, 8)
		#slot.clip_contents = true
		slot.mouse_filter = Control.MOUSE_FILTER_STOP
		slot.gui_input.connect(_on_slot_input.bind(slot))
		slot.mouse_entered.connect(_on_slot_hover.bind(slot, true))
		slot.mouse_exited.connect(_on_slot_hover.bind(slot, false))
		grid.add_child(slot)
		slots.append(slot)
		_setup_slot_style(slot)
	
	# Example items
	slots[0].set_meta("item", {"id": "tower1", "rank": 1})
	#slots[1].set_meta("item", {"id": "tower1", "rank": 1})
	#slots[5].set_meta("item", {"id": "tower2", "rank": 5})
	
	for slot in slots:
		_update_slot(slot)
	
	var spawner_textures: Array[Texture2D] = [
		preload("uid://dyan40sgre5b1"), 
		preload("uid://dyan40sgre5b1"), 
		preload("uid://dyan40sgre5b1"), 
		preload("uid://dyan40sgre5b1"), 
		preload("uid://dyan40sgre5b1"), 
		preload("uid://dyan40sgre5b1"), 
		preload("uid://dyan40sgre5b1"), 
		preload("uid://dyan40sgre5b1"), 
		preload("uid://dyan40sgre5b1"), 
	]

	for rank in range(1):
		var btn = TextureRect.new()
		btn.texture = spawner_textures[rank]
		btn.expand_mode = TextureRect.EXPAND_KEEP_SIZE
		btn.stretch_mode = TextureRect.STRETCH_KEEP
		btn.custom_minimum_size = Vector2(8, 8)
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		
		var cost = base_spawn_cost * pow(3.0, float(rank))
		
		btn.mouse_entered.connect(func():
			btn.modulate = Color(1.3, 1.3, 1.3)
			HealthBarGUI.show_cost_preview(cost))
		
		btn.mouse_exited.connect(func():
			btn.modulate = Color(1, 1, 1)
			HealthBarGUI.hide_cost_preview())
		
		btn.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				_spawn_item(rank))
		
		spawner_grid.add_child(btn)
		
	
	drag_preview = preview
	drag_preview.visible = false
	
	for slot in slots:
		slot.draw.connect(_draw_slot.bind(slot))

var temp_drag_data: Dictionary = {}

func set_temp_drag_data(data: Dictionary) -> void:
	temp_drag_data = data

func clear_temp_drag_data() -> void:
	temp_drag_data = {}



func _draw() -> void:
	if dragged_item.is_empty():
		return
	var mouse_pos = get_global_mouse_position()
	var draw_pos = mouse_pos - Vector2(5, 5)
	# Preview highlight on grid
	if potential_cell != Vector2i(-1, -1):
		var cell_pos = GridController.grid_offset + Vector2(potential_cell.x * GridController.CELL_SIZE, potential_cell.y * GridController.CELL_SIZE)
		var valid = GridController.is_valid_placement(potential_cell)
		var fill_color = Color(0, 1, 0, 0.3) if valid else Color(1, 0, 0, 0.3)
		draw_rect(Rect2(cell_pos, Vector2(GridController.CELL_SIZE, GridController.CELL_SIZE)), fill_color, true)
	# Dragged item preview (existing code)
	var rank = dragged_item.get("rank", 0)
	var border_color = RANK_COLORS.get(rank, Color(1, 1, 1))
	draw_rect(Rect2(draw_pos + Vector2(1.5, 1.5), Vector2(7, 7)), border_color, false, 1.0)
	#draw_rect(Rect2(draw_pos + Vector2(1, 1), Vector2(8, 8)), Color(0.1, 0.1, 0.1), true)
	var tex = items[dragged_item.id].texture
	if tex:
		draw_texture(tex, draw_pos + Vector2(1, 1), Color(1.4, 1.4, 1.4))

# Add this function to InventoryManager.gd
func _draw_slot(slot: Panel) -> void:
	var item = slot.get_meta("item", {})
	if item.is_empty():
		return
	var rank = item.get("rank", 0)
	var border_color = RANK_COLORS.get(rank, Color(1, 1, 1))
	var base_color = border_color * 0.3
	base_color.a = 1.0
	
	var hovered = slot.get_meta("hovered", false)
	var dragged_data = get_current_dragged_data()
	var is_matching = !dragged_data.is_empty() && item.id == dragged_data.id && item.rank == dragged_data.rank
	var blink_on = _merge_blink_state if is_matching else true
	var brighten = (1.2 if hovered else 1.2) if is_matching and blink_on else (1.3 if hovered else 1.0)
	var bg_color = base_color * brighten
	
	slot.draw_rect(Rect2(0.5, 0.5, 7, 7), border_color, false, 1.0 + (0.5 if (hovered or is_matching) else 0.0))
	slot.draw_rect(Rect2(1, 1, 6, 6), bg_color, true)
	
	var tex = items[item.id].texture
	if tex:
		slot.draw_texture(tex, Vector2(0, 0), Color(brighten, brighten, brighten))

func _setup_slot_style(slot: Panel) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1)
	slot.add_theme_stylebox_override("panel", style)
	slot.set_meta("style", style)

func _update_slot(slot: Panel) -> void:
	var style: StyleBoxFlat = slot.get_meta("style")
	style.border_width_left = 0
	style.border_width_top = 0
	style.border_width_right = 0
	style.border_width_bottom = 0
	slot.queue_redraw()
	_update_hover(slot)

func _on_slot_input(event: InputEvent, slot: Panel) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and slot.has_meta("item"):
		HealthBarGUI.show_cost_preview(0.0)
		var item = slot.get_meta("item")
		dragged_item = item.duplicate()
		drag_preview_item = dragged_item.duplicate()
		original_slot = slot
		slot.set_meta("item", {})
		_update_slot(slot)
		queue_redraw()
		refresh_inventory_highlights()
		if grid_controller:
			grid_controller.refresh_grid_highlights()

func refresh_inventory_highlights() -> void:
	for slot in slots:
		slot.queue_redraw()

func _on_slot_hover(slot: Panel, entered: bool) -> void:
	slot.set_meta("hovered", entered)
	_update_hover(slot)

func _update_hover(slot: Panel) -> void:
	var style: StyleBoxFlat = slot.get_meta("style")
	var base = Color(0.1, 0.1, 0.1)
	var hover = Color(0.2, 0.2, 0.2)
	var merge = Color(0.1, 0.4, 0.1)
	var item = slot.get_meta("item", {})
	var hovered = slot.get_meta("hovered", false)
	
	var is_potential_merge = !item.is_empty() and (
		(original_slot != null and !dragged_item.is_empty() and item.id == dragged_item.id and item.rank == dragged_item.rank) or
		(grid_controller != null and grid_controller.dragged_tower != null and 
		 item.id == grid_controller.dragged_tower.get_meta("item_data").id and 
		 item.rank == grid_controller.dragged_tower.get_meta("item_data").rank)
	)
	
	if hovered and is_potential_merge:
		style.bg_color = merge
	elif hovered:
		style.bg_color = hover
	else:
		style.bg_color = base

func _process(_delta: float) -> void:
	var preview_cost: float = 0.0
	
	if !dragged_item.is_empty():
		var mouse_pos = get_global_mouse_position()
		potential_cell = GridController.get_cell_from_pos(mouse_pos)
		
		# Inventory merge preview
		var inv_target = get_closest_slot(mouse_pos, 8.0, false)
		if inv_target and inv_target != original_slot:
			var target_item = inv_target.get_meta("item", {})
			if !target_item.is_empty() and target_item.id == dragged_item.id and target_item.rank == dragged_item.rank:
				var new_rank = dragged_item.rank + 1
				preview_cost = (base_spawn_cost * pow(3.0, float(new_rank - 1))) / 3.0
		
		# Grid merge preview (only if no inventory merge detected)
		if preview_cost == 0.0 and potential_cell != Vector2i(-1, -1):
			var existing = GridController.get_grid_item_at_cell(potential_cell)
			if existing:
				var existing_data = existing.get_meta("item_data", {})
				if existing_data.id == dragged_item.id and existing_data.rank == dragged_item.rank:
					var new_rank = existing_data.rank + 1
					preview_cost = (base_spawn_cost * pow(3.0, float(new_rank - 1))) / 3.0
		
		HealthBarGUI.show_cost_preview(preview_cost)
	else:
		if potential_cell != Vector2i(-1, -1):
			potential_cell = Vector2i(-1, -1)
		queue_redraw()
	
	if original_slot != null:
		queue_redraw()
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) == false and original_slot != null:
		_perform_drop()
		HealthBarGUI.show_cost_preview(0.0)  # Clear preview after drop
		
	if !dragged_item.is_empty() or (grid_controller and grid_controller.dragged_tower != null):
		_merge_blink_timer += _delta
		if _merge_blink_timer >= 0.5:
			_merge_blink_timer -= 0.5
			_merge_blink_state = !_merge_blink_state
			refresh_inventory_highlights()
			if grid_controller:
				grid_controller.refresh_grid_highlights()
	else:
		_merge_blink_timer = 0.0
		if _merge_blink_state:
			_merge_blink_state = false
			refresh_inventory_highlights()
			if grid_controller:
				grid_controller.refresh_grid_highlights()

func get_current_dragged_data(exclude_tower: Node = null) -> Dictionary:
	if !dragged_item.is_empty():
		return dragged_item
	if grid_controller and grid_controller.dragged_tower != null and grid_controller.dragged_tower != exclude_tower:
		return grid_controller.dragged_tower.get_meta("item_data")
	return {}

func _perform_drop() -> void:
	var mouse_pos = get_global_mouse_position()
	var target = get_closest_slot(mouse_pos, 8.0, false)
	var return_to_original = true
	
	if target and target != original_slot:
		var target_item = target.get_meta("item", {})
		if target_item.is_empty():
			target.set_meta("item", dragged_item)
			_update_slot(target)
			return_to_original = false
		elif !target_item.is_empty() and target_item.id == dragged_item.id and target_item.rank == dragged_item.rank:
			var new_rank = target_item.rank + 1
			var cost = (base_spawn_cost * pow(3.0, float(new_rank - 1))) / 3.0
			if StatsManager.spend_health(cost):
				target_item.rank += 1
				target.set_meta("item", target_item)
				_update_slot(target)
				return_to_original = false
	
	if return_to_original and potential_cell != Vector2i(-1, -1):
		if GridController.place_item(dragged_item, potential_cell):
			return_to_original = false
	
	if return_to_original:
		original_slot.set_meta("item", dragged_item)
		_update_slot(original_slot)
	
	dragged_item = {}
	original_slot = null
	drag_preview.visible = false
	potential_cell = Vector2i(-1, -1)
	for slot in slots:
		_update_hover(slot)
	refresh_inventory_highlights()
	if grid_controller:
		grid_controller.refresh_grid_highlights()

func refresh_all_highlights() -> void:
	for slot in slots:
		slot.queue_redraw()
	if grid_controller:
		grid_controller.refresh_grid_highlights()

func _get_slot_under_mouse() -> Panel:
	var pos = get_global_mouse_position()
	for slot in slots:
		if slot.get_global_rect().has_point(pos):
			return slot
	return null

func get_closest_slot(global_pos: Vector2, max_dist: float = 8.0, empty_only: bool = false) -> Panel:
	var closest: Panel = null
	var min_dist_sq: float = INF
	var max_dist_sq: float = max_dist * max_dist
	for slot in slots:
		if empty_only and !slot.get_meta("item", {}).is_empty():
			continue
		var center = slot.get_global_rect().get_center()
		var dist_sq = global_pos.distance_squared_to(center)
		if dist_sq < min_dist_sq:
			min_dist_sq = dist_sq
			closest = slot
	if closest and min_dist_sq <= max_dist_sq:
		return closest
	return null

func _spawn_item(rank: int) -> void:
	var keys = items.keys()
	if keys.is_empty(): return
	var id = keys[randi() % keys.size()]
	var new_item = {"id": id, "rank": rank + 1}
	var cost = base_spawn_cost * pow(3.0, float(rank))
	if not StatsManager.spend_health(cost): return
	for slot in slots:
		if slot.get_meta("item", {}).is_empty():
			slot.set_meta("item", new_item)
			_update_slot(slot)
			return


func clear_inventory() -> void:
	for slot in slots:
		slot.set_meta("item", {})
		_update_slot(slot)
	refresh_inventory_highlights()
