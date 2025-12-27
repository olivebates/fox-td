extends CharacterBody2D
class_name tower_base

@onready var sprite: Sprite2D = $Sprite2D
var invManager = InventoryManager
var _timer: float = 0.0
var draw_radius: bool = false
var hovered: bool = false
var current_target: Node2D = null
var pick_radius: float = 4.0
var fire_rate: float = 1.0
var bullet_scene: PackedScene
var attack_radius: float = 32.0
var tower_level: float = 0
var pause_function = false
var tower_type

# Upgrade hold variables
var hold_timer: float = 0.0
var holding: bool = false
var upgrade_cost: float = 0.0
@onready var cost_label = $UpgradeCost
var rank

var bullets_shot = 1
var path = [0,0,0]

func _ready() -> void:
	if has_meta("item_data"):
		var data = get_meta("item_data")
		var item_def = invManager.items[data.id]
		tower_type = data.id
		tower_level = item_def.get("tower_level", 0)
		fire_rate = item_def.attack_speed
		bullet_scene = item_def.bullet
		attack_radius = item_def.radius
		rank = data.get("rank", 1)
		#fire_rate *= pow(1.07, rank - 1)
		#attack_radius *= pow(1.07, rank - 1)
		sprite.texture = item_def.texture

func is_mouse_over() -> bool:
	return get_global_mouse_position().distance_to(global_position) < pick_radius

func _input(event: InputEvent) -> void:
	if pause_function:
		return

	var mouse_over = is_mouse_over()

	if event is InputEventMouseMotion:
		var was_hovered = hovered
		hovered = mouse_over
		if hovered and not was_hovered:
			draw_radius = true
			queue_redraw()
		elif not hovered and was_hovered:
			draw_radius = false
			if has_meta("item_data"):
				InventoryManager.HealthBarGUI.hide_cost_preview()
			queue_redraw()

		if hovered and not was_hovered and has_meta("item_data"):
			var data = get_meta("item_data")
			var item_def = invManager.items[data.id]
			var rank = data.get("rank", 1)
			
			var cost = InventoryManager.get_placement_cost(data.id, tower_level, rank)
			var dmg = InventoryManager.get_damage_calculation(data.id, rank, 0)
			var atk = 1.0 / invManager.get_attack_speed(data.id, path[1]) / pow(1.07, rank - 1)
			atk = snapped(atk, 0.01)
			var rad = invManager.get_tower_radius(data.id, self)
			
			TooltipManager.show_tooltip(
				item_def.get("name", data.id.capitalize()),
				"[color=gray]————————————————[/color]\n" +
				"[color=cornflower_blue]Damage: " + str(dmg) + "\n" +
				"Attack Speed: " + str(int(atk)) + "/s\n" +
				"Range: " + str(int(rad / 8)) + " tiles[/color]\n[color=gray]————————————————[/color]\n" +
				"[font_size=2][color=dark_gray]Click to upgrade[/color][/font_size]"
			)
			pass
		elif not hovered and was_hovered:
			TooltipManager.hide_tooltip()

		# Cancel hold if mouse moves while holding
		if holding:
			holding = false
			hold_timer = 0.0
			InventoryManager.HealthBarGUI.hide_cost_preview()
			queue_redraw()

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if mouse_over and has_meta("item_data"):
					holding = true
					hold_timer = 0.0
					var data = get_meta("item_data")
					var rank = data.get("rank", 1)
					upgrade_cost = InventoryManager.get_placement_cost(data.id, tower_level, rank)
					var grid_controller = get_node("/root/GridController")
					if grid_controller:
						grid_controller.start_tower_drag(self, global_position - get_global_mouse_position())
					get_viewport().set_input_as_handled()

			else:  # Released
				if holding and mouse_over:  # Short click, no significant movement
					var data = get_meta("item_data")
					var item_def = invManager.items[data.id]
					UpgradeManager.upgrade(self, item_def.name, item_def.rarity, path[0], path[1], path[2])
				
				holding = false
				hold_timer = 0.0
				InventoryManager.HealthBarGUI.hide_cost_preview()
				queue_redraw()

	

func _exit_tree() -> void:
	hovered = false

func _draw() -> void:
	if draw_radius:
		draw_arc(Vector2.ZERO, attack_radius, 0, TAU, 64, Color(1, 0, 0, 0.5), 2.0)
	if not has_meta("item_data"):
		return
	var data = get_meta("item_data")
	var rank = data.get("rank", 0)
	var border_color = InventoryManager.RANK_COLORS.get(rank, Color(1, 1, 1))
	var base_color = border_color * 0.3
	base_color.a = 1.0
	var brighten = 1.5 if hovered else 1.0
	draw_rect(Rect2(-3.2, -3.2, 6.5, 6.5), border_color, false, 1.0 + (0.5 if hovered else 0.0))
	draw_rect(Rect2(-3, -3, 6, 6), base_color * brighten, true)
	var rarity = invManager.items[data.id].rarity
	for i in range(rarity):
		var offset = Vector2(-2.8 + i * 1.5, 3.8)
		draw_colored_polygon(PackedVector2Array([offset + Vector2(0, -2.0), offset + Vector2(1.4, 0.2), offset + Vector2(-0.9, 0.2)]), Color(0, 0, 0, 1))
		draw_colored_polygon(PackedVector2Array([offset + Vector2(0, -1.5), offset + Vector2(1, 0), offset + Vector2(-0.5, 0)]), Color(0.98, 0.98, 0, 1))

func update_target() -> void:
	current_target = null
	var min_dist: float = INF
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		var dist = global_position.distance_to(enemy.global_position)
		if dist <= attack_radius and dist < min_dist:
			min_dist = dist
			current_target = enemy

func fire(target: Node2D) -> void:
	var dir = (target.global_position - global_position).normalized()
	sprite.flip_h = dir.x > 0
	for i in bullets_shot:
		var bullet = bullet_scene.instantiate()
		bullet.target = target
		if has_meta("item_data"):
			var rank = get_meta("item_data").get("rank", 0)
			var name = get_meta("item_data").get("name", 0)
			bullet.damage = InventoryManager.get_damage_calculation(tower_type, rank, 0)
			
		var rand_dir = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
		bullet.velocity = rand_dir * bullet.initial_speed
		bullet.global_position = global_position
		get_tree().current_scene.add_child(bullet)
	
	var tween = create_tween()
	tween.tween_property(sprite, "position", dir * 1.0, 0.0)
	tween.tween_interval(0.2)
	tween.tween_property(sprite, "position", Vector2.ZERO, 0.0)

func _process(delta: float) -> void:
	bullets_shot = path[0] + 1
	attack_radius = invManager.get_tower_radius(tower_type, self)
	var rank = get_meta("item_data").get("rank", 1)
	
	
	if holding:
		hold_timer += delta
	
	fire_rate = invManager.get_attack_speed(tower_type, path[1])
	fire_rate *= pow(1.07, rank - 1)
	
	if not get_tree().get_first_node_in_group("start_wave_button").is_paused:
		_timer += delta
		update_target()
		if _timer >= 1.0 / fire_rate and current_target:
			_timer = 0.0
			fire(current_target)
	queue_redraw()
