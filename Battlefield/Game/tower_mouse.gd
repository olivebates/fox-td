extends tower_base

func _ready() -> void:
	super._ready()
	tower_type = "Mouse"  # Or your actual ID

func _process(delta: float) -> void:
	bullets_shot = path[0]+1
	attack_radius = invManager.get_tower_radius(tower_type, self)
	var rank = get_meta("item_data").get("rank", 1)
	fire_rate = invManager.get_attack_speed(tower_type, path[1])
	fire_rate *= pow(1.07, rank - 1)
	
	if not get_tree().get_first_node_in_group("start_wave_button").is_paused:
		_timer += delta
	
	# Always update timer and fire on cooldown, ignoring target
	if _timer >= 1.0 / fire_rate:
		_timer = 0.0
		fire(null)  # Target not used anyway
	
	queue_redraw()

func update_target() -> void:
	current_target = null  # No targeting needed

func fire(_target: Node2D) -> void:
	if !WaveSpawner._is_spawning and get_tree().get_nodes_in_group("enemy").size() == 0:
		return
	for i in bullets_shot:
		var bullet = bullet_scene.instantiate()
		if has_meta("item_data"):
			var rank = get_meta("item_data").get("rank", 1)
			var random_angle = deg_to_rad(randf_range(-10.0, 10.0))
			var direction = Vector2.RIGHT.rotated(rotation + random_angle)
			bullet.velocity = direction * bullet.speed
			bullet.rotation = direction.angle()
			bullet.damage = InventoryManager.get_damage_calculation(tower_type, rank, 0)
			bullet.global_position = global_position
			get_tree().current_scene.add_child(bullet)
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.1)
