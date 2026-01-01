extends Node

# Array of save paths for slots 1-9
var CURRENT_VERSION = 16
const SAVE_PATHS = [
	"user://savegame1.save",
	"user://savegame2.save",
	"user://savegame3.save",
	"user://savegame4.save",
	"user://savegame5.save",
	"user://savegame6.save",
	"user://savegame7.save",
	"user://savegame8.save",
	"user://savegame9.save",
	"user://savegame10.save",
	"user://null.save"
]

const BASE_SAVE_KEY := "save_"

# Encryption key (should be kept secret in a real application)
const ENCRYPTION_KEY = "xai_savegame_key_2025"

var just_loaded = 10 #Hotfix for transcend button

# Add a saving state variable to prevent concurrent saves
var _is_saving = false
var _save_cancelled = false  # New flag to track if save was cancelled
var _current_temp_path = ""  # Track current temp file path

var focus_lost_time: float
var _periodic_backup_timer: Timer
var _visibility_callback
var _timer_paused_remaining: float = 0.0

func _ready():
	set_process_input(true)
	start_autosave()
	start_periodic_backup()
	if OS.get_name() == "Web":
		_visibility_callback = JavaScriptBridge.create_callback(Callable(self, "_on_visibility_change"))
		JavaScriptBridge.get_interface("document").addEventListener("visibilitychange", _visibility_callback)
	
	#load_game(9)
	
func start_periodic_backup():
	if OS.get_name() != "Web":
		return
	_periodic_backup_timer = Timer.new()
	_periodic_backup_timer.wait_time = 1200.0 # 1200.0 = 20 minutes
	_periodic_backup_timer.autostart = true
	_periodic_backup_timer.connect("timeout", Callable(self, "_on_periodic_backup_timeout"))
	add_child(_periodic_backup_timer)

func _on_visibility_change(_args):
	var is_hidden = JavaScriptBridge.eval("document.hidden", true)
	if is_hidden:
		_timer_paused_remaining = _periodic_backup_timer.time_left
		_periodic_backup_timer.stop()
		focus_lost_time = Time.get_unix_time_from_system()
	else:
		var delta_time = Time.get_unix_time_from_system() - focus_lost_time
		var remaining = _timer_paused_remaining - delta_time
		if remaining <= 0:
			_on_periodic_backup_timeout()
			_periodic_backup_timer.start()
		else:
			_periodic_backup_timer.start(remaining)

func _exit_tree():
	if OS.get_name() == "Web" and _visibility_callback:
		JavaScriptBridge.get_interface("document").removeEventListener("visibilitychange", _visibility_callback)

func _on_periodic_backup_timeout():
	print("Periodic backup triggered")
	var save_path = SAVE_PATHS[9]
	var save_key = save_path.replace("user://", "save_")
	var get_js = """
		console.log('Fetching current save: """ + save_key + """');
		localStorage.getItem('""" + save_key + """') || '';
	"""
	var current_data = JavaScriptBridge.eval(get_js, true)
	var data_len = current_data.length() if current_data else 0
	print("Current data length: " + str(data_len))
	if current_data.is_empty():
		print("No current save data, skipping backup")
		return
	var timestamp = str(int(Time.get_unix_time_from_system() * 1000))
	var backup_key = "timed_backup_" + timestamp + "_" + save_key
	var set_js = """
		console.log('Creating timed backup: """ + backup_key + """ (length: """ + str(data_len) + """)');
		localStorage.setItem('""" + backup_key + """', '""" + current_data + """');
	"""
	JavaScriptBridge.eval(set_js)
	print("Timed backup created: " + backup_key)
	# Manage to keep only 7 timed backups
	var manage_js = """
		console.log('Managing timed backups for: """ + save_key + """');
		var backup_keys = [];
		for (var i = 0; i < localStorage.length; i++) {
			var key = localStorage.key(i);
			if (key.startsWith("timed_backup_") && key.endsWith("_""" + save_key + """")) {
				console.log('Found timed backup: ' + key);
				backup_keys.push(key);
			}
		}
		console.log('Total timed backups: ' + backup_keys.length);
		if (backup_keys.length > 7) {
			backup_keys.sort(function(a, b) { 
				var ts_a = parseInt(a.split("_")[2]);
				var ts_b = parseInt(b.split("_")[2]);
				return ts_a - ts_b;  // Ascending, oldest first
			});
			var to_remove = backup_keys.slice(0, backup_keys.length - 7);
			console.log('Removing old backups: ', to_remove);
			for (var j = 0; j < to_remove.length; j++) {
				localStorage.removeItem(to_remove[j]);
				console.log('Removed: ' + to_remove[j]);
			}
		} else {
			console.log('Keeping all ' + backup_keys.length + ' timed backups');
		}
	"""
	JavaScriptBridge.eval(manage_js)
	print("Timed backup management complete")

