extends CharacterBody2D
class_name Enemy

@export var max_speed: float = 800.0
@export var speed: float = 10.0
@export var health: int = 50
@export var target_position: Vector2

var current_health: int = 50
var path: PackedVector2Array = []
var path_index: int = 0

var health_bg: ColorRect
var health_fg: ColorRect
var sprite: Node
var start_position
var current_damage = 10
signal enemy_died

func _ready() -> void:
	$Label.add_theme_font_size_override("font_size", 3.5)
	$Label.add_theme_color_override("font_color", Color.BLACK)
	$Label.position = Vector2(-3.7, 0.5)
	start_position = position
	add_to_group("enemies")
	sprite = $Sprite2D
	create_healthbar()
	update_healthbar()
	request_path()

func request_path() -> void:
	var astar = AStarManager.astar
	var local_pos: Vector2 = global_position - astar.offset
	var start_cell := Vector2i(
		floor(local_pos.x / astar.cell_size.x),
		floor(local_pos.y / astar.cell_size.y)
	)
	var target_local: Vector2 = target_position - astar.offset
	var target_cell := Vector2i(
		floor(target_local.x / astar.cell_size.x),
		floor(target_local.y / astar.cell_size.y)
	)
	if not astar.is_in_boundsv(start_cell) or not astar.is_in_boundsv(target_cell):
		return
	path = astar.get_point_path(start_cell, target_cell)
	path_index = 0

func _process(delta: float) -> void:
	$Label.text = str(current_health)
	if global_position.distance_to(target_position) < 8.0:
		position = start_position
		StatsManager.take_damage(current_damage)
		current_damage *= 2
		request_path()
		
	if path.is_empty() or path_index >= path.size():
		return
	
	var target_pos: Vector2 = path[path_index]
	var dir := target_pos - global_position
	var dist := dir.length()
	
	if dist < 2.0:
		path_index += 1
	else:
		global_position += dir.normalized() * speed * delta
	
	
	
	update_healthbar()

func create_healthbar():pass
	#health_bg = ColorRect.new()
	#health_bg.color = Color(0.3, 0.3, 0.3, 0.9)
	#health_bg.size = Vector2(10, 6)
	#health_bg.top_level = true
	#add_child(health_bg)
	#
	#health_fg = ColorRect.new()
	#health_fg.color = Color(0.2, 0.8, 0.2)
	#health_fg.size = Vector2(8, 4)
	#health_fg.top_level = true
	#add_child(health_fg)

func update_healthbar():pass
	#var offset = Vector2(0, 8)
	#var pos = (global_position + offset).round()
	#health_bg.global_position = pos - Vector2(5, 3)
	#health_fg.global_position = pos - Vector2(4, 2)
	#health_fg.size.x = 8.0 * (float(current_health) / health)

func take_damage(amount: int):
	current_health -= amount
	update_healthbar()
	var tw = create_tween()
	tw.tween_property(sprite, "modulate", Color.RED, 0.1)
	tw.tween_property(sprite, "modulate", Color.WHITE, 0.3)
	var tw3 = create_tween()
	tw3.tween_property($Sprite2D2, "modulate", Color.RED, 0.1)
	tw3.tween_property($Sprite2D2, "modulate", Color.WHITE, 0.3)
	$Label.add_theme_color_override("font_color", Color.WHITE)
	var tw2 = create_tween()
	tw2.tween_property($Label, "theme_override_colors/font_color", Color.BLACK, 0.3)
	if current_health <= 0:
		die()

func die():
	get_tree().call_group("health_manager", "gain_health_from_kill", 5.0)
	queue_free()
