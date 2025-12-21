# BulletBase.gd (Script, not attached to scene)
class_name BulletBase
extends Area2D

@export var speed: float = 200.0
@export var initial_speed: float = 150.0
@export var homing_strength: float = 8.0
@export var damage: int = 1
@export var lifetime: float = 5.0

var velocity: Vector2 = Vector2.ZERO
var target: Node2D = null

func _ready() -> void:
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
		apply_damage(body)
		on_hit()

func apply_damage(enemy: Node2D) -> void:
	enemy.take_damage(damage)

func on_hit() -> void:
	queue_free()  # default: single hit then die

func explode_effect() -> void:
	pass  # override in subclasses
