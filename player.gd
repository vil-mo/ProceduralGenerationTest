extends CharacterBody2D

var speed = 100

func _physics_process(delta: float) -> void:
	var direction = Vector2(Input.get_axis("left", "right"), Input.get_axis("up", "down")).normalized()
	velocity = speed * direction
	move_and_slide()
