extends Area2D

@export var velocidad = 500

func _physics_process(delta: float) -> void:
	var direccion_frente = Vector2.UP.rotated(rotation)
	position += direccion_frente * velocidad * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemigos"):
		if body.has_method("morir"):
			body.morir()
		else:
			body.queue_free()
		queue_free()
	elif body.name != "Kai":
		queue_free()
