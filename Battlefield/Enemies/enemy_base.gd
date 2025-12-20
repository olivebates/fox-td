# Modified Enemy script
extends CharacterBody2D
class_name Enemy

@export var max_speed: float = 800.0
@export var health: int = 50

var current_health: int = 50
var health_bg: ColorRect
var health_fg: ColorRect
var sprite: Node  # Assuming your visual is a Sprite2D or AnimatedSprite2D

func _ready():
	current_health = health
	add_to_group("enemies")
	sprite = $Sprite2D  # Change to your sprite node name/path
	create_healthbar()
	update_healthbar()

func create_healthbar():
	health_bg = ColorRect.new()
	health_bg.color = Color(0.3, 0.3, 0.3, 0.9)
	health_bg.size = Vector2(10, 6)
	health_bg.top_level = true
	add_child(health_bg)
	
	health_fg = ColorRect.new()
	health_fg.color = Color(0.2, 0.8, 0.2)
	health_fg.size = Vector2(8, 4)
	health_fg.top_level = true
	add_child(health_fg)

func update_healthbar():
	var offset = Vector2(0, 8)
	var pos = (global_position + offset).round()
	health_bg.global_position = pos - Vector2(5, 3)
	health_fg.global_position = pos - Vector2(4, 2)
	health_fg.size.x = 8.0 * (float(current_health) / health)

func _physics_process(delta: float):
	var follow: PathFollow2D = get_parent()
	if follow:
		follow.progress += (max_speed / 4.0) * delta
		if follow.progress_ratio >= 0.999:
			die()
	update_healthbar()

func take_damage(amount: int):
	current_health -= amount
	update_healthbar()
	
	# Flash red
	var tw = create_tween()
	tw.tween_property(sprite, "modulate", Color.RED, 0.1)
	tw.tween_property(sprite, "modulate", Color.WHITE, 0.3)
	
	if current_health <= 0:
		die()

func die():
	get_tree().call_group("health_manager", "gain_health_from_kill", 2.0)
	get_parent().queue_free()
