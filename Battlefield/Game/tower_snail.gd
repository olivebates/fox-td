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
	
	if !has_meta("item_data"):
		return
	var item = get_meta("item_data")
	var path_levels = item.get("path", [0,0,0])
	var stats = InventoryManager.get_tower_stats(tower_type, item.rank, path_levels)
	
	var bullet_count = stats.bullets
	var attack_speed = stats.attack_speed  # Use for fire rate elsewhere if needed
	
	# For omnidirectional towers like Snail/Porcupine
	var directions = [
		Vector2(1,0), Vector2(1,1), Vector2(0,1), Vector2(-1,1),
		Vector2(-1,0), Vector2(-1,-1), Vector2(0,-1), Vector2(1,-1)
	].map(func(d): return d.normalized())
	
	for i in bullet_count:
		var dir = directions[i % directions.size()] if bullet_count <= 8 else directions[0].rotated(i * PI * 2 / bullet_count)
		var bullet = bullet_scene.instantiate()
		bullet.global_position = global_position
		bullet.velocity = dir * bullet.initial_speed
		bullet.target = null
		bullet.damage = stats.damage
		get_tree().current_scene.add_child(bullet)
	
	# Recoil effect
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(sprite, "scale", Vector2(1, 1), 0.1)
