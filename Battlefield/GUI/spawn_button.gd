extends Button

@onready var inventory_manager: Node = get_node("/root/InventoryManager")
@onready var health_bar_gui = get_tree().get_first_node_in_group("HealthBarContainer")

var spawn_cost: float = 50.0  # Must match InventoryManager.base_spawn_cost

func _ready() -> void:
	add_theme_font_size_override("font_size", 4)
	
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.2, 0.2, 0.2)
	style_normal.border_width_left = 0
	style_normal.border_width_top = 0
	style_normal.border_width_right = 0
	style_normal.border_width_bottom = 0
	style_normal.corner_radius_top_left = 0
	style_normal.corner_radius_top_right = 0
	style_normal.corner_radius_bottom_left = 0
	style_normal.corner_radius_bottom_right = 0
	style_normal.content_margin_left = 3
	style_normal.content_margin_right = 2
	style_normal.content_margin_top = 0
	style_normal.content_margin_bottom = 1
	
	var style_hover = style_normal.duplicate()
	style_hover.bg_color = Color(0.3, 0.3, 0.3)
	
	var style_pressed = style_normal.duplicate()
	style_pressed.bg_color = Color(0.15, 0.15, 0.15)
	
	var style_disabled = style_normal.duplicate()
	style_disabled.bg_color = Color(0.1, 0.05, 0.05)
	
	add_theme_stylebox_override("normal", style_normal)
	add_theme_stylebox_override("hover", style_hover)
	add_theme_stylebox_override("pressed", style_pressed)
	add_theme_stylebox_override("disabled", style_disabled)
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	pressed.connect(_on_pressed)

func _on_mouse_entered() -> void:
	modulate = Color(1.3, 1.3, 1.3)
	health_bar_gui.show_cost_preview(InventoryManager.cost_to_spawn)

func _on_mouse_exited() -> void:
	modulate = Color(1, 1, 1)
	health_bar_gui.hide_cost_preview()

func _on_pressed() -> void:
	if StatsManager.spend_health(InventoryManager.cost_to_spawn):
		var keys = inventory_manager.items.keys()
		var id = keys[randi() % keys.size()]
		var new_item = {"id": id, "rank": 1}
		var placed = false
		for slot in inventory_manager.slots:
			if slot.get_meta("item", {}).is_empty():
				slot.set_meta("item", new_item)
				inventory_manager._update_slot(slot)
				placed = true
				InventoryManager.cost_to_spawn += 5
				break
		if not placed:
			Utilities.spawn_floating_text("Inventory full!", get_global_mouse_position(), null, false)
	else:
		Utilities.spawn_floating_text("Not enough meat...", get_global_mouse_position(), null, false)
		