func start_autosave():
	var timer = Timer.new()
	timer.wait_time = 6.0 
	timer.autostart = true
	timer.connect("timeout", Callable(self, "_on_autosave_timeout"))
	add_child(timer)

# Update autosave function
func _on_autosave_timeout():
	# Don't block if already saving
	if _is_saving:
		return
	# Don't await here to prevent blocking the timer
	save_game(9)  # This will run asynchronously

func _input(event):
	if OS.get_name() != "Web":
		if event is InputEventKey and event.pressed:
			# F1-F9 for saving
			for i in range(1, 10):
				if event.keycode == (KEY_F1 + i - 1):
					save_game(i - 1)
					break
			
			# 1-9 for loading
			for i in range(1, 10):
				if event.keycode == (KEY_1 + i - 1):
					load_game(i - 1)
					await get_tree().process_frame
					await get_tree().process_frame
					await get_tree().process_frame
					await get_tree().process_frame
					await get_tree().process_frame
					await get_tree().process_frame
					await get_tree().process_frame
					load_game(i - 1)
					break
			
			## K for save dialog
			#if event.keycode == KEY_K:
				#show_save_dialog()
				#
			## L for load dialog
			#if event.keycode == KEY_L:
				#show_load_dialog()

func rename_save(slot: int, new_name: String):
	var path = SAVE_PATHS[slot]
	var encrypted := ""

	if OS.get_name() == "Web":
		var key = path.replace("user://", "save_")
		encrypted = JavaScriptBridge.eval(
			"localStorage.getItem('%s') || ''" % key,
			true
		)
	else:
		if not FileAccess.file_exists(path):
			return
		var f = FileAccess.open(path, FileAccess.READ)
		encrypted = f.get_as_text()
		f.close()

	if encrypted.is_empty():
		return

	var json_string := decrypt_data(encrypted)
	var parsed = JSON.parse_string(json_string)

	if typeof(parsed) != TYPE_DICTIONARY:
		return

	parsed["save_name"] = new_name

	var new_json := JSON.stringify(parsed)
	var new_encrypted := encrypt_data(new_json)

	if OS.get_name() == "Web":
		var key = path.replace("user://", "save_")
		JavaScriptBridge.eval(
			"localStorage.setItem('%s', '%s')" % [key, new_encrypted]
		)
	else:
		var f2 = FileAccess.open(path, FileAccess.WRITE)
		if f2:
			f2.store_string(new_encrypted)
			f2.close()


func show_save_dialog():
	var file_dialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.access = FileDialog.ACCESS_USERDATA
	file_dialog.filters = ["*.save ; Save Files"]
	file_dialog.current_dir = "user://"
	file_dialog.title = "Save Game"
	file_dialog.connect("file_selected", Callable(self, "_on_save_file_selected"))
	file_dialog.min_size = Vector2(400, 300)
	file_dialog.popup_centered(Vector2(400, 300))
	add_child(file_dialog)
	file_dialog.popup_centered()

func show_load_dialog():
	var file_dialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_USERDATA
	file_dialog.filters = ["*.save ; Save Files"]
	file_dialog.current_dir = "user://"
	file_dialog.title = "Load Game"
	file_dialog.min_size = Vector2(400, 300)
	file_dialog.popup_centered(Vector2(400, 300))
	file_dialog.connect("file_selected", Callable(self, "_on_load_file_selected"))
	add_child(file_dialog)
	file_dialog.popup_centered()

