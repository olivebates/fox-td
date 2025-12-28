# TooltipManager.gd (Autoload singleton)

extends Node

var tooltip: PanelContainer
var title_label: Label
var desc_rich: RichTextLabel

func _ready() -> void:
	tooltip = PanelContainer.new()
	add_child(tooltip)
	tooltip.visible = false
	tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip.z_index = 1002
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.8)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	tooltip.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_right", 4)
	tooltip.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	margin.add_child(vbox)
	
	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 4)
	title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	title_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(title_label)
	
	desc_rich = RichTextLabel.new()
	desc_rich.bbcode_enabled = true
	desc_rich.fit_content = true
	desc_rich.scroll_active = false
	desc_rich.autowrap_mode = TextServer.AUTOWRAP_OFF
	desc_rich.add_theme_font_size_override("normal_font_size", 3)
	desc_rich.add_theme_color_override("default_color", Color.LIGHT_GRAY)
	desc_rich.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(desc_rich)
	
	tooltip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tooltip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	desc_rich.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_rich.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc_rich.fit_content = true  # already set, keep it

	# Also ensure VBoxContainer centers children:
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER

func show_tooltip(title: String, description_bbcode: String) -> void:
	title_label.text = title
	desc_rich.bbcode_text = description_bbcode
	
	tooltip.visible = true
	# Force layout update for correct sizing
	tooltip.size = Vector2(0, 0)
	await get_tree().process_frame

func hide_tooltip() -> void:
	tooltip.visible = false

func append_to_current_tooltip(bbcode: String) -> void:
	if tooltip.visible:
		desc_rich.text += bbcode
		tooltip.size = Vector2(0, 0)
		await get_tree().process_frame

func _process(_delta: float) -> void:
	if not tooltip.visible:
		return
	
	var mouse_pos = get_viewport().get_mouse_position()
	var viewport_rect = get_viewport().get_visible_rect()
	
	var tooltip_size = tooltip.size
	var offset = Vector2(16, 16)
	var pos = mouse_pos + offset
	
	# Flip horizontally if off right edge
	if pos.x + tooltip_size.x > viewport_rect.size.x:
		pos.x = mouse_pos.x - tooltip_size.x - offset.x
	
	# Flip vertically if off bottom edge
	if pos.y + tooltip_size.y > viewport_rect.size.y:
		pos.y = mouse_pos.y - tooltip_size.y - offset.y
	
	# Clamp to viewport
	pos.x = clamp(pos.x, 0, viewport_rect.size.x - tooltip_size.x)
	pos.y = clamp(pos.y, 0, viewport_rect.size.y - tooltip_size.y)
	
	tooltip.position = pos
