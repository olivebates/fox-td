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
var base_spawn_cost = 40.0
@onready var HealthBarGUI = get_tree().get_first_node_in_group("HealthBarContainer")
@onready var grid_controller: Node2D = get_node("/root/GridController")
var _merge_blink_timer: float = 0.0
var _merge_blink_state: bool = false
#var cost_to_spawn = 30


var items: Dictionary = {
	"Fox": {
		"name": "Fox",
		"texture": preload("uid://cs2ic8oeq6fc0"),
		"prefab": preload("uid://dfx5piisk4epn"),
		"bullet": preload("uid://ciuly8asijcg5"),
		"unlocked": true,
		"attack_speed": 1,
		#"damage": 1,
		"radius": 24,
		"rarity": 1,
		"description": "A basic shooting fox!"
	},
	"Duck": {
		"name": "Duck",
		"texture": preload("uid://cqgl3igwvfat8"),
		"prefab": preload("uid://dfx5piisk4epn"),
		"bullet": preload("uid://32xbub5ovblc"),
		"unlocked": false,
		"attack_speed": 1,
		#"damage": 1,
		"radius": 24,
		"rarity": 2,
		"description": "A duck that shoots exploding bullets!"
	},
}


var level_up_stats: Dictionary = {
	"attack_speed": [0, 0, 0, 1, 0, 0, 0],
	"damage":       [0, 1, 0, 0, 0, 1, 0],
	"radius":       [4, 2, 2, 2, 2, 2, 2]
}

func get_placement_cost(id: String, tower_level: int, rank: int) -> float:
	var base = items[id].rarity * 40
	var level_factor = 1.0 + (tower_level * 0.2)
	var rank_factor = pow(3, rank - 1)
	return base * level_factor * rank_factor

func apply_level_up(id: String) -> void:
	var item_data = items.get(id, {})
	if item_data.is_empty():
		return
	
	# Increment base stats directly on the tower definition
	item_data.tower_level += 1
	item_data.attack_speed += level_up_stats.attack_speed[min(Gacha.unlocked_levels[id], level_up_stats.attack_speed.size() - 1)]
	item_data.damage += level_up_stats.damage[min(Gacha.unlocked_levels[id], level_up_stats.damage.size() - 1)]
	item_data.radius += level_up_stats.radius[min(Gacha.unlocked_levels[id], level_up_stats.radius.size() - 1)]

func get_damage_calculation(rank):
	return int(pow(3.5, rank - 1) + rank -1)

func get_stat_for_rank(id: String, stat: String, rank: int) -> int:
	if rank <= 0: return items[id][stat]
	var base = InventoryManager.get_damage_calculation(1)#items[id][stat]
	var bonuses = level_up_stats.get(stat, [])
	for i in range(1, rank + 1):
		var bonus = bonuses[i - 1] if i <= bonuses.size() else bonuses.back()
		base += bonus
	return base

# Runtime state
var slots: Array[Panel] = []
var dragged_item: Dictionary = {}
var original_slot: Panel = null
var drag_preview: Control = null
var drag_preview_item: Dictionary = {}
var potential_cell: Vector2i = Vector2i(-1, -1)


func get_merge_cost(current_rank: int) -> float:
	var new_rank = current_rank + 1
	return base_spawn_cost #* pow(3.0, float(new_rank - 1)) / 3.0

#func _ready():
	#Gacha.register_items(items.keys())

