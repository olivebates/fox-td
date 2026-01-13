extends Control

@onready var toggle_button: Button = $ToggleButton
@onready var popup_panel: PanelContainer = $PopupPanel
@onready var stack_list: VBoxContainer = $PopupPanel/StackVBox/StackList
@onready var money_label: Label = $PopupPanel/StackVBox/MoneyLabel

var percent_labels: Dictionary = {}
var inc_buttons: Dictionary = {}
var dec_buttons: Dictionary = {}
var stack_segments: Dictionary = {}

const FIXED_TRAITS := ["Meat Drain", "Production Jam", "Food Shortage"]
@export var USE_FIXED_TRAITS := true
@export var ALWAYS_EXPANDED := false

const TRAIT_EMOJI := {
	"Speed": "💨",
	"Health": "❤️",
	"Splitting": "🧬",
	"Dodge": "🥷",
	"Armor": "🛡️",
	"Regeneration": "💚",
	"Revive": "🔁",
	"Meat Drain": "🥩",
	"Production Jam": "⛔",
	"Food Shortage": "🍽️",
}


const TRAIT_DESCRIPTIONS := {
	"Speed": "Enemies move faster (+15% speed per level).",
	"Health": "Enemies have more HP (+30% max HP per level).",
	"Splitting": "Killed enemies split into 2 smaller ones (+15% spawnling HP per level).",
	"Dodge": "Enemies can evade shots (+5% dodge chance per level).",
	"Armor": "Enemies take less damage (-7% damage taken per level).",
	"Regeneration": "Enemies heal over time (+5% max HP per second per level).",
	"Revive": "Enemies may revive once (+10% revive chance per level).",
	"Meat Drain": "Kills give less meat (-10% meat per level).\nCan only be changed between games.",
	"Production Jam": "Passive meat gain is reduced (-10% per level).\nCan only be changed between games.",
	"Food Shortage": "You start with less meat (-7% starting meat per level).\nCan only be changed between games.",
}
func _ready() -> void:
	DifficultyManager.trait_changed.connect(_on_trait_changed)
	_apply_button_style(toggle_button)
	_apply_panel_style(popup_panel)
	_apply_label_style(money_label)
	_build_rows()
	_update_money_text()
	_set_expanded(ALWAYS_EXPANDED)
	if ALWAYS_EXPANDED:
		toggle_button.visible = false
	toggle_button.pressed.connect(_on_toggle_pressed)

func _build_rows() -> void:
	for trait_name in DifficultyManager.get_all_traits():
		var entry := HBoxContainer.new()
		entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		entry.add_theme_constant_override("separation", 2)
		entry.custom_minimum_size = Vector2(0, 6)
		entry.mouse_filter = Control.MOUSE_FILTER_STOP
		entry.mouse_entered.connect(_on_trait_hovered.bind(trait_name))
		entry.mouse_exited.connect(_on_trait_unhovered)
		
		var segment := ColorRect.new()
		segment.custom_minimum_size = Vector2(6, 3)
		segment.color = _get_trait_color(trait_name)
		segment.mouse_filter = Control.MOUSE_FILTER_IGNORE
		entry.add_child(segment)
		
		var label := Label.new()
		label.text = "%s %s %s" % [
			TRAIT_EMOJI.get(trait_name, "ƒ?\""),
			trait_name,
			_format_percent(_get_trait_percent(trait_name))
		]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_apply_label_style(label)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		entry.add_child(label)
		
		if USE_FIXED_TRAITS and FIXED_TRAITS.has(trait_name):
			var fixed_label := Label.new()
			fixed_label.text = "(fixed)"
			fixed_label.custom_minimum_size = Vector2(22, 0)
			fixed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_apply_label_style(fixed_label)
			fixed_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			entry.add_child(fixed_label)
		else:
			var dec_btn := Button.new()
			dec_btn.text = "-"
			_apply_button_style(dec_btn)
			dec_btn.pressed.connect(_on_decrease.bind(trait_name))
			entry.add_child(dec_btn)
			
			var inc_btn := Button.new()
			inc_btn.text = "+"
			_apply_button_style(inc_btn)
			inc_btn.pressed.connect(_on_increase.bind(trait_name))
			entry.add_child(inc_btn)
			
			inc_buttons[trait_name] = inc_btn
			dec_buttons[trait_name] = dec_btn
		
		stack_list.add_child(entry)
		percent_labels[trait_name] = label
		stack_segments[trait_name] = segment
		_update_stack_segment(trait_name)
		_update_button_states(trait_name)

func _apply_label_style(label: Label) -> void:
	label.add_theme_font_size_override("font_size", 3)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 1)

func _apply_panel_style(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.14)
	style.border_color = Color(0.25, 0.25, 0.3)
	style.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel", style)

