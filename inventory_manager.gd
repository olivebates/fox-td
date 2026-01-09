# Autoload: InventoryManager.gd
extends Control

const RANK_COLORS = {
	0: Color(1, 1, 1),
	1: Color(0.847, 0.847, 0.847, 1.0),
	2: Color(0.535, 0.813, 0.0, 1.0),
	3: Color(0, 0.5, 1),
	4: Color(0.627, 0.125, 0.941),
	5: Color(0.855, 0.551, 0.0, 1.0),
	6: Color(0.997, 0.0, 0.442),
	7: Color(0, 0, 0),
	8: Color(1.0, 1.0, 0.812),
	9: Color(0.0, 1.0, 1.0),
	10: Color(1.0, 0.531, 0.986),
	11: Color(0.565, 0.0, 0.18),
}
const ELEMENT_COLORS := {
	"red": Color(1.0, 0.2, 0.2),
	"green": Color(0.2, 0.9, 0.3),
	"blue": Color(0.2, 0.6, 1.0)
}
const ELEMENT_COLOR_KEYS := ["red", "green", "blue"]
var base_spawn_cost = 40.0
@onready var HealthBarGUI = get_tree().get_first_node_in_group("HealthBarContainer")
@onready var grid_controller: Node2D = get_node("/root/GridController")
var _merge_blink_timer: float = 0.0
var _merge_blink_state: bool = false
#var cost_to_spawn = 30

enum PATH_ID {
	damage,
	bullets,
	attack_speed,
	range,
	explosion_radius,
	creature_amount,
	creature_damage,
	creature_attack_speed,
	creature_health,
	creature_respawn_time,
}
const PATH_SYMBOLS = {
	PATH_ID.damage: "×",
	PATH_ID.bullets: "☍",
	PATH_ID.attack_speed: "»",
	PATH_ID.range: "◌",
	PATH_ID.explosion_radius: "✹",
	PATH_ID.creature_amount: "☍",
	PATH_ID.creature_damage: "×",
	PATH_ID.creature_attack_speed: "»",
	PATH_ID.creature_health: "♥"
}

