extends GridContainer

@export var is_squad_inventory: bool = false

var slots: Array[Panel] = []
var dragged_tower: Dictionary = {}
var original_slot: Panel = null
var current_dragged_tower: Dictionary = {}
var _merge_blink_timer: float = 0.0
var _merge_blink_state: bool = false

@onready var drag_preview: Control = get_parent().get_parent().get_node("Preview")

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

func _setup_slot_style(slot: Panel) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1)
	slot.add_theme_stylebox_override("panel", style)
	slot.set_meta("style", style)

func _update_slot(slot: Panel) -> void:
	var real_index: int = slot.get_meta("real_index", -1)
	if real_index == -1:
		return
	var tower = TowerManager.get_tower_at(real_index)
	var style: StyleBoxFlat = slot.get_meta("style")
	if tower.is_empty():
		style.bg_color = Color(0.1, 0.1, 0.1)
	else:
		var rank_color = InventoryManager.RANK_COLORS.get(tower.merged, Color(1, 1, 1))
		style.bg_color = rank_color * 0.3
		style.bg_color.a = 1.0
	slot.queue_redraw()

func _on_slot_input(event: InputEvent, slot: Panel) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var real_index: int = slot.get_meta("real_index", -1)
		if real_index == -1:
			return
		var tower = TowerManager.get_tower_at(real_index)
		var unmerge_button = get_tree().get_first_node_in_group("unmerge_towers")
		
		if unmerge_button and unmerge_button.unmerge_mode and event.pressed and !tower.is_empty() and tower.merged > 1:
			_perform_unmerge(real_index, tower, slot)
			return  # Prevent drag if unmerging
		
		if event.pressed and !tower.is_empty():
			# Disable drag for merged level 1 when unmerge mode is active
			if unmerge_button and unmerge_button.unmerge_mode and tower.merged == 1:
				return
			
			# Start drag
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
	var lower = tower.duplicate()
	lower.merged -= 1
	TowerManager.set_tower_at(real_index, lower)
	
	# Place second copy in same inventory
	var inv_size = TowerManager.get_inventory_size(is_squad_inventory)
	var offset = 1000 if is_squad_inventory else 0
	var placed = false
	for i in inv_size:
		var idx = i + offset
		if TowerManager.get_tower_at(idx).is_empty():
			TowerManager.set_tower_at(idx, lower)
			placed = true
			break
	
	_update_slot(slot)
	refresh_all_highlights()
	get_tree().call_group("backpack_inventory" if is_squad_inventory else "squad_inventory", "refresh_all_highlights")

func _on_slot_hover(slot: Panel, entered: bool) -> void:
	slot.set_meta("hovered", entered)
	_update_hover(slot)

func _update_hover(slot: Panel) -> void:
	var unmerge_button = get_tree().get_first_node_in_group("unmerge_towers")
	var style: StyleBoxFlat = slot.get_meta("style")
	var real_index: int = slot.get_meta("real_index", -1)
	if real_index == -1:
		return
	var tower = TowerManager.get_tower_at(real_index)
	var hovered = slot.get_meta("hovered", false)
	var base_color = Color(0.1, 0.1, 0.1) if tower.is_empty() else InventoryManager.RANK_COLORS.get(tower.merged, Color(1,1,1)) * 0.3
	base_color.a = 1.0
	var is_merge_target = !current_dragged_tower.is_empty() && !tower.is_empty() && tower.type == current_dragged_tower.type && tower.merged == current_dragged_tower.merged
	if is_merge_target and !unmerge_button.unmerge_mode:
		style.bg_color = Color(0.1, 0.4, 0.1)
	elif hovered and !unmerge_button.unmerge_mode:
		style.bg_color = base_color * 1.3
	else:
		style.bg_color = base_color
	

func _process(_delta: float) -> void:
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
	var return_to_original = true
	if target_slot:
		var target_real: int = target_slot.get_meta("real_index")
		var target_tower = TowerManager.get_tower_at(target_real)
		var target_inv = target_slot.get_parent()
		if target_tower.is_empty():
			TowerManager.set_tower_at(target_real, dragged_tower)
			target_inv._update_slot(target_slot)
			return_to_original = false
		elif target_tower.type == dragged_tower.type && target_tower.merged == dragged_tower.merged:
			var updated = target_tower.duplicate()
			updated.merged += 1
			TowerManager.set_tower_at(target_real, updated)
			target_inv._update_slot(target_slot)
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
	var rank = dragged_tower.merged
	var border_color = InventoryManager.RANK_COLORS.get(rank, Color(1, 1, 1))
	drag_preview.draw_rect(Rect2(0.5, 0.5, 7, 7), border_color, false, 1.0)
	var tex = dragged_tower.type.texture
	if tex:
		drag_preview.draw_texture(tex, Vector2.ZERO, Color(1.4, 1.4, 1.4))

func _draw_slot(slot: Panel) -> void:
	var unmerge_button = get_tree().get_first_node_in_group("unmerge_towers")
	var real_index: int = slot.get_meta("real_index", -1)
	if real_index == -1:
		return
	var tower = TowerManager.get_tower_at(real_index)
	if tower.is_empty():
		return
	var rank = tower.merged
	var border_color = InventoryManager.RANK_COLORS.get(rank, Color(1, 1, 1))
	var base_color = border_color * 0.3
	base_color.a = 1.0
	var hovered = slot.get_meta("hovered", false)
	var is_merge_target = !current_dragged_tower.is_empty() && tower.type == current_dragged_tower.type && tower.merged == current_dragged_tower.merged
	var brighten = 1.0
	if is_merge_target:
		brighten = 1.5 if _merge_blink_state else 1.2
		border_color = Color.YELLOW
		base_color = Color.YELLOW
	elif hovered:
		brighten = 1.3
	var bg_color = base_color * brighten
	if !unmerge_button.unmerge_mode or tower.merged > 1:
		slot.draw_rect(Rect2(0.5, 0.5, 7, 7), border_color, false, 1.0 + (0.5 if (hovered or is_merge_target) else 0.0))
	slot.draw_rect(Rect2(1, 1, 6, 6), bg_color, true)
	var tex = tower.type.texture
	
	var is_unmerge_active = unmerge_button and unmerge_button.unmerge_mode
	var is_merged_level_1 = tower.merged == 1

	var modulate = Color(brighten, brighten, brighten)
	if is_unmerge_active and is_merged_level_1:
		modulate = Color(0.4, 0.4, 0.4)

	if tex:
		slot.draw_texture(tex, Vector2(0, 0), modulate)
		
	if tex and !unmerge_button.unmerge_mode:
		slot.draw_texture(tex, Vector2(0, 0), Color(brighten, brighten, brighten))
	var rarity = tower.type.get("rarity", 0)
	for i in range(rarity):
		var offset = Vector2(0.8 + i * 1.5, 8.2)
		slot.draw_colored_polygon(
			PackedVector2Array([offset + Vector2(0, -2.0), offset + Vector2(1.4, 0.2), offset + Vector2(-0.9, 0.2)]),
			Color(0.0, 0.0, 0.0, 1.0)
		)
		slot.draw_colored_polygon(
			PackedVector2Array([offset + Vector2(0, -1.5), offset + Vector2(1, 0), offset + Vector2(-0.5, 0)]),
			Color(0.98, 0.98, 0.0, 1.0)
		)
