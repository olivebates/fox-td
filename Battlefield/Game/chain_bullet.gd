extends BulletBase
class_name ChainBullet

@export var max_hits: int = 3
@export var chain_range: float = 24.0

var hits_remaining: int = 0
var hit_ids: Dictionary = {}

func _ready() -> void:
	super._ready()
	hits_remaining = max_hits

func _on_body_entered(body: Node2D) -> void:
	if body == null or !body.is_in_group("enemies"):
		return
	var id = body.get_instance_id()
	if hit_ids.has(id):
		return
	hit_ids[id] = true
	apply_damage(body)
	hits_remaining -= 1
	if hits_remaining <= 0:
		queue_free()
		return
	var next_target = _find_next_target(body.global_position)
	if next_target == null:
		queue_free()
		return
	target = next_target
	velocity = (target.global_position - global_position).normalized() * speed

func _find_next_target(from_pos: Vector2) -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var best: Node2D = null
	var best_dist := INF
	var range_sq = chain_range * chain_range
	for enemy in enemies:
		if enemy == null or !is_instance_valid(enemy):
			continue
		var id = enemy.get_instance_id()
		if hit_ids.has(id):
			continue
		var dist_sq = from_pos.distance_squared_to(enemy.global_position)
		if dist_sq <= range_sq and dist_sq < best_dist:
			best = enemy
			best_dist = dist_sq
	return best
