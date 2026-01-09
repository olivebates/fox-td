extends Control
@export var rectangle_count: int = 10
@export var speed: float = 2.9
@export var speed_multiplier: float = 12.0  # Speed boost when clicking
@export var bar_width: float = 8.0
@export var bar_height: float = 600.0
@export var rect_height: float = 40.0

var rectangles: Array[Dictionary] = []
var current_speed: float
var boosted_rect_index: int = -1  # Track which rectangle was clicked

func _get_type_color(enemy_type: String) -> Color:
	match enemy_type:
		"normal":
			return Color(0.7, 0.6, 0.4)  # Stone/beige
		"swarm":
			return Color(0.8, 0.4, 0.2)  # Orange
		"fast":
			return Color(0.3, 0.7, 1.0)  # Bright blue
		"splitter":
			return Color(0.6, 0.4, 0.2)  # Brown
		"spirit_fox":
			return Color(0.6, 0.8, 1.0)  # Pale blue
		"regenerator":
			return Color(0.3, 0.8, 0.4)  # Green
		"revenant":
			return Color(0.7, 0.3, 0.7)  # Magenta
		"swarmling":
			return Color(0.9, 0.8, 0.3)  # Yellow
		"hardened":
			return Color(0.4, 0.4, 0.4)  # Dark gray
		"stalker":
			return Color(0.4, 0.6, 0.7)  # Steel
		"boss":
			return Color(0.8, 0.2, 0.2)  # Red
		_:
			return Color(0.2, 0.6, 1.0)  # Default blue


func _ready():
	size = Vector2(bar_width, bar_height)
	mouse_filter = Control.MOUSE_FILTER_STOP
	current_speed = speed
	for i in rectangle_count:
		var y = 5 + i * rect_height
		var wave_num = i + 1
		var enemy_type = WaveSpawner.get_enemy_type_for_wave(wave_num)
		var rect_data = {
			"rect": Rect2(Vector2(0, y), Vector2(bar_width, rect_height)),
			"enemy_type": enemy_type
		}
		rectangles.append(rect_data)

func reset_rectangles() -> void:
	rectangles.clear()
	current_speed = speed
	boosted_rect_index = -1
	
	# Recreate the initial rectangles with enemy types
	for i in rectangle_count:
		var y = 5 + i * rect_height
		var wave_num = i + 1
		var enemy_type = WaveSpawner.get_enemy_type_for_wave(wave_num)
		var rect_data = {
			"rect": Rect2(Vector2(0, y), Vector2(bar_width, rect_height)),
			"enemy_type": enemy_type
		}
		rectangles.append(rect_data)
	
	queue_redraw()


func _process(delta):
	var i: int = 0
	while i < rectangles.size():
		rectangles[i].rect.position.y -= current_speed * delta
		if rectangles[i].rect.position.y <= 0: # Disappear when top edge hits top of screen
			# Check if this was the boosted rectangle
			if i == boosted_rect_index:
				current_speed = speed  # Reset to normal speed
				boosted_rect_index = -1
			elif boosted_rect_index > i:
				boosted_rect_index -= 1  # Adjust index after removal
			
			rectangles.remove_at(i)
			#WaveSpawner.start_next_wave()
		else:
			i += 1
	queue_redraw()

func _draw():
	for i in range(rectangles.size()):
		var rect_data = rectangles[i]
		var rect = rect_data.rect
		var enemy_type = rect_data.enemy_type
		var color = _get_type_color(enemy_type)
		
		# Highlight the boosted rectangle
		if i == boosted_rect_index:
			color = color.lightened(0.4)  # Brighten when boosted
		
		draw_rect(rect, color, true) # Fill
		draw_rect(rect, Color(1, 1, 1), false, 2.0) # White outline
	
	draw_rect(Rect2(0, 0, bar_width, bar_height), Color(0.1, 0.1, 0.1), false, 2.0)



func _gui_input(event):pass
	#if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		#var mouse_pos = event.position
		#
		## Check if click is within any rectangle
		#for i in range(rectangles.size()):
			#if rectangles[i].rect.has_point(mouse_pos):
				#boosted_rect_index = i
				#current_speed = speed * speed_multiplier
				#break
