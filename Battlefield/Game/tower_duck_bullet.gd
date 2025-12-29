# ExplosiveBullet.gd
class_name ExplosiveBullet
extends BulletBase

@export var explosion_radius: float = 10.0
@onready var explosion_area: Area2D = Area2D.new()
@onready var explosion_shape: CollisionShape2D = CollisionShape2D.new()


func _ready() -> void:
	super._ready()
	add_child(explosion_area)
	explosion_area.add_child(explosion_shape)
	var circle = CircleShape2D.new()
	explosion_shape.shape = circle
	
	# Fetch upgraded radius if not set
	if explosion_radius <= 0:
		var tower = get_parent()  # Tower that fired the bullet
		if tower and tower.has_meta("item_data"):
			var stats = InventoryManager.get_tower_stats(
				tower.tower_type,
				tower.get_meta("item_data").rank,
				tower.path
			)
			explosion_radius = stats.explosion_radius
	
	circle.radius = explosion_radius
	
	explosion_area.monitoring = false
	explosion_area.monitorable = false

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		on_hit()

func on_hit() -> void:
	explosion_area.monitoring = true
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	var enemies_hit: int = 0
	for body in explosion_area.get_overlapping_bodies():
		if body.is_in_group("enemies") and enemies_hit < 7:
			apply_damage(body)
			enemies_hit += 1
	
	explode_effect()
	queue_free()

func explode_effect() -> void:
	pass

func _draw() -> void:
	draw_circle(Vector2.ZERO, explosion_radius, Color(1, 0, 0, 0.3))
	draw_arc(Vector2.ZERO, explosion_radius, 0, TAU, 64, Color(1, 0.5, 0, 0.8), 0.2)
