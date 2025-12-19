extends Control

@onready var bar: ProgressBar = $Bar
@onready var text: Label = $Text
@onready var red_overlay: ColorRect = $RedOverlay  # Add ColorRect child named "RedOverlay"

var cost_preview_amount: float = 0.0

func _ready() -> void:
	if text == null:
		push_error("Label node 'Text' not found.")
		return
	if red_overlay == null:
		push_error("ColorRect node 'RedOverlay' not found.")
		return
	
	# Background style
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.149, 0.149, 0.149, 1.0)
	bg_style.border_color = Color(0.3, 0.3, 0.3)
	bar.add_theme_stylebox_override("background", bg_style)
	
	# Fill style
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.2, 0.8, 0.2, 1.0)
	bar.add_theme_stylebox_override("fill", fill_style)
	
	bar.show_percentage = false
	bar.min_value = 0
	bar.max_value = StatsManager.max_health
	bar.value = StatsManager.health
	
	# Text setup (overlay)
	text.anchor_left = 0
	text.anchor_top = 0
	text.anchor_right = 1
	text.anchor_bottom = 1
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.add_theme_font_size_override("font_size", 4)
	text.add_theme_color_override("font_color", Color(1, 1, 1))
	
	# Red overlay setup (in front of bar, behind text)
	red_overlay.anchor_left = 0
	red_overlay.anchor_top = 0
	red_overlay.anchor_right = 0
	red_overlay.anchor_bottom = 1
	red_overlay.color = Color(1, 0, 0, 1)
	red_overlay.visible = false
	
	StatsManager.health_changed.connect(_on_health_changed)
	StatsManager.max_health_changed.connect(_on_max_changed)
	_update_text()
	_update_red_overlay()
	
	red_overlay.color = Color(1.0, 0.0, 0.0, 1.0)  # Semi-transparent red
	bar.resized.connect(_update_red_overlay)
	_update_red_overlay()

func _on_health_changed(current: float, max_val: float) -> void:
	bar.value = current
	bar.max_value = max_val
	_update_text()
	_update_red_overlay()

func _on_max_changed(new_max: float) -> void:
	bar.max_value = new_max
	_update_text()
	_update_red_overlay()

func _update_text() -> void:
	text.text = "%d / %d" % [int(StatsManager.health), int(StatsManager.max_health)]

func show_cost_preview(amount: float) -> void:
	cost_preview_amount = amount
	_update_red_overlay()

func hide_cost_preview() -> void:
	cost_preview_amount = 0.0
	_update_red_overlay()

func _update_red_overlay() -> void:
	if cost_preview_amount <= 0.0:
		red_overlay.visible = false
		return
	
	red_overlay.visible = true
	
	var current_ratio = bar.value / bar.max_value
	var deduct_ratio = cost_preview_amount / bar.max_value
	var end_ratio = max(current_ratio - deduct_ratio, 0.0)
	
	var fill_style: StyleBoxFlat = bar.get_theme_stylebox("fill")
	var margin_left = fill_style.content_margin_left
	var margin_right = fill_style.content_margin_right
	var usable_width = bar.size.x - margin_left - margin_right
	
	var start_x = margin_left + usable_width * current_ratio
	var end_x = margin_left + usable_width * end_ratio
	
	start_x = round(start_x)
	end_x = round(end_x)
	
	var overlay_width = max(start_x - end_x, 0)
	
	# Yellow if would clip below 0 (overdeduct), else red
	if current_ratio - deduct_ratio < 0.0:
		red_overlay.color = Color(1.0, 0.0, 0.0, 1.0)  # Red
	else:
		red_overlay.color = Color(1.0, 1.0, 0.0, 1.0)  # Yellow
	
	red_overlay.position = Vector2(bar.position.x + end_x+1, bar.position.y)
	red_overlay.size = Vector2(overlay_width-1, bar.size.y)
