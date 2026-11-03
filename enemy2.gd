extends CharacterBody2D 

@onready var death_sound = get_node_or_null("DeathSound")
@onready var growl_sound = get_node_or_null("GrowlSound")

var is_dying: bool = false 

func _ready() -> void:
	if growl_sound == null:
		print("ERROR: No encontré el nodo GrowlSound")
	else:
		growl_sound.play()

func _physics_process(_delta: float) -> void:
	if is_dying: return
		
	# 1. Rotamos basándonos en la velocidad
	if velocity.length() > 0:
		rotation = velocity.angle() - deg_to_rad(90)
		
	# 2. Aplicamos el movimiento
	move_and_slide()
	
	# 3. Detectamos si durante el movimiento chocamos con Kai
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var body = collision.get_collider()
		
		if body and body.name == "Kai":
			var main_level = get_tree().current_scene
			if main_level.has_method("game_over"):
				main_level.game_over("¡El monstruo te ha matado!\nInténtalo de nuevo.")

func die() -> void:
	if is_dying: return
		
	is_dying = true
	
	# Detenemos al enemigo en seco
	velocity = Vector2.ZERO 
	
	var collision_shape = get_node_or_null("CollisionShape2D")
	if collision_shape: collision_shape.set_deferred("disabled", true)
		
	var sprite = get_node_or_null("Sprite2D") 
	if sprite: sprite.hide()
		
	# --- LÓGICA DE AUDIO ---
	if growl_sound: growl_sound.stop()
		
	if death_sound:
		death_sound.play()
		await death_sound.finished
		
	queue_free()
