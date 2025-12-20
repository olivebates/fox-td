extends Node2D

@export var fire_rate: float = 1.0  # shots per second
@export var bullet_scene: PackedScene = preload("uid://ciuly8asijcg5")
@export var attack_radius: float = 32.0

@onready var sprite: Sprite2D = $Sprite2D

var _timer: float = 0.0
var draw_radius: bool = false
var hovered: bool = false
var current_target: Node2D
var pick_radius: float = 4.0

func _ready() -> void:
	create_mouse_area()

func create_mouse_area() -> void:
	var mouse_area = Area2D.new()
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = pick_radius
	shape.shape = circle
	mouse_area.add_child(shape)
	mouse_area.mouse_entered.connect(_on_mouse_entered)
	mouse_area.mouse_exited.connect(_on_mouse_exited)
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

func _exit_tree() -> void:
	hovered = false

func _draw() -> void:
	# Attack radius
	if draw_radius:
		draw_arc(Vector2.ZERO, attack_radius, 0, TAU, 64, Color(1, 0, 0, 0.5), 2.0)
	
	# Inventory-style highlight/border
	if not has_meta("item_data"):
		return
	var data = get_meta("item_data")
	var rank = data.get("rank", 0)
	var border_color = InventoryManager.RANK_COLORS.get(rank, Color(1, 1, 1))
	var base_color = border_color * 0.3
	base_color.a = 1.0
	
	var dragged_data = InventoryManager.get_current_dragged_data(self)
	var is_matching = !dragged_data.is_empty() && data.id == dragged_data.id && data.rank == dragged_data.rank
	var effective_highlight = hovered or is_matching
	var brighten = 1.4 if effective_highlight else 1.0
	var bg_color = base_color * brighten
	
	draw_rect(Rect2(-3.2, -3.2, 6.5, 6.5), border_color, false, 1.0 + (0.5 if effective_highlight else 0.0))
	draw_rect(Rect2(-3, -3, 6, 6), bg_color, true)
	
	if sprite:
		sprite.modulate = Color(brighten, brighten, brighten) if effective_highlight else Color(1, 1, 1)

func update_target() -> void:
	current_target = null
	var min_dist: float = INF
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		var dist = global_position.distance_to(enemy.global_position)
		if dist <= attack_radius && dist < min_dist:
			min_dist = dist
			current_target = enemy

func fire(target: Node2D) -> void:
	var dir = (target.global_position - global_position).normalized()
	sprite.flip_h = dir.x > 0
	var bullet = bullet_scene.instantiate()
	bullet.target = target
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