var items: Dictionary = {
	"Fox": {
		"name": "Fox",
		"texture": preload("uid://cs2ic8oeq6fc0"),
		"prefab": preload("uid://dfx5piisk4epn"),
		"bullet": preload("uid://ciuly8asijcg5"),
		"paths": [PATH_ID.bullets, PATH_ID.damage, PATH_ID.attack_speed],
		"paths_increment": [1, 1, 1],
		"unlocked": true,
		"attack_speed": 1,
		"damage": 1,
		"radius": 16+4,
		"rarity": 1,
		"bullets": 1,
		"dps_multiplier": 1,
		"description": "A basic shooting fox!",
	},
	"Bunny Hole": {
		"name": "Bunny Hole",
		"texture": preload("uid://d1xf6xo2yoxag"),
		"prefab": preload("uid://cjxvt1upw8qsp"),
		"bullet": preload("uid://c1mvy41rbq2y0"),
		"paths": [PATH_ID.creature_amount, PATH_ID.creature_damage, PATH_ID.creature_attack_speed],
		"paths_increment": [1, 1, 1],
		"unlocked": false,
		"radius": 0,
		"creatures": 1,
		"creature_damage": 1,
		"creature_attack_speed": 1,
		"creatures_hp": 5,
		"creature_respawn_time": 25,
		"rarity": 1,
		"is_guard": true,
		"description": "Continuously spits out bunnies!"
	},
	"Elephant": {
		"name": "Elephant",
		"texture": preload("uid://cqnbvccmrcuat"),
		"prefab": preload("uid://dt4rxcdac07qe"),  # reuse base tower prefab or create new
		"bullet": preload("uid://dky2mhn475xk0"),
		"paths": [PATH_ID.bullets, PATH_ID.damage, PATH_ID.attack_speed],
		"paths_increment": [1, 1, 1],
		"unlocked": false,
		"attack_speed": 1,        # slow fire rate
		"damage": 2,
		"radius": 8+4,                # used for targeting
		"bullets": 1,
		"rarity": 2,
		"dps_multiplier": 1.0,
		"description": "Melee attacker, can damage multiple enemies each hit."
	},
	"Hawk": {
		"name": "Hawk",
		"texture": preload("uid://bu4gnw3uul700"),
		"prefab": preload("uid://ynouns2yxpra"),
		"bullet": preload("uid://d11coximypo74"),
		"paths": [PATH_ID.bullets, PATH_ID.damage, PATH_ID.attack_speed],
		"paths_increment": [1, 1, 1],
		"unlocked": false,
		"attack_speed": 1,
		"damage": 1,
		"radius": 72+4,
		"bullets": 1,
		"rarity": 2,
		"dps_multiplier": 2.5,
		"description": "Long range sniper!"
	},
	"Duck": {
		"name": "Duck",
		"texture": preload("uid://cqgl3igwvfat8"),
		"prefab": preload("uid://dfx5piisk4epn"),
		"bullet": preload("uid://32xbub5ovblc"),
		"paths": [PATH_ID.bullets, PATH_ID.damage, PATH_ID.attack_speed],
		"paths_increment": [1, 1, 1],
		"unlocked": false,
		"attack_speed": 1,
		"damage": 1,
		"radius": 16+4,
		"bullets": 1,
		"explosion_radius": 8,
		"enemies_hit": 3,
		"rarity": 2,
		"dps_multiplier": 2.8,
		"description": "A duck that shoots exploding bullets!"
	},
	"Snail": {
		"name": "Snail",
		"texture": preload("uid://cn7gkfeefcjd1"),
		"prefab": preload("uid://bb3wn8l2vwp2f"),
		"bullet": preload("uid://bgmdgfd4avpi0"),
		"paths": [PATH_ID.bullets, PATH_ID.damage, PATH_ID.attack_speed],
		"paths_increment": [1, 1, 1],
		"unlocked": false,
		"attack_speed": 1,
		"damage": 1,
		"radius": 16+4,
		"bullets": 1,
		"rarity": 2,
		"dps_multiplier": 3,
		"description": "Shoots in all directions!"
	},
	"Mouse": {
		"name": "Mouse",
		"texture": preload("uid://d32p5usdut0ad"),
		"prefab": preload("uid://cq8akf1ulsky"),
		"bullet": preload("uid://djhwllfo2eabv"),
		"paths": [PATH_ID.bullets, PATH_ID.damage, PATH_ID.attack_speed],
		"paths_increment": [1, 1, 1],
		"unlocked": false,
		"attack_speed": 1,
		"damage": 1,
		"radius": 8+4,
		"bullets": 1,
		"rarity": 2,
		"dps_multiplier": 2,
		"description": "Continuously spits out mousetraps!"
	},
	"Porcupine": {
		"name": "Porcupine",
		"texture": preload("uid://dx1e5kbto0dbp"),
		"prefab": preload("uid://cbo0btp4vmx8l"),
		"bullet": preload("uid://dk341876vwr43"),
		"paths": [PATH_ID.bullets, PATH_ID.damage, PATH_ID.attack_speed],
		"paths_increment": [2, 1, 1],
		"unlocked": true,
		"attack_speed": 1,
		"damage": 1,
		"radius": 8+4,
		"rarity": 2,
		"bullets": 2,
		"dps_multiplier": 1.0,
		"description": "Spikes with multiple bullets!",
	},
}


