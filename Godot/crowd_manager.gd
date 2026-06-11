extends Node3D

@export_category("Crowd Settings")
@export var fan_scene: PackedScene # Arraste o Torcedor.tscn aqui
@export_range(0.0, 1.0) var crowd_density: float = 0.5 # 50% de chance de ter torcedor

@export_category("Bleacher Dimensions")
@export var rows: int = 10
@export var columns: int = 20

@export_category("Spacing and Offset")
@export var spacing_x: float = 0.61  # Distância entre cadeiras na mesma linha
@export var spacing_z: float = - 1  # Distância entre as linhas (profundidade)
@export var step_height_y: float = 0.4 # O quanto a arquibancada sobe a cada linha

@export var random_offset: Vector3 = Vector3(0.1, 0.05, 0.1) # Desalinhamento natural (X, Y, Z)

func _ready():
	generate_crowd()

func generate_crowd():
	# Limpa torcida antiga se houver (útil se quiser rodar em tempo de execução)
	for child in get_children():
		child.queue_free()
		
	for r in range(rows):
		for c in range(columns):
			
			# 1. Sistema de Assento Vazio
			if randf() > crowd_density:
				continue # Pula este assento, deixando-o vazio
				
			# 2. Calcula a posição base do assento (Grade)
			var pos_x = c * spacing_x
			var pos_z = r * spacing_z
			var pos_y = r * step_height_y # Offset para cima automático por linha
			
			var final_position = Vector3(pos_x, pos_y, pos_z)
			
			# 3. Aplica o Offset Aleatório (comportamento humano, ninguém senta igual)
			var off_x = randf_range(-random_offset.x, random_offset.x)
			var off_y = randf_range(0.0, random_offset.y) # Offset para cima pedido
			var off_z = randf_range(-random_offset.z, random_offset.z)
			
			final_position += Vector3(off_x, off_y, off_z)
			
			# 4. Instancia o torcedor
			var fan = fan_scene.instantiate()
			add_child(fan)
			fan.transform.origin = final_position
