extends CharacterBody2D

@export var escena_bala: PackedScene
@export var speed = 300

var direccion_joystick = Vector2.ZERO

@onready var sprite = $Sprite2D
@onready var punto_disparo = get_node_or_null("Sprite2D/PuntoDisparo")
@onready var sonido_disparo = get_node_or_null("SonidoDisparo")


func _physics_process(delta):
# Actualizamos la ruta para buscarlo dentro de la nueva capa
	var joystick = get_parent().get_node_or_null("CapaInterfaz/Virtual Joystick")

	if joystick:
		var direccion = joystick.output
		velocity = direccion * speed

# Si se está moviendo, invertimos el eje X para corregir la inversión
	if velocity.length() > 0:
		sprite.rotation = atan2(-velocity.x, -velocity.y)

	move_and_slide()

func _on_boton_disparar_pressed() -> void:
	if escena_bala:
		var nueva_bala = escena_bala.instantiate()

# La bala ahora toma las coordenadas exactas del marcador exterior
	if punto_disparo:
		nueva_bala.global_position = punto_disparo.global_position
	else:
		nueva_bala.global_position = global_position
	
	var sprite = get_node_or_null("Sprite2D")

	if sprite:
		nueva_bala.rotation = sprite.global_rotation
	else:
		nueva_bala.rotation = rotation
		get_parent().add_child(nueva_bala)

	if sonido_disparo:
		sonido_disparo.play()