func get_tower_stats(id: String, rank: int, path_levels: Array) -> Dictionary:
	var def = items[id]
	var paths = def.paths
	var inc = def.paths_increment
	var rarity = def.rarity
	# Rank multiplier - damage INCREASES with rank
	var rank_mult = pow(2, rank - 1) + (rank-1)*2
	var upgrade_rank_mult = pow(2.0, rank )  - pow(1.3, rank )
	if rank >= 7:
		upgrade_rank_mult *= pow(1.1, rank - 6)
	upgrade_rank_mult = max(1, upgrade_rank_mult)
	
	var stats = {
		"damage": def.get("damage", -1) * rank_mult,
		"attack_speed": def.get("attack_speed", -1),
		"range": def.get("radius", -1) + 4,
		"bullets": def.get("bullets", -1),
		"explosion_radius": def.get("explosion_radius", -1),
		"enemies_hit": def.get("enemies_hit", -1),
		"creature_count": def.get("creatures", -1),
		"creature_damage": def.get("creature_damage", -1) * rank_mult,
		"creature_attack_speed": def.get("creature_attack_speed", -1),
		"creature_health": def.get("creatures_hp", -1) * pow(1.6, rank - 1),  # Reduced from pow(2)
		"creature_respawn_time": def.get("creature_respawn_time", -1),
	}
	
	for i in 3:
		var p = paths[i]
		var level = path_levels[i]
		var bonus = level * inc[i]
		match p:
			PATH_ID.attack_speed: stats.attack_speed += bonus
			PATH_ID.bullets: stats.bullets += bonus
			PATH_ID.damage: stats.damage += bonus * upgrade_rank_mult
			PATH_ID.range: stats.range += bonus * 8
			PATH_ID.explosion_radius: stats.explosion_radius += bonus*8
			PATH_ID.creature_amount: stats.creature_count += bonus
			PATH_ID.creature_damage: stats.creature_damage += bonus * upgrade_rank_mult
			PATH_ID.creature_attack_speed: stats.creature_attack_speed += bonus
			PATH_ID.creature_health:stats.creature_health += (rank - 1) * 2
			PATH_ID.creature_respawn_time: stats.creature_respawn_time -= 0
	
	return stats


func show_tower_tooltip(item: Dictionary, cost: float) -> void:
	if item.is_empty():
		return
	var def = items[item.id]
	var path_levels = item.get("path", [0, 0, 0])
	var stats = get_tower_stats(item.id, item.rank, path_levels)
	
	var tooltip_text = "[color=pink]🥩 " + str(int(cost)) + "[/color]\n"
	tooltip_text += "[color=gray]————————————————[/color]\n"
	
	if def.get("is_guard", false):
		tooltip_text += "Creatures:  [color=cornflower_blue]" + str(int(stats.creature_count)) + "\n[/color]"
		tooltip_text += "Damage:  [color=cornflower_blue]" + str(int(stats.creature_damage)) + "\n[/color]"
		tooltip_text += "Attack Speed: [color=cornflower_blue]: " + str(int(stats.creature_attack_speed)) + "/s[/color]\n"
		tooltip_text += "Health:  [color=cornflower_blue]" + str(int(stats.creature_health)) + "\n[/color]"
		tooltip_text += "Respawn:  [color=cornflower_blue]" + str(int(stats.creature_respawn_time)) + "s\n[/color]"
	else:
		tooltip_text += "Damage: [color=cornflower_blue]" + str(int(stats.damage)) + "[/color]\n"
		tooltip_text += "Attack Speed: [color=cornflower_blue]" + str(stats.attack_speed) + "[/color]\n"
		tooltip_text += "Bullets: [color=cornflower_blue]" + str(int(stats.bullets)) + "[/color]\n"
		tooltip_text += "Range: [color=cornflower_blue]" + str(int(stats.range / 8)) + " tiles[/color]\n"
		if stats.explosion_radius != -1:
			tooltip_text += "Explosion Size: [color=cornflower_blue]" + str(int(stats.explosion_radius/8)) + " tiles[/color]\n"
			tooltip_text += "Max enemies hit: [color=cornflower_blue]" + str(int(stats.enemies_hit)) + "[/color]\n"
	
	var colors: Array = item.get("colors", [])
	var color_names: Array[String] = []
	for color_name in colors:
		color_names.append(color_name.capitalize())
	var colors_text = ", ".join(color_names)
	if colors.size() > 0:
		tooltip_text += "Colors: [color=cornflower_blue]" + colors_text + "[/color]\n"
	var bonus_target = "matching wave color"
	if colors.size() > 0:
		bonus_target = colors_text + " waves"
	tooltip_text += "[font_size=2][color=dark_gray]Color Bonus: x2 damage vs " + bonus_target + "[/color][/font_size]\n"
	tooltip_text += "[color=gray]————————————————[/color]\n"
	tooltip_text += "[font_size=2][color=dark_gray]" + def.get("description", "") + "[/color][/font_size]"
	
	TooltipManager.show_tooltip(def.get("name", item.id.capitalize()), tooltip_text)

