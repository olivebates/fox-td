extends StaticBody2D

@onready var sprite: Sprite2D = $Sprite2D
var invManager = InventoryManager
var _timer: float = 0.0
var draw_radius: bool = false
var hovered: bool = false
var current_target: Node2D = null
var pick_radius: float = 4.0
var mouse_area: Area2D
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
		tower_level = item_def.tower_level
		fire_rate = item_def.attack_speed
		bullet_scene = item_def.bullet
		attack_radius = item_def.radius
		var rank = data.get("rank", 1)
		fire_rate *= pow(1.07, rank - 1)
		attack_radius *= pow(1.07, rank - 1)
		sprite.texture = item_def.texture
	create_mouse_area()

func create_mouse_area() -> void:
	mouse_area = Area2D.new()
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = pick_radius
	shape.shape = circle
	mouse_area.add_child(shape)
	mouse_area.mouse_entered.connect(_on_mouse_entered)
	mouse_area.mouse_exited.connect(_on_mouse_exited)
	mouse_area.input_event.connect(_on_mouse_input)
	add_child(mouse_area)

func _on_mouse_entered() -> void:
	draw_radius = true
	#if has_meta("item_data") and not InventoryManager.get_current_dragged_data().is_empty() == false:
		#var data = get_meta("item_data")
		#var rank = data.get("rank", 1)
		#var cost = InventoryManager.get_spawn_cost(rank)
		#InventoryManager.HealthBarGUI.show_cost_preview(cost)
	queue_redraw()

func _on_mouse_exited() -> void:
	draw_radius = false
	if has_meta("item_data"):
		InventoryManager.HealthBarGUI.hide_cost_preview()
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		hovered = get_global_mouse_position().distance_to(global_position) < pick_radius
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and holding:
			# Mouse moved while holding -> cancel upgrade
			holding = false
			hold_timer = 0.0
			queue_redraw()
			InventoryManager.HealthBarGUI.hide_cost_preview()
		queue_redraw()

func _on_mouse_input(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if has_meta("item_data"):
				var data = get_meta("item_data")
				var rank = data.get("rank", 1)
				upgrade_cost = InventoryManager.get_spawn_cost(rank)
				holding = true
				hold_timer = 0.0
				# Allow drag attempt
				var grid_controller = get_node("/root/GridController")
				if grid_controller:
					grid_controller.start_tower_drag(self, global_position - get_global_mouse_position())
				get_viewport().set_input_as_handled()
		#else:
			#holding = false
			#hold_timer = 0.0
			#queue_redraw()
			#if has_meta("item_data"):
				#InventoryManager.HealthBarGUI.hide_cost_preview()

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
	
	var dragged_data = InventoryManager.get_current_dragged_data(self)
	var is_matching = !dragged_data.is_empty() && data.id == dragged_data.id && data.rank == dragged_data.rank
	var merge_cost = InventoryManager.get_merge_cost(rank) if is_matching else 0.0
	var can_afford_merge = StatsManager.health >= merge_cost
	
	var upgrade_mode_active = get_tree().get_nodes_in_group("upgrade_button").any(func(b): return b is Button and b.upgrade_mode)
	var can_afford_upgrade = InventoryManager.get_spawn_cost(rank) <= StatsManager.health
	
	# Blink control
	var blink_on = InventoryManager._merge_blink_state if (is_matching and can_afford_merge) else true
	var should_highlight = hovered or (is_matching and can_afford_merge)
	
	var brighten = 1.5 if should_highlight else 1.0
	
	
	if upgrade_mode_active:
		brighten = 1.5
		if can_afford_upgrade:
			# Blink in upgrade mode when affordable
			brighten = 1.5 if blink_on else 1.2
			sprite.modulate = Color(1.106, 2.0, 1.03, 1.0) if blink_on else Color(0.9, 1.6, 0.8, 1.0)
		else:
			sprite.modulate = Color(2.0, 0.0, 0.0, 1.0)
	#else:
		#sprite.modulate = Color(brighten, brighten, brighten) if should_highlight else Color(1, 1, 1)
	
	
	if cost_label.visible: 
		border_color = Color.YELLOW
		base_color = Color.YELLOW
	
	draw_rect(Rect2(-3.2, -3.2, 6.5, 6.5), border_color, false, 1.0 + (0.5 if should_highlight else 0.0))
	draw_rect(Rect2(-3, -3, 6, 6), base_color * brighten, true)
	
	var rarity = invManager.items[data.id].rarity
	for i in range(rarity):
		var offset = Vector2(-2.8 + i * 1.5, 3.8)
		draw_colored_polygon(PackedVector2Array([offset + Vector2(0, -2.0), offset + Vector2(1.4, 0.2), offset + Vector2(-0.9, 0.2)]), Color(0, 0, 0, 1))
		draw_colored_polygon(PackedVector2Array([offset + Vector2(0, -1.5), offset + Vector2(1, 0), offset + Vector2(-0.5, 0)]), Color(0.98, 0.98, 0, 1))
	
	
	#if holding and hold_timer > 0:
		#var progress = min(hold_timer / 2.0, 1.0)
		#var bar_color = Color(0, 1, 1) if StatsManager.health >= upgrade_cost else Color(1, 0.2, 0.2)
		#draw_rect(Rect2(-4, 3, 8, 1), Color(0.2, 0.2, 0.2))
		#draw_rect(Rect2(-4, 3, 8 * progress, 1), bar_color)
	
	
	#upgrade_mode_active = get_tree().get_first_node_in_group("upgrade_button").upgrade_mode
	#if has_meta("item_data") and upgrade_mode_active:
		#var my_rank = get_meta("item_data").get("rank", 1)
		#var cost = InventoryManager.get_spawn_cost(my_rank)
		#cost_label.text = str(int(cost))
		#cost_label.visible = true
	#else:
		#cost_label.visible = false
	

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
		bullet.damage *= pow(2, rank - 1) + rank - 1
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
	# Hold-to-upgrade works even when paused
	#if holding and has_meta("item_data"):
		#var data = get_meta("item_data")
		#var rank = data.get("rank", 1)
		#upgrade_cost = InventoryManager.get_spawn_cost(rank)
		#
		#hold_timer += delta
		#if upgrade_cost > 0:
			#InventoryManager.HealthBarGUI.show_cost_preview(upgrade_cost)
		#queue_redraw()
		#
		#if hold_timer >= 2.0:
			#if StatsManager.health >= upgrade_cost:
				#StatsManager.spend_health(upgrade_cost)
				#data.rank += 1
				#set_meta("item_data", data)
				#_ready()
				#queue_redraw()
				#Utilities.spawn_floating_text("Rank up!", global_position + Vector2(0, 8), get_tree().current_scene, true)
			#else:
				#Utilities.spawn_floating_text("Not enough meat", global_position + Vector2(0, 8), get_tree().current_scene, false)
			#holding = false
			#hold_timer = 0.0
			#InventoryManager.HealthBarGUI.hide_cost_preview()
			
