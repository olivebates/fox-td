extends CharacterBody2D
class_name Enemy

@export var max_speed: float = 80.0
@export var health: int = 50
var current_health: int = 50

func _ready():
	current_health = health
	add_to_group("enemies")

func _physics_process(delta: float):
	var follow: PathFollow2D = get_parent()
	if follow:
		follow.progress += max_speed * delta
		if follow.progress_ratio >= 0.999:
			die()

func take_damage(amount: int):
	current_health -= amount
	if current_health <= 0:
		die()

func die():
	get_parent().queue_free()
