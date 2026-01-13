extends tower_base

const VOLLEY_GAP = 0.2
const DIRECTIONS = [
	Vector2(1, 0), Vector2(1, 1), Vector2(0, 1), Vector2(-1, 1),
	Vector2(-1, 0), Vector2(-1, -1), Vector2(0, -1), Vector2(1, -1)
]
var is_firing: bool = false

func _ready() -> void:
	super._ready()

func update_target() -> void:
	current_target = null
	var min_dist: float = INF
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		var dist = global_position.distance_to(enemy.global_position)
		if dist <= attack_radius and dist < min_dist:
			min_dist = dist
			current_target = enemy

func fire(target: Node2D) -> void:
	if target == null:
		return
	if is_firing:
		return
	
	if !has_meta("item_data"):
		return
	var stats = get_effective_stats()
	var volley_count = max(1, 1 + int(path[0]))
	is_firing = true
	for volley in volley_count:
		for dir in DIRECTIONS:
			var bullet = bullet_scene.instantiate()
			bullet.global_position = global_position
			bullet.velocity = dir.normalized() * bullet.initial_speed
			bullet.target = null
			bullet.damage = stats.damage
			get_tree().current_scene.add_child(bullet)
		if volley < volley_count - 1:
			await get_tree().create_timer(VOLLEY_GAP).timeout
			if !is_inside_tree():
				is_firing = false
				return
	
	# Recoil effect
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(sprite, "scale", Vector2(1, 1), 0.1)
	is_firing = false
