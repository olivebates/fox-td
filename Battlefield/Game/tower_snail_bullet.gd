extends BulletBase

@export var base_distance_tiles: float = 3.0
var max_distance_tiles = base_distance_tiles
@export var distance_per_level: float = 4.0  # Matches +4 tiles per path[2] level from get_tower_radius
var start_position: Vector2
var tile_size: float = 8.0
var source_tower: tower_base = null

func _ready() -> void:
	super._ready()
	start_position = global_position
	target = null
	homing_strength = 0.0
	velocity = velocity.normalized() * initial_speed
	
	if source_tower and source_tower.has_meta("item_data"):
		var path_range_level = source_tower.path[2]
		var max_distance_tiles = base_distance_tiles + path_range_level * distance_per_level

func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
		return
	
	if has_hit:
		return
	
	var traveled_tiles = global_position.distance_to(start_position) / tile_size
	if traveled_tiles >= max_distance_tiles:
		queue_free()
		return
	
	global_position += velocity * delta
	if velocity.length() > 0:
		rotation = velocity.angle()