func calculate_max_dps(id: String, rank: int) -> float:
	var def = items[id]
	var max_upgrades = rank - 1
	var path_levels = [max_upgrades, max_upgrades, max_upgrades]
	var stats = get_tower_stats(id, rank, path_levels)
	
	var dps: float
	if def.get("is_guard", false):
		dps = (stats.creature_damage * stats.creature_attack_speed) * max(1, stats.creature_count * 0.85)  # Increased from 0.75
	else:
		dps = stats.damage * stats.attack_speed * stats.bullets
	
	var item = items[id]
	if "dps_multiplier" in item:
		dps *= item.dps_multiplier
	
	# Calculate total cost
	var place_cost = get_placement_cost(id, 0, rank)
	var total_upgrades_needed = 3 * max_upgrades
	var upgrade_cost = 0.0
	for i in range(total_upgrades_needed):
		upgrade_cost += get_upgrade_cost(id, rank, i, items[id].rarity)
	
	var total_cost = place_cost + upgrade_cost
	return total_cost / max(dps, 0.001)


func get_all_max_dps_per_rank() -> Dictionary:
	var result = {}
	for id in items.keys():
		result[id] = {}
		for rank in range(1, 13):
			result[id][rank] = calculate_max_dps(id, rank)
	return result

func get_placement_cost(id: String, tower_level: int, rank: int) -> float:
	var base := 40.0
	var rank_factor := pow(2.75, rank - 1)
	if rank >= 5:
		rank_factor *= pow(0.65, rank - 4)  # Even stronger discount
	var rarity_factor := pow(1.35, items[id].rarity - 1)
	return floor(base * rank_factor * rarity_factor / 10) * 10

# In InventoryManager.gd, replace the get_upgrade_cost function:

func get_upgrade_cost(id: String, rank: int, current_total_upgrades: int, rarity: int) -> float:
	var base := 38.0
	var rank_factor := pow(2.75, rank - 1)
	if rank >= 5:
		rank_factor *= pow(0.65, rank - 4)
	var rarity_factor := pow(1.3, rarity - 1)
	
	# Base cost for this rank/rarity
	var base_cost := base * rank_factor * rarity_factor
	
	# Add flat increment per upgrade (equal to rank 1 base cost)
	var rank_1_base := base * rarity_factor
	var total_cost := base_cost + (current_total_upgrades * rank_1_base)
	
	return floor(total_cost / 10) * 10

# Runtime state
var slots: Array[Panel] = []
var dragged_item: Dictionary = {}
var original_slot: Panel = null
var drag_preview: Control = null
var drag_preview_item: Dictionary = {}
var potential_cell: Vector2i = Vector2i(-1, -1)


func get_merge_cost(current_rank: int) -> float:
	var new_rank = current_rank + 1
	return base_spawn_cost #* pow(3.0, float(new_rank - 1)) / 3.0


func register_inventory(grid: GridContainer, spawner_grid: GridContainer, preview: Control) -> void:
	slots.clear()
	for i in 21:
		var slot = Panel.new()
		slot.custom_minimum_size = Vector2(8, 8)
		#slot.clip_contents = true
		slot.mouse_filter = Control.MOUSE_FILTER_STOP
		slot.gui_input.connect(_on_slot_input.bind(slot))
		slot.mouse_entered.connect(_on_slot_hover.bind(slot, true))
		slot.mouse_exited.connect(_on_slot_hover.bind(slot, false))
		grid.add_child(slot)
		slots.append(slot)
		_setup_slot_style(slot)
	
	# Example items
	await get_tree().process_frame
	await get_tree().process_frame
	give_starter_towers()
	#give_all_towers()
	print_all_tower_dps()
	for slot in slots:
		_update_slot(slot)
	
	drag_preview = preview
	drag_preview.visible = false
	
	for slot in slots:
		slot.draw.connect(_draw_slot.bind(slot))
		


