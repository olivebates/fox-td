# Mousetower.gd (revised)

extends tower_base


func _ready() -> void:
	super._ready()
	tower_type = "Mouse"

func _process(delta: float) -> void:
	if has_meta("item_data"):
		var item_data = get_meta("item_data")
		var rank = item_data.get("rank", 1)
		var path = item_data.get("path", [0, 0, 0])  # [bullets_path, damage_path, attack_speed_path]
		
		var stats = invManager.get_tower_stats(tower_type, rank, path)
		
		bullets_shot = stats.bullets
		attack_radius = stats.range  # Though Mouse uses radius=0+4, likely for other logic
		fire_rate = stats.attack_speed
		
		# Removed: fire_rate *= pow(1.07, rank - 1)  # Not in general stats; add if Mouse-specific
		
	if not get_tree().get_first_node_in_group("start_wave_button").is_paused:
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
	
	var item_data = get_meta("item_data")
	var rank = item_data.get("rank", 1)
	var path = item_data.get("path", [0, 0, 0])
	var stats = invManager.get_tower_stats(tower_type, rank, path)
	
	for i in bullets_shot:
		var bullet = bullet_scene.instantiate()
		var random_angle = deg_to_rad(randf_range(-10.0, 10.0))
		var direction = Vector2.RIGHT.rotated(rotation + random_angle)
		bullet.velocity = direction * bullet.speed
		bullet.rotation = direction.angle()
		bullet.damage = stats.damage
		bullet.global_position = global_position
		get_tree().current_scene.add_child(bullet)
	
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.1)