func _on_save_file_selected(path: String):
	save_game(-1, path)  # -1 slot indicates custom path
	for child in get_children():
		if child is FileDialog:
			child.queue_free()

func _on_load_file_selected(path: String):
	load_game(-1, path)  # -1 slot indicates custom path
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	load_game(-1, path)  # -1 slot indicates custom path
	for child in get_children():
		if child is FileDialog:
			child.queue_free()

const FAST_ENCRYPT_MARKER = "FAST_V1:"  # Marker for new encryption

func encrypt_data(data: String) -> String:
	# Use fast encryption for new saves
	return _encrypt_data_fast(data)

func _encrypt_data_fast(data: String) -> String:
	# Add marker to indicate fast encryption
	var marked_data = FAST_ENCRYPT_MARKER + data
	var data_bytes = marked_data.to_utf8_buffer()
	var size = data_bytes.size()
	
	# Simple transposition cipher - just shuffle blocks
	var encrypted = PackedByteArray()
	encrypted.resize(size)
	
	# Fixed pattern shuffle for speed
	var pattern = [3, 7, 1, 5, 2, 8, 4, 6, 0]  # 9-byte blocks
	var block_size = pattern.size()
	var i = 0
	
	# Shuffle complete blocks
	while i + block_size <= size:
		for j in range(block_size):
			encrypted[i + j] = data_bytes[i + pattern[j]]
		i += block_size
	
	# Just copy remaining bytes
	while i < size:
		encrypted[i] = data_bytes[i]
		i += 1
	
	return Marshalls.raw_to_base64(encrypted)

func decrypt_data(encrypted: String) -> String:
	var encrypted_bytes = Marshalls.base64_to_raw(encrypted)
	
	# Try fast decryption first
	var fast_result = _try_decrypt_fast(encrypted_bytes)
	if fast_result != "":
		return fast_result
	
	# Fall back to legacy XOR decryption
	return _decrypt_legacy_xor(encrypted_bytes)

func _try_decrypt_fast(encrypted_bytes: PackedByteArray) -> String:
	var size = encrypted_bytes.size()
	var decrypted = PackedByteArray()
	decrypted.resize(size)
	
	# Reverse the shuffle pattern
	var pattern = [3, 7, 1, 5, 2, 8, 4, 6, 0]
	var reverse_pattern = [8, 2, 4, 0, 6, 3, 7, 1, 5]  # Pre-computed reverse
	var block_size = pattern.size()
	var i = 0
	
	# Unshuffle blocks
	while i + block_size <= size:
		for j in range(block_size):
			decrypted[i + j] = encrypted_bytes[i + reverse_pattern[j]]
		i += block_size
	
	# Copy remaining bytes
	while i < size:
		decrypted[i] = encrypted_bytes[i]
		i += 1
	
	var result = decrypted.get_string_from_utf8()
	
	# Check if it starts with our marker
	if result.begins_with(FAST_ENCRYPT_MARKER):
		return result.substr(FAST_ENCRYPT_MARKER.length())
	
	# Not fast encrypted
	return ""

func _decrypt_legacy_xor(encrypted_bytes: PackedByteArray) -> String:
	# Your original XOR decryption
	var key_bytes = ENCRYPTION_KEY.to_utf8_buffer()
	var decrypted = PackedByteArray()
	
	for i in range(encrypted_bytes.size()):
		var key_byte = key_bytes[i % key_bytes.size()]
		decrypted.append(encrypted_bytes[i] ^ key_byte)
	
	return decrypted.get_string_from_utf8()

# New function to cancel save and clean up temp files
func _cancel_save_and_cleanup():
	if _is_saving:
		print("Cancelling save operation...")
		_save_cancelled = true
		
		# Clean up any temporary files
		if not _current_temp_path.is_empty() and FileAccess.file_exists(_current_temp_path):
			var error = DirAccess.remove_absolute(_current_temp_path)
			if error == OK:
				print("Cleaned up temp file: ", _current_temp_path)
			else:
				print("Failed to clean up temp file: ", _current_temp_path, " Error: ", error)
		
		_current_temp_path = ""
		_is_saving = false
		_show_saving_indicator(false)

