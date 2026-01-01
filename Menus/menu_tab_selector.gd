# CustomTabContainer.gd
extends TabContainer

func _ready() -> void:
	# Small font size
	add_theme_font_size_override("font_size", 4)
	
	# Font outline
	add_theme_color_override("font_outline_color", Color.BLACK)
	add_theme_constant_override("outline_size", 1)
	
	# Common base style
	var base = StyleBoxFlat.new()
	base.content_margin_left = 3
	base.content_margin_right = 3
	base.content_margin_top = 0
	base.content_margin_bottom = 1
	
	# Inactive tab (tab_unselected)
	var inactive = base.duplicate()
	inactive.bg_color = Color(0.2, 0.2, 0.2)
	add_theme_stylebox_override("tab_unselected", inactive)
	
	# Hover on inactive
	var inactive_hover = base.duplicate()
	inactive_hover.bg_color = Color(0.3, 0.3, 0.3)
	add_theme_stylebox_override("tab_hovered", inactive_hover)
	
	# Selected tab (tab_selected)
	var selected = base.duplicate()
	selected.bg_color = Color(1.0, 0.5, 0.2)
	add_theme_stylebox_override("tab_selected", selected)
	
	# No focus style
	add_theme_stylebox_override("tab_focus", StyleBoxEmpty.new())
	
	# Panel (optional, dark background)
	var panel = StyleBoxFlat.new()
	panel.bg_color = Color(0.15, 0.15, 0.15)
	add_theme_stylebox_override("panel", panel)
