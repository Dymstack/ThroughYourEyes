extends Control

@onready var oscuridad = $Oscuridad 
@onready var timer_oxigeno = $CapaInterfaz/Timer
@onready var barra_oxigeno = $CapaInterfaz/ProgressBar
@onready var joystick = get_node_or_null("CapaInterfaz/Virtual Joystick") 
@onready var boton_sonar = $CapaInterfaz/BotonSonar 
@onready var panel_tutorial = $CapaInterfaz/PanelTutorial
@onready var texto_tutorial = $CapaInterfaz/PanelTutorial/Label
@onready var boton_anterior = $CapaInterfaz/PanelTutorial/BotonAnterior
@onready var boton_siguiente = $CapaInterfaz/PanelTutorial/BotonSiguiente
@onready var luz_sonar = get_node_or_null("Kai/Sprite2D/LuzSonar")
@onready var video_player = get_node_or_null("CapaInterfaz/VideoStreamPlayer")
@onready var flecha_meta = get_node_or_null("CapaInterfaz/FlechaMeta")
@onready var panel_muerte = get_node_or_null("CapaInterfaz/PanelMuerte")
@onready var boton_reiniciar = get_node_or_null("CapaInterfaz/PanelMuerte/BotonReiniciar")
@onready var boton_inicio = get_node_or_null("CapaInterfaz/PanelMuerte/BotonInicio")
@onready var label_muerte = get_node_or_null("CapaInterfaz/PanelMuerte/Label")
@onready var sonido_muerte = get_node_or_null("CapaInterfaz/SonidoMuerte")

@onready var kai = $Kai 
var posicion_inicial_kai: Vector2

var paso_tutorial = 0 
var oxigeno = 100
var animacion_actual: Tween 
var animacion_flecha: Tween 

func _ready():
	
	get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	
	if panel_muerte:
		panel_muerte.hide()
		# 1. Obligamos al panel y sus botones a vivir durante la pausa
		panel_muerte.process_mode = Node.PROCESS_MODE_ALWAYS
		
	barra_oxigeno.max_value = 100
	barra_oxigeno.value = oxigeno
	timer_oxigeno.stop() 
	
	if kai:
		posicion_inicial_kai = kai.global_position
	
	panel_tutorial.show()
	paso_tutorial = 0
	actualizar_tutorial()

func _on_boton_siguiente_pressed() -> void:
	paso_tutorial += 1
	actualizar_tutorial()

func _on_boton_anterior_pressed() -> void:
	if paso_tutorial > 0:
		paso_tutorial -= 1
		actualizar_tutorial()

