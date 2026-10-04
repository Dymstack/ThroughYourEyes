extends Control

# En el Inspector, asigna un tamaño de 10 a esta lista y arrastra tus sonidos del 0 al 9
@export var sonidos_teclas: Array[AudioStream] 
@onready var reproductor = $ReproductorAudio
@onready var boton_escuchar = $CapaInterfaz/BotonEscuchar

@onready var barra_oxigeno = $CapaInterfaz/ProgressBar
@onready var timer_oxigeno = $CapaInterfaz/Timer
@onready var oscuridad = $Oscuridad 
@onready var panel_muerte = $CapaInterfaz/PanelMuerte
@onready var sonido_jaula = get_node_or_null("SonidoJaula")
@onready var sonido_error = get_node_or_null("SonidoError")
@onready var panel_tutorial = get_node_or_null("CapaInterfaz/PanelTutorial")
@onready var boton_siguiente = get_node_or_null("CapaInterfaz/PanelTutorial/BotonSiguiente")
@onready var sonido_ganador = get_node_or_null("SonidoGanador")
@onready var panel_exito = get_node_or_null("CapaInterfaz/PanelExito")
@onready var boton_inicio = get_node_or_null("CapaInterfaz/PanelExito/BotonInicio")
@onready var boton_sig_nivel = get_node_or_null("CapaInterfaz/PanelExito/BotonSigNivel")
@onready var label_muerte = get_node_or_null("CapaInterfaz/PanelMuerte/Label")
@onready var sonido_muerte = get_node_or_null("CapaInterfaz/SonidoMuerte")

var oxigeno_local: int

var clave_secreta: Array[int] = []
var clave_ingresada: Array[int] = []
var puede_tocar = false # Bloquea el teclado durante el tutorial y mientras suena la pista

func _ready() -> void:
	get_tree().paused = false

# 1. Copiamos el valor global a nuestra variable local al iniciar
	oxigeno_local = Global.oxigeno_actual
	
	barra_oxigeno.max_value = 100
	barra_oxigeno.value = oxigeno_local
	
	if panel_muerte: panel_muerte.hide()
	if panel_exito: panel_exito.hide()
	
	# Generamos la clave secreta de 4 dígitos (sonidos) al azar
	for i in range(4):
		clave_secreta.append(randi() % 4) 
		
	if boton_escuchar:
		boton_escuchar.pressed.connect(reproducir_clave)
		
	if oscuridad: oscuridad.show()
	
	# Bloqueamos el botón de escuchar mientras esté el tutorial
	if boton_escuchar:
		boton_escuchar.process_mode = Node.PROCESS_MODE_DISABLED
	
	if sonido_ganador: sonido_ganador.play()
	
	# --- CONFIGURACIÓN DEL TUTORIAL ---
	if panel_tutorial:
		panel_tutorial.show()
		panel_tutorial.mouse_filter = Control.MOUSE_FILTER_STOP 
		panel_tutorial.process_mode = Node.PROCESS_MODE_ALWAYS 
		
	if boton_siguiente:
		boton_siguiente.disabled = false 
		boton_siguiente.mouse_filter = Control.MOUSE_FILTER_STOP
		if not boton_siguiente.pressed.is_connected(_on_boton_siguiente_pressed):
			boton_siguiente.pressed.connect(_on_boton_siguiente_pressed)

func reproducir_clave() -> void:
	# Evitamos que el jugador toque botones mientras la clave suena
	puede_tocar = false
	clave_ingresada.clear()
	
	for numero in clave_secreta:
		if sonidos_teclas.size() > numero and sonidos_teclas[numero] != null:
			reproductor.stream = sonidos_teclas[numero]
			reproductor.play()
			
		# Pausa de 0.8 segundos entre cada sonido
		await get_tree().create_timer(0.8).timeout 
		
	# Desbloqueamos el teclado
	puede_tocar = true

func _on_timer_timeout() -> void:
# 2. Solo restamos a la variable local
	oxigeno_local -= 1
	barra_oxigeno.value = oxigeno_local
	
	if oxigeno_local <= 0:
		timer_oxigeno.stop()
		puede_tocar = false
		get_tree().paused = true
		
		# 3. Agregamos el texto y el sonido de muerte
		if label_muerte:
			label_muerte.text = "¡Se te ha agotado el oxígeno!\nInténtalo de nuevo."
		if sonido_muerte:
			sonido_muerte.play()
			
		if panel_muerte: panel_muerte.show()

# --- CONEXIONES DE LOS BOTONES DEL TECLADO ---
func _on_boton_0_pressed(): ingresar_digito(0)
func _on_boton_1_pressed(): ingresar_digito(1)
func _on_boton_2_pressed(): ingresar_digito(2)
func _on_boton_3_pressed(): ingresar_digito(3)
func _on_boton_4_pressed(): ingresar_digito(4)
func _on_boton_5_pressed(): ingresar_digito(5)
func _on_boton_6_pressed(): ingresar_digito(6)
func _on_boton_7_pressed(): ingresar_digito(7)
func _on_boton_8_pressed(): ingresar_digito(8)
func _on_boton_9_pressed(): ingresar_digito(9)

func ingresar_digito(digito: int) -> void:
	# Si el tutorial está activo o la pista está sonando, ignoramos el clic
	if not puede_tocar:
		return
		
	# Reproducir el efecto de sonido de la tecla presionada
	if sonidos_teclas.size() > digito and sonidos_teclas[digito] != null:
		reproductor.stream = sonidos_teclas[digito]
		reproductor.play()
		
	clave_ingresada.append(digito)
	
	# Validar cuando haya ingresado 4 sonidos
	if clave_ingresada.size() == 4:
		validar_codigo()

func validar_codigo() -> void:
	puede_tocar = false 
	
	if clave_ingresada == clave_secreta:
		# CASO 1: Éxito
		if timer_oxigeno: timer_oxigeno.stop()
		
		# 4. Sobrescribimos la variable global SOLO si el jugador gana
		Global.oxigeno_actual = oxigeno_local
		
		if sonido_ganador: sonido_ganador.play()
		if sonido_jaula: sonido_jaula.play()
		if panel_exito: panel_exito.show()
	else:
		# CASO 2: Error
		if sonido_error: sonido_error.play()
		
		# Penalizamos restando oxígeno local
		oxigeno_local = max(0, oxigeno_local - 5)
		barra_oxigeno.value = oxigeno_local
		
		await get_tree().create_timer(0.5).timeout
		
		clave_ingresada.clear()
		puede_tocar = true

# --- INTERFAZ DE FLUJO ---
func _on_boton_siguiente_pressed() -> void:
	if panel_tutorial:
		panel_tutorial.hide()
		panel_tutorial.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel_tutorial.process_mode = Node.PROCESS_MODE_INHERIT
		
	# Desbloqueamos el botón de escuchar
	if boton_escuchar:
		boton_escuchar.process_mode = Node.PROCESS_MODE_INHERIT
		
	# Inicia el juego real: corre el oxígeno y habilitamos el teclado
	if timer_oxigeno:
		timer_oxigeno.start()
	puede_tocar = true
	
func _on_boton_reiniciar_pressed() -> void:
	get_tree().paused = false 
	get_tree().call_deferred("reload_current_scene")

func _on_boton_inicio_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://inicio.tscn") 

func _on_boton_sig_nivel_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://nivel_3.tscn")