func print_all_tower_dps() -> void:
	for id in items.keys():
		var tower_name = items[id].name
		print(tower_name + ":")
		for rank in range(1, 9):
			var dps = calculate_max_dps(id, rank)
			print("  Rank %d: Max DPS = %.2f" % [rank, dps])

func give_all_towers() -> void:
	var slot_index: int = 0
	for id in items.keys():
		if slot_index >= slots.size():
			break
		slots[slot_index].set_meta("item", {"id": id, "rank": 1})
		slot_index += 1
		if slot_index >= slots.size():
			break
		slots[slot_index].set_meta("item", {"id": id, "rank": 2})
		slot_index += 1
	for slot in slots:
		_update_slot(slot)
	
	for slot in slots:
		var item = slot.get_meta("item", {})
		if !item.is_empty():
			var dps = calculate_max_dps(item.id, item.rank)
			print(items[item.id].name + " (Rank " + str(item.rank) + "): Max DPS = " + str(snapped(dps, 0.01)))

func get_total_field_dps() -> float:
	var total := 0.0
	for tower in get_tree().get_nodes_in_group("tower"):
		if !tower.has_meta("item_data"):
			continue
		var item = tower.get_meta("item_data")
		var path = item.get("path", [0,0,0])
		var stats = get_tower_stats(item.id, item.rank, path)

		var def = items[item.id]
		var dps := 0.0
		if def.get("is_guard", false):
			dps = stats.creature_damage * stats.creature_attack_speed * max(1, stats.creature_count)
		else:
			dps = stats.damage * stats.attack_speed * stats.bullets

		if def.has("dps_multiplier"):
			dps *= def.dps_multiplier

		total += dps
	return total

func get_player_power_score() -> float:
	var dps := InventoryManager.get_total_field_dps()
	
	# Add tower upgrade progress as a power factor
	var total_upgrades := 0
	var possible_upgrades := 0
	for tower in get_tree().get_nodes_in_group("tower"):
		if tower.has_meta("item_data"):
			var item = tower.get_meta("item_data")
			var path = item.get("path", [0, 0, 0])
			var rank = item.rank
			total_upgrades += path[0] + path[1] + path[2]
			possible_upgrades += 3 * (rank - 1)  # max upgrades per tower
	
	var upgrade_progress := 0.0
	if possible_upgrades > 0:
		upgrade_progress = float(total_upgrades) / possible_upgrades
	
	# Upgrade progress contributes up to ~30% extra power
	var upgrade_factor := 1.0 + 0.3 * upgrade_progress
	
	# Existing factors
	var health_factor = clamp(StatsManager.health / max(StatsManager.max_health, 1.0), 0.5, 1.5)
	var sustain := StatsManager.production_speed * 0.6
	var kill_gain := StatsManager.kill_multiplier * 0.8
	
	var power := dps * upgrade_factor
	power *= health_factor
	power += sustain * 10.0
	power += kill_gain * 15.0
	
	return max(1.0, power)


func give_starter_towers():
	slots[0].set_meta("item", {"id": "Fox", "rank": 1, "colors": roll_tower_colors(), "merge_children": []})
	slots[1].set_meta("item", {"id": "Fox", "rank": 1, "colors": roll_tower_colors(), "merge_children": []})
	#slots[2].set_meta("item", {"id": "Elephant", "rank": 1})
	WaveSpawner.current_wave = 1
	TimelineManager.save_timeline(0)
	#slots[2].set_meta("item", {"id": "Fox", "rank": 1})
	#slots[3].set_meta("item", {"id": "Fox", "rank": 1})
	#slots[4].set_meta("item", {"id": "Fox", "rank": 1})
	#slots[5].set_meta("item", {"id": "Fox", "rank": 1})
	#slots[6].set_meta("item", {"id": "Fox", "rank": 1})
	#slots[7].set_meta("item", {"id": "Fox", "rank": 1})
	#slots[8].set_meta("item", {"id": "Fox", "rank": 1})
	#slots[9].set_meta("item", {"id": "Fox", "rank": 1})
	#slots[10].set_meta("item", {"id": "Fox", "rank": 1})
	#slots[11].set_meta("item", {"id": "Fox", "rank": 1})
	#slots[12].set_meta("item", {"id": "Fox", "rank": 1})
	#await get_tree().process_frame
	#StatsManager.health = 10000
	

