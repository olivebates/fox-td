extends Control

signal saves_changed()
var _is_saving = false
var _save_cancelled = false
var timeline_saves = []
var current_wave_index: int = 0
var wave_replay_counts: Dictionary = {}
@onready var inventory = get_node("/root/InventoryManager")
func _ready() -> void:
	await get_tree().process_frame
	save_timeline(0)
	current_wave_index = 0

func _get_save_path(slot: int) -> String:
	
	if slot < 0:
		print("Invalid save slot: ", slot)
		return ""
	
	return "wave_save"+str(slot)

func delete_all_timeline_saves_after(index: int) -> void:
	var paths_to_delete: Array = []
	for i in range(index, timeline_saves.size()):
		paths_to_delete.append(timeline_saves[i])
	
	for path in paths_to_delete:
		if OS.get_name() == "Web":
			var key = path.replace("user://", "save_")
			JavaScriptBridge.eval("localStorage.removeItem('" + key + "');")
		else:
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(path)
		timeline_saves.erase(path)
	
	saves_changed.emit()

func get_cell_from_pos(global_pos: Vector2) -> Vector2i:
	var local = global_pos - GridController.grid_offset
	var x = floori(local.x / GridController.CELL_SIZE)
	var y = floori(local.y / GridController.CELL_SIZE)
	if x >= 0 and x < GridController.WIDTH and y >= 0 and y < GridController.HEIGHT:
		return Vector2i(x, y)
	return Vector2i(-1, -1)

func save_timeline(slot: int = 0):
	var save_path = _get_save_path(slot)
	if save_path.is_empty():
		return
	if _is_saving:
		print("Save already in progress")
		return
	_is_saving = true
	_save_cancelled = false
	SaveManager._show_saving_indicator(true)
	
	
	# Basic vars
	var save_dict = {
		"current_wave": WaveSpawner.current_wave,
		"health": StatsManager.health,
		"max_health": StatsManager.max_health,
		"base_max_health": StatsManager.base_max_health,
		"level": StatsManager.level,
	}
	
	save_dict["wave_replay_count"] = wave_replay_counts.get(slot, 0)
	
	
	#Inventory
	var inventory_data: Array = []
	for i in inventory.slots:
		var item = i.get_meta("item", {})
		inventory_data.append(item.duplicate() if !item.is_empty() else {})
	save_dict["inventory"] = inventory_data
	
	# Bullets (persistent)
	var bullets_data: Array = []
	var bullets = get_tree().get_nodes_in_group("persistant_bullet")
	for bullet in bullets:
		if bullet.has_meta("item_data"):
			var data = bullet.get_meta("item_data").duplicate()
			var cell = get_cell_from_pos(bullet.global_position)
			data["cell_x"] = cell.x
			data["cell_y"] = cell.y
			# Add any bullet-specific state here if needed
			bullets_data.append(data)
	save_dict["persistant_bullets"] = bullets_data
	
	
	#Towers
	var temp_pos = Vector2.ZERO
	if GridController.dragged_tower != null:
		# Restore dragged tower to original cell temporarily for save
		temp_pos = GridController.dragged_tower.global_position
		var temp_cell = GridController.original_cell
		GridController.dragged_tower.global_position = GridController.grid_offset + Vector2(
			temp_cell.x * GridController.CELL_SIZE + GridController.CELL_SIZE / 2,
			temp_cell.y * GridController.CELL_SIZE + GridController.CELL_SIZE / 2
		)
		
	var towers_data: Array = []
	var towers = get_tree().get_nodes_in_group("tower")
	for tower in towers:
		if tower.has_meta("item_data"):
			var data = tower.get_meta("item_data").duplicate()
			if tower.has_method("get_path") or "path" in tower:
				data["path"] = tower.path.duplicate()
			var cell = get_cell_from_pos(tower.global_position)
			data["cell_x"] = cell.x
			data["cell_y"] = cell.y
			towers_data.append(data)
			
	save_dict["towers"] = towers_data
	
	#Walls
	var walls_data: Array = []
	var walls = get_tree().get_nodes_in_group("walls")
	for wall in walls:
		if wall.is_placed:
			var cell = GridController.get_cell_from_pos(wall.global_position)
			walls_data.append({"cell_x": cell.x, "cell_y": cell.y})
	save_dict["walls"] = walls_data
	
	if GridController.dragged_tower != null:
		GridController.dragged_tower.global_position = temp_pos
	
	#Rest
	if _save_cancelled:
		print("Save cancelled during dictionary build")
		SaveManager._cleanup_save_state()
		return
	
	var json_string = JSON.stringify(save_dict)
	if json_string.is_empty():
		print("JSON serialization failed")
		SaveManager._cleanup_save_state()
		return
	
	var encrypted_string = SaveManager.encrypt_data(json_string)
	
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
			SaveManager._cleanup_save_state()
			return
		file.store_string(encrypted_string)
		file.close()
	
	SaveManager._show_saving_indicator(false)
	_is_saving = false
	
	var path = _get_save_path(slot)
	if not timeline_saves.has(path):
		timeline_saves.append(path)
		saves_changed.emit()
		
	SaveManager._show_saving_indicator(false)
	_is_saving = false
	
	path = _get_save_path(slot)
	if not timeline_saves.has(path):
		timeline_saves.append(path)
	
	current_wave_index = slot
	saves_changed.emit()

