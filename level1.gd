extends Node

@export_category("Level Flow Configuration")
@export var is_minigame: bool = false
@export var has_tutorial: bool = false

@export_category("HUD Controls")
@export var enable_joystick: bool = true
@export var enable_light: bool = true
@export var enable_shoot: bool = false

@export_category("Kai Appearance")
@export var hide_kai_sprite: bool = false

@export_category("Victory and Defeat Texts")
@export_multiline var msg_death_hazard: String = "¡Te electrocutaste!\nInténtalo de nuevo."
@export_multiline var msg_victory: String = "¡Llegaste a la salida!\nIngresa la clave para abrir la puerta."

@onready var hud = $HUD
@onready var kai = get_node_or_null("Kai")
@onready var tutorial = get_node_or_null("Tutorial")
@onready var start_position = get_node_or_null("StartPosition")
@onready var darkness = get_node_or_null("Darkness")
@onready var goal_arrow = get_node_or_null("GoalArrow")

var initial_kai_position: Vector2

func _ready() -> void:
	get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	get_tree().paused = false
	
	# 1. Configuración de Kai (Posición y Sprite)
	if kai:
		if start_position:
			kai.global_position = start_position.global_position
			initial_kai_position = start_position.global_position
		else:
			initial_kai_position = kai.global_position
			
		# Ocultar sprite para minijuegos manteniendo la luz
		var sprite = kai.get_node_or_null("AnimatedSprite2D")
		if sprite:
			sprite.visible = not hide_kai_sprite
			if enable_shoot:
				sprite.play("armed")
			else:
				sprite.play("default")

	# 2. Configurar HUD (Encender/Apagar botones según el nivel)
	_configure_hud_controls()

	# 3. Conectar señales del HUD
	hud.time_up.connect(_on_oxygen_depleted)
	
	if kai and enable_light:
		hud.light_pressed.connect(kai.activate_light) 
	if kai and enable_shoot:
		hud.shoot_pressed.connect(kai.shoot)

	# 4. Iniciar Tutorial o Flujo Normal
	if has_tutorial and tutorial:
		# NOTA: Asegúrate de que en tu script tutorial.gd esta función se llame 'start_tutorial'
		tutorial.start_tutorial(hud, kai, darkness, goal_arrow)
	else:
		if tutorial: 
			tutorial.hide()
		
		# --- LÓGICA DE HERENCIA DE OXÍGENO ---
		if is_minigame:
			# Si es un minijuego, hereda el oxígeno con el que terminó el nivel anterior
			if Global.current_oxygen > 0:
				hud.start_oxygen(Global.current_oxygen)
			else:
				hud.start_oxygen(100)
		else:
			# Si es un Nivel Principal (1, 2 o 3), siempre reinicia a 100
			Global.current_oxygen = 100
			hud.start_oxygen(100)
			
		hud.start_timer()

func _configure_hud_controls() -> void:
	if hud.joystick:
		hud.joystick.visible = enable_joystick
		hud.joystick.process_mode = Node.PROCESS_MODE_ALWAYS if enable_joystick else Node.PROCESS_MODE_DISABLED
	if hud.button_light:
		hud.button_light.visible = enable_light
		hud.button_light.process_mode = Node.PROCESS_MODE_ALWAYS if enable_light else Node.PROCESS_MODE_DISABLED
	if hud.button_shoot:
		hud.button_shoot.visible = enable_shoot
		hud.button_shoot.process_mode = Node.PROCESS_MODE_ALWAYS if enable_shoot else Node.PROCESS_MODE_DISABLED

# --- COLISIONES Y EVENTOS DEL MUNDO ---
func _on_hazard_body_entered(body: Node2D) -> void:
	if body.name == "Kai":
		# NOTA: Asegúrate de que en tu script tutorial.gd la variable del paso sea 'tutorial_step'
		if has_tutorial and tutorial and tutorial.tutorial_step < 4:
			# Práctica del tutorial
			body.set_deferred("global_position", initial_kai_position)
			if "velocity" in body: body.velocity = Vector2.ZERO
		else:
			game_over(msg_death_hazard)

func _on_goal_body_entered(body: Node2D) -> void:
	if body.name == "Kai":
		if has_tutorial and tutorial and tutorial.tutorial_step < 4:
			return
		victory(msg_victory)

# --- FUNCIONES CENTRALES DE ESTADO ---
func _on_oxygen_depleted() -> void:
	game_over("¡Se te ha agotado el oxígeno!\nInténtalo de nuevo.")

func game_over(reason: String) -> void:
	get_tree().paused = true
	hud.oxygen_timer.stop()
	hud.block_controls(true)
	hud.show_game_over(reason)

func victory(message: String) -> void:
	get_tree().paused = true
	hud.oxygen_timer.stop()
	Global.current_oxygen = hud.local_oxygen # Guardamos el oxígeno para la siguiente escena
	hud.block_controls(true)
	hud.show_victory(message)
