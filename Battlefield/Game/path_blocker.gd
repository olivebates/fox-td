extends StaticBody2D
const LINE_WIDTH = 1.0
@export var cell_size = 16.0
@export var shadow_offset = Vector2(-2, -2)
@export var shadow_color = Color(0, 0, 0, 0.4)

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	#var gray = randf_range(0.75, 1.0)
	#sprite.modulate = Color(gray, gray, 1, 1)
	_apply_cell_size()
	await get_tree().process_frame


var shadow
var highlight

func apply_cell_size(new_size: float) -> void:
	if new_size <= 0.0:
		return
	cell_size = new_size
	_apply_cell_size()

func get_cell_size() -> float:
	return cell_size

func _apply_cell_size() -> void:
	if collision_shape == null:
		return
	var shape = collision_shape.shape
	if shape is RectangleShape2D:
		shape.size = Vector2(cell_size, cell_size)
	if sprite and sprite.texture:
		var tex_size = sprite.texture.get_size()
		if tex_size.x > 0.0 and tex_size.y > 0.0:
			sprite.scale = Vector2(cell_size / tex_size.x, cell_size / tex_size.y)

func _process(delta: float) -> void:
	sprite.modulate = GridController.random_tint
	queue_redraw()

func _draw() -> void:
	shadow = Color.from_hsv(GridController.hue, GridController.saturation, GridController.value-0.8, 1)
	highlight = Color.from_hsv(GridController.hue, GridController.saturation, GridController.value-0.5, 1)
	var dirs = {
		Vector2.UP:    shadow,
		Vector2.DOWN:  highlight,
		Vector2.LEFT:  shadow,
		Vector2.RIGHT: highlight
	}
	
	
	for dir in dirs.keys():
		var neighbor_pos = global_position + dir * cell_size
		var has_neighbor = get_tree().get_nodes_in_group("grid_occupiers") \
			.any(func(occ): return occ != self and occ.global_position == neighbor_pos)
		
		if not has_neighbor:
			var perp = dir.rotated(PI/2) * (cell_size / 2.0)
			var pos = dir * (cell_size / 2.0 + 0.5)
			draw_line(perp + pos, -perp + pos, dirs[dir], LINE_WIDTH)
