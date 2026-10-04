extends Area2D

@export var velocidad = 500.0

func _physics_process(delta: float) -> void:
	# Usamos Vector2.UP porque la rotación de Kai se calculó asumiendo que mira hacia arriba
	var direccion_frente = Vector2.UP.rotated(rotation)
	position += direccion_frente * velocidad * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemigos"):
		# Verificamos si el enemigo tiene la función "morir" y la ejecutamos
		if body.has_method("morir"):
			body.morir()
		else:
			body.queue_free()
			
		queue_free() # La bala sí desaparece al instante
		
	elif body.name != "Kai":
		queue_free()
