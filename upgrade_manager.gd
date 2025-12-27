extends Node

var upgrade_scene = load("uid://87wiugxjr5xt")

func upgrade(calling_tower_reference, tower_id, tower_level, path1, path2, path3):#calling tower reference is always "self"
	pause()
	pause_towers()
	
	var inst = upgrade_scene.instantiate()
	inst.base_tower = calling_tower_reference
	inst.tower_id = tower_id
	inst.tower_level = tower_level
	inst.path1 = path1
	inst.path2 = path2
	inst.path3 = path3
	get_tree().root.add_child(inst)

func pause_towers():
	for node in get_tree().get_nodes_in_group("tower"):
		node.pause_function = true
		
func unpause_towers():
	for node in get_tree().get_nodes_in_group("tower"):
		node.pause_function = false

func pause():
	var is_paused = true
	var enabled = !is_paused
	get_tree().call_group("enemy", "set_process", enabled)
	get_tree().call_group("enemy", "set_physics_process", enabled)
	get_tree().call_group("tower", "set_process", enabled)
	get_tree().call_group("bullet", "set_physics_process", enabled)
	get_tree().call_group("bullet", "set_process", enabled)
	get_tree().call_group("next_wave_shower", "set_process", enabled)
	get_tree().call_group("wave_spawner", "set_game_paused", is_paused)
	get_tree().call_group("health_manager", "set", "is_paused", is_paused)
	
func unpause():
	var is_paused = false
	var enabled = !is_paused
	get_tree().call_group("enemy", "set_process", enabled)
	get_tree().call_group("enemy", "set_physics_process", enabled)
	get_tree().call_group("tower", "set_process", enabled)
	get_tree().call_group("bullet", "set_physics_process", enabled)
	get_tree().call_group("bullet", "set_process", enabled)
	get_tree().call_group("next_wave_shower", "set_process", enabled)
	get_tree().call_group("wave_spawner", "set_game_paused", is_paused)
	get_tree().call_group("health_manager", "set", "is_paused", is_paused)
	
