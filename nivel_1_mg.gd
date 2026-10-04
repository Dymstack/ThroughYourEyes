extends Control

@onready var barra_oxigeno = $CapaInterfaz/ProgressBar
@onready var timer_oxigeno = $CapaInterfaz/Timer
@onready var oscuridad = $Oscuridad 
@onready var luz_sonar = $Kai/Sprite2D/LuzSonar
@onready var panel_muerte = $CapaInterfaz/PanelMuerte
@onready var sonido_tecla = $SonidoTecla
@onready var sonido_puerta = get_node_or_null("SonidoPuerta")
@onready var sonido_error = get_node_or_null("SonidoError")
@onready var panel_tutorial = get_node_or_null("CapaInterfaz/PanelTutorial")
@onready var boton_siguiente = get_node_or_null("CapaInterfaz/PanelTutorial/BotonSiguiente")
@onready var sonido_ganador = get_node_or_null("SonidoGanador")
@onready var panel_exito = get_node_or_null("CapaInterfaz/PanelExito") # Tu nuevo panel para pasar al nivel 2
@onready var boton_inicio = get_node_or_null("CapaInterfaz/PanelExito/BotonInicio")
@onready var boton_sig_nivel = get_node_or_null("CapaInterfaz/PanelExito/BotonSigNivel")
@onready var label_muerte = get_node_or_null("CapaInterfaz/PanelMuerte/Label")
@onready var sonido_muerte = get_node_or_null("CapaInterfaz/SonidoMuerte")

var oxigeno_local: int

# Agrupamos los 4 labels en un arreglo para manejarlos fácilmente
@onready var labels_digitos = [
	$Digito_1,
	$Digito_2,
	$Digito_3,
	$Digito_4
]

var braille_original = [] # Aquí guardaremos los símbolos iniciales
var codigo_secreto = "6730" 
var codigo_ingresado = ""

func _ready() -> void:
	oxigeno_local = Global.oxigeno_actual
	barra_oxigeno.max_value = 100
	barra_oxigeno.value = oxigeno_local
	
	if panel_muerte: panel_muerte.hide()
	if panel_exito: panel_exito.hide()
	
	for label in labels_digitos:
		braille_original.append(label.text)
		
	oscuridad.show() 
	if sonido_ganador: sonido_ganador.play()

	if panel_tutorial:
		panel_tutorial.show()

	# Mostramos el tutorial al entrar a la escena
	if panel_tutorial:
		panel_tutorial.show()

func _on_timer_timeout() -> void:
# Solo restamos a la variable local
	oxigeno_local -= 1
	barra_oxigeno.value = oxigeno_local
	
	if oxigeno_local <= 0:
		timer_oxigeno.stop()
		get_tree().paused = true
		
		# Restauramos el sonido y el texto de muerte
		if sonido_muerte:
			sonido_muerte.play()
		if label_muerte:
			label_muerte.text = "¡Se te ha agotado el oxígeno!\nInténtalo de nuevo."
			
		if panel_muerte: panel_muerte.show()

func _on_boton_sonar_pressed() -> void:
	if luz_sonar:
		luz_sonar.energy = 1.5 
		await get_tree().create_timer(0.5).timeout
		luz_sonar.energy = 0.0 # Esta es la línea que apaga la luz

# --- CONEXIONES DE LOS BOTONES ---
func _on_boton_0_pressed(): ingresar_digito("0")
func _on_boton_1_pressed(): ingresar_digito("1")
func _on_boton_2_pressed(): ingresar_digito("2")
func _on_boton_3_pressed(): ingresar_digito("3")
func _on_boton_4_pressed(): ingresar_digito("4")
func _on_boton_5_pressed(): ingresar_digito("5")
func _on_boton_6_pressed(): ingresar_digito("6")
func _on_boton_7_pressed(): ingresar_digito("7")
func _on_boton_8_pressed(): ingresar_digito("8")
func _on_boton_9_pressed(): ingresar_digito("9")

func ingresar_digito(digito: String) -> void:
	
	# Reproducir el efecto de sonido al instante
	if sonido_tecla:
		sonido_tecla.play()
		
	var indice_actual = codigo_ingresado.length()
	
	if indice_actual < 4:
		# Reemplazamos el texto del label correspondiente con el número presionado
		labels_digitos[indice_actual].text = digito
		codigo_ingresado += digito
		
	# Si acaba de ingresar el cuarto número, validamos
	if codigo_ingresado.length() == 4:
		validar_codigo()

func validar_codigo() -> void:
	if codigo_ingresado == codigo_secreto:
		# CASO 1: Éxito
		timer_oxigeno.stop()
		
		# ¡Sobrescribimos la variable global solo cuando superas el nivel!
		Global.oxigeno_actual = oxigeno_local
		
		if sonido_puerta:
			sonido_puerta.play()
			
		if panel_exito:
			panel_exito.show()
			
		
	else:
		# CASO 2: Error
		if sonido_error:
			sonido_error.play()
			
		# Esperamos medio segundo para que el jugador vea que se equivocó en el último número
		await get_tree().create_timer(0.5).timeout
		
		# Reiniciamos el código interno
		codigo_ingresado = ""
		
		# Restauramos el braille original en los 4 labels
		for i in range(4):
			labels_digitos[i].text = braille_original[i]
			
func _on_boton_siguiente_pressed() -> void:
	if panel_tutorial:
		panel_tutorial.hide()
		# Prevenimos que la barrera invisible bloquee el teclado
		panel_tutorial.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
	# El juego real y el consumo de oxígeno comienzan aquí
	if timer_oxigeno:
		timer_oxigeno.start()

func _on_boton_reiniciar_pressed() -> void:
	get_tree().paused = false 
	get_tree().call_deferred("reload_current_scene")
		
func _on_boton_inicio_pressed() -> void:
	get_tree().paused = false
	# Ajusta el nombre exacto de tu escena de inicio si es diferente
	get_tree().change_scene_to_file("res://inicio.tscn") 

func _on_boton_sig_nivel_pressed() -> void:
	get_tree().paused = false
	# Ajusta el nombre exacto de tu escena del nivel 2
	get_tree().change_scene_to_file("res://nivel_2.tscn")
