extends CharacterBody2D
class_name tower_base

class ColorDots:
	extends Node2D
	var colors: Array = []
	func set_colors(new_colors: Array) -> void:
		colors = new_colors.duplicate()
		queue_redraw()
	func _draw() -> void:
		var dot_pos = Vector2(-2.8, -2.8)
		for color_name in colors:
			draw_circle(dot_pos, 0.6, InventoryManager.get_color_value(color_name))
			dot_pos.x += 1.5

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
var rank
var bullets_shot = 1
var path = [0,0,0]

var cooldown_time: float = 0.0
const BASE_MOVE_COOLDOWN := 4.0
var max_cooldown: float = BASE_MOVE_COOLDOWN
const TARGET_UPDATE_INTERVAL := 0.1
var _target_update_accum: float = 0.0
var _cached_stats: Dictionary = {}
var _effective_stats: Dictionary = {}
var _last_rank: int = -1
var _last_path: Array = []
var _last_tower_type = null
var _last_colors: Array = []
var color_dots: ColorDots = null

func start_cooldown() -> void:
	max_cooldown = BASE_MOVE_COOLDOWN * StatsManager.get_tower_move_cooldown_multiplier()
	cooldown_time = max_cooldown
	if draw_radius or cooldown_time > 0:
		queue_redraw()

func _ready() -> void:
	if has_meta("item_data"):
		var data = get_meta("item_data")
		tower_type = data.id
		rank = data.get("rank", 1)
		path = data.get("path", [0, 0, 0])
		var item_def = invManager.items[tower_type]
		bullet_scene = item_def.bullet
		sprite.texture = item_def.texture
	if has_node("ColorDots"):
		color_dots = get_node("ColorDots")
	else:
		color_dots = ColorDots.new()
		color_dots.name = "ColorDots"
		color_dots.z_index = 1
		add_child(color_dots)
		
		
	#mouse_exited.connect(_on_mouse_exited)
#
#func _on_mouse_exited() -> void:
	#TooltipManager.hide_tooltip()

func is_mouse_over() -> bool:
	return get_global_mouse_position().distance_to(global_position) < pick_radius

func _input(event: InputEvent) -> void:
	if (get_tree().get_nodes_in_group("upgrade_scene").size() > 0):
		return
	
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
	var rarity = invManager.items.get(data.id, {}).get("rarity", 0)
	var border_color = InventoryManager.RANK_COLORS.get(rarity, Color(0.192, 1.0, 1.0, 1.0))
	var base_color = border_color * 0.3
	base_color.a = 1.0
	var brighten = 1.5 if hovered else 1.0
	draw_rect(Rect2(-3.2, -3.2, 6.5, 6.5), border_color, false, 1.0 + (0.5 if hovered else 0.0))
	draw_rect(Rect2(-3, -3, 6, 6), base_color * brighten, true)
	var colors: Array = data.get("colors", [])
	if color_dots != null and colors != _last_colors:
		color_dots.set_colors(colors)
		_last_colors = colors.duplicate()
	var triangle_count = min(rank, InventoryManager.MAX_MERGE_RANK)
	for i in range(triangle_count):
		var offset = Vector2(-2.8 + i * 1.5, 3.8)
		draw_colored_polygon(PackedVector2Array([offset + Vector2(0, -2.0), offset + Vector2(1.4, 0.2), offset + Vector2(-0.9, 0.2)]), Color(0, 0, 0, 1))
		draw_colored_polygon(PackedVector2Array([offset + Vector2(0, -1.5), offset + Vector2(1, 0), offset + Vector2(-0.5, 0)]), Color(0.98, 0.98, 0, 1))
	
	if cooldown_time > 0:
		var ratio = cooldown_time / max_cooldown
		#draw_circle(Vector2.ZERO, 10.0, Color(0, 0, 0, 0.5))  # adjust radius
		draw_arc(Vector2.ZERO, 4.0, -TAU/4, -TAU/4 + ratio * TAU, 64, Color(0, 0, 0, 0.8), 4.0)  # clockwise fill

func update_target() -> void:
	current_target = null
	var min_dist: float = INF
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		var dist = global_position.distance_to(enemy.global_position)
		if dist <= attack_radius and dist < min_dist:
			min_dist = dist
			current_target = enemy