func register_inventory(grid: GridContainer, spawner_grid: GridContainer, preview: Control) -> void:
	slots.clear()
	for i in 21:
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
	slots[0].set_meta("item", {"id": "Fox", "rank": 1})
	#slots[1].set_meta("item", {"id": "tower1", "rank": 1})
	#slots[5].set_meta("item", {"id": "tower2", "rank": 5})
	
	for slot in slots:
		_update_slot(slot)
	
	#var spawner_textures: Array[Texture2D] = [
		#preload("uid://dyan40sgre5b1"), 
		#preload("uid://dyan40sgre5b1"), 
		#preload("uid://dyan40sgre5b1"), 
		#preload("uid://dyan40sgre5b1"), 
		#preload("uid://dyan40sgre5b1"), 
		#preload("uid://dyan40sgre5b1"), 
		#preload("uid://dyan40sgre5b1"), 
		#preload("uid://dyan40sgre5b1"), 
		#preload("uid://dyan40sgre5b1"), 
	#]

	#for rank in range(1):
		#var btn = TextureRect.new()
		#btn.texture = spawner_textures[rank]
		#btn.expand_mode = TextureRect.EXPAND_KEEP_SIZE
		#btn.stretch_mode = TextureRect.STRETCH_KEEP
		#btn.custom_minimum_size = Vector2(8, 8)
		#btn.mouse_filter = Control.MOUSE_FILTER_STOP
		#
		#var cost = get_spawn_cost(rank)
		#
		#btn.mouse_entered.connect(func():
			#btn.modulate = Color(1.3, 1.3, 1.3)
			#HealthBarGUI.show_cost_preview(cost))
		#
		#btn.mouse_exited.connect(func():
			#btn.modulate = Color(1, 1, 1)
			#HealthBarGUI.hide_cost_preview())
		#
		#btn.gui_input.connect(func(event):
			#if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				#if !_spawn_item(rank):
					#Utilities.spawn_floating_text("Not enough meat...", Vector2.ZERO, null))
		#
		#spawner_grid.add_child(btn)
		
	
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
	if potential_cell != Vector2i(-1, -1):
		var nearest_cell = GridController.get_nearest_valid_cell(potential_cell)
		if nearest_cell != Vector2i(-1, -1):
			var cell_pos = GridController.grid_offset + Vector2(nearest_cell.x * GridController.CELL_SIZE, nearest_cell.y * GridController.CELL_SIZE)
			var valid = GridController.is_valid_placement(nearest_cell, dragged_item)
			var fill_color = Color(0, 1, 0, 0.3) if valid else Color(1, 0, 0, 0.3)
			draw_rect(Rect2(cell_pos, Vector2(GridController.CELL_SIZE, GridController.CELL_SIZE)), fill_color, true)
	var rank = dragged_item.get("rank", 0)
	var border_color = RANK_COLORS.get(rank, Color(1, 1, 1))
	draw_rect(Rect2(draw_pos + Vector2(1.5, 1.5), Vector2(7, 7)), border_color, false, 1.0)
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
	var brighten = 1.3 if hovered else 1.0
	var bg_color = base_color * brighten
	slot.draw_rect(Rect2(0.5, 0.5, 7, 7), border_color, false, 1.0 + (0.5 if hovered else 0.0))
	slot.draw_rect(Rect2(1, 1, 6, 6), bg_color, true)
	var tex = items.get(item.get("id", ""), {}).get("texture", null)
	if tex:
		slot.draw_texture(tex, Vector2(0, 0), Color(brighten, brighten, brighten))
	var rarity = items.get(item.get("id", ""), {}).get("rarity", 0)
	for i in range(rarity):
		var offset = Vector2(0.8 + i * 1.5, 8.2)
		slot.draw_colored_polygon(PackedVector2Array([offset + Vector2(0, -2.0), offset + Vector2(1.4, 0.2), offset + Vector2(-0.9, 0.2)]), Color(0.0, 0.0, 0.0, 1.0))
		slot.draw_colored_polygon(PackedVector2Array([offset + Vector2(0, -1.5), offset + Vector2(1, 0), offset + Vector2(-0.5, 0)]), Color(0.98, 0.98, 0.0, 1.0))

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
	if entered and !slot.get_meta("item", {}).is_empty():
		var item = slot.get_meta("item")
		var def = items[item.id]
		var tower_level = def.get("tower_level", 0)
		var atk = get_stat_for_rank(item.id, "attack_speed", item.rank)
		var dmg = get_damage_calculation(item.rank)
		var rad = get_stat_for_rank(item.id, "radius", item.rank)
		var cost = get_placement_cost(item.id, tower_level, item.rank)
		TooltipManager.show_tooltip(
			def.get("name", item.id.capitalize()),
			"[color=cornflower_blue]Place Cost: " + str(int(cost)) + "[/color]\n[color=gray]————————————————[/color]\n" +
			"Damage: " + str(dmg) + "\n" +
			"Attack Speed: " + str(atk) + "/s\n" +
			"Range: " + str(rad/8) + " tiles\n[color=gray]————————————————[/color]\n" +
			"[font_size=2][color=dark_gray]" + def.get("description", "") + "[/color][/font_size]"
		)
		HealthBarGUI.show_cost_preview(cost)
	elif !entered:
		TooltipManager.hide_tooltip()
		if dragged_item.is_empty():
			var any_hovered = false
			for s in slots:
				if s.get_meta("hovered", false):
					any_hovered = true
					break
			if !any_hovered:
				if HealthBarGUI:
					HealthBarGUI.show_cost_preview(0.0)

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
		var item_def = items[dragged_item.id]
		var tower_level = item_def.get("tower_level", 0)
		var cost = get_placement_cost(dragged_item.id, tower_level, dragged_item.rank)
		HealthBarGUI.show_cost_preview(cost)
		var mouse_pos = get_global_mouse_position()
		var raw_cell = GridController.get_cell_from_pos(mouse_pos)
		potential_cell = GridController.get_nearest_valid_cell(raw_cell) if raw_cell != Vector2i(-1, -1) else Vector2i(-1, -1)
		queue_redraw()
	if original_slot != null:
		queue_redraw()
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) == false and original_slot != null:
		_perform_drop()
		HealthBarGUI.show_cost_preview(0.0)

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
	if return_to_original and potential_cell != Vector2i(-1, -1):
		var place_cell = GridController.get_nearest_valid_cell(potential_cell)
		if place_cell != Vector2i(-1, -1):
			if GridController.get_grid_item_at_cell(place_cell) == null && GridController.is_valid_placement(place_cell, dragged_item):
				if GridController.place_item(dragged_item, place_cell):
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

func _spawn_item(rank: int) -> bool:
	var keys = items.keys()
	if keys.is_empty(): return false
	var id = keys[randi() % keys.size()]
	var new_item = {"id": id, "rank": rank + 1}
	var cost = get_placement_cost(id, 1, rank)
	if not StatsManager.spend_health(cost): return false
	for slot in slots:
		if slot.get_meta("item", {}).is_empty():
			slot.set_meta("item", new_item)
			_update_slot(slot)
			return true
	return false


func clear_inventory() -> void:
	for slot in slots:
		slot.set_meta("item", {})
		_update_slot(slot)
	refresh_inventory_highlights()
