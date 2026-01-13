extends Label

func _ready() -> void:
	add_theme_font_size_override("font_size", 4)
	add_theme_color_override("font_color", Color(1.0, 0.95, 0.7))
	add_theme_color_override("font_outline_color", Color.BLACK)
	add_theme_constant_override("outline_size", 1)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_update_text()

func _process(_delta: float) -> void:
	_update_text()

func _update_text() -> void:
	var rate = StatsManager.get_backpack_money_per_hour()
	text = "+" + StatsManager.get_coin_symbol() + str(rate) + "/hour"

func _on_mouse_entered() -> void:
	TooltipManager.show_tooltip(
		"Backpack Income",
		"Backpack critters generate money.\nOffline production is capped at 8 hours."
	)

func _on_mouse_exited() -> void:
	TooltipManager.hide_tooltip()
