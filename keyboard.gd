extends Control

@onready var digit_labels = [
	$Digit_1,
	$Digit_2,
	$Digit_3,
	$Digit_4
]

# Referencias de audio
@onready var sound_key = get_node_or_null("SoundKey")
@onready var sound_error = get_node_or_null("SoundError")
@onready var sound_door = get_node_or_null("SoundDoor")

var original_braille: Array[String] = []

# IMPORTANTE: Cambia esta clave para que solo use los 4 números de tus botones disponibles
var secret_code: String = "1234" 
var entered_code: String = ""

func _ready() -> void:
	# Guardamos los símbolos Braille iniciales para restaurarlos si hay un error
	for label in digit_labels:
		if label:
			original_braille.append(label.text)
		else:
			original_braille.append("")

# Conecta las señales 'pressed' de tus 4 botones desde el editor a estas funciones
func _on_button_1_pressed() -> void: enter_digit("1")
func _on_button_2_pressed() -> void: enter_digit("2")
func _on_button_3_pressed() -> void: enter_digit("3")
func _on_button_4_pressed() -> void: enter_digit("4")

func enter_digit(digit: String) -> void:
	if sound_key: 
		sound_key.play()
		
	var current_index = entered_code.length()
	
	if current_index < 4:
		if digit_labels[current_index]:
			digit_labels[current_index].text = digit
		entered_code += digit
		
	if entered_code.length() == 4:
		validate_code()

func validate_code() -> void:
	if entered_code == secret_code:
		if sound_door: 
			sound_door.play()
			
		# Le decimos al script universal del nivel que ganamos
		var level_root = get_parent()
		if level_root and level_root.has_method("victory"):
			level_root.victory(level_root.msg_victory)
			
	else:
		if sound_error: 
			sound_error.play()
			
		# Pequeña pausa antes de reiniciar
		await get_tree().create_timer(0.5).timeout
		
		entered_code = ""
		# Restauramos los símbolos de braille originales
		for i in range(4):
			if digit_labels[i]:
				digit_labels[i].text = original_braille[i]
