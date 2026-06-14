extends Node

@export var view_camera : Node3D       # Arraste seu nó de câmera (view.gd) aqui
@export var ball : Node3D              # Arraste o nó da bola aqui

# --- NOVO: Referência para o arquivo do modelo/cena do jogador ---
@export var player_scene : PackedScene 

# Definição das posições ideais da formação (Ex: 5 jogadores)
@export var formation_offsets : Array[Vector3] = [
	Vector3(20, 0, 15),  # Defensor Esquerdo
	Vector3(10, 0, 15),   # Defensor Direito
	Vector3(0, 0, 0),     # Meio Campo
	Vector3(5, 0, 15),  # Atacante 1
	Vector3(5, 0, 15)    # Atacante 2
]

# Lista que vai guardar os jogadores criados dinamicamente
var team_players : Array[Node3D] = []
var current_controlled_idx : int = 0

func _ready() -> void:
	if not player_scene:
		push_error("Erro: Você esqueceu de passar a player_scene no Inspetor do TeamManager!")
		return
		
	# LOOP: Cria um jogador para cada posição definida na formação
	for i in range(formation_offsets.size()):
		# 1. Instancia uma nova cópia do jogador na memória
		var new_player = player_scene.instantiate() as CharacterBody3D
		
		# 2. Adiciona o jogador como filho da cena atual para ele aparecer no mundo
		add_child(new_player)
		
		# 3. Configura as variáveis iniciais dele (como a bola e as posições)
		new_player.ball_node = ball
		new_player.global_position = formation_offsets[i]
		new_player.formation_target_position = formation_offsets[i]
		
		# 4. Guarda a referência dele na nossa lista de gerenciamento
		team_players.append(new_player)
	
	# Define o primeiro jogador criado (índice 0) como o controlado pelo usuário
	if team_players.size() > 0:
		definir_jogador_ativo(current_controlled_idx)

func _process(_delta: float) -> void:
	# Mantém a IA atualizando a posição tática dinamicamente com base na bola
	for i in range(team_players.size()):
		if ball:
			var shift = Vector3(ball.global_position.x * 0.3, 0, ball.global_position.z * 0.5)
			team_players[i].formation_target_position = formation_offsets[i] + shift

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
		return # Não há outros jogadores para alternar ou a bola não existe
		
	var jogador_mais_proximo_idx: int = -1
	var menor_distancia: float = 999999.0 # Começa com um valor absurdamente alto
	
	# Percorre todos os jogadores do time
	for i in range(team_players.size()):
		# Se for o jogador que o usuário JÁ está controlando, pula ele
		if i == current_controlled_idx:
			continue
			
		var player = team_players[i]
		
		# Calcula a distância em 3D deste jogador até a bola
		var distancia_ate_a_bola = player.global_position.distance_to(ball.global_position)
		
		# Se a distância for menor do que a menor distância registrada até agora, atualiza
		if distancia_ate_a_bola < menor_distancia:
			menor_distancia = distancia_ate_a_bola
			jogador_mais_proximo_idx = i
			
	# Se encontramos um jogador válido (mais próximo), fazemos a troca para ele
	if jogador_mais_proximo_idx != -1:
		definir_jogador_ativo(jogador_mais_proximo_idx)
