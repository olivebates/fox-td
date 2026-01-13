extends tower_base

func _ready() -> void:
	super._ready()

func update_target() -> void:
	current_target = null
	var best_dist := INF
	var best_poisoned_dist := INF
	var poisoned_target: Node2D = null
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy == null or !is_instance_valid(enemy):
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist > attack_radius:
			continue
		var is_poisoned = enemy.has_method("is_poisoned") and enemy.is_poisoned()
		if not is_poisoned and dist < best_dist:
			best_dist = dist
			current_target = enemy
		elif is_poisoned and dist < best_poisoned_dist:
			best_poisoned_dist = dist
			poisoned_target = enemy
	if current_target == null:
		current_target = poisoned_target

func get_effective_stats() -> Dictionary:
	if !has_meta("item_data"):
		return {}
	var data = get_meta("item_data")
	var path_levels = data.get("path", [0, 0, 0])
	var base_stats = InventoryManager.get_tower_stats(tower_type, data.rank, path_levels)
	return _apply_adjacent_buffs(base_stats)

func fire(target: Node2D) -> void:
	if target == null:
		return
	var data = get_meta("item_data")
	var path_levels = data.get("path", [0, 0, 0])
	var stats = get_effective_stats()
	var base_poison = max(1.0, StatsManager.get_global_damage_multiplier())
	var poison_dps = base_poison + float(stats.damage)
	var poison_duration = 4.0 + (float(path_levels[1]) * 4.0)
	var dir = (target.global_position - global_position).normalized()
	sprite.flip_h = dir.x > 0
	for i in stats.bullets:
		var bullet = bullet_scene.instantiate()
		bullet.global_position = global_position
		bullet.target = target
		bullet.damage = 0
		bullet.source_tower = self
		if bullet is PoisonBullet:
			bullet.poison_dps = poison_dps
			bullet.poison_duration = poison_duration
		get_tree().current_scene.add_child(bullet)
