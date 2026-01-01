# MineBullet.gd - Fade only the Sprite2D child
extends BulletBase
class_name MineBullet

@onready var sprite: Sprite2D = $Sprite2D
var damaged_enemies: Array[Node2D] = []
var hit_count: int = 0

func _ready() -> void:
	lifetime = 1
	velocity = Vector2.ZERO
	monitoring = true
	body_entered.connect(_on_body_entered)
	
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 2.0).set_delay(lifetime - 2.0)
	tween.tween_callback(queue_free)

func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body not in damaged_enemies:
		apply_damage(body)
		damaged_enemies.append(body)
		hit_count += 1
		if hit_count >= 3:
			queue_free()