func actualizar_tutorial() -> void:
	boton_anterior.visible = (paso_tutorial > 0)
	
	reiniciar_posicion_kai()
	
	match paso_tutorial:
		0: #PASO 0: NAVE AVERIADA (VIDEO Y FLECHA)
			oscuridad.color = Color(1, 1, 1, 1) # Sin oscuridad
			texto_tutorial.text = "La nave se averió. Llega a la salida evitando las fallas eléctricas."
			boton_siguiente.text = ">"
			
			if video_player:
				video_player.show()
				
			# --- CORRECCIÓN DEL JOYSTICK ---
			if animacion_actual:
				animacion_actual.kill() # Detenemos la animación de latido
				
			if joystick:
				if "output" in joystick:
					joystick.output = Vector2.ZERO # Obligamos al personaje a detenerse
				joystick.scale = Vector2(0.76, 0.76) # Restauramos la escala original
				joystick.process_mode = Node.PROCESS_MODE_DISABLED # Lo bloqueamos
				
			if boton_sonar:
				boton_sonar.scale = Vector2(0.15, 0.15)
				boton_sonar.process_mode = Node.PROCESS_MODE_DISABLED 
			# -------------------------------
			
			if flecha_meta:
				flecha_meta.show()
				animar_flecha(flecha_meta)
				
			if luz_sonar:
				luz_sonar.energy = 0.0
				
			reiniciar_oxigeno()

		1: # PASO 1: CEGUERA Y MOVIMIENTO
			oscuridad.color = Color(0, 0, 0, 1) # Todo oscuro
			texto_tutorial.text = "No puedes ver. Desliza el círculo con flechas para moverte en la oscuridad."
			
			if video_player:
				video_player.hide() # Quitamos el video porque ya quedó ciego
			if flecha_meta:
				flecha_meta.hide()
				if animacion_flecha:
					animacion_flecha.kill()
					
			if joystick:
				joystick.process_mode = Node.PROCESS_MODE_INHERIT # Desbloqueado
				animar_pulsacion_joystick(joystick)
			if boton_sonar:
				boton_sonar.process_mode = Node.PROCESS_MODE_DISABLED # Aún bloqueado
				boton_sonar.scale = Vector2(0.15, 0.15)
				
			if luz_sonar:
				luz_sonar.energy = 1.5 # Luz permanente
				
			reiniciar_oxigeno()
				
		2: # PASO 2: ECOLOCALIZACIÓN Y BASTÓN
			oscuridad.color = Color(0, 0, 0, 1) 
			texto_tutorial.text = "Toca el botón con el ícono del bastón para revelar tu entorno por un segundo."
			
			if joystick:
				joystick.scale = Vector2(0.76, 0.76) 
				
			if boton_sonar:
				boton_sonar.process_mode = Node.PROCESS_MODE_INHERIT # Botón de sonar desbloqueado
				animar_pulsacion_sonar(boton_sonar)
				
			if luz_sonar:
				luz_sonar.energy = 0.0 # Se apaga, ahora depende del botón
				
			reiniciar_oxigeno()
				
		3: # PASO 3: OXÍGENO Y RESCATE DE CAP
			oscuridad.color = Color(0, 0, 0, 1) 
			texto_tutorial.text = "Tu tanque de oxígeno se agota. Rescata a Cap antes de que llegue a cero."
			
			if boton_sonar:
				boton_sonar.scale = Vector2(0.15, 0.15)
			if animacion_actual:
				animacion_actual.kill()
				
			# Aquí comienza a disminuir el oxígeno
			timer_oxigeno.start()
			
		4: # PASO 4: INICIAR JUEGO
			panel_tutorial.hide()


# --- FUNCIÓN DE APOYO PARA RESETEAR EL OXÍGENO ---
func reiniciar_oxigeno() -> void:
	timer_oxigeno.stop()
	oxigeno = 100
	barra_oxigeno.value = oxigeno
	
	# Restauramos el color original por si retrocedió estando en nivel rojo
	var estilo_base = barra_oxigeno.get_theme_stylebox("fill").duplicate()
	# Cambia este hexadecimal por tu color original si lo necesitas (ej. azul)
	estilo_base.bg_color = Color("#4a90e2") 
	barra_oxigeno.add_theme_stylebox_override("fill", estilo_base)


# --- FUNCIONES DE ANIMACIÓN ---
func animar_flecha(nodo) -> void:
	if animacion_flecha:
		animacion_flecha.kill()
	# Guardamos la posición inicial para que oscile en su lugar original
	var pos_inicial = nodo.position
	animacion_flecha = create_tween().set_loops()
	animacion_flecha.tween_property(nodo, "position:y", pos_inicial.y + 15, 0.5).set_trans(Tween.TRANS_SINE)
	animacion_flecha.tween_property(nodo, "position:y", pos_inicial.y, 0.5).set_trans(Tween.TRANS_SINE)

func animar_pulsacion_joystick(nodo) -> void:
	if animacion_actual:
		animacion_actual.kill() 
	animacion_actual = create_tween().set_loops() 
	animacion_actual.tween_property(nodo, "scale", Vector2(0.76, 0.76), 0.5).set_trans(Tween.TRANS_SINE)
	animacion_actual.tween_property(nodo, "scale", Vector2(0.8, 0.8), 0.5).set_trans(Tween.TRANS_SINE)

func animar_pulsacion_sonar(nodo) -> void:
	if animacion_actual:
		animacion_actual.kill()
	animacion_actual = create_tween().set_loops() 
	animacion_actual.tween_property(nodo, "scale", Vector2(0.15, 0.15), 0.5).set_trans(Tween.TRANS_SINE)
	animacion_actual.tween_property(nodo, "scale", Vector2(0.16, 0.16), 0.5).set_trans(Tween.TRANS_SINE)


