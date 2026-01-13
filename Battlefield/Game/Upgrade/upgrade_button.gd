extends Button

var base_tower
var tower_id
var tower_level
var path_id
var current_level
@onready var rank = base_tower.rank
@onready var icon_text = %UpgradeButtonText
@onready var cost_text = %UpgradeCost
#@onready var icon_container = $UpgradeButtonIcon
#var icon_textures = [preload("uid://w1oh5me4amo0"), preload("uid://w1oh5me4amo0"), preload("uid://w1oh5me4amo0")]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var PATH_ID = InventoryManager.PATH_ID
	cost_text.bbcode_enabled = true
	var item_def = InventoryManager.items[tower_id]
	var path_enum = item_def.paths[path_id]
	current_level = base_tower.path[path_id]
	icon_text.text = InventoryManager.PATH_SYMBOLS[path_enum]
	icon_text.position = Vector2(-4,-28)
	icon_text.add_theme_font_size_override("font_size", 40)

	_update_display()

	pressed.connect(_on_button_pressed)
	custom_minimum_size = Vector2(32, 10)
	flat = true
	focus_mode = Control.FOCUS_NONE
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _update_display() -> void:
	if current_level >= rank:
		cost_text.text = "[font_size=7.5]Maxed[/font_size]"
		disabled = true
		return

	disabled = false
	var current_path_levels = base_tower.path.duplicate()
	var next_path_levels = current_path_levels.duplicate()
	next_path_levels[path_id] += 1

	var current_stats = InventoryManager.get_tower_stats(tower_id, rank, current_path_levels)
	var next_stats = InventoryManager.get_tower_stats(tower_id, rank, next_path_levels)

	# Calculate total upgrades this tower has bought
	var total_upgrades = base_tower.path[0] + base_tower.path[1] + base_tower.path[2]
	
	var item_def = InventoryManager.items[tower_id]
	var cost = InventoryManager.get_upgrade_cost(tower_id, rank, total_upgrades, item_def.rarity)
	cost_text.text = "[font_size=7.5][color=cornflower_blue]Cost: " + str(int(cost)) + "[/color][/font_size]"

	var path_enum = item_def.paths[path_id]
	var is_turtle = tower_id == "Turtle"
	var is_starfish = tower_id == "Starfish"
	var is_snake = tower_id == "Snake"
	var is_snail = tower_id == "Snail"

	match path_enum:
		InventoryManager.PATH_ID.bullets:
			if is_turtle:
				var current_targets = InventoryManager.TURTLE_BASE_TARGETS + (InventoryManager.TURTLE_TARGETS_PER_LEVEL * int(current_path_levels[path_id]))
				var next_targets = InventoryManager.TURTLE_BASE_TARGETS + (InventoryManager.TURTLE_TARGETS_PER_LEVEL * int(next_path_levels[path_id]))
				cost_text.append_text("\n[font_size=4][color=light_gray]Targets: " + str(current_targets) + " -> [/color][color=lime]" + str(next_targets) + "[/color][/font_size]")
			elif is_snake:
				var current_duration = 4.0 + (float(current_path_levels[path_id]) * 4.0)
				var next_duration = 4.0 + (float(next_path_levels[path_id]) * 4.0)
				cost_text.append_text("\n[font_size=4][color=light_gray]Poison Duration: " + str(int(current_duration)) + "s -> [/color][color=lime]" + str(int(next_duration)) + "s[/color][/font_size]")
			elif is_snail:
				var current_volleys = 1 + int(current_path_levels[path_id])
				var next_volleys = 1 + int(next_path_levels[path_id])
				cost_text.append_text("\n[font_size=4][color=light_gray]Volleys: " + str(current_volleys) + " -> [/color][color=lime]" + str(next_volleys) + "[/color][/font_size]")
			else:
				cost_text.append_text("\n[font_size=4][color=light_gray]Bullets: " + str(int(current_stats.bullets)) + " -> [/color][color=lime]" + str(int(next_stats.bullets)) + "[/color][/font_size]")
		InventoryManager.PATH_ID.attack_speed:
			if is_starfish:
				var current_bonus = 30 + (int(current_path_levels[path_id]) * 30)
				var next_bonus = 30 + (int(next_path_levels[path_id]) * 30)
				cost_text.append_text("\n[font_size=4][color=light_gray]Adj Speed: +" + str(current_bonus) + "% -> [/color][color=lime]+" + str(next_bonus) + "%[/color][/font_size]")
			else:
				cost_text.append_text("\n[font_size=4][color=light_gray]Attack Speed: " + str(int(snapped(current_stats.attack_speed, 0.01))) + "/s -> [/color][color=lime]" + str(int(snapped(next_stats.attack_speed, 0.01))) + "/s[/color][/font_size]")
		InventoryManager.PATH_ID.range:
			if is_starfish:
				var current_tiles = int(current_path_levels[path_id])
				var next_tiles = int(next_path_levels[path_id])
				cost_text.append_text("\n[font_size=4][color=light_gray]Adj Range: " + str(current_tiles) + " -> [/color][color=lime]" + str(next_tiles) + " tiles[/color][/font_size]")
			else:
				cost_text.append_text("\n[font_size=4][color=light_gray]Range: " + str(int(current_stats.range / 8)) + " -> [/color][color=lime]" + str(int(next_stats.range / 8)) + " tiles[/color][/font_size]")
		InventoryManager.PATH_ID.damage:
			if is_turtle:
				var current_slow = clamp(InventoryManager.TURTLE_BASE_SLOW + (InventoryManager.TURTLE_SLOW_PER_LEVEL * float(current_path_levels[path_id])), 0.0, 0.9)
				var next_slow = clamp(InventoryManager.TURTLE_BASE_SLOW + (InventoryManager.TURTLE_SLOW_PER_LEVEL * float(next_path_levels[path_id])), 0.0, 0.9)
				var current_percent = int(round(current_slow * 100.0))
				var next_percent = int(round(next_slow * 100.0))
				cost_text.append_text("\n[font_size=4][color=light_gray]Slow: " + str(current_percent) + "% -> [/color][color=lime]" + str(next_percent) + "%[/color][/font_size]")
			elif is_snake:
				var base_poison = StatsManager.get_global_damage_multiplier()
				var current_dps = base_poison + current_stats.damage
				var next_dps = base_poison + next_stats.damage
				cost_text.append_text("\n[font_size=4][color=light_gray]Poison: " + str(int(current_dps)) + " damage/s -> [/color][color=lime]" + str(int(next_dps)) + " damage/s[/color][/font_size]")
			elif is_starfish:
				var current_bonus = int(current_path_levels[path_id]) * 30
				var next_bonus = int(next_path_levels[path_id]) * 30
				cost_text.append_text("\n[font_size=4][color=light_gray]Adj Damage: +" + str(current_bonus) + "% -> [/color][color=lime]+" + str(next_bonus) + "%[/color][/font_size]")
			else:
				cost_text.append_text("\n[font_size=4][color=light_gray]Damage: " + str(int(current_stats.damage)) + " -> [/color][color=lime]" + str(int(next_stats.damage)) + "[/color][/font_size]")
		InventoryManager.PATH_ID.explosion_radius:
			cost_text.append_text("\n[font_size=4][color=light_gray]Explosion Radius: " + str(int(current_stats.explosion_radius / 8)) + " -> [/color][color=lime]" + str(int(next_stats.explosion_radius / 8)) + " tiles[/color][/font_size]")
		InventoryManager.PATH_ID.creature_amount:
			cost_text.append_text("\n[font_size=4][color=light_gray]Creatures: " + str(int(current_stats.creature_count)) + " -> [/color][color=lime]" + str(int(next_stats.creature_count)) + "[/color][/font_size]")
		InventoryManager.PATH_ID.creature_damage:
			cost_text.append_text("\n[font_size=4][color=light_gray]Damage: " + str(int(current_stats.creature_damage)) + " -> [/color][color=lime]" + str(int(next_stats.creature_damage)) + "[/color][/font_size]")
		InventoryManager.PATH_ID.creature_attack_speed:
			cost_text.append_text("\n[font_size=4][color=light_gray]Attack Speed: " + str(int(snapped(current_stats.creature_attack_speed, 0.01))) + "/s -> [/color][color=lime]" + str(int(snapped(next_stats.creature_attack_speed, 0.01))) + "/s[/color][/font_size]")
		InventoryManager.PATH_ID.creature_health:
			cost_text.append_text("\n[font_size=4][color=light_gray]Health: " + str(int(current_stats.creature_health)) + " -> [/color][color=lime]" + str(int(next_stats.creature_health)) + "[/color][/font_size]")


