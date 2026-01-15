extends Button

@onready var title_label: Label = %TitleLabel
@onready var info_label: Label = %InfoLabel
@onready var action_row: HBoxContainer = %ActionRow
@onready var start_button: Button = %StartButton
@onready var delete_button: Button = %DeleteButton

var slot_index = -1
var is_new_slot = false
var _delete_confirm_step = 0

signal selected(slot: int)
signal start_requested(slot: int)
signal delete_requested(slot: int)

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	text = ""
	_apply_styles()
	_apply_label_styles()
	action_row.add_theme_constant_override("separation", 4)
	action_row.visible = true
	_set_action_visible(false)
	_set_delete_button_text("Delete")
	delete_button.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))
	toggled.connect(_on_toggled)
	start_button.pressed.connect(_on_start_pressed)
	delete_button.pressed.connect(_on_delete_pressed)

func setup_existing(slot: int, info: Dictionary) -> void:
	slot_index = slot
	is_new_slot = false
	toggle_mode = true
	disabled = false
	_set_action_visible(false)
	_reset_delete_confirm()
	var save_name = String(info.get("name", ""))
	if save_name.is_empty():
		save_name = "Save %d" % (slot + 1)
	title_label.text = save_name
	info_label.text = _format_info(info)

func setup_new(can_create: bool) -> void:
	slot_index = -1
	is_new_slot = true
	toggle_mode = false
	disabled = !can_create
	title_label.text = "New Slot"
	if can_create:
		info_label.text = "Create a new save"
	else:
		info_label.text = "No slots available"
	_set_action_visible(false)
	_reset_delete_confirm()

func _apply_styles() -> void:
	var normal = StyleBoxFlat.new()
	normal.bg_color = Color(0.32, 0.26, 0.18)
	normal.border_width_left = 1
	normal.border_width_top = 1
	normal.border_width_right = 1
	normal.border_width_bottom = 1
	normal.border_color = Color(0.92, 0.86, 0.7)
	normal.content_margin_left = 4
	normal.content_margin_right = 4
	normal.content_margin_top = 2
	normal.content_margin_bottom = 2

	var hover = normal.duplicate()
	hover.bg_color = Color(0.38, 0.31, 0.22)
	hover.border_color = Color(1, 0.96, 0.8)

	var pressed = normal.duplicate()
	pressed.bg_color = Color(0.28, 0.23, 0.16)
	pressed.border_color = Color(1, 0.98, 0.85)

	var disabled_style = normal.duplicate()
	disabled_style.bg_color = Color(0.2, 0.17, 0.12)
	disabled_style.border_color = Color(0.75, 0.68, 0.5)

	add_theme_stylebox_override("normal", normal)
	add_theme_stylebox_override("hover", hover)
	add_theme_stylebox_override("pressed", pressed)
	add_theme_stylebox_override("disabled", disabled_style)
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func _apply_label_styles() -> void:
	title_label.add_theme_font_size_override("font_size", 5)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	title_label.add_theme_color_override("font_outline_color", Color.BLACK)
	title_label.add_theme_constant_override("outline_size", 1)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.add_theme_font_size_override("font_size", 4)
	info_label.add_theme_color_override("font_color", Color.WHITE)
	info_label.add_theme_color_override("font_outline_color", Color.BLACK)
	info_label.add_theme_constant_override("outline_size", 1)
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _format_info(info: Dictionary) -> String:
	var level = int(info.get("level", 0))
	var money = int(info.get("money", 0))
	var timestamp = int(info.get("timestamp", 0))
	var time_text = ""
	if timestamp > 0:
		var time = Time.get_datetime_dict_from_unix_time(timestamp)
		time_text = "%02d/%02d %02d:%02d" % [
			time.month,
			time.day,
			time.hour,
			time.minute
		]
	else:
		time_text = "New"
	return "🚩 %d | 🪙 %d | 🕒 %s" % [level, money, time_text]

func _on_toggled(is_on: bool) -> void:
	if is_new_slot:
		return
	_set_action_visible(is_on)
	if !is_on:
		_reset_delete_confirm()
	if is_on:
		selected.emit(slot_index)

func _on_start_pressed() -> void:
	if slot_index < 0:
		return
	start_requested.emit(slot_index)

func _on_delete_pressed() -> void:
	if slot_index < 0:
		return
	if _delete_confirm_step == 0:
		_delete_confirm_step = 1
		_set_delete_button_text("Sure?")
		return
	if _delete_confirm_step == 1:
		_delete_confirm_step = 2
		_set_delete_button_text("Really Sure?")
		return
	_reset_delete_confirm()
	delete_requested.emit(slot_index)

func _set_action_visible(is_visible: bool) -> void:
	action_row.modulate = Color(1, 1, 1, 1 if is_visible else 0)
	start_button.disabled = !is_visible
	delete_button.disabled = !is_visible
	action_row.mouse_filter = Control.MOUSE_FILTER_STOP if is_visible else Control.MOUSE_FILTER_IGNORE

func _reset_delete_confirm() -> void:
	_delete_confirm_step = 0
	_set_delete_button_text("Delete")

func _set_delete_button_text(text_value: String) -> void:
	delete_button.text = text_value
