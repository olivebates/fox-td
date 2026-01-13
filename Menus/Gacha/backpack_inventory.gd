extends GridContainer

@export var is_squad_inventory: bool = false
var slots: Array[Panel] = []
var dragged_tower: Dictionary = {}
var original_slot: Panel = null
var current_dragged_tower: Dictionary = {}
var _merge_blink_timer: float = 0.0
var _merge_blink_state: bool = false
const LOCK_ICON = "🔒"

@onready var drag_preview: Control = get_parent().get_parent().get_node("Preview")
@onready var inventory_manager = $/root/InventoryManager

func _ready() -> void:
	add_to_group("squad_inventory" if is_squad_inventory else "backpack_inventory")
	if drag_preview:
		drag_preview.visible = false
		drag_preview.draw.connect(_draw_preview)
	_rebuild_slots()
	

func set_current_dragged(tower: Dictionary) -> void:
	current_dragged_tower = tower.duplicate() if !tower.is_empty() else {}



func _rebuild_slots() -> void:
	for child in get_children():
		if child is Panel:
			child.queue_free()
	slots.clear()
	var size = TowerManager.get_inventory_size(is_squad_inventory)
	for i in size:
		var slot = Panel.new()
		slot.custom_minimum_size = Vector2(8, 8)
		slot.mouse_filter = Control.MOUSE_FILTER_STOP
		slot.gui_input.connect(_on_slot_input.bind(slot))
		slot.mouse_entered.connect(_on_slot_hover.bind(slot, true))
		slot.mouse_exited.connect(_on_slot_hover.bind(slot, false))
		slot.draw.connect(_draw_slot.bind(slot))
		add_child(slot)
		slots.append(slot)
		var real_index = i + (1000 if is_squad_inventory else 0)
		slot.set_meta("local_index", i)
		slot.set_meta("real_index", real_index)
		_setup_slot_style(slot)
		_update_slot(slot)
	refresh_all_highlights()

func _is_slot_locked(slot: Panel) -> bool:
	var real_index = int(slot.get_meta("real_index", -1))
	if real_index < 1000:
		return false
	var local_index = int(slot.get_meta("local_index", -1))
	if local_index == -1:
		return false
	return !TowerManager.is_squad_slot_unlocked(local_index)

func _setup_slot_style(slot: Panel) -> void:
	var style = StyleBoxFlat.new()
	var base = GridController.random_tint
	style.bg_color = Color.from_hsv(GridController.hue, GridController.saturation, GridController.value - 0.7, 1.0)
	style.border_width_top = 1
	style.border_width_left = 1
	style.border_color = Color.from_hsv(GridController.hue, GridController.saturation, GridController.value - 0.6, 1.0)  # lighter
	slot.add_theme_stylebox_override("panel", style)
	slot.set_meta("style", style)

func _update_slot(slot: Panel) -> void:
	var real_index: int = slot.get_meta("real_index", -1)
	if real_index == -1:
		return
	var tower = TowerManager.get_tower_at(real_index)
	var style: StyleBoxFlat = slot.get_meta("style")
	var locked = _is_slot_locked(slot)
	if tower.is_empty():
		style.bg_color = Color(0.1, 0.1, 0.1)
	else:
		if not tower.has("colors"):
			tower["colors"] = InventoryManager.roll_tower_colors()
			tower["merge_children"] = tower.get("merge_children", [])
			TowerManager.set_tower_at(real_index, tower)
		var rarity = tower.type.get("rarity", 0)
		var rarity_color = InventoryManager.RANK_COLORS.get(rarity, Color(1, 1, 1))
		style.bg_color = rarity_color * 0.3
		style.bg_color.a = 1.0
	if locked:
		style.bg_color = style.bg_color * 0.45
		style.bg_color.a = 1.0
	slot.queue_redraw()

func _on_slot_input(event: InputEvent, slot: Panel) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if _is_slot_locked(slot):
			return
		var real_index: int = slot.get_meta("real_index", -1)
		if real_index == -1:
			return
		var tower = TowerManager.get_tower_at(real_index)
		var unmerge_button = get_tree().get_first_node_in_group("unmerge_towers")
		# Handle unmerge mode
		if unmerge_button and unmerge_button.unmerge_mode and event.pressed:
			if  tower.get("rank", 1) >= 2:
				_perform_unmerge(real_index, tower, slot)
			return
		
		# Handle normal drag
		if event.pressed and !tower.is_empty():
			dragged_tower = tower.duplicate()
			original_slot = slot
			TowerManager.set_tower_at(real_index, {})
			_update_slot(slot)
			if drag_preview:
				drag_preview.visible = true
			get_tree().call_group("backpack_inventory", "set_current_dragged", dragged_tower)
			get_tree().call_group("squad_inventory", "set_current_dragged", dragged_tower)
			get_tree().call_group("backpack_inventory", "refresh_all_highlights")
			get_tree().call_group("squad_inventory", "refresh_all_highlights")

