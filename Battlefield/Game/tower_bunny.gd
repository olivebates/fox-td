extends tower_base
class_name summon_tower

var base_minion_health: int = 5
var base_minion_damage: int = 2
@export var minion_scene: PackedScene
var desired_minion_count := 0
var last_desired_minion_count := 0
var minions: Array = []

func _ready() -> void:
	super._ready()
	desired_minion_count = path[0] + 1
	last_desired_minion_count = desired_minion_count
	spawn_minions()

var respawn_timers: Dictionary = {}  # minion_instance_id -> timer

# Modify spawn_minions()
func spawn_minions() -> void:
	desired_minion_count = path[0] + 1
	var rank = get_meta("item_data").get("rank", 1)
	var multiplier = pow(2, rank - 1)
	var minion_health = base_minion_health * multiplier
	var minion_damage = base_minion_damage * multiplier
	for i in desired_minion_count:
		_spawn_single_minion(minion_health, minion_damage)

func _spawn_single_minion(health: int, damage: int) -> void:
	if not minion_scene: return
	var minion = minion_scene.instantiate()
	minion.global_position = global_position + Vector2(randf_range(-10, 10), randf_range(-10, 10))
	minion.tower = self
	minion.max_health = health
	minion.current_health = health
	minion.damage_per_attack = damage
	get_tree().current_scene.add_child(minion)
	minions.append(minion)

func request_respawn(minion) -> void:
	var id = minion.get_instance_id()
	if respawn_timers.has(id):
		return
	respawn_timers[id] = 5.0
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
	
	if hovered and event is InputEventMouseMotion:
		var rank = get_meta("item_data").get("rank", 1)
		var creature_count = path[0] + 1
		var multiplier = pow(3, rank - 1)
		var creature_damage = base_minion_damage * multiplier
		var rad = attack_radius
		
		TooltipManager.show_tooltip(
			"Bunny Hole",
			"[color=gray]————————————————[/color]\n" +
			"[color=cornflower_blue]Creatures: " + str(int(creature_count)) + "\n" +
			"Damage: " + str(int(creature_damage)) + "\n" +
			"Attack Speed: 1/s\n" +
			"Health: " + str(int(base_minion_health * multiplier)) + "\n" +
			"[color=gray]————————————————[/color]\n" +
            "[font_size=2][color=dark_gray]Click to upgrade[/color][/font_size]"
		)
	elif not hovered and hovered:
		TooltipManager.hide_tooltip()

func _process(delta: float) -> void:
	var new_desired_count = path[0] + 1
	
	if new_desired_count > desired_minion_count:
		var rank = get_meta("item_data").get("rank", 1)
		var multiplier = pow(3, rank - 1)
		var to_spawn = new_desired_count - desired_minion_count
		
		for i in to_spawn:
			_spawn_single_minion(
				base_minion_health * multiplier,
				base_minion_damage * multiplier
			)
	
	desired_minion_count = new_desired_count
	
	attack_radius = invManager.get_tower_radius(tower_type, self)
	var rank = get_meta("item_data").get("rank", 1)
	if holding:
		hold_timer += delta
	fire_rate = invManager.get_attack_speed(tower_type, path[1])
	fire_rate *= pow(1.07, rank - 1)
	
	var multiplier = pow(3, rank - 1)
	
	# Update existing minions
	for minion in minions:
		if is_instance_valid(minion):
			minion.max_health = base_minion_health * multiplier
			minion.damage_per_attack = base_minion_damage * multiplier
	
	
	queue_redraw()
	
	# Respawn timer logic...
	var keys_to_respawn := []
		
	for inst_id in respawn_timers:
		respawn_timers[inst_id] -= delta
		if respawn_timers[inst_id] <= 0.0:
			keys_to_respawn.append(inst_id)
	for inst_id in keys_to_respawn:
		respawn_timers.erase(inst_id)

		if minions.size() < desired_minion_count:
			call_deferred(
				"_spawn_single_minion",
				base_minion_health * multiplier,
				base_minion_damage * multiplier
			)
