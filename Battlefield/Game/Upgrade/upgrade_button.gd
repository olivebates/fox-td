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
	icon_text.position = Vector2(-4,-14)
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

	var cost = InventoryManager.get_upgrade_cost(tower_id, rank, current_level + 1, rank)
	cost_text.text = "[font_size=7.5][color=cornflower_blue]Cost: " + str(int(cost)) + "[/color][/font_size]"

	var item_def = InventoryManager.items[tower_id]
	var path_enum = item_def.paths[path_id]

	match path_enum:
		InventoryManager.PATH_ID.bullets:
			cost_text.append_text("\n[font_size=4][color=light_gray]Bullets: " + str(int(current_stats.bullets)) + " -> [/color][color=lime]" + str(int(next_stats.bullets)) + "[/color][/font_size]")
		InventoryManager.PATH_ID.attack_speed:
			cost_text.append_text("\n[font_size=4][color=light_gray]Attack Speed: " + str(int(snapped(current_stats.attack_speed, 0.01))) + "/s -> [/color][color=lime]" + str(int(snapped(next_stats.attack_speed, 0.01))) + "/s[/color][/font_size]")
		InventoryManager.PATH_ID.range:
			cost_text.append_text("\n[font_size=4][color=light_gray]Range: " + str(int(current_stats.range / 8)) + " -> [/color][color=lime]" + str(int(next_stats.range / 8)) + " tiles[/color][/font_size]")
		InventoryManager.PATH_ID.damage:
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

func _on_mouse_entered() -> void:
	var fake_item = {"id": tower_id, "rank": rank, "path": base_tower.path.duplicate()}
	InventoryManager.show_tower_tooltip(fake_item, 0.0)

func _on_mouse_exited() -> void:
	TooltipManager.hide_tooltip()

func _on_button_pressed() -> void:
	get_viewport().set_input_as_handled()  # Prevent further input bubbling
	if current_level >= rank:
		return
	var next_level = current_level + 1
	var cost = InventoryManager.get_upgrade_cost(tower_id, rank, next_level, rank)
	if StatsManager.spend_health(cost):
		base_tower.path[path_id] += 1
		current_level += 1
		_update_display()
		UpgradeManager.unpause()
		get_parent().get_parent().queue_free()
	else:
		Utilities.spawn_floating_text("Not enough meat...", Vector2(0, 0), null)
		# Do NOT queue_free here — keep UI open on failure

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
