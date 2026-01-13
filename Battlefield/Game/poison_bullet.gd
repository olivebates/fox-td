extends BulletBase
class_name PoisonBullet

@export var poison_dps: float = 1.0
@export var poison_duration: float = 3.0

func _on_body_entered(body: Node2D) -> void:
	if has_hit:
		return
	if body.is_in_group("enemies"):
		has_hit = true
		apply_damage(body)
		if body.has_method("apply_poison"):
			body.apply_poison(poison_dps, poison_duration)
		on_hit()