func load_timeline(slot: int = 0):
	var custom_path: String = _get_save_path(slot)
	var direct_string: String = ""
	SaveManager._cancel_save_and_cleanup()
	
	var old_nodes = get_tree().get_nodes_in_group("persistent_real")
	for node in old_nodes:
		if is_instance_valid(node) and not node.is_queued_for_deletion():
			node.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	
	AudioServer.set_bus_mute(0, true)
	var load_path = custom_path if not custom_path.is_empty() else timeline_saves[slot]
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
	
	var json_string = SaveManager.decrypt_data(encrypted_string)
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		print("Failed to parse save file")
		AudioServer.set_bus_mute(0, false)
		return
	
	var save_dict = json.data
	
	#Basic vars
	#if save_dict.has("current_wave"):
		#WaveSpawner.current_wave = save_dict["current_wave"]
	current_wave_index = slot
	saves_changed.emit()
	
	
	var count = 0
	if save_dict.has("wave_replay_count"):
		count = save_dict["wave_replay_count"]
	wave_replay_counts[slot] = count
	
	if save_dict.has("health"):
		StatsManager.health = save_dict["health"]
	if save_dict.has("max_health"):
		StatsManager.max_health = save_dict["max_health"]
	if save_dict.has("base_max_health"):
		StatsManager.base_max_health = save_dict["base_max_health"]
	if save_dict.has("level"):
		StatsManager.level = save_dict["level"]
		
		
	var health_bar_gui = get_tree().get_first_node_in_group("HealthBarContainer")
	health_bar_gui.bar.value = StatsManager.health
	health_bar_gui.bar.max_value = StatsManager.max_health
	health_bar_gui._update_text()
	health_bar_gui._update_red_overlay()
	
	
	# Enemies
	WaveSpawner._is_spawning = false
	var enemies = get_tree().get_nodes_in_group("enemy")
	for i in enemies:
		i.queue_free()
		
	#Inventory
	if save_dict.has("inventory"):
		var inventory_data: Array = save_dict["inventory"]
		inventory.clear_inventory()
		for i in min(inventory_data.size(), inventory.slots.size()):
			var item = inventory_data[i]
			if !item.is_empty():
				inventory.slots[i].set_meta("item", item.duplicate())
				inventory._update_slot(inventory.slots[i])
		inventory.refresh_inventory_highlights()
	
	# Clear old persistent bullets
	var old_bullets = get_tree().get_nodes_in_group("persistant_bullet")
	for b in old_bullets:
		if is_instance_valid(b):
			b.queue_free()

	# Load persistent bullets
	if save_dict.has("persistant_bullets"):
		var bullets_data: Array = save_dict["persistant_bullets"]
		for data in bullets_data:
			var item_def = inventory.items[data.id]
			var bullet = item_def.prefab.instantiate()
			bullet.set_meta("item_data", data.duplicate())
			var cell = Vector2i(data.cell_x, data.cell_y)
			bullet.global_position = GridController.grid_offset + Vector2(
				cell.x * GridController.CELL_SIZE + GridController.CELL_SIZE / 2,
				cell.y * GridController.CELL_SIZE + GridController.CELL_SIZE / 2
			)
			add_child(bullet)
			bullet.add_to_group("persistant_bullet")
	
	# Clear all existing towers
	var towers = get_tree().get_nodes_in_group("tower")
	for tower in towers:
		tower.queue_free()

	# Also clear grid occupations
	for y in range(GridController.HEIGHT):
		for x in range(GridController.WIDTH):
			if GridController.grid[y][x] != null and GridController.grid[y][x].is_in_group("tower"):
				GridController.grid[y][x] = null
	
	# Towers
	var guards = get_tree().get_nodes_in_group("guard")
	for i in guards:
		i.queue_free()
	
	if save_dict.has("towers"):
		var towers_data: Array = save_dict["towers"]	
		for data in towers_data:
			var item_def = inventory.items[data.id]
			var tower = item_def.prefab.instantiate()
			tower.set_meta("item_data", data.duplicate())
			var cell = Vector2i(data.cell_x, data.cell_y)
			tower.global_position = GridController.grid_offset + Vector2(cell.x * GridController.CELL_SIZE + GridController.CELL_SIZE / 2, cell.y * GridController.CELL_SIZE + GridController.CELL_SIZE / 2)
			add_child(tower)
			GridController.grid[cell.y][cell.x] = tower
			if data.has("path"):
				tower.path = data["path"].duplicate()
			tower.add_to_group("tower")
	
	# Walls
	var old_walls = get_tree().get_nodes_in_group("walls")
	for w in old_walls:
		if is_instance_valid(w) and w.is_placed:
			w.queue_free()
	await get_tree().process_frame

	if save_dict.has("walls"):
		var walls_data: Array = save_dict["walls"]
		for data in walls_data:
			var cell = Vector2i(data.cell_x, data.cell_y)
			if cell != Vector2i(-1, -1):
				var wall = load("uid://823ref1rao2h").instantiate()
				wall.position = GridController.grid_offset + Vector2(
					cell.x * GridController.CELL_SIZE + GridController.CELL_SIZE / 2,
					cell.y * GridController.CELL_SIZE + GridController.CELL_SIZE / 2
				)
				wall.is_placed = true
				add_child(wall)
				wall.add_to_group("walls")

	AStarManager._update_grid()
	

func delete_all_timeline_saves() -> void:
	wave_replay_counts.clear()  # Reset all penalties
	for i in timeline_saves.size():
		var path = timeline_saves[i]
		if OS.get_name() == "Web":
			var key = path.replace("user://", "save_")
			JavaScriptBridge.eval("localStorage.removeItem('" + key + "');")
		else:
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(path)
	timeline_saves.clear()
	saves_changed.emit()
