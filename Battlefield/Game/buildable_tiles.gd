extends CharacterBody2D

@export var shadow_offset := Vector2(-2, -2)
@export var shadow_color := Color(0, 0, 0, 0.4)

@onready var sprite: Sprite2D = $Sprite2D

func _draw() -> void:pass
	#if sprite.texture:
		#var tex := sprite.texture
		#draw_texture(tex, shadow_offset, shadow_color)
		#draw_texture(tex, shadow_offset-Vector2(1,1), shadow_color)

func _ready() -> void:
	var gray := randf_range(0.75, 1.0)
	sprite.modulate = Color(gray, gray, 1, 1)
