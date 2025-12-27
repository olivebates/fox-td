extends BulletBase

@export var stop_after_lock: bool = false  # Keep moving forever

func _ready() -> void:
	super._ready()
	monitoring = true
	lifetime = INF
	
	var initial_target = find_closest_grid_occupier()
	if initial_target != null:
		var dir = (initial_target.global_position - global_position).normalized()
		rotation = dir.angle()
		velocity = dir.rotated(randf_range(-0.4, 0.4)) * (initial_speed / 2)
	else:
		velocity = Vector2.RIGHT.rotated(rotation) / 2
	
	rotation += randf_range(-0.3, 0.3)
	velocity = velocity.rotated(randf_range(-0.3, 0.3))
	

func find_closest_grid_occupier() -> Node2D:
	var occupiers = get_tree().get_nodes_in_group("path_object")
	if occupiers.is_empty():
		return null
	var closest = occupiers[0]
	var closest_dist = global_position.distance_squared_to(closest.global_position)
	for node in occupiers:
		if not is_instance_valid(node):
			continue
		var dist = global_position.distance_squared_to(node.global_position)
		if dist < closest_dist:
			closest = node
			closest_dist = dist
	return closest

func _physics_process(delta: float) -> void:
	if speed > 0:
		speed -= 100
	else:
		speed = 0
	if has_hit:
		return

	var new_target = find_closest_grid_occupier()
	if new_target != null:
		target = new_target
	else:
		return  # keep flying instead of dying

	var dir = (target.global_position - global_position).normalized()
	velocity = velocity.lerp(dir * speed, homing_strength * delta)
	global_position += velocity * delta

	#if velocity.length() > 0:
		#rotation = velocity.angle()
