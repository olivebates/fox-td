extends Control

@onready var save_list: GridContainer = %SaveList
@onready var title_label: Label = %TitleLabel

const SLOT_CARD_SCENE = preload("res://Menus/SaveSelect/save_slot_card.tscn")

var _slot_group = ButtonGroup.new()
var _max_slots = 0
var _game_area: CanvasItem

func _ready() -> void:
	_max_slots = max(0, SaveManager.SAVE_PATHS.size() - 1)
	_slot_group.allow_unpress = true
	title_label.add_theme_font_size_override("font_size", 6)
	title_label.add_theme_color_override("font_outline_color", Color.BLACK)
	title_label.add_theme_constant_override("outline_size", 1)
	save_list.add_theme_constant_override("hseparation", 4)
	save_list.add_theme_constant_override("vseparation", 4)
	_game_area = get_tree().get_first_node_in_group("game_area")
	_set_game_area_visible(false)
	var slots = _get_all_save_slots()
	if slots.is_empty():
		await _on_new_slot_pressed()
		return
	refresh()

func refresh() -> void:
	for child in save_list.get_children():
		child.queue_free()

	var slots = _get_all_save_slots()
	for slot in slots:
		var info = _get_slot_info(slot)
		if !info.get("exists", false):
			continue
		var card = SLOT_CARD_SCENE.instantiate()
		save_list.add_child(card)
		card.call_deferred("setup_existing", slot, info)
		card.start_requested.connect(_on_start_requested)
		card.delete_requested.connect(_on_delete_requested)
		card.button_group = _slot_group

	var next_free = _get_next_free_slot(slots)
	var new_card = SLOT_CARD_SCENE.instantiate()
	new_card.call_deferred("setup_new", next_free != -1)
	new_card.pressed.connect(_on_new_slot_pressed)
	save_list.add_child(new_card)

func _on_start_requested(slot: int) -> void:
	visible = false
	SaveManager.current_slot = slot
	_set_game_area_visible(true)
	await SaveManager.load_game(slot)
	queue_free()

func _on_new_slot_pressed() -> void:
	var slots = _get_all_save_slots()
	var next_free = _get_next_free_slot(slots)
	if next_free == -1:
		return
	StatsManager.current_save_name = "Save %d" % (next_free + 1)
	SaveManager.current_slot = next_free
	visible = false
	await SaveManager.force_save_completion(next_free)
	_set_game_area_visible(true)
	queue_free()

func _on_delete_requested(slot: int) -> void:
	_delete_slot(slot)
	refresh()

func _delete_slot(slot: int) -> void:
	if slot < 0 or slot >= _max_slots:
		return
	var path = SaveManager.SAVE_PATHS[slot]
	if OS.get_name() == "Web":
		var key = path.replace("user://", "save_")
		JavaScriptBridge.eval("localStorage.removeItem('%s')" % key)
	else:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	if SaveManager.current_slot == slot:
		SaveManager.current_slot = -1

func _get_all_save_slots() -> Array:
	var slots = []
	if _max_slots <= 0:
		return slots

	if OS.get_name() == "Web":
		var js = """
		var result = [];
		for (var i = 0; i < localStorage.length; i++) {
			var key = localStorage.key(i);
			if (key.startsWith('save_')) {
				var match = key.match(/savegame(\\d+)\\.save$/);
				if (match) result.push(parseInt(match[1]) - 1);
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

	var filtered = []
	for slot in slots:
		var slot_index = int(slot)
		if slot_index >= 0 and slot_index < _max_slots:
			filtered.append(slot_index)
	filtered.sort()
	return filtered

func _get_next_free_slot(used: Array) -> int:
	for i in range(_max_slots):
		if !used.has(i):
			return i
	return -1

func _get_slot_info(slot: int) -> Dictionary:
	if slot < 0 or slot >= _max_slots:
		return { "exists": false }

	var path = SaveManager.SAVE_PATHS[slot]
	var encrypted = ""

	if OS.get_name() == "Web":
		var key = path.replace("user://", "save_")
		encrypted = JavaScriptBridge.eval(
			"localStorage.getItem('%s') || ''" % key,
			true
		)
	else:
		if FileAccess.file_exists(path):
			var f = FileAccess.open(path, FileAccess.READ)
			if f:
				encrypted = f.get_as_text()
				f.close()

	if encrypted.is_empty():
		return { "exists": false }

	var json_string = SaveManager.decrypt_data(encrypted)
	var parsed = JSON.parse_string(json_string)
	if typeof(parsed) != TYPE_DICTIONARY:
		return { "exists": false }

	return {
		"exists": true,
		"timestamp": parsed.get("timestamp", 0),
		"level": parsed.get("current_level", 0),
		"money": parsed.get("money", 0),
		"name": parsed.get("save_name", "")
	}

func _set_game_area_visible(is_visible: bool) -> void:
	if _game_area and _game_area is CanvasItem:
		_game_area.visible = is_visible
