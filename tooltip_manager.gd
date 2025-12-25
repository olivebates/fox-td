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
	
	# Force immediate layout update
	tooltip.size = Vector2(0, 0)
	await get_tree().process_frame
	
	tooltip.visible = true

func hide_tooltip() -> void:
	tooltip.visible = false

func _process(_delta: float) -> void:
	if tooltip.visible:
		var mouse_pos = get_viewport().get_mouse_position()
		var viewport_rect = get_viewport().get_visible_rect()
		
		var pos = mouse_pos + Vector2(10, 10)
		
		if pos.x + tooltip.size.x > viewport_rect.end.x:
			pos.x = mouse_pos.x - tooltip.size.x - 10
		if pos.y + tooltip.size.y > viewport_rect.end.y:
			pos.y = mouse_pos.y - tooltip.size.y - 10
		
		pos.x = clamp(pos.x, 0, viewport_rect.size.x - tooltip.size.x)
		pos.y = clamp(pos.y, 0, viewport_rect.size.y - tooltip.size.y)
		
		tooltip.position = pos
