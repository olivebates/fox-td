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

func _input(event: InputEvent) -> void:
	super._input(event)
	
	var mouse_over = is_mouse_over()
	if event is InputEventMouseMotion:
		var was_hovered = hovered
		hovered = mouse_over
		if hovered and not was_hovered:
			draw_radius = true
			queue_redraw()
		elif not hovered and was_hovered:
			draw_radius = false
			queue_redraw()
	
	if hovered:
		var data = get_meta("item_data")
		InventoryManager.show_tower_tooltip(data, 0.0)
	#elif not hovered:
		#TooltipManager.hide_tooltip()

func fire(target: Node2D) -> void:
	if target == null:
		return
	
	var data = get_meta("item_data")
	var stats = InventoryManager.get_tower_stats(tower_type, data.rank, path)
	
	burst_target = target
	bullets_left = stats.bullets
	is_bursting = true
	burst_timer = 0.0
	
	var dir = (target.global_position - global_position).normalized()
	sprite.flip_h = dir.x > 0

func _fire_single(t: Node2D) -> void:
	if not is_instance_valid(t):
		return
	
	var data = get_meta("item_data")
	var stats = InventoryManager.get_tower_stats(tower_type, data.rank, path)
	
	var dir = (t.global_position - global_position).normalized()
	
	var bullet = bullet_scene.instantiate()
	bullet.global_position = global_position
	bullet.velocity = dir * bullet.initial_speed
	bullet.target = t
	bullet.source_tower = self
	bullet.damage = stats.damage
	
	get_tree().current_scene.add_child(bullet)
	
	sprite.flip_h = dir.x > 0
	
	var tween = create_tween()
	tween.tween_property(sprite, "position:x", sign(dir.x) * 2.0, 0.05)
	tween.tween_property(sprite, "position:x", 0.0, 0.1)

func _process(delta: float) -> void:
	super._process(delta)
	
	if is_bursting:
		burst_timer -= delta
		if burst_timer <= 0.0 and bullets_left > 0:
			if is_instance_valid(burst_target):
				_fire_single(burst_target)
			bullets_left -= 1
			if bullets_left > 0:
				burst_timer = burst_delay
			else:
				is_bursting = false
				burst_target = null
