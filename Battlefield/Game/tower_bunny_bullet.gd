extends BulletBase
class_name summon_minion

@export var wander_speed: float = 30.0
@export var wander_radius: float = 8.0
@onready var health_bg: ColorRect = $HealthBG
@onready var health_fg: ColorRect = $HealthFG
var patrol_points: Array[Vector2] = []
var patrol_index: int = 0
var damage_per_attack: int = 1
var max_health: int = 5
var current_health: int = 5

@onready var sprite: Sprite2D = $Sprite2D

var tower
var target_object: Node2D = null
var wander_center: Vector2
var wander_target: Vector2
var wait_timer: float = 0.0
var wait_time: float = 0.0
var state: String = "patrolling"  # "patrolling", "chasing", "fighting"  # "to_target", "moving", "waiting", "fighting"

var attack_speed = 1.0
var attack_timer: float = 0.0
var current_enemy: Node2D = null

func setup_patrol_square() -> void:
	var c := wander_center
	patrol_points = [
		c + Vector2(-2, -2),
		c + Vector2( 2, -2),
		c + Vector2( 2,  2),
		c + Vector2(-2,  2),
	]
	patrol_index = randi() % patrol_points.size()

func _ready() -> void:
	lifetime = INF
	monitoring = true
	monitorable = true
	add_to_group("guard")
	body_entered.connect(_on_body_entered)
	find_nearest_path_object()
	wander_center = target_object.global_position
	setup_patrol_square()  # Still defines square bounds
	state = "patrolling"
	set_new_wander_target()

	# Healthbar setup (unchanged)
	health_bg = ColorRect.new()
	health_bg.color = Color(0.3, 0.3, 0.3, 0.9)
	health_bg.size = Vector2(6, 1.5)
	add_child(health_bg)
	health_fg = ColorRect.new()
	health_fg.color = Color(0.8, 0.2, 0.2)
	health_fg.size = Vector2(6, 1.5)
	add_child(health_fg)
	update_healthbar()

func update_healthbar() -> void:
	var ratio = float(current_health) / max_health
	health_fg.size.x = 6.0 * ratio
	health_bg.position = Vector2(-3, 3)
	health_fg.position = Vector2(-3, 4)

func find_nearest_path_object() -> void:
	var objects = get_tree().get_nodes_in_group("path_object")
	if objects.is_empty():
		queue_free()
		return

	var tower_pos = tower.global_position
	var closest = objects[0]
	var min_dist = tower_pos.distance_squared_to(closest.global_position)

	for obj in objects:
		var d = tower_pos.distance_squared_to(obj.global_position)
		if d < min_dist:
			min_dist = d
			closest = obj

	target_object = closest
	wander_center = closest.global_position


func set_new_wander_target() -> void:
	var half = wander_radius  # wander_radius = 8.0 → covers square
	var offset = Vector2(randf_range(-half, half), randf_range(-half, half))
	wander_target = wander_center + offset
	wait_time = randf_range(1.0, 3.0)
	wait_timer = 0.0

var engaged_enemy: Node2D = null  # Tracks exclusively engaged enemy

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and state != "fighting" and engaged_enemy == null:
		state = "fighting"
		current_enemy = body
		engaged_enemy = body
		velocity = Vector2.ZERO
		body.add_to_group("blocked")  # Custom temporary group
		body.request_path()  # Force immediate stop/repath attempt

func take_damage(amount: int) -> void:
	current_health = maxi(current_health - amount, 0)
	update_healthbar()
	if current_health <= 0:
		if tower:
			tower.request_respawn(self)
		if current_enemy:
			current_enemy.remove_from_group("blocked")
		queue_free()

func _physics_process(delta: float) -> void:
	# Always update to closest path_object
	if is_instance_valid(tower):
		find_nearest_path_object()
		if wander_center != target_object.global_position:
			wander_center = target_object.global_position
			set_new_wander_target()
	
	if !WaveSpawner._is_spawning and get_tree().get_nodes_in_group("enemy").size() <= 0:
		current_health = max_health

	var nearest_enemy := _find_nearest_enemy(16.0)

	# State transitions
	if state != "fighting" and nearest_enemy:
		state = "chasing"
		current_enemy = nearest_enemy

	if state == "chasing" and (!is_instance_valid(current_enemy)):
		state = "patrolling"
		current_enemy = null

	if state == "fighting" and (!is_instance_valid(current_enemy)):
		state = "patrolling"
		current_enemy = null
		engaged_enemy = null
		attack_timer = 0.0

	# State behavior
	match state:
		"patrolling":
			var dir := wander_target - global_position
			if dir.length() < 1.0:
				velocity = Vector2.ZERO
				wait_timer += delta
				if wait_timer >= wait_time:
					set_new_wander_target()
			else:
				wait_timer = 0.0
				velocity = dir.normalized() * wander_speed

		"chasing":
			if not is_instance_valid(current_enemy):
				state = "patrolling"
				velocity = Vector2.ZERO
			else:
				var dir := current_enemy.global_position - global_position
				if dir.length() <= 1.5:
					state = "fighting"
					velocity = Vector2.ZERO
					engaged_enemy = current_enemy
					if is_instance_valid(current_enemy):
						current_enemy.add_to_group("blocked")
						current_enemy.request_path()
				else:
					velocity = dir.normalized() * wander_speed

		"fighting":
			velocity = Vector2.ZERO
			if is_instance_valid(current_enemy):
				self_damage_timer += delta
				if self_damage_timer >= 1.0:
					self_damage_timer = 0.0
					take_damage(1)
					update_healthbar()
				attack_timer += delta
				if attack_timer >= float(1.0/attack_speed):
					attack_timer = 0.0
					if is_instance_valid(current_enemy):
						current_enemy.take_damage(damage_per_attack)

	# Movement
	global_position += velocity * delta

	# Sprite facing
	if state == "fighting" and is_instance_valid(current_enemy):
		sprite.flip_h = current_enemy.global_position.x > global_position.x
	elif velocity.length() > 0:
		sprite.flip_h = velocity.x > 0

	update_healthbar()
var self_damage_timer = 0.0

func _find_nearest_enemy(max_dist: float) -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest: Node2D = null
	var min_dist: float = max_dist * max_dist
	for enemy in enemies:
		if not is_instance_valid(enemy): continue
		var d = global_position.distance_squared_to(enemy.global_position)
		if d < min_dist:
			min_dist = d
			closest = enemy
	return closest

func _is_wall_ahead(pos: Vector2) -> bool:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, pos)
	query.exclude = [self]
	var result = space_state.intersect_ray(query)
	return result and result.collider.is_in_group("walls")