func _apply_button_style(button: Button) -> void:
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 3)
	button.add_theme_color_override("font_outline_color", Color.BLACK)
	button.add_theme_constant_override("outline_size", 1)
	
	var style_normal := StyleBoxFlat.new()
	style_normal.bg_color = Color(0.2, 0.2, 0.2)
	style_normal.content_margin_left = 3
	style_normal.content_margin_right = 3
	style_normal.content_margin_bottom = 1
	
	var style_hover := style_normal.duplicate()
	style_hover.bg_color = Color(0.3, 0.3, 0.3)
	style_hover.border_color = Color(0.7, 0.7, 0.7)
	
	var style_pressed := style_normal.duplicate()
	style_pressed.bg_color = Color(0.15, 0.15, 0.15)
	style_pressed.border_color = Color(0.8, 0.8, 0.8)
	
	var style_disabled := style_normal.duplicate()
	style_disabled.bg_color = Color(0.1, 0.1, 0.1)
	style_disabled.border_color = Color(0.3, 0.3, 0.3)
	
	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_pressed)
	button.add_theme_stylebox_override("disabled", style_disabled)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func _on_toggle_pressed() -> void:
	if ALWAYS_EXPANDED:
		return
	_set_expanded(not popup_panel.visible)

func _set_expanded(expanded: bool) -> void:
	popup_panel.visible = expanded
	if expanded:
		toggle_button.text = "Difficulty"
	else:
		toggle_button.text = "Difficulty"#_get_money_text()

func _on_increase(trait_name: String) -> void:
	DifficultyManager.increase_trait(trait_name)

func _on_decrease(trait_name: String) -> void:
	DifficultyManager.decrease_trait(trait_name)

func _on_trait_changed(trait_name: String, _new_value: int) -> void:
	if percent_labels.has(trait_name):
		percent_labels[trait_name].text = "%s %s %s" % [
			TRAIT_EMOJI.get(trait_name, "ƒ?\""),
			trait_name,
			_format_percent(_get_trait_percent(trait_name))
		]
	_update_stack_segment(trait_name)
	_update_button_states(trait_name)
	_update_money_text()
	if not popup_panel.visible:
		toggle_button.text = _get_money_text()

func _update_button_states(trait_name: String) -> void:
	var value = DifficultyManager.get_trait(trait_name)
	if dec_buttons.has(trait_name):
		dec_buttons[trait_name].disabled = value <= DifficultyManager.MIN_LEVEL
	if inc_buttons.has(trait_name):
		inc_buttons[trait_name].disabled = value >= DifficultyManager.MAX_LEVEL

func _update_money_text() -> void:
	money_label.text = _get_money_text()

func _get_money_text() -> String:
	#var mult = DifficultyManager.get_money_multiplier()
	return "Difficulty"

func _get_trait_percent(trait_name: String) -> float:
	var level := DifficultyManager.get_trait(trait_name)
	match trait_name:
		"Speed":
			return float(level) * DifficultyManager.SPEED_PER_LEVEL * 100.0
		"Health":
			return float(level) * DifficultyManager.HEALTH_MULT_PER_LEVEL * 100.0
		"Splitting":
			return float(level) * DifficultyManager.SPLIT_HEALTH_PER_LEVEL * 100.0
		"Dodge":
			return float(level) * DifficultyManager.DODGE_CHANCE_PER_LEVEL * 100.0
		"Armor":
			return float(level) * DifficultyManager.ARMOR_DAMAGE_REDUCTION_PER_LEVEL * 100.0
		"Regeneration":
			return float(level) * DifficultyManager.REGEN_MAX_HP_PER_LEVEL * 100.0
		"Revive":
			return float(level) * DifficultyManager.REVIVE_CHANCE_PER_LEVEL * 100.0
		"Meat Drain":
			return float(level) * DifficultyManager.MEAT_DRAIN_PER_LEVEL * 100.0
		"Production Jam":
			return float(level) * DifficultyManager.PRODUCTION_JAM_PER_LEVEL * 100.0
		"Food Shortage":
			return float(level) * DifficultyManager.FOOD_SHORTAGE_PER_LEVEL * 100.0
		_:
			return 0.0

func _format_percent(value: float) -> String:
	var rounded = snapped(value, 0.1)
	if abs(rounded - round(rounded)) < 0.05:
		return "+%d%%" % int(round(rounded))
	return "+%.1f%%" % rounded

func _get_trait_color(trait_name: String) -> Color:
	match trait_name:
		"Speed":
			return Color(0.5, 0.8, 1.0)
		"Health":
			return Color(1.0, 0.5, 0.5)
		"Splitting":
			return Color(0.8, 0.7, 1.0)
		"Dodge":
			return Color(0.9, 0.9, 0.5)
		"Armor":
			return Color(0.7, 0.7, 0.8)
		"Regeneration":
			return Color(0.5, 1.0, 0.6)
		"Revive":
			return Color(0.9, 0.6, 0.9)
		"Meat Drain":
			return Color(0.9, 0.6, 0.5)
		"Production Jam":
			return Color(1.0, 0.7, 0.4)
		"Food Shortage":
			return Color(1.0, 0.8, 0.4)
		_:
			return Color(0.8, 0.8, 0.8)

func _update_stack_segment(trait_name: String) -> void:
	if not stack_segments.has(trait_name):
		return
	var level := DifficultyManager.get_trait(trait_name)
	var width := 6 + int(round(20.0 * (float(level) / float(DifficultyManager.MAX_LEVEL))))
	stack_segments[trait_name].custom_minimum_size = Vector2(width, 3)

func _on_trait_hovered(trait_name: String) -> void:
	var desc = TRAIT_DESCRIPTIONS.get(trait_name, "")
	#var percent := _format_percent(_get_trait_percent(trait_name))
	#var detail := "%s\nCurrent: %s" % [desc, percent]
	TooltipManager.show_tooltip(trait_name, desc)

func _on_trait_unhovered() -> void:
	TooltipManager.hide_tooltip()
