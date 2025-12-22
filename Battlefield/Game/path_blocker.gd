extends StaticBody2D
const CELL_SIZE := 16.0
const OFFSET := 8.5
const LINE_WIDTH := 1.0

func _draw() -> void:
	var dirs := {
		Vector2.UP:    Color("#0A1121"),
		Vector2.DOWN:  Color("#303C54"),
		Vector2.LEFT:  Color("#0A1121"),
		Vector2.RIGHT: Color("#303C54")
	}
	
	for dir in dirs.keys():
		var neighbor_pos = global_position + dir * CELL_SIZE
		var has_neighbor := get_tree().get_nodes_in_group("grid_occupiers") \
			.any(func(occ): return occ != self and occ.global_position == neighbor_pos)
		
		if not has_neighbor:
			var perp = dir.rotated(PI/2) * (CELL_SIZE / 2.0)
			var pos = dir * OFFSET
			draw_line(perp + pos, -perp + pos, dirs[dir], LINE_WIDTH)
