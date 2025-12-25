extends Button

@onready var gacha_overlay = %GachaOverlay # Add ColorRect as child, full-screen
@onready var gacha_sprite = %TowerSprite # Child of overlay
@onready var gacha_button: Button = self
@onready var stats_label = %StatsLabel 

var pending_pull: bool = false
var revealed_id: String = ""

func _ready() -> void:
	stats_label.bbcode_enabled = true
	stats_label.add_theme_font_size_override("normal_font_size", 4)
	stats_label.add_theme_font_size_override("bold_font_size", 4)
	stats_label.visible = false
	gacha_overlay.visible = false
	gacha_overlay.color = Color(0, 0, 0, 0.7)
	gacha_overlay.size = get_viewport_rect().size
	gacha_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	gacha_sprite.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	gacha_sprite.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	gacha_sprite.position = gacha_overlay.size / 2
	gacha_sprite.size = Vector2(8, 8) # Adjust size as needed
	
	focus_mode = Control.FOCUS_NONE
	add_theme_font_size_override("font_size", 4)
	
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.2, 0.2, 0.2)
	style_normal.border_width_left = 0
	style_normal.border_width_top = 0
	style_normal.border_width_right = 0
	style_normal.border_width_bottom = 0
	style_normal.corner_radius_top_left = 0
	style_normal.corner_radius_top_right = 0
	style_normal.corner_radius_bottom_left = 0
	style_normal.corner_radius_bottom_right = 0
	style_normal.content_margin_left = 3
	style_normal.content_margin_right = 3
	style_normal.content_margin_top = 0
	style_normal.content_margin_bottom = 1
	
	var style_hover = style_normal.duplicate()
	style_hover.bg_color = Color(0.3, 0.3, 0.3)
	style_hover.border_color = Color(0.7, 0.7, 0.7)
	
	var style_pressed = style_normal.duplicate()
	style_pressed.bg_color = Color(0.15, 0.15, 0.15)
	style_pressed.border_color = Color(0.8, 0.8, 0.8)
	
	add_theme_stylebox_override("normal", style_normal)
	add_theme_stylebox_override("hover", style_hover)
	add_theme_stylebox_override("pressed", style_pressed)
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	gacha_button.pressed.connect(_on_gacha_pressed)
	text = "Pull (€%d)" % Gacha.pull_cost
	Gacha.item_pulled.connect(_on_item_pulled)



func _on_gacha_pressed() -> void:
	if Gacha.pull():
		pending_pull = true
	else:
		Utilities.spawn_floating_text("Not enough money!", gacha_button.global_position)

func _on_item_pulled(id: String, is_new: bool) -> void:
	revealed_id = id
	gacha_sprite.texture = InventoryManager.items.get(id, {}).get("texture", null)
	if is_new:
		show_sunbeams = true
		sunbeam_timer = 0.0
	if !is_new:
		InventoryManager.apply_level_up(id)
	
	var old_rank = Gacha.unlocked_levels[id] - 1
	var new_rank = Gacha.unlocked_levels[id]
	
	var old_as = InventoryManager.get_stat_for_rank(id, "attack_speed", old_rank)
	var new_as = InventoryManager.get_stat_for_rank(id, "attack_speed", new_rank)
	var old_dmg = InventoryManager.get_stat_for_rank(id, "damage", old_rank)
	var new_dmg = InventoryManager.get_stat_for_rank(id, "damage", new_rank)
	var old_rad = InventoryManager.get_stat_for_rank(id, "radius", old_rank)
	var new_rad = InventoryManager.get_stat_for_rank(id, "radius", new_rank)
	
	stats_label.clear()
	stats_label.push_color(Color.WHITE)
	stats_label.push_bold()
	
	if is_new:
		stats_label.add_text("New Tower!\n")
		stats_label.add_text(id.capitalize() + "!")
		stats_label.pop()
		stats_label.pop()
		
		#stats_label.newline()
		#stats_label.add_text("Attack Speed: ")
		#stats_label.push_color(Color.LIME_GREEN)
		#stats_label.add_text(str(new_as))
		#stats_label.pop()
		#
		#stats_label.newline()
		#stats_label.add_text("Damage: ")
		#stats_label.push_color(Color.LIME_GREEN)
		#stats_label.add_text(str(new_dmg))
		#stats_label.pop()
		#
		#stats_label.newline()
		#stats_label.add_text("Radius: ")
		#stats_label.push_color(Color.LIME_GREEN)
		#stats_label.add_text(str(new_rad))
		#stats_label.pop()
	else:
		stats_label.add_text(id.capitalize() + "\n")
		stats_label.add_text("Level " + str(old_rank) + " → ")
		stats_label.push_color(Color.LIME_GREEN)
		stats_label.add_text(str(new_rank))
		stats_label.pop()
		stats_label.pop()
		stats_label.pop()
		
		if new_as > old_as:
			stats_label.newline()
			stats_label.add_text("Attack Speed: " + str(old_as) + " → ")
			stats_label.push_color(Color.LIME_GREEN)
			stats_label.add_text(str(new_as))
			stats_label.pop()
		
		if new_dmg > old_dmg:
			stats_label.newline()
			stats_label.add_text("Damage: " + str(old_dmg) + " → ")
			stats_label.push_color(Color.LIME_GREEN)
			stats_label.add_text(str(new_dmg))
			stats_label.pop()
		
		if new_rad > old_rad:
			stats_label.newline()
			stats_label.add_text("Radius: " + str(old_rad) + " → ")
			stats_label.push_color(Color.LIME_GREEN)
			stats_label.add_text(str(new_rad))
			stats_label.pop()
	
	stats_label.visible = true
	gacha_overlay.visible = true
	gacha_button.disabled = true
	text = "Pull (€%d)" % Gacha.pull_cost

func _input(event: InputEvent) -> void:
	if pending_pull and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var new_item = {"id": revealed_id, "rank": Gacha.unlocked_levels[revealed_id]}
		for slot in InventoryManager.slots:
			if slot.get_meta("item", {}).is_empty():
				slot.set_meta("item", new_item)
				InventoryManager._update_slot(slot)
				break
		var msg = "Unlocked %s!" % revealed_id if Gacha.unlocked_levels[revealed_id] == 1 else "Leveled %s!" % revealed_id
		Utilities.spawn_floating_text(msg, get_global_mouse_position(), null, true)
		gacha_overlay.visible = false
		pending_pull = false
		gacha_button.disabled = false


var sunbeam_timer: float = 0.0
var show_sunbeams: bool = false
var sunbeam_duration: float = 2.0

func _process(delta: float) -> void:
	if show_sunbeams:
		sunbeam_timer += delta
		if sunbeam_timer >= sunbeam_duration:
			show_sunbeams = false
		queue_redraw()
		
func _draw() -> void:
	if !show_sunbeams:
		return
	
	var center = gacha_sprite.position - Vector2(78,85)
	var alpha = 1.0 - (sunbeam_timer / sunbeam_duration)  # Fade out
	var color = Color(1.0, 0.9, 0.4, 0.6 * alpha)  # Golden yellow, semi-transparent
	var spin_speed = 2.0
	var time = sunbeam_timer * spin_speed
	
	for i in 8:
		var angle = (i / 8.0) * TAU + time
		var start = center + Vector2(cos(angle), sin(angle)) * 8
		var end = center + Vector2(cos(angle), sin(angle)) * 64
		draw_line(start, end, color, 3.0)
		draw_line(start, end, Color(1.0, 1.0, 0.8, 0.8 * alpha), 1.0)  # Inner glow
		
