extends CharacterBody2D

@export var laser_scene: PackedScene
@export var speed = 300
var direccion_joystick = Vector2.ZERO

@onready var sprite = $AnimatedSprite2D
@onready var trigger = get_node_or_null("AnimatedSprite2D/Marker2D")
@onready var light = get_node_or_null("AnimatedSprite2D/PointLight2D")

func _ready() -> void:
	if light: light.energy = 0.0

func _physics_process(delta) -> void:
	var joystick = get_tree().current_scene.get_node_or_null("HUD/Virtual Joystick")
	
	if joystick:
		var direction = joystick.output
		velocity = direction * speed
		
		if velocity.length() > 0:
			sprite.rotation = velocity.angle() + deg_to_rad(90)
			
		move_and_slide()
		
func shoot() -> void:
	if laser_scene:
		var new_bullet = laser_scene.instantiate()
		
		if trigger:
			new_bullet.global_position = trigger.global_position
		else:
			new_bullet.global_position = global_position
			
		if sprite:
			new_bullet.rotation = sprite.global_rotation
		else:
			new_bullet.rotation = rotation
			
		get_tree().current_scene.add_child(new_bullet)

func activate_light() -> void:
	if light:
		light.energy = 1.5 
		await get_tree().create_timer(0.5).timeout
		light.energy = 0.0
		
func update_appearance(is_armed: bool) -> void:
	if not sprite: return
	
	if is_armed:
		sprite.play("armed")
	else:
		sprite.play("default")