func _on_mouse_entered() -> void:pass
	#var fake_item = {"id": tower_id, "rank": rank, "path": base_tower.path.duplicate()}
	#InventoryManager.show_tower_tooltip(fake_item, 0.0)

func _on_mouse_exited() -> void:pass
	#TooltipManager.hide_tooltip()

func _on_button_pressed() -> void:
	get_viewport().set_input_as_handled()
	if current_level >= rank:
		return
	
	# Calculate total upgrades this tower has bought
	var total_upgrades = base_tower.path[0] + base_tower.path[1] + base_tower.path[2]
	var item_def = InventoryManager.items[tower_id]
	var cost = InventoryManager.get_upgrade_cost(tower_id, rank, total_upgrades, item_def.rarity)
	
	if StatsManager.spend_health(cost):
		base_tower.path[path_id] += 1
		current_level += 1
		_update_display()
		UpgradeManager.unpause()
		get_parent().get_parent().queue_free()
	else:
		Utilities.spawn_floating_text("Not enough meat...", Vector2(0, 0), null)

func _draw() -> void:
	var tower_rarity = InventoryManager.items[tower_id].rarity
	if current_level < rank:
		
		var border_color = InventoryManager.RANK_COLORS.get(int(base_tower.path[path_id])+1, Color(0.0, 1.0, 1.0, 1.0))
		var base_color = border_color * 0.3
		base_color.a = 1.0
		var brighten = 1.5 if is_hovered() else 1.0
		draw_rect(Rect2(0.0, 0.0, 32.0, 32.0), border_color, false, 2.0 + (1.0 if is_hovered() else 0.0))
		draw_rect(Rect2(1.0, 1.0, 30.0, 30.0), base_color * brighten, true)
	
	

func _process(_delta: float) -> void:
	queue_redraw()
