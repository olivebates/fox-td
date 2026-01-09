extends CharacterBody2D
class_name Enemy

@export var max_speed: float = 800.0
@export var speed: float = 10.0
@export var health: int = 50
@export var target_position: Vector2

var current_health: int = 50
var path: PackedVector2Array = []
var path_index: int = 0
var enemy_type: String = "normal"
var spawn_wave: int = 1
var can_split: bool = true
var no_meat_reward: bool = false
var revive_used: bool = false
var regen_buffer: float = 0.0

var health_bg: ColorRect
var health_fg: ColorRect
var sprite: Node
var start_position
var current_damage = 1
var cycles = 1
var wobble_offset = Vector2.ZERO


func _on_astar_updated() -> void:
	await get_tree().process_frame
	request_path()

func _ready() -> void:
	AStarManager.astar_updated.connect(_on_astar_updated)

	$Visuals/Label.add_theme_font_size_override("font_size", 3.5)
	$Visuals/Label.add_theme_color_override("font_color", Color.BLACK)
	$Visuals/Label.position = Vector2(-3.7, -0.5)

	$Visuals/Sprite2D2.modulate = Color(1.0, 0.2, 0.2)

	start_position = position
	add_to_group("enemies")

	sprite = $Visuals/Sprite2D

	create_healthbar()
	update_healthbar()
	request_path()

	# ONE wobble offset for everything
	wobble_offset = Vector2(
		randi_range(-3.0, 3.0),
		randi_range(-3.0, 3.0)
	)

	$Visuals.position = wobble_offset


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
	if path.is_empty() or path_index >= path.size():
		request_path()
	
	$Visuals/Label.text = str(current_health)
	
	if is_in_group("blocked"):
		return
	if global_position.distance_to(target_position) < 8.0:
		current_damage = WaveSpawner.calculate_enemy_damage(current_health, cycles)
		var damage = current_damage
		Utilities.spawn_floating_text("-"+str(int(damage))+" Meat", position-Vector2(0,4)+Vector2(randf_range(-4, 4), randf_range(-4, 4)), get_tree().current_scene)
		position = start_position
		StatsManager.take_damage(damage)
		cycles += 1
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

	var regen_per_second := DifficultyManager.get_enemy_regen_per_second(health)
	if regen_per_second > 0.0 and current_health < health:
		regen_buffer += regen_per_second * delta
		if regen_buffer >= 1.0:
			var regen_points := int(floor(regen_buffer))
			regen_buffer -= regen_points
			current_health = min(health, current_health + regen_points)

	update_healthbar()

func create_healthbar():
	health_bg = ColorRect.new()
	health_bg.color = Color(0.3, 0.3, 0.3, 0.9)
	health_bg.size = Vector2(4, 1)
	health_bg.top_level = true
	add_child(health_bg)
	
	health_fg = ColorRect.new()
	health_fg.color = Color(0.2, 0.8, 0.2)
	health_fg.size = Vector2(4, 1)
	health_fg.top_level = true
	add_child(health_fg)

func update_healthbar():
	var offset = Vector2(0, 8) + wobble_offset
	var pos = (global_position + offset).round()

	health_bg.global_position = pos - Vector2(0, 4)
	health_fg.global_position = pos - Vector2(0, 3)
	health_fg.size.x = 4.0 * (float(current_health) / health)

func take_damage(amount: int):
	if DifficultyManager.should_enemy_dodge():
		return
	amount = DifficultyManager.apply_enemy_damage_taken(amount)
	if amount <= 0:
		return
	current_health -= amount
	update_healthbar()
	
	var tw = create_tween()
	tw.tween_property(sprite, "modulate", Color.RED, 0.1)
	tw.tween_property(sprite, "modulate", Color.WHITE, 0.3)
	
	var health_ratio = float(current_health) / health
	var green_blue = 0.2 + (0.8 - 0.2) * (1.0 - health_ratio)
	var target_color = Color(1.0, green_blue, green_blue)
	
	var tw3 = create_tween()
	tw3.tween_property($Sprite2D2, "modulate", Color.RED, 0.1)
	tw3.tween_property($Sprite2D2, "modulate", target_color, 0.3)
	
	$Visuals/Label.add_theme_color_override("font_color", Color.WHITE)
	var tw2 = create_tween()
	tw2.tween_property($Visuals/Label, "theme_override_colors/font_color", Color.BLACK, 0.3)
	
	if current_health <= 0:
		die()

func die():
	if _try_revive():
		return
	var penalty = TimelineManager.wave_replay_counts.get(TimelineManager.current_wave_index, 0)
	var money_gain = max(1, WaveSpawner.get_enemy_death_money() - penalty)
	var money_mult := DifficultyManager.get_money_multiplier()
	money_gain = max(1, int(round(money_gain * money_mult)))
	StatsManager.money += money_gain
	Utilities.spawn_floating_text("🪙"+str(int(money_gain)), global_position + Vector2(0, 8), get_tree().current_scene, false, Color.YELLOW)
	_grant_meat_reward()
	_spawn_split_enemies()
	if get_tree().get_nodes_in_group("enemy").size() == 1 and !WaveSpawner._is_spawning:
		TimelineManager.save_timeline(WaveSpawner.current_wave)
		WaveSpawner.current_wave += 1
		WaveSpawner.wave_locked = false
	queue_free()

func _grant_meat_reward() -> void:
	if no_meat_reward:
		return
	var base_reward = WaveSpawner.get_enemy_death_health_gain()
	var reward = DifficultyManager.apply_meat_gain(base_reward)
	get_tree().call_group("health_manager", "gain_health_from_kill", reward)

func _spawn_split_enemies() -> void:
	if not can_split:
		return
	var split_count := DifficultyManager.get_split_count()
	if split_count <= 0:
		return
	var split_health := DifficultyManager.get_split_spawn_health(health)
	DifficultyManager.spawn_split_enemies(self, split_count, split_health)

func _try_revive() -> bool:
	if revive_used:
		return false
	if not DifficultyManager.should_enemy_revive():
		return false
	_grant_meat_reward()
	no_meat_reward = true
	revive_used = true
	current_health = max(1, int(round(float(health) * DifficultyManager.get_enemy_revive_health_ratio())))
	update_healthbar()
	return true
