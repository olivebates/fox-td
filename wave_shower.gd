# Wa.gd (new AutoLoad singleton)

extends Control

@export var preparation_time: float = 20.0
var upcoming_waves: Array[int] = []
var container: VBoxContainer
@onready var next_wave_shower = get_tree().get_first_node_in_group("next_wave_shower")

func _ready():
	anchor_left = 1.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = -140
	offset_top = 80
	offset_bottom = -80
	
	container = VBoxContainer.new()
	container.alignment = BoxContainer.ALIGNMENT_END
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(container)

func reset_preview() -> void:
	upcoming_waves.clear()
	
	# Clear all slots
	for child in container.get_children():
		child.queue_free()
	
	# Reset the next_wave_shower (the bar with rectangles)
	if next_wave_shower:
		next_wave_shower.reset_rectangles()

func add_wave(wave_number: int):
	upcoming_waves.append(wave_number)
	var enemy_type = WaveSpawner.get_enemy_type_for_wave(wave_number)
	_create_slot(wave_number, enemy_type)

func start_wave(wave_number: int):
	if upcoming_waves.front() == wave_number:
		upcoming_waves.pop_front()
		if container.get_child_count() > 0:
			var slot = container.get_child(container.get_child_count() - 1)
			slot.queue_free()  # Bottom slot disappears when wave starts

func _create_slot(wave_number: int, enemy_type: String):
	var slot = Control.new()
	slot.custom_minimum_size = Vector2(120, 80)
	
	# Get color based on enemy type
	var type_color = _get_type_color(enemy_type)
	
	# Stone-like background with type tint
	var bg = ColorRect.new()
	bg.color = Color(0.2, 0.2, 0.2, 0.9).lerp(type_color, 0.3)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	slot.add_child(bg)
	
	# Border with type color
	var border = ReferenceRect.new()
	border.border_color = type_color
	border.editor_only = false
	border.anchor_right = 1.0
	border.anchor_bottom = 1.0
	border.offset_left = -4
	border.offset_top = -4
	border.offset_right = 4
	border.offset_bottom = 4
	slot.add_child(border)
	
	# Wave label with type name
	var label = Label.new()
	label.text = "Wave %d\n%s" % [wave_number, enemy_type.capitalize()]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.anchor_top = 0.0
	label.anchor_bottom = 0.5
	label.anchor_left = 0.0
	label.anchor_right = 1.0
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", type_color.lightened(0.3))
	slot.add_child(label)
	
	# Progress bar (fills upward) with type color
	var progress = ProgressBar.new()
	progress.anchor_top = 0.5
	progress.anchor_bottom = 1.0
	progress.anchor_left = 0.1
	progress.anchor_right = 0.9
	progress.rotation_degrees = 180  # Flip to fill upward
	progress.value = 0
	progress.max_value = 100
	progress.add_theme_stylebox_override("fill", _stone_style(type_color))
	progress.add_theme_stylebox_override("bg", _dark_style())
	slot.add_child(progress)
	
	slot.set_meta("progress", progress)
	slot.set_meta("enemy_type", enemy_type)
	container.add_child(slot)
	container.move_child(slot, 0)  # Newest at bottom

func update_progress(wave_number: int, progress_ratio: float):
	if upcoming_waves.is_empty() or upcoming_waves.front() != wave_number:
		return
	var slot = container.get_child(container.get_child_count() - 1)
	var pb: ProgressBar = slot.get_meta("progress")
	pb.value = progress_ratio * 100

func _stone_style(type_color: Color) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = type_color
	return s

func _dark_style() -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.1, 0.1, 0.1)
	return s

func _get_type_color(enemy_type: String) -> Color:
	match enemy_type:
		"normal":
			return Color(0.7, 0.6, 0.4)  # Stone/beige
		"swarm":
			return Color(0.8, 0.4, 0.2)  # Orange
		"fast":
			return Color(0.3, 0.7, 1.0)  # Bright blue
		"boss":
			return Color(0.8, 0.2, 0.2)  # Red
		_:
			return Color(0.7, 0.6, 0.4)  # Default stone color
