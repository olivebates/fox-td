extends HBoxContainer

@onready var stats_manager = StatsManager
@onready var left_column: VBoxContainer = $LeftColumn
@onready var right_column: VBoxContainer = $RightColumn

const CATEGORY_LAYOUT := [
	{
		"title": "Economy",
		"keys": [
			"start_meat",
			"meat_production",
			"kill_multiplier",
			"meat_wave_clear",
			"money_kill_bonus",
			"gacha_cost_reduction",
			"free_pulls_per_run",
		]
	},
	{
		"title": "Combat",
		"keys": [
			"tower_placement_discount",
			"wall_placement_discount",
			"tower_move_cooldown_reduction",
			"global_tower_damage",
			"global_tower_attack_speed",
			"global_tower_range",
		]
	},
]

var buttons: Array[Button] = []
var labels: Array[Label] = []
var stat_keys: Array[String] = []

func _ready() -> void:
	stats_manager.update_persistant_upgrades()
	stat_keys.clear()
	buttons.clear()
	labels.clear()
	_clear_column(left_column)
	_clear_column(right_column)
	
	var left_config = CATEGORY_LAYOUT[0]
	var right_config = CATEGORY_LAYOUT[1]
	_add_category(left_column, left_config.title, left_config.keys)
	_add_category(right_column, right_config.title, right_config.keys)
	
	_update_buttons()

func _on_upgrade_pressed(stat: String) -> void:
	if stats_manager.upgrade_stat(stat):
		_update_buttons()

func _process(delta: float) -> void:
	_update_buttons()

func _update_buttons() -> void:
	for i in stat_keys.size():
		var stat_key = stat_keys[i]
		
		labels[i].text = stats_manager.set_upgrade_text(stat_key)
		
		var cost = stats_manager.get_upgrade_cost(stat_key)
		var btn = buttons[i]
		btn.disabled = stats_manager.money < cost
		btn.text = stats_manager.get_coin_symbol() + str(cost)

func _clear_column(column: VBoxContainer) -> void:
	for child in column.get_children():
		child.queue_free()

func _add_category(column: VBoxContainer, title: String, keys: Array) -> void:
	var header = Label.new()
	header.text = title
	header.add_theme_font_size_override("font_size", 5)
	header.add_theme_color_override("font_outline_color", Color.BLACK)
	header.add_theme_constant_override("outline_size", 1)
	column.add_child(header)
	
	for key in keys:
		var stat_key = String(key)
		if !stats_manager.persistent_upgrade_data.has(stat_key):
			continue
		var data = stats_manager.persistent_upgrade_data[stat_key]
		var display_title = stats_manager.get_upgrade_display_title(stat_key)
		
		var upgrade_button = preload("uid://bgnahptvucmwh").instantiate()
		upgrade_button.title_label = display_title
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
		
		var row = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.alignment = BoxContainer.ALIGNMENT_END
		column.add_child(row)
		row.add_child(stat_label)
		stat_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		labels.append(stat_label)
		
		inc_btn.pressed.connect(_on_upgrade_pressed.bind(stat_key))
		inc_btn.custom_minimum_size = Vector2(32, 0)
		row.add_child(inc_btn)
		buttons.append(inc_btn)
		
		inc_btn.mouse_entered.connect(func(): TooltipManager.show_tooltip(display_title, data.desc))
		inc_btn.mouse_exited.connect(func(): TooltipManager.hide_tooltip())
		inc_btn.focus_mode = Control.FOCUS_NONE
		
		stat_keys.append(stat_key)
		upgrade_button.queue_free()
