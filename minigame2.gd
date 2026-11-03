extends Node

@export var key_sounds: Array[AudioStream]
@onready var audio_player = $AudioPlayer
@onready var button_hear = $ButtonHear
@onready var sound_error = get_node_or_null("ErrorSound")

var secret_code: Array[int] = []
var entered_code: Array[int] = []
var can_touch: bool = true 

func _ready() -> void:
	# Generamos la clave secreta de 4 dígitos (sonidos) al azar
	for i in range(4):
		secret_code.append(randi() % 4) 
		
	if button_hear:
		button_hear.pressed.connect(play_sequence)

func play_sequence() -> void:
	if not can_touch: return
	
	# Evitamos que el jugador toque botones mientras la clave suena
	can_touch = false
	entered_code.clear()
	
	for number in secret_code:
		if key_sounds.size() > number and key_sounds[number] != null:
			audio_player.stream = key_sounds[number]
			audio_player.play()
			
		# Pausa de 0.8 segundos entre cada sonido
		await get_tree().create_timer(0.8).timeout 
		
	# Desbloqueamos el teclado
	can_touch = true

# --- CONEXIONES DE LOS BOTONES DEL TECLADO ---
# Conecta las señales 'pressed' de tus botones desde el editor a estas funciones
func _on_button_0_pressed(): enter_digit(0)
func _on_button_1_pressed(): enter_digit(1)
func _on_button_2_pressed(): enter_digit(2)
func _on_button_3_pressed(): enter_digit(3)

func enter_digit(digit: int) -> void:
	# Si la pista está sonando, ignoramos el clic
	if not can_touch:
		return
		
	# Reproducir el efecto de sonido de la tecla presionada
	if key_sounds.size() > digit and key_sounds[digit] != null:
		audio_player.stream = key_sounds[digit]
		audio_player.play()
		
	entered_code.append(digit)
	
	# Validar cuando haya ingresado 4 sonidos
	if entered_code.size() == 4:
		validate_code()

func validate_code() -> void:
	can_touch = false 
	
	var level_root = get_parent() # Llamamos al administrador del nivel
	
	if entered_code == secret_code:
		# CASO 1: Éxito
		if level_root and level_root.has_method("victory"):
			level_root.victory(level_root.msg_victory)
			
	else:
		# CASO 2: Error
		if sound_error: sound_error.play()
		Input.vibrate_handheld(50)
		
		# Penalizamos restando oxígeno directamente desde el HUD universal
		#if level_root and level_root.get("hud"):
			#var hud = level_root.hud
			#hud.local_oxygen = max(0, hud.local_oxygen - 5)
			#if hud.oxygen_bar:
				#hud.oxygen_bar.value = hud.local_oxygen
		
		await get_tree().create_timer(0.5).timeout
		
		entered_code.clear()
		can_touch = true
