extends Control

@onready var oscuridad = $Oscuridad 
@onready var timer_oxigeno = $CapaInterfaz/Timer
@onready var barra_oxigeno = $CapaInterfaz/ProgressBar
@onready var joystick = get_node_or_null("CapaInterfaz/Virtual Joystick") 
@onready var boton_sonar = $CapaInterfaz/BotonSonar
@onready var panel_tutorial = $CapaInterfaz/PanelTutorial
@onready var boton_siguiente = $CapaInterfaz/PanelTutorial/BotonSiguiente
@onready var luz_sonar = get_node_or_null("Kai/Sprite2D/LuzSonar")
@onready var panel_muerte = get_node_or_null("CapaInterfaz/PanelMuerte")
@onready var boton_reiniciar = get_node_or_null("CapaInterfaz/PanelMuerte/BotonReiniciar")
@onready var boton_inicio = get_node_or_null("CapaInterfaz/PanelMuerte/BotonInicio")
@onready var label_muerte = get_node_or_null("CapaInterfaz/PanelMuerte/Label")
@onready var sonido_muerte = get_node_or_null("CapaInterfaz/SonidoMuerte")
@onready var boton_disparar = get_node_or_null("CapaInterfaz/BotonDisparar")

@onready var kai = $Kai 
var posicion_inicial_kai: Vector2

var oxigeno = 100

func _ready():
	get_tree().paused = false
	get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	
	if panel_muerte:
		panel_muerte.hide()
		panel_muerte.process_mode = Node.PROCESS_MODE_ALWAYS
		
	barra_oxigeno.max_value = 100
	barra_oxigeno.value = oxigeno
	timer_oxigeno.stop() 
	
	if kai:
		posicion_inicial_kai = kai.global_position
		
	if joystick:
		joystick.process_mode = Node.PROCESS_MODE_DISABLED
	if boton_sonar:
		boton_sonar.process_mode = Node.PROCESS_MODE_DISABLED
	if boton_disparar:
		boton_disparar.process_mode = Node.PROCESS_MODE_DISABLED
		
	oscuridad.color = Color(0, 0, 0, 1)
	if luz_sonar:
		luz_sonar.energy = 0.0
		
	if panel_tutorial:
		panel_tutorial.show()
		
	if boton_disparar and kai:
		boton_disparar.pressed.connect(kai._on_boton_disparar_pressed)

# --- INTERFAZ ---
func _on_boton_siguiente_pressed() -> void:
	if panel_tutorial:
		panel_tutorial.hide()
		panel_tutorial.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
	if joystick:
		joystick.process_mode = Node.PROCESS_MODE_INHERIT
	if boton_sonar:
		boton_sonar.process_mode = Node.PROCESS_MODE_INHERIT
	if boton_disparar:
		boton_disparar.process_mode = Node.PROCESS_MODE_INHERIT
		
	if timer_oxigeno:
		timer_oxigeno.start()

# --- LÓGICA DE JUEGO ---
func _on_boton_sonar_pressed() -> void:
	if luz_sonar:
		luz_sonar.energy = 1.5 
		await get_tree().create_timer(0.5).timeout
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
		
		if sonido_muerte:
			sonido_muerte.play()
			
		if label_muerte:
			label_muerte.text = "¡Se te ha agotado el oxígeno!\nInténtalo de nuevo."
			
		if panel_muerte:
			panel_muerte.show()

# --- NUEVA LÓGICA DE MUERTE POR ENEMIGOS ---
func matar_a_kai_por_enemigo() -> void:
	if sonido_muerte:
		sonido_muerte.play()
		
	oxigeno = 0
	if barra_oxigeno:
		barra_oxigeno.value = 0
		
	get_tree().paused = true 
	
	if label_muerte:
		label_muerte.text = "¡Un enemigo te ha atrapado!"
		
	if panel_muerte:
		panel_muerte.show()

func _on_boton_reiniciar_pressed() -> void:
	get_tree().paused = false 
	get_tree().call_deferred("reload_current_scene")

func _on_boton_inicio_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://inicio.tscn")

func _on_meta_escape_body_entered(body: Node2D) -> void:
	if body.name == "Kai":
		if timer_oxigeno:
			timer_oxigeno.stop()
			
		Global.oxigeno_actual = oxigeno
		# Ajusta esta ruta a tu pantalla de victoria o fin de juego
		get_tree().call_deferred("change_scene_to_file", "res://nivel_2_mg.tscn")
