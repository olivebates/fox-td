extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$GameOverText.add_theme_font_size_override("font_size", 8)
	mouse_filter = Control.MOUSE_FILTER_STOP  # Ensure it captures input
	get_tree().get_first_node_in_group("game_area").visible = false

func _process(delta: float) -> void:
	$GameOverText.text = "You have run out of meat.
Your critters have gone on strike.
You made it far! Good job!"
