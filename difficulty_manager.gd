extends Node
class_name TraitData

signal trait_changed(trait_name: String, new_value: int)

# Trait name -> level
var traits := {
	"Strength": 1,
	"Agility": 1,
	"Intelligence": 1,
	"Luck": 1
}

const MIN_LEVEL := 0
const MAX_LEVEL := 10

func get_trait(trait_name: String) -> int:
	return traits.get(trait_name, 0)

func increase_trait(trait_name: String) -> void:
	if traits.has(trait_name) and traits[trait_name] < MAX_LEVEL:
		traits[trait_name] += 1
		trait_changed.emit(trait_name, traits[trait_name])

func decrease_trait(trait_name: String) -> void:
	if traits.has(trait_name) and traits[trait_name] > MIN_LEVEL:
		traits[trait_name] -= 1
		trait_changed.emit(trait_name, traits[trait_name])

func get_all_traits():
	return traits.keys()
