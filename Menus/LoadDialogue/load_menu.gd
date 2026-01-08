extends Control

@onready var save_list: VBoxContainer = %SaveList

const SLOT_COUNT := 10
const SLOT_ROW_SCENE := preload("uid://d4efbo7ussulp")

func _ready():
	refresh()
	set_process_input(true)
	visible = Dev.dev

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_B and Dev.dev:
		visible = !visible
		if visible:
			refresh()
		get_viewport().set_input_as_handled()

func request_rename(slot: int, new_name: String):
	StatsManager.current_save_name = new_name
	SaveManager.save_game(slot)
	await get_tree().process_frame
	refresh()

func refresh():
	for c in save_list.get_children():
		c.queue_free()

	var slots = _get_all_save_slots()

	for slot in slots:
		var row = SLOT_ROW_SCENE.instantiate()
		save_list.add_child(row)
		row.setup(slot, _get_slot_info(slot), self)

func _get_all_save_slots() -> Array:
	var slots := []

	if OS.get_name() == "Web":
		var js := """
		var result = [];
		for (var i = 0; i < localStorage.length; i++) {
			var key = localStorage.key(i);
			if (key.startsWith('save_')) {
				var num = parseInt(key.replace('save_', ''));
				if (!isNaN(num)) result.push(num);
			}
		}
		result;
		"""
		slots = JavaScriptBridge.eval(js, true)
	else:
		var dir = DirAccess.open("user://")
		if dir:
			dir.list_dir_begin()
			var file = dir.get_next()
			while file != "":
				if file.begins_with("savegame") and file.ends_with(".save"):
					var num = file.get_basename().replace("savegame", "").to_int() - 1
					slots.append(num)
				file = dir.get_next()
			dir.list_dir_end()

	slots.sort()
	return slots

func create_new_save():
	var slot := _get_next_free_slot()
	StatsManager.current_save_name = "New Save"
	SaveManager.save_game(slot)
	await get_tree().process_frame
	refresh()

func _get_next_free_slot() -> int:
	var used := _get_all_save_slots()
	var i := 0
	while i in used:
		i += 1
	return i


func _get_slot_info(slot: int) -> Dictionary:
	var path = SaveManager.SAVE_PATHS[slot]
	var encrypted := ""

	if OS.get_name() == "Web":
		var key = path.replace("user://", "save_")
		encrypted = JavaScriptBridge.eval(
			"localStorage.getItem('%s') || ''" % key,
			true
		)
	else:
		if FileAccess.file_exists(path):
			var f = FileAccess.open(path, FileAccess.READ)
			encrypted = f.get_as_text()
			f.close()

	if encrypted.is_empty():
		return { "exists": false }

	var json := SaveManager.decrypt_data(encrypted)
	var parsed = JSON.parse_string(json)

	if typeof(parsed) != TYPE_DICTIONARY:
		return { "exists": false }

	return {
		"exists": true,
		"timestamp": parsed.get("timestamp", 0),
		"version": parsed.get("version_number", -1),
		"level": parsed.get("current_level", 0),
		"money": parsed.get("money", 0),
		"name": parsed.get("save_name", "Unnamed Save") # NEW
	}



func request_save(slot: int):
	SaveManager.save_game(slot)
	await get_tree().process_frame
	refresh()

func request_load(slot: int):
	SaveManager.load_game(slot)
	hide()

func request_delete(slot: int):
	var path = SaveManager.SAVE_PATHS[slot]

	if OS.get_name() == "Web":
		var key = path.replace("user://", "save_")
		JavaScriptBridge.eval("localStorage.removeItem('%s')" % key)
	else:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)

	refresh()
