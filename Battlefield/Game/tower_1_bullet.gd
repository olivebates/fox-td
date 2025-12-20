# Bullet.gd (attach to Area2D scene with CollisionShape2D child, e.g. CircleShape2D r=2)
extends Area2D
class_name Bullet

@export var speed: float = 200.0
@export var initial_speed: float = 150.0
@export var homing_strength: float = 8.0
@export var damage: int = 10
@export var lifetime: float = 5.0

var velocity: Vector2 = Vector2.ZERO
var target: Node2D

func _ready():
	monitoring = true
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
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
	if body.is_in_group("enemies"):
		body.take_damage(damage)
		queue_free()
