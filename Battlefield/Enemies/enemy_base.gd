extends CharacterBody2D
class_name Enemy

@export var max_speed: float = 800.0
@export var speed: float = 10.0
@export var health: int = 50
@export var target_position: Vector2

var current_health: int = 50
var path: PackedVector2Array = []
var path_index: int = 0
var enemy_type: String = "normal":
	set = _set_enemy_type, get = _get_enemy_type
var _enemy_type: String = "normal"
var spawn_wave: int = 1
var wave_color: String = "red":
	set = _set_wave_color, get = _get_wave_color
var _wave_color: String = "red"
var can_split: bool = true
var no_meat_reward: bool = false
var revive_used: bool = false
var regen_buffer: float = 0.0
var type_regen_ratio: float = 0.0
var type_damage_mult: float = 1.0
var type_split_count: int = 0
var type_split_health_ratio: float = 0.0
var type_phase_cycle: float = 0.0
var type_phase_duration: float = 0.0
var type_phase_timer: float = 0.0
var type_phase_range: float = 0.0
var type_revive_ratio: float = 0.0
var type_scale: float = 1.0
var is_phased: bool = false

var health_bg: ColorRect
var health_fg: ColorRect
var sprite: Node
var start_position
var current_damage = 1
var cycles = 1
var wobble_offset = Vector2.ZERO
var base_tint: Color = Color.WHITE

const TYPE_CONFIGS := {
	"splitter": {
		"split_count": 2,
		"split_health_ratio": 0.35
	},
	"phase": {
		"phase_range_tiles": 1.5,
		"base_alpha": 0.75
	},
	"regenerator": {
		"regen_ratio": 0.06
	},
	"revenant": {
		"revive_ratio": 0.5
	},
	"swarmling": {
		"scale": 0.7
	},
	"hardened": {
		"damage_mult": 0.7
	},
	"stalker": {
		"phase_range_tiles": 1.5,
		"base_alpha": 0.85
	}
}


func _set_enemy_type(value: String) -> void:
	_enemy_type = value
	if is_inside_tree():
		_apply_type_modifiers()

func _get_enemy_type() -> String:
	return _enemy_type


func _on_astar_updated() -> void:
	await get_tree().process_frame
	request_path()

func _ready() -> void:
	AStarManager.astar_updated.connect(_on_astar_updated)

	$Visuals/Label.add_theme_font_size_override("font_size", 3.5)
	$Visuals/Label.add_theme_color_override("font_color", Color.BLACK)
	$Visuals/Label.position = Vector2(-3.7, -0.5)

	_apply_wave_color()

	start_position = position
	add_to_group("enemies")

	sprite = $Visuals/Sprite2D

	create_healthbar()
	update_healthbar()
	request_path()
	_apply_type_modifiers()

	# ONE wobble offset for everything
	wobble_offset = Vector2(
		randi_range(-3.0, 3.0),
		randi_range(-3.0, 3.0)
	)

	$Visuals.position = wobble_offset

func _set_wave_color(value: String) -> void:
	_wave_color = value
	if is_inside_tree():
		_apply_wave_color()

func _get_wave_color() -> String:
	return _wave_color


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

	_update_phasing(delta)
	var regen_per_second := DifficultyManager.get_enemy_regen_per_second(health) + (float(health) * type_regen_ratio)
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

func take_damage(amount: int, source_tower_id: String = ""):
	if is_phased:
		return
	if DifficultyManager.should_enemy_dodge():
		return
	amount = DifficultyManager.apply_enemy_damage_taken(amount)
	amount = int(max(1, ceil(float(amount) * type_damage_mult)))
	if amount <= 0:
		return
	var applied_damage = min(amount, current_health)
	current_health -= amount
	update_healthbar()
	StatsManager.gain_meat_on_hit(applied_damage)
	WaveSpawner.record_tower_damage(source_tower_id, applied_damage, spawn_wave)
	
	var tw = create_tween()
	tw.tween_property(sprite, "modulate", Color.RED, 0.1)
	tw.tween_property(sprite, "modulate", base_tint, 0.3)
	
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
	money_gain = max(1, int(round(money_gain * money_mult * StatsManager.get_money_kill_multiplier())))
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
	if enemy_type == "splitter" and type_split_count > 0 and type_split_health_ratio > 0.0:
		_spawn_type_splits("swarmling", type_split_count, type_split_health_ratio)
		return
	var split_count := DifficultyManager.get_split_count()
	if split_count <= 0:
		return
	var split_health := DifficultyManager.get_split_spawn_health(health)
	DifficultyManager.spawn_split_enemies(self, split_count, split_health)

func _try_revive() -> bool:
	if revive_used:
		return false
	if enemy_type == "revenant":
		_grant_meat_reward()
		no_meat_reward = true
		revive_used = true
		current_health = max(1, int(round(float(health) * type_revive_ratio)))
		update_healthbar()
		return true
	if not DifficultyManager.should_enemy_revive():
		return false
	_grant_meat_reward()
	no_meat_reward = true
	revive_used = true
	current_health = max(1, int(round(float(health) * DifficultyManager.get_enemy_revive_health_ratio())))
	update_healthbar()
	return true