func _perform_unmerge(real_index: int, tower: Dictionary, slot: Panel) -> void:
	var lower_a: Dictionary = {}
	var lower_b: Dictionary = {}
	if tower.has("merge_children") and tower.merge_children.size() >= 2:
		lower_a = tower.merge_children[0].duplicate(true)
		lower_b = tower.merge_children[1].duplicate(true)
	else:
		lower_a = tower.duplicate(true)
		lower_a.rank -= 1
		lower_b = lower_a.duplicate(true)
	TowerManager.set_tower_at(real_index, lower_a)
	var inv_size = TowerManager.get_inventory_size(is_squad_inventory)
	var offset = 1000 if is_squad_inventory else 0
	var placed = false
	for i in inv_size:
		if is_squad_inventory and !TowerManager.is_squad_slot_unlocked(i):
			continue
		var idx = i + offset
		if TowerManager.get_tower_at(idx).is_empty():
			TowerManager.set_tower_at(idx, lower_b)
			placed = true
			break
	_update_slot(slot)
	refresh_all_highlights()
	get_tree().call_group("backpack_inventory" if is_squad_inventory else "squad_inventory", "refresh_all_highlights")

func _on_slot_hover(slot: Panel, entered: bool) -> void:
	slot.set_meta("hovered", entered)
	_update_hover(slot)
	if entered:
		show_tooltip(slot)
	else:
		TooltipManager.hide_tooltip()

func show_tooltip(slot: Panel) -> void:
	if _is_slot_locked(slot):
		return
	var real_index: int = slot.get_meta("real_index", -1)
	if real_index == -1:
		return
	var tower = TowerManager.get_tower_at(real_index)
	if tower.is_empty():
		if _is_slot_locked(slot):
			_draw_lock(slot)
		return
	var item = {
		"id": tower.id,
		"rank": tower.get("rank", 1),
		"path": tower.get("path", [0, 0, 0])
	}
	var cost = inventory_manager.get_placement_cost(tower.id, 0, item.rank)
	inventory_manager.show_tower_tooltip(item, cost)

func _update_hover(slot: Panel) -> void:
	var unmerge_button = get_tree().get_first_node_in_group("unmerge_towers")
	var style: StyleBoxFlat = slot.get_meta("style")
	var real_index: int = slot.get_meta("real_index", -1)
	if real_index == -1:
		return
	var tower = TowerManager.get_tower_at(real_index)
	if _is_slot_locked(slot):
		if tower.is_empty():
			style.bg_color = Color(0.07, 0.07, 0.07)
		else:
			var rarity = tower.type.get("rarity", 0)
			var rarity_color = InventoryManager.RANK_COLORS.get(rarity, Color(1, 1, 1))
			style.bg_color = rarity_color * 0.15
			style.bg_color.a = 1.0
		return
	var hovered = slot.get_meta("hovered", false)
	var base_color = Color(0.1, 0.1, 0.1) if tower.is_empty() else InventoryManager.RANK_COLORS.get(tower.type.get("rarity", 0), Color(1,1,1)) * 0.3
	base_color.a = 1.0
	var is_merge_target = !current_dragged_tower.is_empty() && \
		!tower.is_empty() && \
		tower.id == current_dragged_tower.id && \
		tower.get("rank", 1) == current_dragged_tower.get("rank", 1) && \
		tower.get("rank", 1) < InventoryManager.MAX_MERGE_RANK
	if is_merge_target and !unmerge_button.unmerge_mode:
		style.bg_color = Color(0.1, 0.4, 0.1)
	elif hovered and !unmerge_button.unmerge_mode:
		style.bg_color = base_color * 1.3
	else:
		style.bg_color = base_color

func should_show_merge_hint() -> bool:
	if WaveSpawner.current_level != 2:
		return false
	for tower in TowerManager.tower_inventory:
		if !tower.is_empty() and tower.get("rank", 1) >= 2:
			return false
	for tower in TowerManager.squad_slots:
		if !tower.is_empty() and tower.get("rank", 1) >= 2:
			return false
	var count = 0
	for tower in TowerManager.squad_slots:
		if !tower.is_empty() and tower.get("rank", 1) == 1:
			count += 1
	return count >= 3

