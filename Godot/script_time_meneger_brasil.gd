extends Node

@export var view_camera : Node3D       
@export var ball : Node3D              
@export var player_scene : PackedScene 

# Posições iniciais de formação 
@export var formation_offsets : Array[Vector3] = [
	Vector3(35, 0, 50),
	Vector3(15, 0, 15),
	Vector3(35, 0, 15),
	Vector3(52, 0, 15),  
	Vector3(25.5, 0, 22),   
	Vector3(44, 0, 22),     
	Vector3(8, 0, 40), 
	Vector3(61.5, 0, 40),
	Vector3(20, 0, 47),
	Vector3(50, 0, 47)   
]

var team_players : Array[Node3D] = []
var current_controlled_idx : int = 0

func _ready() -> void:
	if not player_scene:
		return
		
	# Instancia os jogadores nas suas posições iniciais fixas
	for i in range(formation_offsets.size()):
		var new_player = player_scene.instantiate() as CharacterBody3D
		
		# Adicionamos o jogador na árvore de nós
		add_child(new_player)
		
		# Injetamos a referência da bola
		new_player.ball_node = ball
		
		# Aplicamos a posição real de jogo no mundo 3D
		new_player.global_position = formation_offsets[i]
		
		# Forçamos o script do jogador a salvar este ponto como seu início
		new_player.home_position = formation_offsets[i]
		new_player.formation_target_position = formation_offsets[i]
		
		# Guardamos a referência na lista do time
		team_players.append(new_player)
	
	if team_players.size() > 0:
		definir_jogador_ativo(current_controlled_idx)

func _process(_delta: float) -> void:
	if not ball:
		return

	# Comando para alternar de jogador baseado no mais próximo da bola
	if Input.is_action_just_pressed("change_player"):
		alternar_proximo_jogador()

func definir_jogador_ativo(index: int):
	if index >= team_players.size():
		return
		
	current_controlled_idx = index
	
	for i in range(team_players.size()):
		var player = team_players[i]
		if i == index:
			player.is_controlled = true
			player.view = view_camera  
			view_camera.target = player 
		else:
			player.is_controlled = false
			player.view = null 

func alternar_proximo_jogador():
	if team_players.size() <= 1 or not ball:
		return 
		
	var j_mais_proximo_idx: int = -1
	var menor_distancia: float = 999999.0 
	
	for i in range(team_players.size()):
		if i == current_controlled_idx:
			continue
			
		var player = team_players[i]
		var dist = player.global_position.distance_to(ball.global_position)
		
		if dist < menor_distancia:
			menor_distancia = dist
			j_mais_proximo_idx = i
			
	if j_mais_proximo_idx != -1:
		definir_jogador_ativo(j_mais_proximo_idx)
		
func resetar_posicoes_time() -> void:
	for i in range(team_players.size()):
		var player = team_players[i]
		if player:
			player.global_position = player.home_position
			
			if player is CharacterBody3D:
				player.velocity = Vector3.ZERO
				player.moviment_velocity = Vector3.ZERO