func _apply_type_modifiers() -> void:
	type_regen_ratio = 0.0
	type_damage_mult = 1.0
	type_split_count = 0
	type_split_health_ratio = 0.0
	type_phase_cycle = 0.0
	type_phase_duration = 0.0
	type_phase_range = 0.0
	type_revive_ratio = 0.0
	type_scale = 1.0
	is_phased = false
	_set_phased(false)

	var config: Dictionary = TYPE_CONFIGS.get(enemy_type, {})
	if config.has("regen_ratio"):
		type_regen_ratio = float(config.regen_ratio)
	if config.has("damage_mult"):
		type_damage_mult = float(config.damage_mult)
	if config.has("split_count"):
		type_split_count = int(config.split_count)
	if config.has("split_health_ratio"):
		type_split_health_ratio = float(config.split_health_ratio)
	if config.has("phase_cycle"):
		type_phase_cycle = float(config.phase_cycle)
	if config.has("phase_duration"):
		type_phase_duration = float(config.phase_duration)
	if config.has("phase_range_tiles"):
		type_phase_range = float(config.phase_range_tiles) * GridController.CELL_SIZE
	if type_phase_cycle > 0.0:
		type_phase_timer = randf_range(0.0, type_phase_cycle)
	if config.has("revive_ratio"):
		type_revive_ratio = float(config.revive_ratio)
	if config.has("scale"):
		type_scale = float(config.scale)

	if $Visuals:
		$Visuals.scale = Vector2(type_scale, type_scale)
		if config.has("base_alpha"):
			var alpha := float(config.base_alpha)
			$Visuals.modulate = Color(1.0, 1.0, 1.0, alpha)
		else:
			$Visuals.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _apply_wave_color() -> void:
	base_tint = InventoryManager.get_color_value(_wave_color)
	if $Visuals/Sprite2D:
		$Visuals/Sprite2D.modulate = base_tint
	if $Visuals/Sprite2D2:
		$Visuals/Sprite2D2.modulate = base_tint.darkened(0.2)

func _update_phasing(delta: float) -> void:
	if type_phase_range > 0.0:
		var range_sq = type_phase_range * type_phase_range
		var should_phase = false
		for tower in get_tree().get_nodes_in_group("tower"):
			if not is_instance_valid(tower):
				continue
			if global_position.distance_squared_to(tower.global_position) <= range_sq:
				should_phase = true
				break
		if should_phase != is_phased:
			_set_phased(should_phase)
		return
	if type_phase_cycle <= 0.0:
		return
	type_phase_timer += delta
	if not is_phased and type_phase_timer >= type_phase_cycle:
		type_phase_timer = 0.0
		_set_phased(true)
	elif is_phased and type_phase_timer >= type_phase_duration:
		type_phase_timer = 0.0
		_set_phased(false)

func _set_phased(value: bool) -> void:
	is_phased = value
	if is_phased:
		if is_in_group("enemies"):
			remove_from_group("enemies")
		if $Visuals:
			var current = $Visuals.modulate
			$Visuals.modulate = Color(current.r, current.g, current.b, 0.4)
	else:
		if not is_in_group("enemies"):
			add_to_group("enemies")
		if $Visuals:
			var config: Dictionary = TYPE_CONFIGS.get(enemy_type, {})
			var alpha := 1.0
			if config.has("base_alpha"):
				alpha = float(config.base_alpha)
			$Visuals.modulate = Color(1.0, 1.0, 1.0, alpha)

func _spawn_type_splits(split_type: String, split_count: int, split_health_ratio: float) -> void:
	if split_count <= 0 or split_health_ratio <= 0.0:
		return
	var parent = get_parent()
	if parent == null:
		return
	var wave = spawn_wave
	if not WaveSpawner.active_waves.has(wave):
		WaveSpawner.active_waves[wave] = 0
	WaveSpawner.active_waves[wave] += split_count
	for i in split_count:
		var enemy := WaveSpawner.enemy_scene.instantiate()
		var split_health = max(1, int(round(float(health) * split_health_ratio)))
		enemy.enemy_type = split_type
		enemy.spawn_wave = wave
		enemy.wave_color = wave_color
		enemy.can_split = false
		enemy.no_meat_reward = true
		enemy.max_speed = max_speed
		enemy.speed = speed
		enemy.health = split_health
		enemy.current_health = split_health
		enemy.position = position + Vector2(randf_range(-2.0, 2.0), randf_range(-2.0, 2.0))
		enemy.target_position = target_position
		parent.add_child(enemy)
		enemy.add_to_group("enemy")
		enemy.tree_exited.connect(func():
			if WaveSpawner.active_waves.has(wave):
				WaveSpawner.active_waves[wave] -= 1
				if WaveSpawner.active_waves[wave] <= 0:
					WaveSpawner.active_waves.erase(wave)
					WaveSpawner.wave_completed.emit(wave)
					var button = get_tree().get_first_node_in_group("start_wave_button")
					if button: button.disabled = false
		)
