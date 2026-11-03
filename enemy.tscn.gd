extends CharacterBody2D

@export var speed: float = 35.0
@export var max_distance: float = 160.0 
@onready var death_sound = get_node_or_null("DeathSound")

var distance_traveled: float = 0.0
var is_turning: bool = false # Nueva variable para pausar el movimiento temporalmente

func _physics_process(delta: float) -> void:
	# Si el enemigo está ejecutando su animación de giro, evitamos que avance o choque
	if is_turning:
		return
		
	var forward_direction = Vector2.UP.rotated(rotation)
	var movement_this_frame = forward_direction * speed * delta
	var collision = move_and_collide(movement_this_frame)
	
	if collision:
		var collided_object = collision.get_collider()
		if collided_object.name == "Kai":
			var main_level = get_tree().current_scene
			# Llama directamente a la función maestra del nivel para morir
			if main_level.has_method("game_over"):
				main_level.game_over("¡El monstruo te ha matado!\nInténtalo de nuevo.")
		else:
			turn_around()
	else:
		distance_traveled += movement_this_frame.length()
		
		if distance_traveled >= max_distance:
			turn_around()

func turn_around() -> void:
	if is_turning:
		return # Previene que múltiples choques activen varios giros al mismo tiempo
		
	is_turning = true
	distance_traveled = 0.0
	
	# Creamos un Tween para animar la rotación suavemente
	var tween = create_tween()
	tween.tween_property(self, "rotation_degrees", rotation_degrees + 180, 1.2).set_trans(Tween.TRANS_SINE)
	
	# Una vez que termina la animación, el enemigo vuelve a caminar
	tween.tween_callback(func(): is_turning = false)
	
func die() -> void:
	# 1. Detenemos su movimiento
	set_physics_process(false)
	
	# 2. Apagamos su colisión para que Kai y otras balas lo atraviesen
	var collision_shape = get_node_or_null("CollisionShape2D")
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
		
	# 3. Lo hacemos invisible
	var sprite = get_node_or_null("Sprite2D") # Ajusta si tu nodo se llama AnimatedSprite2D
	if sprite:
		sprite.hide()
		
	# 4. Reproducimos el sonido, esperamos a que termine y luego borramos el nodo
	if death_sound:
		death_sound.play()
		await death_sound.finished
		
	queue_free()
