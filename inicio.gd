extends Control

@onready var video = $ColorRect/VideoStreamPlayer
@onready var imagen_fondo = $TextureRect
@onready var boton_jugar = $Button
@onready var musica_fondo = get_node_or_null("MusicaFondo")
@onready var boton_omitir = $BotonOmitir # Tu nuevo botón

func _ready():
	get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	
	imagen_fondo.hide()
	boton_jugar.hide()
	
	# Mostramos el botón Omitir al arrancar y lo conectamos
	if boton_omitir:
		boton_omitir.show()
		boton_omitir.pressed.connect(_on_boton_omitir_pressed)
	
	video.finished.connect(_on_video_terminado)
	boton_jugar.pressed.connect(_on_boton_jugar_pressed)
	
	video.play()

# Nueva función para el botón Omitir
func _on_boton_omitir_pressed() -> void:
	video.stop() # Detiene el video al instante
	_on_video_terminado() # Ejecuta la transición de la pantalla

func _on_video_terminado() -> void:
	video.hide()
	
	# Ocultamos el botón de omitir porque el video ya no está
	if boton_omitir:
		boton_omitir.hide()
		
	imagen_fondo.show()
	boton_jugar.show()
	
	if musica_fondo:
		musica_fondo.play()

func _on_boton_jugar_pressed() -> void:
	get_tree().change_scene_to_file("res://level1.tscn")
