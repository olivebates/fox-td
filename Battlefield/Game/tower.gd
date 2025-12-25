extends CharacterBody2D

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

# Upgrade hold variables
var hold_timer: float = 0.0
var holding: bool = false
var upgrade_cost: float = 0.0
@onready var cost_label = $UpgradeCost

func _ready() -> void:
	if has_meta("item_data"):
		var data = get_meta("item_data")
		var item_def = invManager.items[data.id]
		tower_level = item_def.get("tower_level", 0)
		fire_rate = item_def.attack_speed
		bullet_scene = item_def.bullet
		attack_radius = item_def.radius
		var rank = data.get("rank", 1)
		fire_rate *= pow(1.07, rank - 1)
		attack_radius *= pow(1.07, rank - 1)
		sprite.texture = item_def.texture

func is_mouse_over() -> bool:
	return get_global_mouse_position().distance_to(global_position) < pick_radius

func _input(event: InputEvent) -> void:
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
		
		if holding and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			holding = false
			hold_timer = 0.0
			InventoryManager.HealthBarGUI.hide_cost_preview()
			queue_redraw()
	
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if mouse_over and has_meta("item_data"):
			var data = get_meta("item_data")
			var rank = data.get("rank", 1)
			upgrade_cost = InventoryManager.get_spawn_cost(rank)
			holding = true
			hold_timer = 0.0
			var grid_controller = get_node("/root/GridController")
			if grid_controller:
				grid_controller.start_tower_drag(self, global_position - get_global_mouse_position())
			get_viewport().set_input_as_handled()

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
	var bullet = bullet_scene.instantiate()
	bullet.target = target
	if has_meta("item_data"):
		var rank = get_meta("item_data").get("rank", 0)
		bullet.damage = get_meta("item_data").get("damage", 1)
		bullet.damage *= InventoryManager.get_damage_calculation(rank)
	var rand_dir = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
	bullet.velocity = rand_dir * bullet.initial_speed
	bullet.global_position = global_position
	get_tree().current_scene.add_child(bullet)
	
	var tween = create_tween()
	tween.tween_property(sprite, "position", dir * 1.0, 0.0)
	tween.tween_interval(0.2)
	tween.tween_property(sprite, "position", Vector2.ZERO, 0.0)

func _process(delta: float) -> void:
	# Shooting and targeting respect pause
	if not get_tree().get_first_node_in_group("start_wave_button").is_paused:
		_timer += delta
		update_target()
		if _timer >= 1.0 / fire_rate and current_target:
			_timer = 0.0
			fire(current_target)
	
	queue_redraw()
