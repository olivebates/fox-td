extends tower_base
class_name tower_aoe

var aoe_radius: float = 15.0  # Example AoE radius, adjust via stats if needed
var aoe_damage: float = 10.0

# In tower_aoe.gd (replace the existing fire() and _draw())
func fire(target: Node2D) -> void:
	var stats = get_effective_stats()
	var damage = stats.damage
	
	var enemies = get_tree().get_nodes_in_group("enemies")
	var tower_id := str(get_meta("item_data").get("id", ""))
	for enemy in enemies:
		if global_position.distance_to(enemy.global_position) <= aoe_radius:
			enemy.take_damage(damage, tower_id)
	
	# Visual recoil
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.2)

func _draw() -> void:
	super._draw()
	if draw_radius:
		draw_arc(Vector2.ZERO, aoe_radius, 0, TAU, 64, Color(1, 0.5, 0, 0.4), 2.0)
		draw_arc(Vector2.ZERO, attack_radius, 0, TAU, 64, Color(1, 0, 0, 0.3), 1.5)
