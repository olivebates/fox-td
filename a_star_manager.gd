extends Node2D

var astar: AStarGrid2D = AStarGrid2D.new()
const CELL_SIZE: Vector2 = Vector2(8, 8)

func _ready() -> void:
	astar.cell_size = CELL_SIZE
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER  # or adjust as needed
	astar.jumping_enabled = true
	_update_grid()
func _update_grid() -> void:
	var viewport: Rect2 = get_viewport_rect()
	var extra_cells: int = 4
	var grid_cells: Vector2i = Vector2i(
		ceil((viewport.size.x + extra_cells * 2 * CELL_SIZE.x) / CELL_SIZE.x),
		ceil((viewport.size.y + extra_cells * 2 * CELL_SIZE.y) / CELL_SIZE.y)
	)
	var offset: Vector2 = viewport.position - Vector2(extra_cells * CELL_SIZE.x, extra_cells * CELL_SIZE.y)
	astar.region = Rect2i(Vector2i.ZERO, grid_cells)
	astar.offset = offset
	astar.offset += Vector2(4, 4)
	astar.update()

	# --- STEP 1: collect allowed cells ---
	var allowed_cells := {}

	var directions := [
		Vector2i.ZERO,
		Vector2i.LEFT,
		Vector2i.UP,
		Vector2i(-1, -1)
	]

	for node in get_tree().get_nodes_in_group("grid_occupiers"):
		var world_pos: Vector2 = node.global_position - offset
		var base_cell := Vector2i(
			floor(world_pos.x / CELL_SIZE.x),
			floor(world_pos.y / CELL_SIZE.y)
		)

		for dir in directions:
			var cell = base_cell + dir
			if astar.is_in_boundsv(cell):
				allowed_cells[cell] = true

	# --- STEP 2: mark everything else solid ---
	for x in astar.region.size.x:
		for y in astar.region.size.y:
			var cell := Vector2i(x, y)
			var is_valid := allowed_cells.has(cell)
			astar.set_point_solid(cell, not is_valid)


#func _draw() -> void:
	#var green: Color = Color(0, 1, 0, 0.2)
	#var red: Color = Color(1, 0, 0, 0.3)
	#
	#for x in astar.region.size.x:
		#for y in astar.region.size.y:
			#var cell_pos: Vector2i = Vector2i(x, y)
			#var rect: Rect2 = Rect2(astar.get_point_position(cell_pos), CELL_SIZE)
			#var color: Color = red if astar.is_point_solid(cell_pos) else green
			#draw_rect(rect, color, true)

func _process(_delta: float) -> void:
	queue_redraw()
