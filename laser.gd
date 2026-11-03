extends Area2D

@export var velocidad = 500
@onready var laser_sound = get_node_or_null("LaserSound")

func _ready() -> void:
	# Apenas el láser entra a la escena, suena
	if laser_sound:
		laser_sound.play()
		
func _physics_process(delta: float) -> void:
	var direccion_frente = Vector2.UP.rotated(rotation)
	position += direccion_frente * velocidad * delta

func _on_body_entered(body: Node2D) -> void:
	# 1. Si choca contra Kai, ignoramos el choque y la bala sigue su camino
	if body.name == "Kai":
		return
		
	# 2. Si choca contra un enemigo, lo matamos
	if body.is_in_group("enemigos"):
		if body.has_method("die"): # Actualizado a "die" para coincidir con tu nuevo script
			body.die()
		else:
			body.queue_free()
			
	# 3. Ya sea que chocó con un enemigo o con una pared, iniciamos la destrucción silenciosa
	_destruir_bala()

func _destruir_bala() -> void:
	# Hacemos invisible el láser
	var sprite = get_node_or_null("Sprite2D")
	if sprite:
		sprite.hide()
		
	# Desactivamos su colisión
	var collision = get_node_or_null("CollisionShape2D")
	if collision:
		collision.set_deferred("disabled", true)
		
	# Detenemos su movimiento
	set_physics_process(false)
	
	# Esperamos a que el sonido del disparo termine antes de borrar el nodo
	if laser_sound and laser_sound.playing:
		await laser_sound.finished
		
	# Finalmente, destruimos el láser de forma segura
	queue_free()
