extends Control

@onready var total_label: Label = $TotalLabel

func _ready() -> void:
	DifficultyManager.trait_changed.connect(_on_trait_changed)
	$DifficultyTitle.add_theme_font_size_override("font_size", 8)
	$DifficultyTitle.add_theme_color_override("font_outline_color", Color.BLACK)
	$DifficultyTitle.add_theme_constant_override("outline_size", 1)
	_apply_label_style(total_label)
	_update_total_label()

func _apply_label_style(label: Label) -> void:
	label.add_theme_font_size_override("font_size", 4)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 1)

func _on_trait_changed(_trait_name: String, _new_value: int) -> void:
	_update_total_label()

func _update_total_label() -> void:
	var mult = DifficultyManager.get_money_multiplier()
	total_label.text = "Money Gain: ÑYİTx" + ("%.1f" % mult)