var temp_drag_data: Dictionary = {}

func set_temp_drag_data(data: Dictionary) -> void:
	temp_drag_data = data

func clear_temp_drag_data() -> void:
	temp_drag_data = {}

func roll_tower_colors() -> Array[String]:
	var roll = randf()
	var colors: Array[String] = []
	if roll < 0.01:
		colors = ELEMENT_COLOR_KEYS.duplicate()
	elif roll < 0.11:
		var pool = ELEMENT_COLOR_KEYS.duplicate()
		pool.shuffle()
		colors = [pool[0], pool[1]]
	else:
		colors = [ELEMENT_COLOR_KEYS[randi() % ELEMENT_COLOR_KEYS.size()]]
	return colors

func get_color_value(color_name: String) -> Color:
	return ELEMENT_COLORS.get(color_name, Color.WHITE)


func _draw() -> void:
	if dragged_item.is_empty():
		return
	var mouse_pos = get_global_mouse_position()
	var draw_pos = mouse_pos - Vector2(5, 5)
	if potential_cell != Vector2i(-1, -1):
		var nearest_cell = GridController.get_nearest_valid_cell(potential_cell)
		if nearest_cell != Vector2i(-1, -1):
			var cell_pos = GridController.grid_offset + Vector2(nearest_cell.x * GridController.CELL_SIZE, nearest_cell.y * GridController.CELL_SIZE)
			var valid = GridController.is_valid_placement(nearest_cell, dragged_item)
			var fill_color = Color(0, 1, 0, 0.3) if valid else Color(1, 0, 0, 0.3)
			draw_rect(Rect2(cell_pos, Vector2(GridController.CELL_SIZE, GridController.CELL_SIZE)), fill_color, true)
	var rank = dragged_item.get("rank", 0)
	var border_color = RANK_COLORS.get(rank, Color(1, 1, 1))
	draw_rect(Rect2(draw_pos + Vector2(1.5, 1.5), Vector2(7, 7)), border_color, false, 1.0)
	var tex = items[dragged_item.id].texture
	if tex:
		draw_texture(tex, draw_pos + Vector2(1, 1), Color(1.4, 1.4, 1.4))
	

# Add this function to InventoryManager.gd
func _draw_slot(slot: Panel) -> void:
	
	
	var item = slot.get_meta("item", {})
	if item.is_empty():
		return
	var rank = item.get("rank", 1)
	var border_color = RANK_COLORS.get(rank, Color(1, 1, 1))
	var base_color = border_color * 0.3
	base_color.a = 1.0
	var hovered = slot.get_meta("hovered", false)
	var brighten = 1.3 if hovered else 1.0
	var bg_color = base_color * brighten
	
	
	slot.draw_rect(Rect2(0.5, 0.5, 7, 7), border_color, false, 1.0 + (0.5 if hovered else 0.0))
	slot.draw_rect(Rect2(1, 1, 6, 6), bg_color, true)
	
	var tex = items.get(item.get("id", ""), {}).get("texture", null)
	if tex:
		slot.draw_texture(tex, Vector2(0, 0), Color(brighten, brighten, brighten))
	var colors: Array = item.get("colors", [])
	if colors.size() > 0:
		var dot_pos = Vector2(1.2, 1.2)
		for color_name in colors:
			var dot_color = get_color_value(color_name)
			slot.draw_circle(dot_pos, 0.7, dot_color)
			dot_pos.x += 1.7
	
	var rarity = items.get(item.get("id", ""), {}).get("rarity", 0)
	for i in range(rarity):
		var offset = Vector2(0.8 + i * 1.5, 8.2)
		slot.draw_colored_polygon(PackedVector2Array([offset + Vector2(0, -2.0), offset + Vector2(1.4, 0.2), offset + Vector2(-0.9, 0.2)]), Color(0.0, 0.0, 0.0, 1.0))
		slot.draw_colored_polygon(PackedVector2Array([offset + Vector2(0, -1.5), offset + Vector2(1, 0), offset + Vector2(-0.5, 0)]), Color(0.98, 0.98, 0.0, 1.0))
		