func save_game(slot: int = 0, custom_path: String = ""):
	var save_path = _get_save_path(slot, custom_path)
	if save_path.is_empty() or _is_dialogue_active():
		return
	if _is_saving:
		print("Save already in progress")
		return
	_is_saving = true
	_save_cancelled = false
	_show_saving_indicator(true)
	
	# Build save dictionary with money
	var serialized_backpack = []
	for tower in TowerManager.tower_inventory:
		if tower.is_empty():
			serialized_backpack.append({})
		else:
			serialized_backpack.append({
				"id": tower.id,
				"rank": tower.get("rank", 1)
			})
	
	var serialized_squad = []
	for tower in TowerManager.squad_slots:
		if tower.is_empty():
			serialized_squad.append({})
		else:
			serialized_squad.append({
				"id": tower.id,
				"rank": tower.get("rank", 1)
			})
	
	# Build save dictionary with money
	var save_dict = {
		"version": "1.0.0",
		"version_number": CURRENT_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"save_name": StatsManager.current_save_name,
		"money": StatsManager.money,
		"current_level": WaveSpawner.current_level,
		"backpack_inventory": serialized_backpack,
		"squad_inventory": serialized_squad,
		"pull_cost": TowerManager.pull_cost,
		"persistent_upgrades": StatsManager.persistent_upgrade_data
	}

	
	
	if _save_cancelled:
		print("Save cancelled during dictionary build")
		_cleanup_save_state()
		return
	
	var json_string = JSON.stringify(save_dict)
	if json_string.is_empty():
		print("JSON serialization failed")
		_cleanup_save_state()
		return
	
	var encrypted_string = encrypt_data(json_string)
	
	if OS.get_name() == "Web":
		var save_key = save_path.replace("user://", "save_")
		JavaScriptBridge.eval("""
			localStorage.setItem('""" + save_key + """', '""" + encrypted_string + """');
		""")
		await get_tree().process_frame
		await get_tree().process_frame
	else:
		var file = FileAccess.open(save_path, FileAccess.WRITE)
		if file == null:
			print("Failed to open save file: ", FileAccess.get_open_error())
			_cleanup_save_state()
			return
		file.store_string(encrypted_string)
		file.close()
	
	_show_saving_indicator(false)
	_is_saving = false

# Helper function to clean up save state
func _cleanup_save_state():
	_show_saving_indicator(false)
	_is_saving = false
	_current_temp_path = ""

# Helper function to determine save path
func _get_save_path(slot: int, custom_path: String) -> String:
	if not custom_path.is_empty():
		return custom_path
	
	if slot < 0 or slot >= SAVE_PATHS.size():
		print("Invalid save slot: ", slot)
		return ""
	
	return SAVE_PATHS[slot]

# Helper function to check dialogue state
func _is_dialogue_active() -> bool:
	return has_node("/root/DialogueHandler") and get_node("/root/DialogueHandler").is_dialogue_active

# Optional saving indicator
func _show_saving_indicator(show: bool):
	if has_node("/root/UI/SavingIndicator"):
		get_node("/root/UI/SavingIndicator").visible = show

func is_currently_saving() -> bool:
	return _is_saving

func force_save_completion(slot: int = 0, custom_path: String = ""):
	if _is_saving:
		while _is_saving:
			await get_tree().process_frame
	else:
		await save_game(slot, custom_path)

