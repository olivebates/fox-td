extends Button

var highlight_mode: bool = false

const WALL_PREFAB_UID: String = "uid://71114a1asxv"
const WALL_PREVIEW_TEXTURE_UID: String = "uid://c3n6vabbm3ngv"  # UID of the preview texture
var wall_prefab: PackedScene
var wall_preview_texture: Texture2D
var wall_cost: float = 10.0
var walls_placed: int = 0

var start_pos: Vector2
var goal_pos: Vector2

@onready var health_bar_gui = get_tree().get_first_node_in_group("HealthBarContainer")
@onready var wave_spawner = get_tree().get_first_node_in_group("wave_spawner")

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	toggle_mode = true
	toggled.connect(_on_toggled)
	add_theme_font_size_override("font_size", 4)
	
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.2, 0.2, 0.2)
	style_normal.border_width_left = 0
	style_normal.border_width_top = 0
	style_normal.border_width_right = 0
	style_normal.border_width_bottom = 0
	style_normal.corner_radius_top_left = 0
	style_normal.corner_radius_top_right = 0
	style_normal.corner_radius_bottom_left = 0
	style_normal.corner_radius_bottom_right = 0
	style_normal.content_margin_left = 3
	style_normal.content_margin_right = 3
	style_normal.content_margin_top = 0
	style_normal.content_margin_bottom = 1
	
	var style_hover = style_normal.duplicate()
	style_hover.bg_color = Color(0.3, 0.3, 0.3)
	style_hover.border_color = Color(0.7, 0.7, 0.7)
	
	var style_pressed = style_normal.duplicate()
	style_pressed.bg_color = Color(0.15, 0.15, 0.15)
	style_pressed.border_color = Color(0.8, 0.8, 0.8)
	
	add_theme_stylebox_override("normal", style_normal)
	add_theme_stylebox_override("hover", style_hover)
	add_theme_stylebox_override("pressed", style_pressed)
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	wall_prefab = ResourceLoader.load(WALL_PREFAB_UID)
	wall_preview_texture = ResourceLoader.load(WALL_PREVIEW_TEXTURE_UID)
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	TooltipManager.show_tooltip(
	"Build Walls",
	"[font_size=3][color=cornflower_blue]Costs: " + str(int(GridController.get_wall_cost())) + "[/color][/font_size]\n[color=gray]————————————————[/color]\n" +
	"[font_size=2][color=dark_gray]Click on the path to build a wall!\n" +
	"Walls cannot be removed, so place them carefully![/color][/font_size]"
	)


func _on_mouse_exited() -> void:
	TooltipManager.hide_tooltip()
	
func _on_toggled(pressed: bool) -> void:
	highlight_mode = pressed
	GridController.highlight_mode = pressed
	GridController.queue_redraw()
	
	var base = StyleBoxFlat.new()
	base.border_width_left = 0
	base.border_width_top = 0
	base.border_width_right = 0
	base.border_width_bottom = 0
	base.corner_radius_top_left = 0
	base.corner_radius_top_right = 0
	base.corner_radius_bottom_left = 0
	base.corner_radius_bottom_right = 0
	base.content_margin_left = 3
	base.content_margin_right = 3
	base.content_margin_top = 0
	base.content_margin_bottom = 1
	
	var hover_style: StyleBoxFlat
	var pressed_style: StyleBoxFlat
	
	if pressed:
		base.bg_color = Color(1.0, 0.6, 0.3)
		base.border_color = Color(1.0, 0.8, 0.5)
		hover_style = base.duplicate()
		hover_style.bg_color = Color(1.0, 0.7, 0.4)
		pressed_style = base.duplicate()
		pressed_style.bg_color = Color(0.9, 0.5, 0.2)
	else:
		base.bg_color = Color(0.2, 0.2, 0.2)
		base.border_color = Color(0.5, 0.5, 0.5)
		hover_style = base.duplicate()
		hover_style.bg_color = Color(0.3, 0.3, 0.3)
		hover_style.border_color = Color(0.7, 0.7, 0.7)
		pressed_style = base.duplicate()
		pressed_style.bg_color = Color(0.15, 0.15, 0.15)
		pressed_style.border_color = Color(0.8, 0.8, 0.8)
	
	add_theme_stylebox_override("normal", base)
	add_theme_stylebox_override("hover", hover_style)
	add_theme_stylebox_override("pressed", pressed_style)
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func _process(_delta: float) -> void:
	if highlight_mode:
		var cell := GridController.get_cell_from_pos(get_global_mouse_position())
		if cell != Vector2i(-1, -1):
			# Check if placement would be valid (no existing wall + path remains open)
			var can_place := true
			for wall in get_tree().get_nodes_in_group("walls"):
				if GridController.get_cell_from_pos(wall.global_position) == cell:
					can_place = false
					break
			if can_place:
				var current_cost: float = GridController.wall_cost + (GridController.walls_placed * GridController.cost_increment)
				health_bar_gui.show_cost_preview(current_cost)
			else:
				health_bar_gui.show_cost_preview(0.0)
		else:
			health_bar_gui.show_cost_preview(0.0)
		queue_redraw()
