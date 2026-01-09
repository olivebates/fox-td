extends Control

const STAT_KEYS := [
	"damage",
	"attack_speed",
	"radius",
	"bullets",
	"enemies_hit",
	"creatures",
	"creature_damage",
	"creature_attack_speed",
	"creatures_hp",
	"creature_respawn_time",
]

const STAT_LABELS := {
	"damage": "Damage",
	"attack_speed": "Attack Speed",
	"radius": "Range",
	"bullets": "Bullets",
	"enemies_hit": "Max Enemies Hit",
	"creatures": "Creatures",
	"creature_damage": "Damage",
	"creature_attack_speed": "Attack Speed",
	"creatures_hp": "Health",
	"creature_respawn_time": "Respawn Time",
}

const STAT_INCREMENTS := {
	"radius": 8.0,
}

const STAT_MIN := {}

const BASE_UPGRADE_COST := 1000

@onready var layout: HBoxContainer = $Layout
@onready var left_panel: VBoxContainer = $Layout/LeftPanel
@onready var right_panel: VBoxContainer = $Layout/RightPanel
@onready var left_title: Label = $Layout/LeftPanel/LeftTitle
@onready var tower_list: VBoxContainer = $Layout/LeftPanel/LeftScroll/TowerList
@onready var tower_image: TextureRect = $Layout/RightPanel/ImageCenter/TowerImage
@onready var tower_name: Label = $Layout/RightPanel/TowerName
@onready var empty_label: Label = $Layout/RightPanel/EmptyLabel
@onready var stats_list: VBoxContainer = $Layout/RightPanel/StatsScroll/StatsList

var selected_tower_id := ""
var tower_button_group := ButtonGroup.new()
var stat_rows: Array = []
var _last_money := -1
var _cached_unlocked_ids: Array = []

func _ready() -> void:
	
	$UpgradesTitle.add_theme_font_size_override("font_size", 8)
	$UpgradesTitle.add_theme_color_override("font_outline_color", Color.BLACK)
	$UpgradesTitle.add_theme_constant_override("outline_size", 1)
	
	visibility_changed.connect(_on_visibility_changed)
	#tower_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_resolve_ui_nodes()
	_apply_compact_layout()
	_rebuild_tower_list()
	_select_first_unlocked()
	_refresh_stats()

func _process(_delta: float) -> void:
	if !visible:
		return
	_check_unlocked_updates()
	if selected_tower_id.is_empty():
		return
	if _last_money != StatsManager.money:
		_last_money = StatsManager.money
		_refresh_stat_rows()

func _on_visibility_changed() -> void:
	if !visible:
		return
	refresh_unlocked_towers()
	if selected_tower_id.is_empty() or !InventoryManager.items.has(selected_tower_id):
		_select_first_unlocked()
	_refresh_stats()

func _rebuild_tower_list() -> void:
	for child in tower_list.get_children():
		child.queue_free()
	var unlocked_ids := _get_unlocked_ids()
	_cached_unlocked_ids = unlocked_ids.duplicate()
	for tower_id in unlocked_ids:
		var btn := Button.new()
		btn.text = InventoryManager.items[tower_id].get("name", tower_id)
		btn.icon = InventoryManager.items[tower_id].get("texture", null)
		btn.toggle_mode = true
		btn.button_group = tower_button_group
		btn.focus_mode = Control.FOCUS_NONE
		_apply_compact_button(btn)
		btn.pressed.connect(_on_tower_pressed.bind(tower_id))
		tower_list.add_child(btn)
		if tower_id == selected_tower_id:
			btn.button_pressed = true

func _select_first_unlocked() -> void:
	var unlocked_ids := _get_unlocked_ids()
	if !unlocked_ids.is_empty():
		_select_tower(unlocked_ids[0])
		return
	_clear_selection()

func _on_tower_pressed(tower_id: String) -> void:
	_select_tower(tower_id)

func _select_tower(tower_id: String) -> void:
	selected_tower_id = tower_id
	_refresh_stats()

func _clear_selection() -> void:
	selected_tower_id = ""
	if tower_image:
		tower_image.texture = null
	if tower_name:
		tower_name.text = "Select a tower"
	if empty_label:
		empty_label.visible = true
	_clear_stat_rows()