func _setup_slot_style(slot: Panel) -> void:
	var style = StyleBoxFlat.new()
	var base = GridController.random_tint
	style.bg_color = Color.from_hsv(GridController.hue, GridController.saturation, GridController.value - 0.7, 1.0)
	style.border_width_top = 1
	style.border_width_left = 1
	style.border_color = Color.from_hsv(GridController.hue, GridController.saturation, GridController.value - 0.6, 1.0)
	slot.add_theme_stylebox_override("panel", style)
	slot.set_meta("style", style)

func _update_slot(slot: Panel) -> void:
	_setup_slot_style(slot)
	var item = slot.get_meta("item", {})
	if item.is_empty():
		slot.get_meta("style").bg_color = Color(0.1, 0.1, 0.1)
	else:
		if not item.has("colors"):
			item["colors"] = roll_tower_colors()
			item["merge_children"] = item.get("merge_children", [])
			slot.set_meta("item", item)
		var rank = item.get("rank", 1)
		var rank_color = RANK_COLORS.get(rank, Color(1, 1, 1))
		slot.get_meta("style").bg_color = rank_color * 0.3
		slot.get_meta("style").bg_color.a = 1.0
	slot.queue_redraw()

func _on_slot_input(event: InputEvent, slot: Panel) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and slot.has_meta("item"):
		HealthBarGUI.show_cost_preview(0.0)
		var item = slot.get_meta("item", {})
		if item.is_empty():
			return
		dragged_item = item.duplicate()
		drag_preview_item = dragged_item.duplicate()
		original_slot = slot
		slot.set_meta("item", {})
		_update_slot(slot)
		queue_redraw()
		refresh_inventory_highlights()
		if grid_controller:
			grid_controller.refresh_grid_highlights()

func refresh_slot_styles() -> void:
	for slot in slots:
		_setup_slot_style(slot)
		slot.queue_redraw()

func refresh_inventory_highlights() -> void:
	for slot in slots:
		slot.queue_redraw()

func _on_slot_hover(slot: Panel, entered: bool) -> void:
	slot.set_meta("hovered", entered)
	_update_hover(slot)
	if entered and !slot.get_meta("item", {}).is_empty():
		var item = slot.get_meta("item")
		var cost = get_placement_cost(item.id, 0, item.rank)
		show_tower_tooltip(item, cost)
		HealthBarGUI.show_cost_preview(cost)
	elif !entered:
		TooltipManager.hide_tooltip()
		HealthBarGUI.hide_cost_preview()
		# hide preview handling unchanged


func _update_hover(slot: Panel) -> void:
	var style: StyleBoxFlat = slot.get_meta("style")
	var base = Color(0.1, 0.1, 0.1)
	var hover = Color(0.2, 0.2, 0.2)
	var merge = Color(0.1, 0.4, 0.1)
	var item = slot.get_meta("item", {})
	var hovered = slot.get_meta("hovered", false)
	
	var is_potential_merge = !item.is_empty() and (
		(original_slot != null and !dragged_item.is_empty() and item.id == dragged_item.id and item.rank == dragged_item.rank) or
		(grid_controller != null and grid_controller.dragged_tower != null and 
		 item.id == grid_controller.dragged_tower.get_meta("item_data").id and 
		 item.rank == grid_controller.dragged_tower.get_meta("item_data").rank)
	)
	
	if hovered and is_potential_merge:
		style.bg_color = merge
	elif hovered:
		style.bg_color = hover
	else:
		style.bg_color = base

