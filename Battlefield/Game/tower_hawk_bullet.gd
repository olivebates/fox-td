extends BulletBase

var start_position: Vector2
var tile_size: float = 8.0

func _ready() -> void:
	super._ready()
	start_position = global_position
	
	# Enable homing
	homing_strength = 8.0
	speed = initial_speed
	
	# Initial velocity toward current target
	if source_tower and source_tower.current_target and is_instance_valid(source_tower.current_target):
		target = source_tower.current_target
		velocity = (target.global_position - global_position).normalized() * initial_speed

func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
		return
	
	if has_hit:
		return
	
	# Distance limit: tower's attack_radius (includes path[2] upgrades)
	var max_distance_tiles = source_tower.attack_radius / tile_size if source_tower else 10.0
	var traveled_tiles = global_position.distance_to(start_position) / tile_size
	if traveled_tiles >= max_distance_tiles:
		queue_free()
		return
	
	# Homing logic from BulletBase
	if target == null or not is_instance_valid(target):
		target = find_closest_enemy()
		if target == null:
			queue_free()
			return
	
	var dir = (target.global_position - global_position).normalized()
	velocity = velocity.lerp(dir * speed, homing_strength * delta)
	global_position += velocity * delta
	if velocity.length() > 0:
		rotation = velocity.angle()
