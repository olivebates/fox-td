extends tower_base
class_name tower_sniper

var burst_delay: float = 0.15
var burst_timer: float = 0.0
var is_bursting: bool = false
var bullets_left: int = 0
var burst_target: Node2D = null

func _ready() -> void:
	super._ready()

func update_target() -> void:
	current_target = null
	var max_dist: float = 0.0
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		var dist = global_position.distance_to(enemy.global_position)
		if dist <= attack_radius and dist > max_dist:
			max_dist = dist
			current_target = enemy

func fire(target: Node2D) -> void:
	if target == null:
		return
	
	var dir = (target.global_position - global_position).normalized()
	sprite.flip_h = dir.x > 0
	
	for i in bullets_shot:
		var bullet = bullet_scene.instantiate()
		bullet.global_position = global_position
		bullet.target = target
		
		if has_meta("item_data"):
			var rank = get_meta("item_data").get("rank", 1)
			bullet.damage = InventoryManager.get_damage_calculation(tower_type, rank, 0)
		
		# Fixed: use dir as base, small random spread
		var spread = 0.2
		var rand_offset = Vector2(randf_range(-spread, spread), randf_range(-spread, spread))
		bullet.velocity = (dir + rand_offset).normalized() * bullet.initial_speed
		
		get_tree().current_scene.add_child(bullet)
	
	# Recoil animation
	var tween = create_tween()
	tween.tween_property(sprite, "position", dir * -2.0, 0.1)  # recoil back
	tween.tween_property(sprite, "position", Vector2.ZERO, 0.2)

func _fire_single(t: Node2D) -> void:
	if not is_instance_valid(t):
		return
	var dir = (t.global_position - global_position).normalized()
	var bullet = bullet_scene.instantiate()
	bullet.global_position = global_position
	bullet.velocity = dir * bullet.initial_speed
	bullet.target = t
	bullet.source_tower = self
	if has_meta("item_data"):
		var rank = get_meta("item_data").get("rank", 1)
		bullet.damage = InventoryManager.get_damage_calculation(tower_type, rank, 0)
	get_tree().current_scene.add_child(bullet)
	sprite.flip_h = dir.x > 0
	var tween = create_tween()
	tween.tween_property(sprite, "position:x", sign(dir.x) * 2.0, 0.05)
	tween.tween_property(sprite, "position:x", 0.0, 0.1)

func _process(delta: float) -> void:
	super._process(delta)
	if is_bursting:
		burst_timer -= delta
		if burst_timer <= 0 and bullets_left > 0:
			if is_instance_valid(burst_target):
				_fire_single(burst_target)
				bullets_left -= 1
				if bullets_left <= 0:
					is_bursting = false
					burst_target = null
				else:
					burst_timer = burst_delay
			else:
				is_bursting = false
				burst_target = null
