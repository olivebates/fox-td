extends Button

var _last_cost = -1
var _last_money = -1
var _last_unlocked = -1
var _last_can_unlock = false

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	add_theme_font_size_override("font_size", 4)
	add_theme_color_override("font_outline_color", Color.BLACK)
	add_theme_constant_override("outline_size", 1)
	
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.2, 0.2, 0.2)
	style_normal.content_margin_left = 2
	style_normal.content_margin_right = 2
	style_normal.content_margin_top = 0
	style_normal.content_margin_bottom = 1
	
	var style_hover = style_normal.duplicate()
	style_hover.bg_color = Color(0.3, 0.3, 0.3)
	
	var style_pressed = style_normal.duplicate()
	style_pressed.bg_color = Color(0.15, 0.15, 0.15)

	var style_disabled = style_normal.duplicate()
	
	add_theme_stylebox_override("normal", style_normal)
	add_theme_stylebox_override("hover", style_hover)
	add_theme_stylebox_override("pressed", style_pressed)
	add_theme_stylebox_override("disabled", style_disabled)
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_update_button()

func _process(_delta: float) -> void:
	_update_button()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if disabled:
			if event.pressed:
				Utilities.spawn_floating_text("Not enough " + StatsManager.get_coin_symbol(), Vector2.ZERO, null)
			return
		if event.pressed:
			position += Vector2(1, 1)
			$ColorRect.visible = false
		else:
			position -= Vector2(1, 1)
			$ColorRect.visible = true

func _on_pressed() -> void:
	if !TowerManager.can_unlock_squad_slot():
		return
	var cost = TowerManager.get_next_squad_unlock_cost()
	if StatsManager.money < cost:
		Utilities.spawn_floating_text("Not enough " + StatsManager.get_coin_symbol() + "...", Vector2.ZERO, null)
		return
	if TowerManager.unlock_next_squad_slot():
		get_tree().call_group("squad_inventory", "refresh_all_highlights")
		_update_button()

func _on_mouse_entered() -> void:
	if !TowerManager.can_unlock_squad_slot():
		return
	var cost = TowerManager.get_next_squad_unlock_cost()
	TooltipManager.show_tooltip(
		"Unlock Squad Slot",
		"[font_size=2][color=dark_gray]Unlocks one more squad slot for " + StatsManager.get_coin_symbol() + str(cost) + ".[/color][/font_size]"
	)

func _on_mouse_exited() -> void:
	TooltipManager.hide_tooltip()

func _update_button() -> void:
	var can_unlock = TowerManager.can_unlock_squad_slot()
	var unlocked = TowerManager.get_unlocked_squad_size()
	var cost = TowerManager.get_next_squad_unlock_cost()
	var money = StatsManager.money
	if can_unlock == _last_can_unlock and unlocked == _last_unlocked and cost == _last_cost and money == _last_money:
		return
	_last_can_unlock = can_unlock
	_last_unlocked = unlocked
	_last_cost = cost
	_last_money = money
	if !can_unlock:
		text = "All Slots Unlocked"
		disabled = true
		return
	text = "+Slot " + StatsManager.get_coin_symbol() + str(cost)
	disabled = money < cost
