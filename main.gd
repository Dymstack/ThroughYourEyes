extends Node

@onready var video = $ColorRect/VideoStreamPlayer
@onready var image = $TextureRect
@onready var play = $Button
@onready var music = get_node_or_null("Music")
@onready var skip = $ButtonSkip # Tu nuevo botón

func _ready():
	get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	
	image.hide()
	play.hide()
	
	if skip:
		skip.show()
		skip.pressed.connect(_on_button_skip_pressed)
	
	video.finished.connect(_on_video_finished)
	play.pressed.connect(_on_button_play_pressed)
	
	video.play()

func _on_button_skip_pressed() -> void:
	video.stop()
	_on_video_finished()

func _on_video_finished() -> void:
	video.hide()
	if skip: skip.hide()
	image.show()
	play.show()
	if music: music.play()

func _on_button_play_pressed() -> void:
	get_tree().change_scene_to_file("res://level1.tscn")
