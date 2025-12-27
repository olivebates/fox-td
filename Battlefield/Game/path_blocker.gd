extends StaticBody2D
const CELL_SIZE := 16.0
const OFFSET := 8.5
const LINE_WIDTH := 1.0
@export var shadow_offset := Vector2(-2, -2)
@export var shadow_color := Color(0, 0, 0, 0.4)

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	#var gray := randf_range(0.75, 1.0)
	#sprite.modulate = Color(gray, gray, 1, 1)
	await get_tree().process_frame


var shadow
var highlight

func _process(delta: float) -> void:
	sprite.modulate = GridController.random_tint
	queue_redraw()

func _draw() -> void:
	shadow = Color.from_hsv(GridController.hue, GridController.saturation, GridController.value-0.8, 1)
	highlight = Color.from_hsv(GridController.hue, GridController.saturation, GridController.value-0.5, 1)
	var dirs := {
		Vector2.UP:    shadow,
		Vector2.DOWN:  highlight,
		Vector2.LEFT:  shadow,
		Vector2.RIGHT: highlight
	}
	
	
	for dir in dirs.keys():
		var neighbor_pos = global_position + dir * CELL_SIZE
		var has_neighbor := get_tree().get_nodes_in_group("grid_occupiers") \
			.any(func(occ): return occ != self and occ.global_position == neighbor_pos)
		
		if not has_neighbor:
			var perp = dir.rotated(PI/2) * (CELL_SIZE / 2.0)
			var pos = dir * OFFSET
			draw_line(perp + pos, -perp + pos, dirs[dir], LINE_WIDTH)
