extends CanvasLayer

# Nodos propios del tutorial
@onready var tutorial_panel = $Panel
@onready var tutorial_label = $Panel/Label
@onready var button_back = $Panel/ButtonBack
@onready var button_next = $Panel/ButtonNext

# Referencias externas (El Nivel se las pasará)
var hud
var kai
var darkness
var goal_arrow

var tutorial_step: int = 0
var initial_kai_position: Vector2
var current_tween: Tween
var arrow_tween: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if button_next: button_next.pressed.connect(_on_button_next_pressed)
	if button_back: button_back.pressed.connect(_on_button_back_pressed)

func start_tutorial(ref_hud, ref_kai, ref_darkness, ref_arrow) -> void:
	hud = ref_hud
	kai = ref_kai
	darkness = ref_darkness
	goal_arrow = ref_arrow
	
	if kai:
		initial_kai_position = kai.global_position
		
	tutorial_panel.show()
	tutorial_step = 0
	update_tutorial()

func _on_button_next_pressed() -> void:
	tutorial_step += 1
	update_tutorial()

func _on_button_back_pressed() -> void:
	if tutorial_step > 0:
		tutorial_step -= 1
		update_tutorial()

# --- TU MÁQUINA DE ESTADOS ORIGINAL ---
func update_tutorial() -> void:
	button_back.visible = (tutorial_step > 0)
	
	if kai:
		kai.global_position = initial_kai_position
		if "velocity" in kai: kai.velocity = Vector2.ZERO
		
	match tutorial_step:
		0:
			if darkness: darkness.color = Color(1, 1, 1, 1)
			tutorial_label.text = "La nave se averió. Llega a la salida evitando las fallas eléctricas."
			button_next.text = ">"
			
			if current_tween: current_tween.kill()
			
			if hud.joystick:
				if "output" in hud.joystick: hud.joystick.output = Vector2.ZERO
				hud.joystick.scale = Vector2(0.76, 0.76)
				hud.joystick.process_mode = Node.PROCESS_MODE_DISABLED
				
			if hud.button_light:
				hud.button_light.scale = Vector2(0.15, 0.15)
				hud.button_light.process_mode = Node.PROCESS_MODE_DISABLED
				
			if goal_arrow:
				goal_arrow.show()
				animate_arrow(goal_arrow)
				
			if kai.light: kai.light.energy = 0.0
			reset_oxygen()

		1:
			if darkness: darkness.color = Color(0, 0, 0, 1)
			tutorial_label.text = "No puedes ver. Desliza el círculo con flechas para moverte en la oscuridad."
			
			if goal_arrow:
				goal_arrow.hide()
				if arrow_tween: arrow_tween.kill()
				
			if hud.joystick:
				hud.joystick.process_mode = Node.PROCESS_MODE_INHERIT
				animate_joystick(hud.joystick)
				
			if hud.button_light:
				hud.button_light.process_mode = Node.PROCESS_MODE_DISABLED
				hud.button_light.scale = Vector2(0.15, 0.15)
				
			if kai.light: kai.light.energy = 1.5
			reset_oxygen()
				
		2:
			if darkness: darkness.color = Color(0, 0, 0, 1)
			tutorial_label.text = "Toca el botón con el ícono del bastón para revelar tu entorno por un segundo."
			
			if hud.joystick: hud.joystick.scale = Vector2(0.76, 0.76)
				
			if hud.button_light:
				hud.button_light.process_mode = Node.PROCESS_MODE_INHERIT
				animate_light(hud.button_light)
				
			if kai.light: kai.light.energy = 0.0
			reset_oxygen()
				
		3:
			if darkness: darkness.color = Color(0, 0, 0, 1)
			tutorial_label.text = "Tu tanque de oxígeno se agota. Rescata a Cap antes de que llegue a cero."
			
			if hud.button_light: hud.button_light.scale = Vector2(0.15, 0.15)
			if current_tween: current_tween.kill()
			
			hud.oxygen_timer.start()
			
		4:
			tutorial_panel.hide()

# --- FUNCIONES DE ANIMACIÓN ---
func animate_arrow(node) -> void:
	if arrow_tween: arrow_tween.kill()
	var start_pos = node.position
	arrow_tween = create_tween().set_loops()
	arrow_tween.tween_property(node, "position:y", start_pos.y + 15, 0.5).set_trans(Tween.TRANS_SINE)
	arrow_tween.tween_property(node, "position:y", start_pos.y, 0.5).set_trans(Tween.TRANS_SINE)

func animate_joystick(node) -> void:
	if current_tween: current_tween.kill()
	current_tween = create_tween().set_loops()
	current_tween.tween_property(node, "scale", Vector2(0.76, 0.76), 0.5).set_trans(Tween.TRANS_SINE)
	current_tween.tween_property(node, "scale", Vector2(0.8, 0.8), 0.5).set_trans(Tween.TRANS_SINE)

func animate_light(node) -> void:
	if current_tween: current_tween.kill()
	current_tween = create_tween().set_loops()
	current_tween.tween_property(node, "scale", Vector2(0.15, 0.15), 0.5).set_trans(Tween.TRANS_SINE)
	current_tween.tween_property(node, "scale", Vector2(0.16, 0.16), 0.5).set_trans(Tween.TRANS_SINE)

func reset_oxygen() -> void:
	if hud:
		hud.oxygen_timer.stop()
		hud.local_oxygen = 100
		if hud.oxygen_bar:
			hud.oxygen_bar.value = 100
			var base_style = hud.oxygen_bar.get_theme_stylebox("fill").duplicate()
			base_style.bg_color = Color("#4a90e2")
			hud.oxygen_bar.add_theme_stylebox_override("fill", base_style)
