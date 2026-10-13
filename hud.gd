extends CanvasLayer

signal light_pressed
signal shoot_pressed
signal time_up

@onready var oxygen_bar = $ProgressBar
@onready var oxygen_timer = $Timer
@onready var joystick = get_node_or_null("Virtual Joystick")
@onready var button_light = get_node_or_null("ButtonLight")
@onready var button_shoot = get_node_or_null("ButtonShoot")
@onready var game_over_panel = get_node_or_null("GameOver")
@onready var game_over_label = get_node_or_null("GameOver/Label")
@onready var game_over_sound = get_node_or_null("GameOver/AudioStreamPlayer2D")
@onready var button_restart = get_node_or_null("GameOver/Restart")
@onready var button_home = get_node_or_null("GameOver/Home")
@onready var victory_panel = get_node_or_null("Victory")
@onready var victory_label = get_node_or_null("Victory/Label")
@onready var victory_sound = get_node_or_null("Victory/AudioStreamPlayer2D")
@onready var button_next_level = get_node_or_null("Victory/NextLevel")
@onready var button_home2 = get_node_or_null("Victory/Home")

var local_oxygen: int

func _ready() -> void:
	if button_light: button_light.pressed.connect(func(): emit_signal("light_pressed"))
	if button_shoot: button_shoot.pressed.connect(func(): emit_signal("shoot_pressed"))
		
	if button_restart: button_restart.pressed.connect(_on_restart_pressed)
	if button_home: button_home.pressed.connect(_on_home_pressed)
	if button_home2: button_home2.pressed.connect(_on_home_pressed2)
	if button_next_level: button_next_level.pressed.connect(_on_next_level_pressed)

func start_oxygen(amount: int) -> void:
	local_oxygen = amount
	if oxygen_bar:
		oxygen_bar.max_value = 100
		oxygen_bar.value = local_oxygen

func start_timer() -> void:
	if oxygen_timer: oxygen_timer.start()

func _on_timer_timeout() -> void:
	local_oxygen -= 1
	if oxygen_bar: oxygen_bar.value = local_oxygen
	if local_oxygen <= 0:
		oxygen_timer.stop()
		emit_signal("time_up")

func setup_shoot_button(is_enabled: bool) -> void:
	if button_shoot: button_shoot.visible = is_enabled

func block_controls(is_blocked: bool) -> void:
	# Protegemos las animaciones bloqueando solo el input
	var mouse_state = Control.MOUSE_FILTER_IGNORE if is_blocked else Control.MOUSE_FILTER_STOP
	
	if button_light: button_light.mouse_filter = mouse_state
	if button_shoot: button_shoot.mouse_filter = mouse_state
	
	# El joystick virtual suele requerir desactivación directa de proceso
	if joystick: 
		joystick.process_mode = Node.PROCESS_MODE_DISABLED if is_blocked else Node.PROCESS_MODE_ALWAYS

func show_game_over(reason_text: String) -> void:
	if game_over_label: game_over_label.text = reason_text
	
	if game_over_panel:
		game_over_panel.show()
		game_over_sound.play()
		
	block_controls(true)
		
func show_victory(victory_text: String) -> void:
	if victory_label: victory_label.text = victory_text
		
	if victory_panel:
		victory_panel.show()
		victory_sound.play()
		
	block_controls(true)
	
# --- FUNCIONES DE NAVEGACIÓN ---

func _on_restart_pressed() -> void:
	# 1. Quitamos la pausa del árbol antes de recargar
	get_tree().paused = false 
	# 2. Recargamos la escena en la que estamos actualmente (sirve para Nivel 1, 2 o 3)
	get_tree().call_deferred("reload_current_scene")

func _on_home_pressed() -> void:
	get_tree().paused = false
	# PON LA RUTA EXACTA DE TU MENÚ DE INICIO AQUÍ:
	get_tree().change_scene_to_file("res://main.tscn")
	
func _on_home_pressed2() -> void:
	get_tree().paused = false
	# PON LA RUTA EXACTA DE TU MENÚ DE INICIO AQUÍ:
	get_tree().change_scene_to_file("res://main.tscn")

func _on_next_level_pressed() -> void:
	get_tree().paused = false
	
	# Para saber a qué nivel ir, podemos revisar el nombre de la escena actual
	var current_scene_name = get_tree().current_scene.name
	
	if current_scene_name == "Level1":
		get_tree().call_deferred("change_scene_to_file", "res://level_2.tscn")
	elif current_scene_name == "Level2":
		get_tree().call_deferred("change_scene_to_file", "res://level_3.tscn")
	else:
		# Si ya estamos en el Nivel 3, volver al inicio o pantalla final
		get_tree().change_scene_to_file("res://main.tscn")