func _refresh_stats() -> void:
	_resolve_ui_nodes()
	if selected_tower_id.is_empty() or !InventoryManager.items.has(selected_tower_id):
		_clear_selection()
		return
	var def: Dictionary = InventoryManager.items[selected_tower_id]
	if tower_image:
		tower_image.texture = def.get("texture", null)
	if tower_name:
		tower_name.text = def.get("name", selected_tower_id)
	if empty_label:
		empty_label.visible = false
	_build_stat_rows(def)
	_refresh_stat_rows()

func _build_stat_rows(def: Dictionary) -> void:
	_clear_stat_rows()
	var upgrade_levels: Dictionary = _get_upgrade_levels(def)
	for stat_key in STAT_KEYS:
		if def.get("is_guard", false) and stat_key in ["radius", "creature_respawn_time"]:
			continue
		if !def.has(stat_key):
			continue
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 0)
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.mouse_filter = Control.MOUSE_FILTER_STOP
		_apply_compact_label(label)
		label.text = _format_stat_text(stat_key, def.get(stat_key, 0.0), upgrade_levels.get(stat_key, 0))
		label.mouse_entered.connect(_on_stat_hover.bind(stat_key))
		label.mouse_exited.connect(_on_stat_exit)
		var button := Button.new()
		button.focus_mode = Control.FOCUS_NONE
		_apply_compact_button(button)
		button.pressed.connect(_on_upgrade_pressed.bind(stat_key))
		row.add_child(label)
		row.add_child(button)
		stats_list.add_child(row)
		stat_rows.append({
			"key": stat_key,
			"label": label,
			"button": button,
		})

func _clear_stat_rows() -> void:
	for child in stats_list.get_children():
		child.queue_free()
	stat_rows.clear()

func _refresh_stat_rows() -> void:
	if selected_tower_id.is_empty():
		return
	var def: Dictionary = InventoryManager.items[selected_tower_id]
	var upgrade_levels: Dictionary = _get_upgrade_levels(def)
	for row in stat_rows:
		var stat_key: String = row["key"]
		var level := int(upgrade_levels.get(stat_key, 0))
		var value = def.get(stat_key, 0.0)
		row["label"].text = _format_stat_text(stat_key, value, level)
		var cost := _get_upgrade_cost(level)
		var button: Button = row["button"]
		button.text = "Upgrade 🪙" + str(cost)
		button.disabled = StatsManager.money < cost

func _on_upgrade_pressed(stat_key: String) -> void:
	if selected_tower_id.is_empty():
		return
	var def: Dictionary = InventoryManager.items[selected_tower_id]
	var upgrade_levels: Dictionary = _get_upgrade_levels(def)
	var level := int(upgrade_levels.get(stat_key, 0))
	var cost := _get_upgrade_cost(level)
	if StatsManager.money < cost:
		return
	StatsManager.money -= cost
	var current_value := float(def.get(stat_key, 0.0))
	var delta := _get_stat_increment(stat_key)
	var new_value := current_value + delta
	if STAT_MIN.has(stat_key):
		new_value = max(new_value, STAT_MIN[stat_key])
	def[stat_key] = new_value
	upgrade_levels[stat_key] = level + 1
	def["meta_upgrade_levels"] = upgrade_levels
	_refresh_live_towers(selected_tower_id)
	_refresh_stat_rows()

func _get_upgrade_levels(def: Dictionary) -> Dictionary:
	var levels = def.get("meta_upgrade_levels", {})
	if typeof(levels) != TYPE_DICTIONARY:
		levels = {}
	def["meta_upgrade_levels"] = levels
	return levels

func _get_upgrade_cost(level: int) -> int:
	return int(BASE_UPGRADE_COST * pow(2, level))

func _get_stat_increment(stat_key: String) -> float:
	return float(STAT_INCREMENTS.get(stat_key, 1.0))

func _format_stat_text(stat_key: String, value: float, _level: int) -> String:
	var label = STAT_LABELS.get(stat_key, stat_key.capitalize())
	if stat_key == "radius":
		value = floor(value / 8.0)
	var text_value := _format_value(value)
	if stat_key == "attack_speed" or stat_key == "creature_attack_speed":
		text_value += "/s"
	elif stat_key == "radius":
		text_value += " tiles"
	return "%s: %s" % [label, text_value]

func _on_stat_hover(stat_key: String) -> void:
	var label = STAT_LABELS.get(stat_key, stat_key.capitalize())
	TooltipManager.show_tooltip(label, _get_stat_tooltip_text(stat_key))

