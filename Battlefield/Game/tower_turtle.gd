extends tower_base

const BASE_PULSE_INTERVAL = 4.0
const BASE_SLOW = 0.3
const SLOW_PER_LEVEL = 0.2
const BASE_SLOW_DURATION = 2.0
const BASE_MAX_TARGETS = 5
const TARGETS_PER_LEVEL = 3

var pulse_timer: float = 0.0
var pulse_interval: float = BASE_PULSE_INTERVAL

func _ready() -> void:
	super._ready()

func _process(delta: float) -> void:
	if not has_meta("item_data"):
		return
	var data = get_meta("item_data")
	var path_levels = data.get("path", [0, 0, 0])
	var stats = get_effective_stats()
	attack_radius = stats.range

	if cooldown_time > 0:
		cooldown_time -= delta
		if cooldown_time <= 0:
			cooldown_time = 0
		var enemies = get_tree().get_nodes_in_group("enemy").size() > 0
		if (WaveSpawner._is_spawning or enemies):
			pass
		else:
			cooldown_time = 0

	var start_button = get_tree().get_first_node_in_group("start_wave_button")
	if start_button == null or !start_button.is_paused:
		pulse_timer += delta

	pulse_interval = BASE_PULSE_INTERVAL / max(stats.attack_speed, 0.001)
	if pulse_timer >= pulse_interval and cooldown_time <= 0:
		pulse_timer = 0.0
		_pulse(path_levels)
	queue_redraw()

func _draw() -> void:
	if pulse_interval <= 0.0:
		return
	var progress = clamp(pulse_timer / pulse_interval, 0.0, 1.0)
	var radius = attack_radius * progress
	var alpha = 0.45 * (1.0 - progress)
	draw_arc(Vector2.ZERO, radius, 0, TAU, 64, Color(0.2, 0.6, 1.0, alpha), 1.5)

func _pulse(path_levels: Array) -> void:
	var def: Dictionary = {}
	var inv = get_node_or_null("/root/InventoryManager")
	if inv:
		var items = inv.get("items")
		if typeof(items) == TYPE_DICTIONARY:
			def = items.get(tower_type, {})
	var base_slow = float(def.get("slow", BASE_SLOW))
	var base_targets = int(def.get("max_targets", BASE_MAX_TARGETS))
	var slow_amount = clamp(base_slow + (SLOW_PER_LEVEL * float(path_levels[0])), 0.0, 0.9)
	var max_targets = base_targets + (TARGETS_PER_LEVEL * int(path_levels[1]))
	var enemies = get_tree().get_nodes_in_group("enemies")
	var fresh: Array = []
	var slowed: Array = []
	for enemy in enemies:
		if enemy == null or !is_instance_valid(enemy):
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist > attack_radius:
			continue
		if enemy.has_method("is_slowed") and enemy.is_slowed():
			slowed.append({"enemy": enemy, "dist": dist})
		else:
			fresh.append({"enemy": enemy, "dist": dist})

	fresh.sort_custom(func(a, b): return a.dist < b.dist)
	slowed.sort_custom(func(a, b): return a.dist < b.dist)

	var targets: Array = []
	for entry in fresh:
		targets.append(entry.enemy)
		if targets.size() >= max_targets:
			break
	if targets.size() < max_targets:
		for entry in slowed:
			targets.append(entry.enemy)
			if targets.size() >= max_targets:
				break

	for enemy in targets:
		if enemy.has_method("apply_slow"):
			enemy.apply_slow(slow_amount, BASE_SLOW_DURATION)
