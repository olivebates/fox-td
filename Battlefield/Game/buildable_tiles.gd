extends CharacterBody2D

@export var shadow_offset := Vector2(-2, -2)
@export var shadow_color := Color(0, 0, 0, 0.4)
@export var is_placed = false
@onready var sprite: Sprite2D = $Sprite2D

func _draw() -> void:
	await get_tree().process_frame
	if is_placed:
		add_to_group("placed_walls")
	#if sprite.texture:
		#var tex := sprite.texture
		#draw_texture(tex, shadow_offset, shadow_color)
		#draw_texture(tex, shadow_offset-Vector2(1,1), shadow_color)
var variation
func _ready() -> void:
	variation = randf_range(0.82, 1.25)

func _process(delta: float) -> void:
	var base := GridController.random_tint
	sprite.modulate = base * variation
	sprite.modulate.a = 1.0
