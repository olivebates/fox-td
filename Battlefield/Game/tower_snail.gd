extends tower_base

func _ready() -> void:
	super._ready()

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
	if target == null:
		return
	var directions = [
		Vector2(1,0), Vector2(1,1), Vector2(0,1), Vector2(-1,1),
		Vector2(-1,0), Vector2(-1,-1), Vector2(0,-1), Vector2(1,-1)
	].map(func(d): return d.normalized())
	
	for dir in directions:
		var bullet = bullet_scene.instantiate()
		bullet.global_position = global_position
		bullet.velocity = dir * bullet.initial_speed
		bullet.target = null  # straight shot, no homing
		if has_meta("item_data"):
			var rank = get_meta("item_data").get("rank", 1)
			bullet.damage = InventoryManager.get_damage_calculation(tower_type, rank, 0)
		get_tree().current_scene.add_child(bullet)
	
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(sprite, "scale", Vector2(1, 1), 0.1)
