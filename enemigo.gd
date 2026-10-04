extends CharacterBody2D

@export var velocidad = 35.0
@export var distancia_maxima = 160.0 
@onready var sonido_muerte = get_node_or_null("SonidoMuerte")

var distancia_recorrida = 0.0
var esta_girando = false # Nueva variable para pausar el movimiento temporalmente

func _physics_process(delta: float) -> void:
	# Si el enemigo está ejecutando su animación de giro, evitamos que avance o choque
	if esta_girando:
		return
		
	var direccion_frente = Vector2.UP.rotated(rotation)
	var movimiento_este_frame = direccion_frente * velocidad * delta
	var colision = move_and_collide(movimiento_este_frame)
	
	if colision:
		var objeto_chocado = colision.get_collider()
		if objeto_chocado.name == "Kai":
			var nivel_principal = get_tree().current_scene
			if nivel_principal.has_method("matar_a_kai_por_enemigo"):
				nivel_principal.matar_a_kai_por_enemigo()
		else:
			dar_vuelta()
	else:
		distancia_recorrida += movimiento_este_frame.length()
		
		if distancia_recorrida >= distancia_maxima:
			dar_vuelta()

func dar_vuelta() -> void:
	if esta_girando:
		return # Previene que múltiples choques activen varios giros al mismo tiempo
		
	esta_girando = true
	distancia_recorrida = 0.0
	
	# Creamos un Tween para animar la rotación suavemente durante 0.5 segundos
	var tween = create_tween()
	tween.tween_property(self, "rotation_degrees", rotation_degrees + 180, 1.2).set_trans(Tween.TRANS_SINE)
	
	# Una vez que termina la animación de 0.5 segundos, el enemigo vuelve a caminar
	tween.tween_callback(func(): esta_girando = false)
	
func morir() -> void:
	# 1. Detenemos su movimiento
	set_physics_process(false)
	
	# 2. Apagamos su colisión para que Kai y otras balas lo atraviesen
	var colision = get_node_or_null("CollisionShape2D")
	if colision:
		colision.set_deferred("disabled", true)
		
	# 3. Lo hacemos invisible
	var sprite = get_node_or_null("Sprite2D")
	if sprite:
		sprite.hide()
		
	# 4. Reproducimos el sonido, esperamos a que termine y luego borramos el nodo
	if sonido_muerte:
		sonido_muerte.play()
		await sonido_muerte.finished
		
	queue_free()
