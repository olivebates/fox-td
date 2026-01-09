extends Button

const POLL_INTERVAL := 0.2
var _poll_timer: float = 0.0
var _normal_style: StyleBoxFlat
var _hover_style: StyleBoxFlat
var _current_color: Color = Color(0.2, 0.2, 0.2)

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	text = "Next"
	add_theme_font_size_override("font_size", 4)
	add_theme_color_override("font_outline_color", Color.BLACK)
	add_theme_constant_override("outline_size", 1)
	add_theme_constant_override("h_separation", 0)
	add_theme_constant_override("corner_radius_top_left", 0)
	add_theme_constant_override("corner_radius_top_right", 0)
	add_theme_constant_override("corner_radius_bottom_right", 0)
	add_theme_constant_override("corner_radius_bottom_left", 0)
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_apply_style()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _apply_style() -> void:
	_normal_style = StyleBoxFlat.new()
	_hover_style = StyleBoxFlat.new()
	for stylebox in [_normal_style, _hover_style]:
		stylebox.content_margin_left = 0
		stylebox.content_margin_right = 0
		stylebox.content_margin_top = 0
		stylebox.content_margin_bottom = 0
	_set_wave_style(_current_color)
	add_theme_stylebox_override("normal", _normal_style)
	add_theme_stylebox_override("hover", _hover_style)

func _set_wave_style(base_color: Color) -> void:
	_current_color = base_color
	_normal_style.bg_color = base_color
	_hover_style.bg_color = base_color.lightened(0.15)

func _process(delta: float) -> void:
	_poll_timer += delta
	if _poll_timer < POLL_INTERVAL:
		return
	_poll_timer = 0.0
	var display_wave = _get_display_wave_index(WaveSpawner.current_wave)
	var preview = WaveSpawner.get_wave_preview(display_wave)
	if preview.is_empty():
		text = "Next"
		_set_wave_style(Color(0.2, 0.2, 0.2))
		return
	var type_data = WaveSpawner.get_enemy_type_data(preview.type)
	var label = type_data.get("label", preview.type)
	text = str(label)
	var wave_color_name = preview.get("color", WaveSpawner.get_wave_color(display_wave))
	var wave_color = InventoryManager.get_color_value(wave_color_name).darkened(0.2)
	if not _current_color.is_equal_approx(wave_color):
		_set_wave_style(wave_color)

func _on_mouse_entered() -> void:
	var display_wave = _get_display_wave_index(WaveSpawner.current_wave)
	var preview = WaveSpawner.get_wave_preview(display_wave)
	var type_data = WaveSpawner.get_enemy_type_data(preview.type)
	var label = type_data.get("label", preview.type)
	var base_speed = float(type_data.get("speed", 0.0))
	var final_speed = DifficultyManager.get_enemy_spawn_speed(base_speed)
	var final_health = DifficultyManager.get_enemy_spawn_health(int(preview.health))
	var abilities: Array = type_data.get("abilities", [])
	var wave_color = preview.get("color", WaveSpawner.get_wave_color(display_wave))
	var title_prefix = "Final Wave " if WaveSpawner.current_wave > WaveSpawner.MAX_WAVES else "Wave "
	var title = title_prefix + str(int(display_wave)) + " - " + str(label)
	var info_line = "[font_size=3][color=cornflower_blue]Count: " + str(int(preview.count)) \
		+ " | HP: " + str(int(final_health)) + " | Speed: " + str(int(round(final_speed))) + "[/color][/font_size]"
	var desc = info_line + "\n[font_size=2][color=dark_gray]Wave Color: " + str(wave_color).capitalize() + "[/color][/font_size]\n[color=gray]----------------[/color]"
	if abilities.size() > 0:
		desc += "\n[font_size=2][color=dark_gray]- " + "\n- ".join(abilities) + "[/color][/font_size]"
	TooltipManager.show_tooltip(title, desc)

func _on_mouse_exited() -> void:
	TooltipManager.hide_tooltip()

func _get_display_wave_index(wave_index: int) -> int:
	if wave_index > WaveSpawner.MAX_WAVES:
		return WaveSpawner.MAX_WAVES
	return max(1, wave_index)
