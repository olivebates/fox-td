# Mousetower.gd (revised)

extends tower_base


func _ready() -> void:
	super._ready()
	tower_type = "Mouse"

func _process(delta: float) -> void:
	if has_meta("item_data"):
		var stats = get_effective_stats()
		
		bullets_shot = stats.bullets
		attack_radius = stats.range  # Though Mouse uses radius=0+4, likely for other logic
		fire_rate = stats.attack_speed
		
		# Removed: fire_rate *= pow(1.07, rank - 1)  # Not in general stats; add if Mouse-specific
		
	var start_button = get_tree().get_first_node_in_group("start_wave_button")
	if start_button == null or !start_button.is_paused:
		_timer += delta
	
	if _timer >= 1.0 / max(fire_rate, 0.001):
		_timer = 0.0
		fire(null)  # No target needed
	
	queue_redraw()

func update_target() -> void:
	current_target = null

func fire(_target: Node2D) -> void:
	if !WaveSpawner._is_spawning and get_tree().get_nodes_in_group("enemy").size() == 0:
		return
	
	var stats = get_effective_stats()
	var spawn_pos = global_position
	var path_target = _get_nearest_path_object(attack_radius)
	if path_target != null:
		spawn_pos = path_target.global_position
	
	for i in bullets_shot:
		var bullet = bullet_scene.instantiate()
		var random_angle = deg_to_rad(randf_range(-10.0, 10.0))
		var direction = Vector2.RIGHT.rotated(rotation + random_angle)
		bullet.velocity = direction * bullet.speed
		bullet.rotation = direction.angle()
		bullet.damage = stats.damage
		bullet.global_position = spawn_pos
		get_tree().current_scene.add_child(bullet)
	
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.1)

func _get_nearest_path_object(max_dist: float) -> Node2D:
	var objects = get_tree().get_nodes_in_group("path_object")
	if objects.is_empty():
		return null
	var max_dist_sq = max_dist * max_dist
	var closest: Node2D = null
	var closest_dist = max_dist_sq
	for obj in objects:
		if obj == null or !is_instance_valid(obj):
			continue
		var dist = global_position.distance_squared_to(obj.global_position)
		if dist <= closest_dist:
			closest = obj
			closest_dist = dist
	return closest
