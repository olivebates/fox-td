extends ColorRect
@export var brightness_shift := 0.7  # 0.0 = original (darker), 1.0 = white
@export var is_button_shadow = false

func _ready() -> void:
	await get_tree().process_frame
	if is_button_shadow:
		position += Vector2(1,1)

func _process(delta: float) -> void:
	if is_button_shadow:
		size = get_parent().size
	#await get_tree().process_frame
	var base := GridController.random_tint
	color = Color.from_hsv(GridController.hue, GridController.saturation, GridController.value-brightness_shift, 1)
	color.a = 1.0
