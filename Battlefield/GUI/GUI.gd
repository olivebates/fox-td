# Main scene script (e.g., InventoryScene.gd attached to root Control)
extends Control

@onready var grid: GridContainer = %Inventory
@onready var spawner_grid: GridContainer = %SpawnButtons
@onready var drag_preview: Control = %DragPreview

func _ready() -> void:
	InventoryManager.register_inventory(grid, spawner_grid, drag_preview)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		StatsManager.take_damage(99999)
		var unmerge_button = get_tree().get_first_node_in_group("unmerge_towers")
		if unmerge_button:
			unmerge_button.toggle_unmerge_mode()