# --- LÓGICA DE JUEGO ---
func _on_boton_sonar_pressed() -> void:
	if luz_sonar:
		luz_sonar.energy = 1.5 
		await get_tree().create_timer(0.5).timeout
		
		# Solo apagamos la luz si ya pasó el tutorial 1, 
		# para no apagarla accidentalmente si spamean el botón en otros pasos
		if paso_tutorial >= 2:
			luz_sonar.energy = 0.0 

func _on_timer_timeout() -> void:
	oxigeno -= 1
	barra_oxigeno.value = oxigeno
	
	if oxigeno == 20:
		var estilo_rojo = StyleBoxFlat.new()
		estilo_rojo.bg_color = Color("#fa3458ff")
		barra_oxigeno.add_theme_stylebox_override("fill", estilo_rojo)
	
	if oxigeno <= 0:
		timer_oxigeno.stop()
		get_tree().paused = true 
		
		# Reproducir el sonido de derrota
		if sonido_muerte:
			sonido_muerte.play()
			
		# Bloqueamos el tutorial para que no robe clics
		if panel_tutorial:
			panel_tutorial.hide()
			panel_tutorial.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if boton_siguiente:
			boton_siguiente.disabled = true
		if boton_anterior:
			boton_anterior.disabled = true
			
		# Cambiamos el texto dinámicamente
		if label_muerte:
			label_muerte.text = "¡Se te ha agotado el oxígeno!\nInténtalo de nuevo."
			
		if panel_muerte:
			panel_muerte.show()
		
func _on_peligro_body_entered(body: Node2D) -> void:
	if body.name == "Kai":
		
		# 1. Reproducimos el sonido al instante, sin importar en qué paso estemos
		if sonido_muerte:
			sonido_muerte.play()
		
		# 2. Verificamos si es un error de práctica en el tutorial
		if paso_tutorial < 4:
			body.set_deferred("global_position", posicion_inicial_kai)
			if "velocity" in body:
				body.velocity = Vector2.ZERO
				
		# 3. Si el tutorial terminó, aplicamos la muerte real
		else:
			oxigeno = 0
			if barra_oxigeno:
				barra_oxigeno.value = 0
				
			get_tree().paused = true 
			
			if panel_tutorial:
				panel_tutorial.hide()
				panel_tutorial.mouse_filter = Control.MOUSE_FILTER_IGNORE
			if boton_siguiente:
				boton_siguiente.disabled = true
			if boton_anterior:
				boton_anterior.disabled = true
				
			if label_muerte:
				label_muerte.text = "¡Te has electrocutado!"
				
			if panel_muerte:
				panel_muerte.show()

func _on_boton_reiniciar_pressed() -> void:
	print("Clic detectado en el botón de reinicio")
	get_tree().paused = false # Vital quitar la pausa primero
	get_tree().call_deferred("reload_current_scene")

func _on_boton_inicio_pressed() -> void:
	get_tree().paused = false
	# Reemplaza el texto entre comillas con la ruta exacta de tu escena de menú principal
	get_tree().change_scene_to_file("res://inicio.tscn")
	
func reiniciar_posicion_kai() -> void:
	if kai:
		kai.global_position = posicion_inicial_kai
		# Detenemos cualquier movimiento residual
		if "velocity" in kai:
			kai.velocity = Vector2.ZERO


func _on_meta_escape_body_entered(body: Node2D) -> void:
	# Verificamos que sea Kai y que esté en la fase de juego real (Paso 4)
	if body.name == "Kai" and paso_tutorial >= 4:
		print("¡Misión cumplida! Encontraste a Cap y llegaste a la nave.")
		
		# Detenemos el consumo de oxígeno instantáneamente
		if timer_oxigeno:
			timer_oxigeno.stop()
			
		# Cambiamos al siguiente nivel usando call_deferred para evitar errores de físicas
		# Reemplaza el texto con la ruta exacta de la escena de tu nivel 2
		Global.oxigeno_actual = oxigeno
		get_tree().call_deferred("change_scene_to_file", "res://nivel_1_mg.tscn")