func _apply_adjacent_buffs(stats: Dictionary) -> Dictionary:
	if stats.is_empty():
		return stats
	var grid_controller = get_node_or_null("/root/GridController")
	if grid_controller == null:
		return stats
	var own_cell: Vector2i = grid_controller.get_cell_from_pos(global_position)
	if own_cell == Vector2i(-1, -1):
		return stats
	var offsets = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	var damage_mult = 1.0
	var speed_mult = 1.0
	var range_bonus = 0.0
	var starfish_def: Dictionary = {}
	var inv = get_node_or_null("/root/InventoryManager")
	if inv:
		var items = inv.get("items")
		if typeof(items) == TYPE_DICTIONARY:
			starfish_def = items.get(InventoryManager.ADJACENT_BUFF_TOWER_ID, {})
	var base_speed_bonus = float(starfish_def.get("adjacent_speed_bonus", InventoryManager.STARFISH_BASE_SPEED_BONUS))
	var base_damage_bonus = float(starfish_def.get("adjacent_damage_bonus", 0.0))
	var base_range_bonus = float(starfish_def.get("adjacent_range_bonus", 0.0))
	for off in offsets:
		var cell = own_cell + off
		if cell.x < 0 or cell.x >= GridController.WIDTH or cell.y < 0 or cell.y >= GridController.HEIGHT:
			continue
		var neighbor = grid_controller.get_grid_item_at_cell(cell)
		if neighbor == null or !neighbor.has_meta("item_data"):
			continue
		var neighbor_data = neighbor.get_meta("item_data")
		if str(neighbor_data.get("id", "")) != InventoryManager.ADJACENT_BUFF_TOWER_ID:
			continue
		var path_levels = neighbor_data.get("path", [0, 0, 0])
		damage_mult *= 1.0 + base_damage_bonus + (InventoryManager.STARFISH_DAMAGE_PER_LEVEL * float(path_levels[1]))
		var speed_bonus = base_speed_bonus + (InventoryManager.STARFISH_SPEED_PER_LEVEL * float(path_levels[0]))
		speed_mult *= 1.0 + speed_bonus
		range_bonus += (base_range_bonus + float(path_levels[2])) * 8.0
	if damage_mult != 1.0:
		if stats.has("damage") and stats.damage != -1:
			stats.damage *= damage_mult
		if stats.has("creature_damage") and stats.creature_damage != -1:
			stats.creature_damage *= damage_mult
	if speed_mult != 1.0:
		if stats.has("attack_speed") and stats.attack_speed != -1:
			stats.attack_speed *= speed_mult
		if stats.has("creature_attack_speed") and stats.creature_attack_speed != -1:
			stats.creature_attack_speed *= speed_mult
	if range_bonus != 0.0 and stats.has("range") and stats.range != -1:
		stats.range += range_bonus
	return stats

func get_effective_stats() -> Dictionary:
	if !has_meta("item_data"):
		return {}
	var data = get_meta("item_data")
	if data.rank != _last_rank or path != _last_path or tower_type != _last_tower_type:
		_cached_stats = InventoryManager.get_tower_stats(tower_type, data.rank, path)
		_last_rank = data.rank
		_last_path = path.duplicate()
		_last_tower_type = tower_type
	_effective_stats = _apply_adjacent_buffs(_cached_stats.duplicate())
	return _effective_stats

func _process(delta: float) -> void:
	if not has_meta("item_data"): return
	var stats = get_effective_stats()
	bullets_shot = stats.bullets
	fire_rate = stats.attack_speed
	attack_radius = stats.range
	if holding:
		hold_timer += delta
		
	if cooldown_time > 0:
		cooldown_time -= delta
		if cooldown_time <= 0:
			cooldown_time = 0
		var enemies = get_tree().get_nodes_in_group("enemy").size() > 0
		if (WaveSpawner._is_spawning or enemies):
			pass  # keep cooldown
		else:
			cooldown_time = 0
		
	var start_button = get_tree().get_first_node_in_group("start_wave_button")
	if start_button == null or !start_button.is_paused:
		_timer += delta
	_target_update_accum += delta
	if _target_update_accum >= TARGET_UPDATE_INTERVAL:
		_target_update_accum = 0.0
		update_target()
	if _timer >= 1.0 / fire_rate and current_target and cooldown_time <= 0:
		_timer = 0.0
		fire(current_target)
	queue_redraw()

func fire(target: Node2D) -> void:
	var dir = (target.global_position - global_position).normalized()
	sprite.flip_h = dir.x > 0
	var stats = get_effective_stats()
	var damage = stats.damage
	for i in bullets_shot:
		var bullet = bullet_scene.instantiate()
		bullet.target = target
		bullet.damage = damage
		bullet.source_tower = self
		if stats.has("explosion_radius"):
			if stats.explosion_radius != -1:
				bullet.explosion_radius = int(stats.explosion_radius)
		bullet.global_position = global_position
		get_tree().current_scene.add_child(bullet)
	var tween = create_tween()
	tween.tween_property(sprite, "position", dir * 1.0, 0.0)
	tween.tween_interval(0.2)
	tween.tween_property(sprite, "position", Vector2.ZERO, 0.0)
