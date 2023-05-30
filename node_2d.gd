extends Node2D

@onready var generation = get_node("Generation")

func _ready() -> void:
	generation.generate_room()

@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("generate"):
		generation.clear()
		generation.generate_room()
