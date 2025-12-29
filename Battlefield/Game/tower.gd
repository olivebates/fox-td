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
var attack_radius: float = 20.0
var tower_level: float = 0
var pause_function = false
var tower_type
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
		tower_type = data.id
		rank = data.get("rank", 1)
		path = data.get("path", [0, 0, 0])
		var item_def = invManager.items[tower_type]
		bullet_scene = item_def.bullet
		sprite.texture = item_def.texture

func is_mouse_over() -> bool:
	return get_global_mouse_position().distance_to(global_position) < pick_radius

func _input(event: InputEvent) -> void:
	if pause_function: return
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
			var item_with_path = data.duplicate()
			item_with_path["path"] = path
			var cost = InventoryManager.get_placement_cost(data.id, tower_level, data.rank)
			InventoryManager.show_tower_tooltip(item_with_path, cost)
			TooltipManager.append_to_current_tooltip("\n[font_size=2][color=dark_gray]Click to upgrade[/color][/font_size]")
		elif not hovered and was_hovered:
			TooltipManager.hide_tooltip()
		if holding:
			holding = false
			hold_timer = 0.0
			InventoryManager.HealthBarGUI.hide_cost_preview()
			queue_redraw()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if mouse_over and has_meta("item_data"):
				holding = true
				hold_timer = 0.0
				var data = get_meta("item_data")
				upgrade_cost = InventoryManager.get_placement_cost(data.id, tower_level, data.get("rank", 1))
				var grid_controller = get_node("/root/GridController")
				if grid_controller:
					grid_controller.start_tower_drag(self, global_position - get_global_mouse_position())
				get_viewport().set_input_as_handled()
		else:
			if holding and mouse_over:
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
	if not has_meta("item_data"): return
	var data = get_meta("item_data")
	var rank = int(data.get("rank", 0))
	var border_color = InventoryManager.RANK_COLORS.get(rank, Color(0.192, 1.0, 1.0, 1.0))
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

func _process(delta: float) -> void:
	if not has_meta("item_data"): return
	var data = get_meta("item_data")
	var stats = InventoryManager.get_tower_stats(tower_type, data.rank, path)
	bullets_shot = stats.bullets
	fire_rate = stats.attack_speed
	attack_radius = stats.range
	if holding:
		hold_timer += delta
	if not get_tree().get_first_node_in_group("start_wave_button").is_paused:
		_timer += delta
	update_target()
	if _timer >= 1.0 / fire_rate and current_target:
		_timer = 0.0
		fire(current_target)
	queue_redraw()

func fire(target: Node2D) -> void:
	var dir = (target.global_position - global_position).normalized()
	sprite.flip_h = dir.x > 0
	var stats = InventoryManager.get_tower_stats(tower_type, get_meta("item_data").rank, path)
	var damage = stats.damage
	for i in bullets_shot:
		var bullet = bullet_scene.instantiate()
		bullet.target = target
		bullet.damage = damage
		if stats.has("explosion_radius"):
			bullet.explosion_radius = stats.explosion_radius
		bullet.global_position = global_position
		get_tree().current_scene.add_child(bullet)
	var tween = create_tween()
	tween.tween_property(sprite, "position", dir * 1.0, 0.0)
	tween.tween_interval(0.2)
	tween.tween_property(sprite, "position", Vector2.ZERO, 0.0)
