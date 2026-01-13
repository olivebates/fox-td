# Elephant.gd - Updated fire() with shooting animation
extends tower_base

# Elephant.gd - Updated fire()
func fire(target: Node2D) -> void:
	var stats = get_effective_stats()
	var dir = (target.global_position - global_position).normalized()
	sprite.flip_h = dir.x > 0
	
	var own_cell: Vector2i = GridController.get_cell_from_pos(global_position)
	if own_cell == Vector2i(-1, -1):
		return
	
	var target_cell: Vector2i = GridController.get_cell_from_pos(target.global_position)
	if target_cell == Vector2i(-1, -1):
		return
	
	var target_pos: Vector2 = GridController.grid_offset + Vector2(
		target_cell.x * GridController.CELL_SIZE + GridController.CELL_SIZE / 2,
		target_cell.y * GridController.CELL_SIZE + GridController.CELL_SIZE / 2
	)
	
	var dist_to_target_pos = global_position.distance_to(target_pos)
	if dist_to_target_pos > stats.range:
		return
	
	for i in stats.bullets:
		# Recoil animation
		var tween = create_tween()
		tween.tween_property(sprite, "position", dir * 4.0, 0.05)
		tween.tween_property(sprite, "position", Vector2.ZERO, 0.15)
		
		# Place mine
		var mine = bullet_scene.instantiate()
		mine.global_position = target_pos
		mine.damage = stats.damage
		get_tree().current_scene.add_child(mine)
		
		# Delay next bullet
		if i < stats.bullets - 1:
			await get_tree().create_timer(0.2).timeout
