extends tower_base

func _ready() -> void:
	super._ready()

func fire(target: Node2D) -> void:
	if target == null:
		return
	var stats = get_effective_stats()
	var dir = (target.global_position - global_position).normalized()
	sprite.flip_h = dir.x > 0
	for i in stats.bullets:
		var bullet = bullet_scene.instantiate()
		bullet.global_position = global_position
		bullet.target = target
		bullet.damage = stats.damage
		bullet.source_tower = self
		if bullet is ChainBullet:
			bullet.chain_range = attack_radius
		get_tree().current_scene.add_child(bullet)
