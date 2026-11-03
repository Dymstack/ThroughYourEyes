extends Node

@export var speed: float = 150.0

func _process(delta: float) -> void:
	# 1. Recorremos TODOS los hijos del Spawner buscando los caminos
	for ruta in get_children():
		
		# 2. Verificamos si el nodo actual es un camino (sin importar su nombre)
		if ruta is Path2D:
			
			# 3. Buscamos todos los "carritos" dentro de ese camino específico
			for carrito in ruta.get_children():
				if carrito is PathFollow2D:
					# Hacemos avanzar a cada enemigo
					carrito.progress += speed * delta
					
					# Si el carrito llega al final de la línea, lo destruimos
					if carrito.progress_ratio >= 1.0:
						carrito.queue_free()
