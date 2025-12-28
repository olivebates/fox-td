extends Control

@onready var container = $UpgradeContainer
@onready var colorrect = $UpgradeBG

var upgrade_button = load("uid://ei7mtmm8k8ig")
var base_tower
var tower_id
var tower_level
var path1
var path2
var path3

func _ready() -> void:
	setup_buttons()
	await get_tree().process_frame
	colorrect.gui_input.connect(_on_color_rect_gui_input)
	TooltipManager.hide_tooltip()

func _on_color_rect_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		UpgradeManager.unpause()
		UpgradeManager.unpause_towers()
		queue_free()

# In upgrade UI script (setup_buttons)
func setup_buttons() -> void:
	var item_def = InventoryManager.items[tower_id]
	for i in 3:
		var inst = upgrade_button.instantiate()
		inst.base_tower = base_tower
		inst.tower_id = tower_id
		inst.tower_level = tower_level
		inst.path_id = i
		inst.current_level = base_tower.path[i]
		container.add_child(inst)