var hint_label = null

func _process(_delta: float) -> void:
	#if WaveSpawner.current_level == 2 and !hint_label and should_show_merge_hint():
		#hint_label = Label.new()
		#hint_label.text = "Merge two critters by draggin one atop the other! ^"
		#hint_label.position = Vector2(80, 50)
		#hint_label.add_theme_font_size_override("font_size", 24)
		#hint_label.add_theme_color_override("font_color", Color.WHITE)
		#hint_label.add_theme_font_size_override("font_size", 8)
		#hint_label.z_index = 800
		#var tween = create_tween()
		#tween.set_loops()
		#tween.tween_property(hint_label, "position:y", position.y -13, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		#tween.tween_property(hint_label, "position:y", position.y -11, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		#get_tree().get_first_node_in_group("gacha_menu").add_child(hint_label)
	#if hint_label and (WaveSpawner.current_level != 2 or !should_show_merge_hint()):
		#hint_label.queue_free()
		#hint_label = null
	if !dragged_tower.is_empty():
		if drag_preview:
			drag_preview.global_position = get_global_mouse_position() - Vector2(4, 4)
			drag_preview.queue_redraw()
		_merge_blink_timer += _delta
		if _merge_blink_timer >= 0.5:
			_merge_blink_timer -= 0.5
			_merge_blink_state = !_merge_blink_state
		refresh_all_highlights()
		var other_group = "squad_inventory" if is_squad_inventory else "backpack_inventory"
		for node in get_tree().get_nodes_in_group(other_group):
			node.refresh_all_highlights()
	else:
		if _merge_blink_state:
			_merge_blink_state = false
		refresh_all_highlights()
	if !Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) && original_slot != null:
		_perform_drop()

func _perform_drop() -> void:
	var mouse_pos = get_global_mouse_position()
	var target_slot: Panel = _get_slot_at_position(mouse_pos)
	if target_slot and _is_slot_locked(target_slot):
		target_slot = null
	var return_to_original = true
	if target_slot:
		var target_real: int = target_slot.get_meta("real_index")
		var target_tower = TowerManager.get_tower_at(target_real)
		var target_inv = target_slot.get_parent()
		if target_tower.is_empty():
			TowerManager.set_tower_at(target_real, dragged_tower)
			target_inv._update_slot(target_slot)
			return_to_original = false
		elif target_tower.id == dragged_tower.id && target_tower.get("rank", 1) == dragged_tower.get("rank", 1) && target_tower.get("rank", 1) < InventoryManager.MAX_MERGE_RANK:
			var updated = target_tower.duplicate(true)
			updated.rank += 1
			updated.colors = target_tower.get("colors", [])
			updated.merge_children = [
				target_tower.duplicate(true),
				dragged_tower.duplicate(true)
			]
			TowerManager.set_tower_at(target_real, updated)
			target_inv._update_slot(target_slot)
			show_tooltip(target_slot)
			return_to_original = false
	if return_to_original && original_slot:
		var orig_real: int = original_slot.get_meta("real_index")
		TowerManager.set_tower_at(orig_real, dragged_tower)
		_update_slot(original_slot)
	if !is_squad_inventory && TowerManager.tower_inventory.size() != slots.size():
		_rebuild_slots()
	else:
		refresh_all_highlights()
	dragged_tower = {}
	original_slot = null
	if drag_preview:
		drag_preview.visible = false
	get_tree().call_group("backpack_inventory", "set_current_dragged", {})
	get_tree().call_group("squad_inventory", "set_current_dragged", {})
	get_tree().call_group("backpack_inventory", "refresh_all_highlights")
	get_tree().call_group("squad_inventory", "refresh_all_highlights")

func _get_slot_at_position(global_pos: Vector2) -> Panel:
	for group in ["backpack_inventory", "squad_inventory"]:
		for inv in get_tree().get_nodes_in_group(group):
			for slot in inv.slots:
				if slot.get_global_rect().has_point(global_pos):
					return slot
	return null

func refresh_all_highlights() -> void:
	for slot in slots:
		_update_hover(slot)
		slot.queue_redraw()

