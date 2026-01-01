extends HBoxContainer

@onready var slot_label: Label = $SlotLabel
@onready var name_edit: LineEdit = $NameEdit
@onready var info_label: Label = $InfoLabel
@onready var save_button: Button = $SaveButton
@onready var load_button: Button = $LoadButton
@onready var delete_button: Button = $DeleteButton

var slot_index := 0
var menu

func _on_rename(_unused := ""):
	if not is_instance_valid(name_edit):
		return

	var new_name := name_edit.text.strip_edges()

	if new_name.is_empty():
		name_edit.text = "Unnamed Save"
		return

	if SaveManager.is_currently_saving():
		return

	SaveManager.rename_save(slot_index, new_name)
	menu.call_deferred("refresh")

func setup(slot: int, info: Dictionary, parent_menu):
	if not is_instance_valid(self):
		return
	name_edit.add_theme_font_size_override("font_size", 4)
	name_edit.custom_minimum_size.x = 80
	name_edit.placeholder_text = "Save name"

	if info.get("exists", false):
		var save_name = info.get("name")
		if typeof(save_name) != TYPE_STRING or save_name.is_empty():
			save_name = "Unnamed Save"

		name_edit.text = save_name
	else:
		name_edit.text = ""

	name_edit.text_submitted.connect(_on_rename)
	name_edit.focus_exited.connect(_on_rename)
	
	if name_edit == null:
		return
	
	slot_label.add_theme_font_size_override("font_size", 4)
	info_label.add_theme_font_size_override("font_size", 4)
	save_button.add_theme_font_size_override("font_size", 4)
	load_button.add_theme_font_size_override("font_size", 4)
	delete_button.add_theme_font_size_override("font_size", 4)
	
	# Remove padding from all buttons
	var minimal_style := StyleBoxFlat.new()
	minimal_style.bg_color = Color(0.2, 0.2, 0.2, 1)
	minimal_style.border_color = Color(0.5, 0.5, 0.5, 1)
	
	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = Color(0.3, 0.3, 0.3, 1)
	hover_style.border_color = Color(0.7, 0.7, 0.7, 1)
	
	var pressed_style := StyleBoxFlat.new()
	pressed_style.bg_color = Color(0.1, 0.1, 0.1, 1)
	pressed_style.border_color = Color(0.8, 0.8, 0.8, 1)
	
	for btn in [save_button, load_button, delete_button]:
		btn.add_theme_constant_override("hseparation", 0)
		btn.add_theme_constant_override("outline_size", 0)
		btn.add_theme_stylebox_override("normal", minimal_style)
		btn.add_theme_stylebox_override("hover", hover_style)
		btn.add_theme_stylebox_override("pressed", pressed_style)
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		btn.add_theme_stylebox_override("disabled", StyleBoxFlat.new())  # grayed out when disabled
	# Rest of your existing code...
	slot_index = slot
	menu = parent_menu
	slot_label.text = "Slot %d" % (slot + 1)

	if not info.get("exists", false):
		info_label.text = "Empty"
		load_button.disabled = true
		delete_button.disabled = true
	else:
		var time := Time.get_datetime_dict_from_unix_time(info["timestamp"])
		info_label.text = "%02d/%02d %02d:%02d | Lv %d | $%d" % [
			time.month,
			time.day,
			time.hour,
			time.minute,
			info.get("level", 0),
			info.get("money", 0)
		]

	save_button.pressed.connect(_on_save)
	load_button.pressed.connect(_on_load)
	delete_button.pressed.connect(_on_delete)

func _on_save():
	menu.request_save(slot_index)

func _on_load():
	menu.request_load(slot_index)

func _on_delete():
	menu.request_delete(slot_index)
