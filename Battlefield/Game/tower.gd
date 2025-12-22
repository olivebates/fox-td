extends Node2D

@export var fire_rate: float = 1.0  # base shots per second
@export var bullet_scene: PackedScene = preload("uid://ciuly8asijcg5")
@export var attack_radius: float = 32.0  # base radius

@onready var sprite: Sprite2D = $Sprite2D

var _timer: float = 0.0
var draw_radius: bool = false
var hovered: bool = false
var current_target: Node2D = null
var pick_radius: float = 4.0  # increased for better clicking

var mouse_area: Area2D

func _ready() -> void:
	create_mouse_area()
	if has_meta("item_data"):
		var data = get_meta("item_data")
		var rank = data.get("rank", 0)
		fire_rate *= pow(1.07, rank)
		attack_radius *= pow(1.07, rank)

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
	queue_redraw()

func _on_mouse_exited() -> void:
	draw_radius = false
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		hovered = get_global_mouse_position().distance_to(global_position) < pick_radius
		queue_redraw()

func _on_mouse_input(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
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
	
	var dragged_data = InventoryManager.get_current_dragged_data(self)
	var is_matching = !dragged_data.is_empty() && data.id == dragged_data.id && data.rank == dragged_data.rank
	var blink_on = InventoryManager._merge_blink_state if is_matching else true
	var effective_highlight = hovered or (is_matching and blink_on)
	var brighten = 1.2 if effective_highlight else 1.0
	var bg_color = base_color * brighten
	
	draw_rect(Rect2(-3.2, -3.2, 6.5, 6.5), border_color, false, 1.0)
	draw_rect(Rect2(-3, -3, 6, 6), bg_color, true)
	
	if sprite:
		sprite.modulate = Color(brighten, brighten, brighten) if effective_highlight else Color(1, 1, 1)

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
		bullet.damage *= pow(2, rank - 1)  # damage doubles per rank
	
	var rand_dir = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
	bullet.velocity = rand_dir * bullet.initial_speed
	bullet.global_position = global_position
	get_tree().current_scene.add_child(bullet)
	
	var tween = create_tween()
	tween.tween_property(sprite, "position", dir * 1.0, 0.0)
	tween.tween_interval(0.2)
	tween.tween_property(sprite, "position", Vector2.ZERO, 0.0)

func _process(delta: float) -> void:
	_timer += delta
	update_target()
	if _timer >= 1.0 / fire_rate and current_target:
		_timer = 0.0
		fire(current_target)