func load_game(slot: int = 0, custom_path: String = "", direct_string: String = "", should_backup = false):
	_cancel_save_and_cleanup()
	
	var old_nodes = get_tree().get_nodes_in_group("persistent_real")
	for node in old_nodes:
		if is_instance_valid(node) and not node.is_queued_for_deletion():
			node.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	
	AudioServer.set_bus_mute(0, true)
	var load_path = custom_path if not custom_path.is_empty() else SAVE_PATHS[slot]
	var encrypted_string = ""
	
	if OS.get_name() == "Web":
		if slot == -1 and custom_path == "":
			encrypted_string = direct_string
		else:
			var save_key = load_path.replace("user://", "save_")
			encrypted_string = JavaScriptBridge.eval("""
				localStorage.getItem('""" + save_key + """') || '';
			""", true)
			if encrypted_string.is_empty():
				print("No save data found")
				AudioServer.set_bus_mute(0, false)
				return
	else:
		if not FileAccess.file_exists(load_path):
			print("Save file doesn't exist: ", load_path)
			AudioServer.set_bus_mute(0, false)
			return
		var file = FileAccess.open(load_path, FileAccess.READ)
		if file == null:
			print("Failed to open save file: ", FileAccess.get_open_error())
			AudioServer.set_bus_mute(0, false)
			return
		encrypted_string = file.get_as_text()
		file.close()
	
	var json_string = decrypt_data(encrypted_string)
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		print("Failed to parse save file")
		AudioServer.set_bus_mute(0, false)
		return
	
	var save_dict = json.data
	
	# Load money
	if save_dict.has("money"):
		StatsManager.money = save_dict["money"]
	
	if save_dict.has("current_level"):
		WaveSpawner.current_level = int(save_dict["current_level"])

	if save_dict.has("pull_cost"):
		TowerManager.pull_cost = int(save_dict["pull_cost"])
	
	if save_dict.has("persistent_upgrades"):
		StatsManager.persistent_upgrade_data =  save_dict["persistent_upgrades"]
	
	# Load backpack inventory
	if save_dict.has("backpack_inventory"):
		TowerManager.clear_backpack()
		var loaded_backpack = save_dict["backpack_inventory"]
		for i in range(min(loaded_backpack.size(), TowerManager.BACKPACK_SIZE)):
			var tower_data = loaded_backpack[i]
			if tower_data.is_empty() or !tower_data.has("id"):
				TowerManager.tower_inventory[i] = {}
			else:
				TowerManager.tower_inventory[i] = TowerManager._create_tower(
					tower_data["id"],
					tower_data.get("rank", 1)
				)
	
	# Load squad inventory
	if save_dict.has("squad_inventory"):
		TowerManager.clear_squad()
		var loaded_squad = save_dict["squad_inventory"]
		for i in range(min(loaded_squad.size(), TowerManager.SQUAD_SIZE)):
			var tower_data = loaded_squad[i]
			if tower_data.is_empty() or !tower_data.has("id"):
				TowerManager.squad_slots[i] = {}
			else:
				TowerManager.squad_slots[i] = TowerManager._create_tower(
					tower_data["id"],
					tower_data.get("rank", 1)
				)
	
	# Refresh UI
	get_tree().call_group("backpack_inventory", "_rebuild_slots")
	get_tree().call_group("squad_inventory", "_rebuild_slots")
	
	var i = load("uid://cda7be4lkl7n8").instantiate()
	get_tree().root.add_child(i)
	
	StatsManager.new_map()

func _on_popup_close_pressed(popup: Window):
	popup.queue_free()

func _on_popup_closed(popup: Window):
	popup.queue_free()

func read_text_from(path: String) -> String:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var content: String = file.get_as_text()
	file.close()
	return content

func get_js_popup_command(input: String, atitle: String, subtitle: String, button: String) -> String:
	var js_path: String = "res://native/js/text_modal.js" # Fixed path
	var js_code: String = read_text_from(js_path)
	return js_code.format({"input": input, "atitle": atitle, "subtitle": subtitle, "button": button})

func await_js_popup_command(input: String, atitle: String, subtitle: String, button: String) -> String:
	var command: String = get_js_popup_command(input, atitle, subtitle, button)
	var eval_return: Variant = JavaScriptBridge.eval(command)
	var result
	while true:
		result = JavaScriptBridge.eval("window.globalTextAreaResult")
		if result != null:
			break
		await get_tree().create_timer(0.1).timeout
	JavaScriptBridge.eval("window.globalTextAreaResult = null;")
	return result

func import_text() -> String:
	var result: String = await await_js_popup_command(
		"",
		"Import Save",
		"Restore your progress from a previous session.",
		"Accept"
	)
	return result

func export_text(text_to_export: String) -> void:
	await await_js_popup_command(
		text_to_export,
		"Export Save",
		"Copy and save this code to restore your progress later.",
		"Accept"
	)
