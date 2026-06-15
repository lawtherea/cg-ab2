extends Node

@export var ball : Node3D              
@export var argentina_player_scene : PackedScene 

# Formação da Argentina posicionada no lado oposto (Valores altos de Z)
@export var formation_offsets : Array[Vector3] = [
	Vector3(35, 0, 60),   # Goleiro
	Vector3(15, 0, 75),   # Lateral Direito
	Vector3(28, 0, 70),   # Zagueiro 1
	Vector3(42, 0, 70),   # Zagueiro 2
	Vector3(55, 0, 75),   # Lateral Esquerdo
	Vector3(20, 0, 85),   # Meio Campo 1
	Vector3(35, 0, 80),   # Meio Campo Central
	Vector3(50, 0, 85),   # Meio Campo 2
	Vector3(25, 0, 95),   # Atacante 1
	Vector3(45, 0, 95)    # Atacante 2
]

var team_players : Array[Node3D] = []

func _ready() -> void:
	if not argentina_player_scene:
		push_error("Manager Argentina: Por favor, atribua a PackedScene do jogador da Argentina.")
		return
		
	# Instancia os jogadores adversários
	for i in range(formation_offsets.size()):
		var new_player = argentina_player_scene.instantiate()
		add_child(new_player)
		
		new_player.ball_node = ball
		new_player.global_position = formation_offsets[i]
		new_player.home_position = formation_offsets[i]
		new_player.formation_target_position = formation_offsets[i]
		
		team_players.append(new_player)

func _physics_process(_delta: float) -> void:
	if team_players.size() == 0 or not ball:
		return

	eleger_perseguidor_da_bola()

func eleger_perseguidor_da_bola():
	var ball_pos = ball.global_position
	var melhor_jogador_idx: int = -1
	var menor_distancia: float = 999999.0 
	
	# Loop para achar o jogador mais perto que atenda à regra tática
	for i in range(team_players.size()):
		var player = team_players[i]
		
		# REGRA SOLICITADA: Se o jogador estiver em uma posição Z menor que a bola (à frente dela na defesa),
		# ele não pode ir atrás dela, pois empurraria a bola para o próprio campo.
		if player.global_position.z < ball_pos.z:
			continue # Ignora este jogador, passa para o próximo
			
		var dist = player.global_position.distance_to(ball_pos)
		if dist < menor_distancia:
			menor_distancia = dist
			melhor_jogador_idx = i
			
	# Atualiza o estado de todos os jogadores com base na eleição
	for i in range(team_players.size()):
		if i == melhor_jogador_idx:
			team_players[i].is_chaser = true
		else:
			team_players[i].is_chaser = false
