extends Button

var upgrade_mode: bool = false
@onready var grid_controller = GridController

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	toggle_mode = true
	button_pressed = false
	toggled.connect(_on_toggled)
	
	# Remove padding and rounded corners
	add_theme_font_size_override("font_size", 4)
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.2, 0.2, 0.2)
	style_normal.border_width_left = 0
	style_normal.border_width_top = 0
	style_normal.border_width_right = 0
	style_normal.border_width_bottom = 0
	style_normal.border_color = Color(0.5, 0.5, 0.5)
	style_normal.corner_radius_top_left = 0
	style_normal.corner_radius_top_right = 0
	style_normal.corner_radius_bottom_left = 0
	style_normal.corner_radius_bottom_right = 0
	style_normal.content_margin_left = 3
	style_normal.content_margin_right = 3
	style_normal.content_margin_top = 0
	style_normal.content_margin_bottom = 1
	
	var style_hover = style_normal.duplicate()
	style_hover.bg_color = Color(0.3, 0.3, 0.3)
	style_hover.border_color = Color(0.7, 0.7, 0.7)
	
	var style_pressed = style_normal.duplicate()
	style_pressed.bg_color = Color(0.15, 0.15, 0.15)
	style_pressed.border_color = Color(0.8, 0.8, 0.8)
	
	add_theme_stylebox_override("normal", style_normal)
	add_theme_stylebox_override("hover", style_hover)
	add_theme_stylebox_override("pressed", style_pressed)
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	TooltipManager.show_tooltip(
	"Upgrade Critters",
	"[font_size=2][color=dark_gray]Click a critter on the field to upgrade it![/color][/font_size]"
	)

func _on_mouse_exited() -> void:
	TooltipManager.hide_tooltip()

func _on_toggled(pressed: bool) -> void:
	upgrade_mode = pressed
	grid_controller.refresh_grid_highlights()
	
	var base_style = StyleBoxFlat.new()
	base_style.border_width_left = 0
	base_style.border_width_top = 0
	base_style.border_width_right = 0
	base_style.border_width_bottom = 0
	base_style.corner_radius_top_left = 0
	base_style.corner_radius_top_right = 0
	base_style.corner_radius_bottom_left = 0
	base_style.corner_radius_bottom_right = 0
	base_style.content_margin_left = 3
	base_style.content_margin_right = 3
	base_style.content_margin_top = 0
	base_style.content_margin_bottom = 1
	
	if pressed:
		# Soft lime when toggled ON (normal state)
		base_style.bg_color = Color(0.5, 1.0, 0.5)      # soft lime
		base_style.border_color = Color(0.7, 1.0, 0.7)
		var hover = base_style.duplicate()
		hover.bg_color = Color(0.6, 1.0, 0.6)
		var pressed_style = base_style.duplicate()
		pressed_style.bg_color = Color(0.4, 0.9, 0.4)
		add_theme_stylebox_override("normal", base_style)
		add_theme_stylebox_override("hover", hover)
		add_theme_stylebox_override("pressed", pressed_style)
	else:
		# Original dark when toggled OFF
		base_style.bg_color = Color(0.2, 0.2, 0.2)
		base_style.border_color = Color(0.5, 0.5, 0.5)
		var hover = base_style.duplicate()
		hover.bg_color = Color(0.3, 0.3, 0.3)
		hover.border_color = Color(0.7, 0.7, 0.7)
		var pressed_style = base_style.duplicate()
		pressed_style.bg_color = Color(0.15, 0.15, 0.15)
		pressed_style.border_color = Color(0.8, 0.8, 0.8)
		add_theme_stylebox_override("normal", base_style)
		add_theme_stylebox_override("hover", hover)
		add_theme_stylebox_override("pressed", pressed_style)
	
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func _unhandled_input(event: InputEvent) -> void:
	if !upgrade_mode: return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var cell = grid_controller.get_cell_from_pos(get_global_mouse_position())
		var tower = grid_controller.get_grid_item_at_cell(cell)
		if tower:
			_attempt_upgrade(tower)
			get_viewport().set_input_as_handled()
		else:
			upgrade_mode = false
			button_pressed = false
			grid_controller.refresh_grid_highlights()

func _attempt_upgrade(tower: Node) -> void:
	var data = tower.get_meta("item_data")
	var cost = InventoryManager.get_spawn_cost(data.rank)
	if StatsManager.spend_health(cost):
		data.rank += 1
		tower.set_meta("item_data", data)
		tower._ready()  # reapply stats
		tower.queue_redraw()
		Utilities.spawn_floating_text("Rank up!", tower.global_position, null, true)
	else:
		Utilities.spawn_floating_text("Not enough meat...", tower.global_position, null, false)
	grid_controller.refresh_grid_highlights()
