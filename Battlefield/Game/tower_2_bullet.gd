# ExplosiveBullet.gd
extends Area2D
class_name ExplosiveBullet

@export var speed: float = 200.0
@export var initial_speed: float = 150.0
@export var homing_strength: float = 8.0
@export var explosion_radius: float = 8.0
@export var explosion_damage: int = 20
@export var max_hits: int = 7
@export var lifetime: float = 5.0

var velocity: Vector2 = Vector2.ZERO
var target: Node2D
var exploded: bool = false

func _ready():
	monitoring = true
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
		return
	
	if exploded:
		return
	
	if target and is_instance_valid(target):
		var dir = (target.global_position - global_position).normalized()
		velocity = velocity.lerp(dir * speed, homing_strength * delta)
	else:
		velocity = velocity.normalized() * speed
	
	global_position += velocity * delta
	
	if velocity.length() > 0:
		rotation = velocity.angle()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and not exploded:
		explode()

func explode() -> void:
	exploded = true
	
	var enemies = get_tree().get_nodes_in_group("enemies")
	var candidates: Array[Node2D] = []
	for enemy in enemies:
		var dist = global_position.distance_to(enemy.global_position)
		if dist <= explosion_radius:
			candidates.append(enemy)
	
	candidates.sort_custom(func(a, b):
		return global_position.distance_to(a.global_position) < global_position.distance_to(b.global_position)
	)
	
	for i in range(min(max_hits, candidates.size())):
		candidates[i].take_damage(explosion_damage)
	
	# Circular explosion visual, visible for 0.5s
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.5)
	tw.tween_callback(queue_free)
	
	queue_redraw()

func _draw():
	if exploded:
		draw_circle(Vector2.ZERO, explosion_radius * 2, Color(1.0, 0.4, 0.0, 0.3))
