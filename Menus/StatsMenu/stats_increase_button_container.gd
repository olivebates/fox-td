extends GridContainer

@onready var stats_manager = StatsManager

var buttons: Array[Button] = []
var labels: Array[Label] = []

func _ready() -> void:
	columns = 2
	
	for stat_key in stats_manager.persistent_upgrade_data.keys():
		var data = stats_manager.persistent_upgrade_data[stat_key]
		
		var upgrade_button = preload("uid://bgnahptvucmwh").instantiate()
		upgrade_button.title_label = data.title
		upgrade_button.description = data.desc
		
		var stat_label = upgrade_button.get_node("StatsLabel")
		var inc_btn = upgrade_button.get_node("IncreaseButton")
		
		# Font styling
		stat_label.add_theme_font_size_override("font_size", 4)
		inc_btn.add_theme_font_size_override("font_size", 4)
		inc_btn.add_theme_color_override("font_outline_color", Color.BLACK)
		inc_btn.add_theme_constant_override("outline_size", 1)
		stat_label.add_theme_color_override("font_outline_color", Color.BLACK)
		stat_label.add_theme_constant_override("outline_size", 1)
		
		# Button styles
		var style_normal := StyleBoxFlat.new()
		style_normal.bg_color = Color(0.2, 0.2, 0.2)
		style_normal.content_margin_left = 2
		style_normal.content_margin_right = 2
		
		var style_hover = style_normal.duplicate()
		style_hover.bg_color = Color(0.3, 0.3, 0.3)
		style_hover.border_color = Color(0.7, 0.7, 0.7)
		
		var style_pressed = style_normal.duplicate()
		style_pressed.bg_color = Color(0.15, 0.15, 0.15)
		style_pressed.border_color = Color(0.8, 0.8, 0.8)
		
		var style_disabled = style_normal.duplicate()
		style_disabled.bg_color = Color(0.1, 0.1, 0.1)
		style_disabled.border_color = Color(0.3, 0.3, 0.3)
		
		inc_btn.add_theme_stylebox_override("normal", style_normal)
		inc_btn.add_theme_stylebox_override("hover", style_hover)
		inc_btn.add_theme_stylebox_override("pressed", style_pressed)
		inc_btn.add_theme_stylebox_override("disabled", style_disabled)
		
		# Reparent nodes
		upgrade_button.remove_child(stat_label)
		upgrade_button.remove_child(inc_btn)
		
		add_child(stat_label)
		labels.append(stat_label)
		
		inc_btn.pressed.connect(_on_upgrade_pressed.bind(stat_key))
		add_child(inc_btn)
		buttons.append(inc_btn)
		
		inc_btn.mouse_entered.connect(func(): TooltipManager.show_tooltip(data.title, data.desc))
		inc_btn.mouse_exited.connect(func(): TooltipManager.hide_tooltip())
		inc_btn.focus_mode = Control.FOCUS_NONE
		
		upgrade_button.queue_free()
	
	_update_buttons()

func _on_upgrade_pressed(stat: String) -> void:
	if stats_manager.upgrade_stat(stat):
		_update_buttons()

func _process(delta: float) -> void:
	_update_buttons()

func _update_buttons() -> void:
	var keys = stats_manager.persistent_upgrade_data.keys()
	for i in keys.size():
		var stat_key = keys[i]
		
		labels[i].text = stats_manager.set_upgrade_text(stat_key)
		
		var cost = stats_manager.get_upgrade_cost(stat_key)
		var btn = buttons[i]
		btn.disabled = stats_manager.money < cost
		btn.text = "€" + str(cost)
