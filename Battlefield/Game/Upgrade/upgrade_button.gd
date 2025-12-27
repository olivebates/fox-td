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
	cost_text.bbcode_enabled = true
	
	var tower_rarity = InventoryManager.items[tower_id].rarity
	current_level = base_tower.path[path_id]
	
	icon_text.size = Vector2(30, 30)
	icon_text.position = Vector2(1.5, -17)
	icon_text.add_theme_font_size_override("font_size", 40)
	
	if current_level >= rank:
		cost_text.text = "[font_size=7.5]Maxed[/font_size]"
		disabled = true
	else:
		var next_level = current_level + 1
		var rank = base_tower.rank
		var cost = InventoryManager.get_upgrade_cost(tower_id, 1, next_level, rank)
		cost_text.text = "[font_size=7.5][color=cornflower_blue]Cost: " + str(int(cost)) + "[/color][/font_size]"
		
		if path_id == 0:
			icon_text.position = Vector2(1, -14)
			icon_text.text = "☍"
			cost_text.append_text("\n[font_size=4][color=light_gray]Bullets: " + str(int(current_level + 1)) + " -> [/color][color=lime]" + str(next_level + 1) + "[/color][/font_size]")
		elif path_id == 1:
			icon_text.text = "»"
			var current_speed = InventoryManager.get_attack_speed(tower_id, current_level)
			var next_speed = InventoryManager.get_attack_speed(tower_id, next_level)
			cost_text.append_text("\n[font_size=4][color=light_gray]Attack Speed: " + str(int(snapped(current_speed, 0.01))) + "/s -> [/color][color=lime]" + str(int(snapped(next_speed, 0.01))) + "/s[/color][/font_size]")
		else:
			icon_text.text = "◌"
			var current_rad = InventoryManager.items[tower_id].radius + (current_level * 8)
			var next_rad = InventoryManager.items[tower_id].radius + (next_level * 8)
			cost_text.append_text("\n[font_size=4][color=light_gray]Range: " + str(int(snapped(current_rad / 8, 0.1))) + " -> [/color][color=lime]" + str(int(snapped(next_rad / 8, 0.1))) + " tiles[/color][/font_size]")
	
	pressed.connect(_on_button_pressed)
	custom_minimum_size = Vector2(32, 10)
	flat = true
	focus_mode = Control.FOCUS_NONE
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _on_mouse_entered() -> void: pass
	#TooltipManager.show_tooltip(
		#"Increase Bullets",
		#"[font_size=3][color=cornflower_blue]Costs: " + str(int(InventoryManager.get_placement_cost(tower_id, 1, current_level+1))) + "[/color][/font_size]\n[color=gray]————————————————[/color]\n" +
		#"[font_size=2][color=dark_gray]Click on the path to build a wall!\n" +
		#"Walls cannot be removed, so place them carefully![/color][/font_size]"
	#)

func _on_mouse_exited() -> void:
	TooltipManager.hide_tooltip()


func _on_button_pressed() -> void:
	var next_level = current_level + 1
	var rank = base_tower.rank
	var cost = InventoryManager.get_upgrade_cost(tower_id, 1, next_level, rank)
	
	if StatsManager.spend_health(cost):
		base_tower.path[path_id] += 1
		UpgradeManager.unpause()
		UpgradeManager.unpause_towers()
		get_parent().get_parent().queue_free()
	else:
		Utilities.spawn_floating_text("Not enough meat...", Vector2(0, 0), null)

func _draw() -> void:
	var tower_rarity = InventoryManager.items[tower_id].rarity
	if current_level < rank:
		var border_color = InventoryManager.RANK_COLORS.get(base_tower.path[path_id]+1, Color(1, 1, 1))
		var base_color = border_color * 0.3
		base_color.a = 1.0
		var brighten = 1.5 if is_hovered() else 1.0
		draw_rect(Rect2(0.0, 0.0, 32.0, 32.0), border_color, false, 2.0 + (1.0 if is_hovered() else 0.0))
		draw_rect(Rect2(1.0, 1.0, 30.0, 30.0), base_color * brighten, true)
	
	

func _process(_delta: float) -> void:

	queue_redraw()