func _on_stat_exit() -> void:
	TooltipManager.hide_tooltip()

func _get_stat_tooltip_text(stat_key: String) -> String:
	if selected_tower_id.is_empty() or !InventoryManager.items.has(selected_tower_id):
		return "Upgrade increases this stat.\nCurrent level: 0"
	var def: Dictionary = InventoryManager.items[selected_tower_id]
	var upgrade_levels: Dictionary = _get_upgrade_levels(def)
	var level := int(upgrade_levels.get(stat_key, 0))
	var delta := _get_stat_increment(stat_key)
	var sign := "+" if delta >= 0 else "-"
	var label = STAT_LABELS.get(stat_key, stat_key.capitalize())
	var amount := _format_value(abs(delta))
	var desc = "Upgrade increases " + label + " by " + sign + amount + "."
	if stat_key == "radius":
		var tiles = abs(delta) / 8.0
		var tile_amount := _format_value(tiles)
		var tile_label := "tile" if is_equal_approx(tiles, 1.0) else "tiles"
		desc = "Upgrade increases " + label + " by " + sign + tile_amount + " " + tile_label + "."
	return "\n".join([
		desc,
		"Current level: " + str(level),
	])

func _format_value(value: float) -> String:
	if abs(value - round(value)) < 0.01:
		return str(int(round(value)))
	return "%.2f" % value

func _refresh_live_towers(tower_id: String) -> void:
	for tower in get_tree().get_nodes_in_group("tower"):
		if !tower.has_meta("item_data"):
			continue
		var data: Dictionary = tower.get_meta("item_data")
		if data.get("id", "") == tower_id:
			tower._last_tower_type = null

func _check_unlocked_updates() -> void:
	var unlocked_ids := _get_unlocked_ids()
	if unlocked_ids != _cached_unlocked_ids:
		refresh_unlocked_towers()

func refresh_unlocked_towers() -> void:
	_rebuild_tower_list()

func _apply_compact_layout() -> void:
	for container in [layout, left_panel, right_panel, tower_list, stats_list]:
		if container:
			container.add_theme_constant_override("separation", 0)
	if stats_list:
		stats_list.add_theme_constant_override("separation", 2)
	_apply_compact_label(tower_name)
	_apply_compact_label(empty_label)
	_apply_compact_label(left_title)

func _apply_compact_label(label: Label) -> void:
	if !label:
		return
	label.add_theme_font_size_override("font_size", 4)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("line_spacing", 0)
	label.add_theme_constant_override("outline_size", 1)

func _apply_compact_button(button: Button) -> void:
	if !button:
		return
	button.add_theme_font_size_override("font_size", 4)
	button.add_theme_color_override("font_outline_color", Color.BLACK)
	button.add_theme_constant_override("outline_size", 1)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.2, 0.2, 0.2)
	normal.content_margin_left = 3
	normal.content_margin_right = 3
	normal.content_margin_top = 0
	normal.content_margin_bottom = 1
	var hover := normal.duplicate()
	hover.bg_color = Color(0.3, 0.3, 0.3)
	var pressed := normal.duplicate()
	pressed.bg_color = Color(0.15, 0.15, 0.15)
	var disabled := normal.duplicate()
	disabled.bg_color = Color(0.1, 0.1, 0.1)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func _get_unlocked_ids() -> Array:
	var unlocked_ids: Array = []
	for tower_id in InventoryManager.items.keys():
		if InventoryManager.items[tower_id].get("unlocked", false):
			unlocked_ids.append(tower_id)
	unlocked_ids.sort()
	return unlocked_ids

func _resolve_ui_nodes() -> void:
	if !layout:
		layout = find_child("Layout", true, false) as HBoxContainer
	if !left_panel:
		left_panel = find_child("LeftPanel", true, false) as VBoxContainer
	if !right_panel:
		right_panel = find_child("RightPanel", true, false) as VBoxContainer
	if !left_title:
		left_title = find_child("LeftTitle", true, false) as Label
	if !tower_list:
		tower_list = find_child("TowerList", true, false) as VBoxContainer
	if !tower_image:
		tower_image = find_child("TowerImage", true, false) as TextureRect
	if !tower_name:
		tower_name = find_child("TowerName", true, false) as Label
	if !empty_label:
		empty_label = find_child("EmptyLabel", true, false) as Label
	if !stats_list:
		stats_list = find_child("StatsList", true, false) as VBoxContainer
