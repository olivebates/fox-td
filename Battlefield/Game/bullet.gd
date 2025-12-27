class_name BulletBase
extends Area2D

@export var speed: float = 200.0
@export var initial_speed: float = 150.0
@export var homing_strength: float = 8.0
@export var damage: int = 1
@export var lifetime: float = 5.0

var velocity: Vector2 = Vector2.ZERO
var target: Node2D = null
var has_hit: bool = false  # Track if already hit

func _ready() -> void:
	monitoring = true
	body_entered.connect(_on_body_entered)

func find_closest_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return null
	var closest = enemies[0]
	var closest_dist = global_position.distance_squared_to(closest.global_position)
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var dist = global_position.distance_squared_to(enemy.global_position)
		if dist < closest_dist:
			closest = enemy
			closest_dist = dist
	return closest

func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
		return
	
	if has_hit:  # Stop moving after hit
		return
	
	if target and is_instance_valid(target):
		pass
	else:
		target = find_closest_enemy()
	
	if target == null:
		queue_free()
		return
	
	var dir = (target.global_position - global_position).normalized()
	velocity = velocity.lerp(dir * speed, homing_strength * delta)
	global_position += velocity * delta
	
	if velocity.length() > 0:
		rotation = velocity.angle()

func _on_body_entered(body: Node2D) -> void:
	if has_hit:
		return
	if body.is_in_group("enemies"):
		has_hit = true
		apply_damage(body)
		on_hit()

func apply_damage(enemy: Node2D) -> void:
	enemy.take_damage(damage)

func on_hit() -> void:
	queue_free()

func explode_effect() -> void:
	pass
