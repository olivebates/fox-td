extends Control

@onready var bar: ProgressBar = $Bar
@onready var text: Label = $Text
@onready var red_overlay: ColorRect = $Bar/RedOverlay
@onready var prodSpeedLabel: Label = $ProdictionSpeed
@onready var health_bar_gui = get_tree().get_first_node_in_group("HealthBarContainer")
var cost_preview_amount: float = 0.0

func _update_prod_speed_text() -> void:
	prodSpeedLabel.text = "Production: " + str(StatsManager.production_speed)

func _ready() -> void:
	prodSpeedLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prodSpeedLabel.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prodSpeedLabel.add_theme_font_size_override("font_size", 2)
	_update_prod_speed_text()
	StatsManager.production_speed_changed.connect(_update_prod_speed_text)
	
	# Background style
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.149, 0.149, 0.149)
	bg_style.border_color = Color(0.3, 0.3, 0.3)
	bar.add_theme_stylebox_override("background", bg_style)
	# Fill style
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color(0.2, 0.8, 0.2)
	bar.add_theme_stylebox_override("fill", fill_style)

	bar.show_percentage = false
	bar.min_value = 0

	# Text overlay
	text.anchor_left = 0
	text.anchor_top = 0
	text.anchor_right = 1
	text.anchor_bottom = 1
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.add_theme_constant_override("outline_size", 1)
	text.add_theme_font_size_override("font_size", 4)
	text.add_theme_color_override("font_color", Color.WHITE)

	# Red overlay setup (BAR-LOCAL SPACE)
	red_overlay.anchor_left = 0
	red_overlay.anchor_right = 0
	red_overlay.anchor_top = 0
	red_overlay.anchor_bottom = 1
	red_overlay.offset_top = 0
	red_overlay.offset_bottom = 0
	red_overlay.visible = false

	StatsManager.health_changed.connect(_on_health_changed)
	StatsManager.max_health_changed.connect(_on_max_changed)
	bar.resized.connect(_update_red_overlay)
	
	_update_text()
	_update_red_overlay()
	$Bar.mouse_entered.connect(_on_mouse_entered)
	$Bar.mouse_exited.connect(_on_mouse_exited)


func _on_mouse_entered() -> void:
	TooltipManager.show_tooltip(
	"Meat",
	"[font_size=3][color=cornflower_blue]Production: " + str(StatsManager.production_speed).trim_suffix(".0") + "/s\n"+
	"Kill multiplier: x" +str(StatsManager.kill_multiplier).trim_suffix(".0") +"\n"+
	"[/color][/font_size]" +
	"[color=gray]————————————————[/color]\n"+
	"[font_size=2][color=dark_gray]Meat is used to buy and upgrade towers.
Maxing it out levels up, increasing production![/color][/font_size]"
	)

func _on_mouse_exited() -> void:
	TooltipManager.hide_tooltip()

func _on_health_changed(current: float, max_val: float) -> void:
	bar.value = current
	bar.max_value = max_val
	_update_text()
	_update_red_overlay()

func _on_max_changed(new_max: float) -> void:
	if new_max != StatsManager.base_max_health:
		Utilities.spawn_floating_text("Level Up!", get_parent().position, get_tree().current_scene, true)
		StatsManager.level += 1
	bar.max_value = new_max
	_update_text()
	_update_red_overlay()

func _update_text() -> void:
	text.text = "🥩%d / %d" % [
		int(StatsManager.health),
		int(StatsManager.max_health)
	]

func show_cost_preview(amount: float) -> void:
	cost_preview_amount = amount
	_update_red_overlay()

func hide_cost_preview() -> void:
	cost_preview_amount = 0.0
	_update_red_overlay()

func _update_red_overlay() -> void:
	if cost_preview_amount <= 0.0 or bar.max_value <= 0:
		red_overlay.visible = false
		return

	red_overlay.visible = true

	var width := bar.size.x

	# Godot ProgressBar snaps internally — we must too
	var current_px := int(round(width * bar.value / bar.max_value))
	var end_px := int(round(width * max(bar.value - cost_preview_amount, 0.0) / bar.max_value))

	var overlay_width = max(current_px - end_px, 0)

	# Color logic
	if bar.value - cost_preview_amount < 0.1:
		red_overlay.color = Color(1.0, 0.0, 0.0, 1.0)
	else:
		red_overlay.color = Color(1.0, 1.0, 0.0, 1.0)

	red_overlay.position = Vector2(end_px, 0)
	red_overlay.size = Vector2(overlay_width, bar.size.y)


func _process(delta: float) -> void:
	bar.max_value = StatsManager.max_health
	bar.value = StatsManager.health
	queue_redraw()
# Level number
#func _draw() -> void:
	#if bar.size.x <= 0: return
	#var center := Vector2(31, bar.size.y / 2.0 - 15.0)
	#var radius := 2.5
	#draw_circle(center, radius, Color(0.7, 0.95, 1.0))
	#draw_arc(center, radius, 0, TAU, 64, Color(0.1, 0.4, 0.6), 1.0)
	#
	#var font := get_theme_default_font()
	#var font_size := 3
	#var str_text := str(StatsManager.level)
	#var text_size := font.get_string_size(str_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	#var pos := center - text_size / 2 + Vector2(0.25, 3.5)  # slight vertical tweak for centering
	#draw_string(font, pos, str_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.BLACK)
