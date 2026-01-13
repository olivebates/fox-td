extends tower_base
class_name summon_tower

var base_minion_health: int = 5
var base_minion_damage: int = 1
@export var minion_scene: PackedScene
var desired_minion_count := 0
var last_desired_minion_count := 0
var minions: Array = []
var respawn_timers: Dictionary = {}  # minion_instance_id -> remaining_time
var current_respawn_time: float = 15.0

func _ready() -> void:
	super._ready()
	desired_minion_count = path[0] + 1
	last_desired_minion_count = desired_minion_count
	spawn_minions()


# Modify spawn_minions()
func spawn_minions() -> void:
	var stats = get_effective_stats()
	desired_minion_count = stats.creature_count
	for i in desired_minion_count:
		_spawn_single_minion(stats.creature_health, stats.creature_damage, stats.creature_attack_speed)

func _spawn_single_minion(health: int, damage: int, attack_speed: float) -> void:
	if not minion_scene: return
	var minion = minion_scene.instantiate()
	minion.global_position = global_position + Vector2(randf_range(-10, 10), randf_range(-10, 10))
	minion.tower = self
	minion.max_health = health
	minion.current_health = health
	minion.damage_per_attack = damage
	minion.attack_speed = attack_speed
	get_tree().current_scene.add_child(minion)
	minions.append(minion)

func request_respawn(minion) -> void:
	var id = minion.get_instance_id()
	if respawn_timers.has(id):
		return
	respawn_timers[id] = current_respawn_time
	minions.erase(minion)

# Override to disable shooting
func update_target() -> void:
	pass

func fire(target: Node2D) -> void:
	pass

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
		InventoryManager.show_tower_tooltip(data, 0.0)  # cost 0 for placed tower

func _process(delta: float) -> void:
	var stats = get_effective_stats()
	current_respawn_time = stats.creature_respawn_time
	desired_minion_count = stats.creature_count
	
	if !WaveSpawner._is_spawning and get_tree().get_nodes_in_group("enemy").size() == 0:
		while minions.size() < desired_minion_count:
			_spawn_single_minion(stats.creature_health, stats.creature_damage, stats.creature_attack_speed)
	
	# Spawn new minions if count increased
	if respawn_timers.is_empty() and minions.size() < desired_minion_count:
		while minions.size() < desired_minion_count:
			_spawn_single_minion(stats.creature_health, stats.creature_damage, stats.creature_attack_speed)
	
	# Update existing minions
	for minion in minions:
		if is_instance_valid(minion):
			minion.max_health = stats.creature_health
			#minion.current_health = minion.max_health  # heal on upgrade
			minion.damage_per_attack = stats.creature_damage
			minion.attack_speed = stats.creature_attack_speed
			
	
	# Respawn logic
	var keys_to_respawn := []
	for inst_id in respawn_timers:
		respawn_timers[inst_id] -= delta
		if respawn_timers[inst_id] <= 0.0:
			keys_to_respawn.append(inst_id)
	
	for inst_id in keys_to_respawn:
		respawn_timers.erase(inst_id)
		if minions.size() < desired_minion_count:
			call_deferred("_spawn_single_minion", stats.creature_health, stats.creature_damage, stats.creature_attack_speed)
	
	queue_redraw()
