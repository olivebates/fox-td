# CustomTabContainer.gd
extends TabContainer

func _ready() -> void:
	# Font styling
	add_theme_font_size_override("font_size", 4)
	add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.5))
	add_theme_constant_override("outline_size", 1)
	
	# Base style with better padding
	var base = StyleBoxFlat.new()
	base.content_margin_left = 4
	base.content_margin_right = 4
	base.content_margin_top = 4
	base.content_margin_bottom = 4
	base.corner_radius_bottom_left = 6
	base.corner_radius_bottom_right = 6
	
	# Inactive tab - subtle gray
	var inactive = base.duplicate()
	inactive.bg_color = Color(0.25, 0.25, 0.28)
	inactive.border_width_bottom = 2
	inactive.border_color = Color(0.15, 0.15, 0.18)
	add_theme_stylebox_override("tab_unselected", inactive)
	
	# Hover state - lighter with smooth transition feel
	var inactive_hover = base.duplicate()
	inactive_hover.bg_color = Color(0.32, 0.32, 0.36)
	inactive_hover.border_width_bottom = 2
	inactive_hover.border_color = Color(0.4, 0.4, 0.45)
	add_theme_stylebox_override("tab_hovered", inactive_hover)
	
	# Selected tab - vibrant accent with shadow effect
	var selected = base.duplicate()
	selected.bg_color = Color(0.95, 0.55, 0.25)
	selected.border_width_bottom = 3
	selected.border_color = Color(0.85, 0.45, 0.15)
	selected.shadow_size = 1
	selected.shadow_color = Color(0.0, 0.0, 0.0, 0.0)
	selected.shadow_offset = Vector2(0, 2)
	add_theme_stylebox_override("tab_selected", selected)
	
	# Disabled tab state
	var disabled = base.duplicate()
	disabled.bg_color = Color(0.2, 0.2, 0.22)
	add_theme_stylebox_override("tab_disabled", disabled)
	add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.5))
	
	# Clean focus style
	add_theme_stylebox_override("tab_focus", StyleBoxEmpty.new())
	
	# Panel with subtle gradient feel
	var panel = StyleBoxFlat.new()
	panel.bg_color = Color(0.18, 0.18, 0.2, 0.0)
	panel.border_width_left = 1
	panel.border_width_right = 1
	panel.border_width_bottom = 1
	panel.border_color = Color(0.122, 0.122, 0.141, 0.0)
	panel.corner_radius_bottom_left = 4
	panel.corner_radius_bottom_right = 4
	add_theme_stylebox_override("panel", panel)
	
	# Tab separation
	add_theme_constant_override("h_separation", 4)
