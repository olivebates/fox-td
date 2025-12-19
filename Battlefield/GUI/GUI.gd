# Main scene script (e.g., InventoryScene.gd attached to root Control)
extends Control

@onready var grid: GridContainer = %Inventory
@onready var spawner_grid: GridContainer = %SpawnButtons
@onready var drag_preview: Control = %DragPreview

func _ready() -> void:
	InventoryManager.register_inventory(grid, spawner_grid, drag_preview)