func _draw_preview() -> void:
	if dragged_tower.is_empty():
		return
	var rarity = dragged_tower.type.get("rarity", 0)
	var border_color = InventoryManager.RANK_COLORS.get(rarity, Color(1, 1, 1))
	drag_preview.draw_rect(Rect2(0.5, 0.5, 7, 7), border_color, false, 1.0)
	var tex = dragged_tower.type.texture
	if tex:
		drag_preview.draw_texture(tex, Vector2.ZERO, Color(1.4, 1.4, 1.4))


func _draw_slot(slot: Panel) -> void:
	var real_index: int = slot.get_meta("real_index", -1)
	if real_index == -1:
		return
	var tower = TowerManager.get_tower_at(real_index)
	if tower.is_empty():
		if _is_slot_locked(slot):
			_draw_lock(slot)
		return
		
	if tower.is_empty():
		var light_color = Color.from_hsv(GridController.hue, GridController.saturation, GridController.value - 0.4, 1.0)
		# Right border (outside)
		slot.draw_line(Vector2(8.5, 1), Vector2(8.5, 9), light_color, 1.0)
		# Bottom border (outside)
		slot.draw_line(Vector2(1, 8.5), Vector2(9, 8.5), light_color, 1.0)
		
	var rank = tower.get("rank", 1)
	var rarity = tower.type.get("rarity", 0)
	var border_color = InventoryManager.RANK_COLORS.get(rarity, Color(1, 1, 1))
	var base_color = border_color * 0.3
	base_color.a = 1.0
	var hovered = slot.get_meta("hovered", false)
	var is_merge_target = !current_dragged_tower.is_empty() && tower.id == current_dragged_tower.id && rank == current_dragged_tower.get("rank", 1) && rank < InventoryManager.MAX_MERGE_RANK
	var brighten = 1.0
	if is_merge_target:
		brighten = 1.5 if _merge_blink_state else 1.2
		border_color = Color.YELLOW
		base_color = Color.YELLOW
	elif hovered:
		brighten = 1.3
	var bg_color = base_color * brighten
	var unmerge_button = get_tree().get_first_node_in_group("unmerge_towers")
	var is_unmerge_active = unmerge_button and unmerge_button.unmerge_mode
	var modulate = Color(brighten, brighten, brighten)
	if is_unmerge_active && rank == 1:
		modulate = Color(0.4, 0.4, 0.4)
	slot.draw_rect(Rect2(0.5, 0.5, 7, 7), border_color, false, 1.0 + (0.5 if (hovered or is_merge_target) else 0.0))
	slot.draw_rect(Rect2(1, 1, 6, 6), bg_color, true)
	var tex = tower.type.texture
	if tex:
		slot.draw_texture(tex, Vector2(0, 0), modulate)
	var spawner = get_tree().get_first_node_in_group("wave_spawner")
	var is_banned = spawner and spawner.has_method("is_tower_banned") and bool(spawner.call("is_tower_banned", tower.id))
	if is_banned:
		slot.draw_rect(Rect2(1, 1, 6, 6), Color(0, 0, 0, 0.5), true)
		var font = slot.get_theme_default_font()
		if font:
			slot.draw_string(font, Vector2(1.2, 6.8), "⛔", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(1, 1, 1, 0.9))
	var colors: Array = tower.get("colors", [])
	if colors.size() > 0:
		var dot_pos = Vector2(1.2, 1.2)
		for color_name in colors:
			var dot_color = InventoryManager.get_color_value(color_name)
			slot.draw_circle(dot_pos, 0.7, dot_color)
			dot_pos.x += 1.7
	if _is_slot_locked(slot):
		_draw_lock(slot)
		

	
	var triangle_count = min(int(rank), InventoryManager.MAX_MERGE_RANK)
	for i in range(triangle_count):
		var offset = Vector2(0.8 + i * 1.5, 8.2)
		slot.draw_colored_polygon(PackedVector2Array([offset + Vector2(0, -2.0), offset + Vector2(1.4, 0.2), offset + Vector2(-0.9, 0.2)]), Color(0.0, 0.0, 0.0, 1.0))
		slot.draw_colored_polygon(PackedVector2Array([offset + Vector2(0, -1.5), offset + Vector2(1, 0), offset + Vector2(-0.5, 0)]), Color(0.98, 0.98, 0.0, 1.0))

func _draw_lock(slot: Panel) -> void:
	var font = slot.get_theme_default_font()
	if font:
		slot.draw_string(font, Vector2(1.2, 6.8), LOCK_ICON, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(1, 1, 1, 0.9))
		