func _process(_delta: float) -> void:
	var preview_cost: float = 0.0
	if !dragged_item.is_empty():
		var item_def = items[dragged_item.id]
		var tower_level = item_def.get("tower_level", 0)
		var cost = get_placement_cost(dragged_item.id, tower_level, dragged_item.rank)
		HealthBarGUI.show_cost_preview(cost)
		var mouse_pos = get_global_mouse_position()
		var raw_cell = GridController.get_cell_from_pos(mouse_pos)
		potential_cell = GridController.get_nearest_valid_cell(raw_cell) if raw_cell != Vector2i(-1, -1) else Vector2i(-1, -1)
		queue_redraw()
	if original_slot != null:
		queue_redraw()
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) == false and original_slot != null:
		_perform_drop()
		HealthBarGUI.show_cost_preview(0.0)

func get_current_dragged_data(exclude_tower: Node = null) -> Dictionary:
	if !dragged_item.is_empty():
		return dragged_item
	if grid_controller and grid_controller.dragged_tower != null and grid_controller.dragged_tower != exclude_tower:
		return grid_controller.dragged_tower.get_meta("item_data")
	return {}

func _perform_drop() -> void:
	var mouse_pos = get_global_mouse_position()
	if dragged_item.is_empty():
		dragged_item = {}
		original_slot = null
		drag_preview.visible = false
		potential_cell = Vector2i(-1, -1)
		return
	var target = get_closest_slot(mouse_pos, 8.0, false)
	var return_to_original = true
	if target and target != original_slot:
		var target_item = target.get_meta("item", {})
		if target_item.is_empty():
			target.set_meta("item", dragged_item)
			_update_slot(target)
			return_to_original = false
	if return_to_original and potential_cell != Vector2i(-1, -1):
		var place_cell = GridController.get_nearest_valid_cell(potential_cell)
		if place_cell != Vector2i(-1, -1):
			if GridController.get_grid_item_at_cell(place_cell) == null && GridController.is_valid_placement(place_cell, dragged_item):
				if GridController.place_item(dragged_item, place_cell):
					return_to_original = false
	if return_to_original:
		original_slot.set_meta("item", dragged_item)
		_update_slot(original_slot)
	dragged_item = {}
	original_slot = null
	drag_preview.visible = false
	potential_cell = Vector2i(-1, -1)
	for slot in slots:
		_update_hover(slot)
	refresh_inventory_highlights()
	if grid_controller:
		grid_controller.refresh_grid_highlights()

func refresh_all_highlights() -> void:
	for slot in slots:
		slot.queue_redraw()
	if grid_controller:
		grid_controller.refresh_grid_highlights()

func _get_slot_under_mouse() -> Panel:
	var pos = get_global_mouse_position()
	for slot in slots:
		if slot.get_global_rect().has_point(pos):
			return slot
	return null

func get_closest_slot(global_pos: Vector2, max_dist: float = 8.0, empty_only: bool = false) -> Panel:
	var closest: Panel = null
	var min_dist_sq: float = INF
	var max_dist_sq: float = max_dist * max_dist
	for slot in slots:
		if empty_only and !slot.get_meta("item", {}).is_empty():
			continue
		var center = slot.get_global_rect().get_center()
		var dist_sq = global_pos.distance_squared_to(center)
		if dist_sq < min_dist_sq:
			min_dist_sq = dist_sq
			closest = slot
	if closest and min_dist_sq <= max_dist_sq:
		return closest
	return null

func _spawn_item(rank: int) -> bool:
	var keys = items.keys()
	if keys.is_empty(): return false
	var id = keys[randi() % keys.size()]
	var new_item = {"id": id, "rank": rank + 1, "colors": roll_tower_colors(), "merge_children": []}
	var cost = get_placement_cost(id, 1, rank)
	if not StatsManager.spend_health(cost): return false
	for slot in slots:
		if slot.get_meta("item", {}).is_empty():
			slot.set_meta("item", new_item)
			_update_slot(slot)
			return true
	return false


func clear_inventory() -> void:
	for slot in slots:
		slot.set_meta("item", {})
		_update_slot(slot)
	refresh_inventory_highlights()
