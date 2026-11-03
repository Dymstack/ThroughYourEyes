extends CharacterBody2D

@export var speed: float = 35.0
@export var max_distance: float = 160.0 

@onready var death_sound = get_node_or_null("DeathSound")
@onready var growl_sound = get_node_or_null("GrowlSound") # Referencia al nuevo sonido

var distance_traveled: float = 0.0
var is_turning: bool = false 

func _ready() -> void:
	if growl_sound == null:
		print("ERROR: No encontré el nodo GrowlSound en este enemigo")
	else:
		print("¡Sonido encontrado! Todo está bien con los nodos")

func _physics_process(delta: float) -> void:
	if is_turning:
		return
		
	var forward_direction = Vector2.UP.rotated(rotation)
	var movement_this_frame = forward_direction * speed * delta
	var collision = move_and_collide(movement_this_frame)
	
	if collision:
		var collided_object = collision.get_collider()
		if collided_object.name == "Kai":
			var main_level = get_tree().current_scene
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
		return 
		
	is_turning = true
	distance_traveled = 0.0
	
	var tween = create_tween()
	tween.tween_property(self, "rotation_degrees", rotation_degrees + 180, 1.2).set_trans(Tween.TRANS_SINE)
	
	tween.tween_callback(func(): is_turning = false)
	
func die() -> void:
	set_physics_process(false)
	
	var collision_shape = get_node_or_null("CollisionShape2D")
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
		
	var sprite = get_node_or_null("Sprite2D") 
	if sprite:
		sprite.hide()
		
	# --- LÓGICA DE AUDIO ACTUALIZADA ---
	# 1. Apagamos el gruñido en loop inmediatamente
	if growl_sound:
		growl_sound.stop()
		
	# 2. Reproducimos el sonido de muerte y esperamos a que termine
	if death_sound:
		death_sound.play()
		await death_sound.finished
		
	queue_free()
