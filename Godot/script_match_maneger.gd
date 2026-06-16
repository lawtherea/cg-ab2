extends Node

@export var ball : Node3D              
@export var interface_hud : CanvasLayer  # Placar que fica colado na tela do jogador

# --- NOVA REFERÊNCIA PARA O TELÃO 3D ---
@export var interface_telao : SubViewport # O SubViewport que alimenta o material do telão

# --- GERENCIADORES DOS DOIS TIMES ---
@export var team_manager_jogador : Node  
@export var team_manager_adversario : Node 

@export var mesh_telao : MeshInstance3D #  nó 3D do telão 

var gols_time_A : int = 0
var gols_time_B : int = 0

func _ready() -> void:
	# 1. Espera um frame para garantir que todos os nós nasceram na memória
	await get_tree().process_frame
	
	# 2. Configura a textura do telão diretamente via código (Runtime)
	if mesh_telao and interface_telao:
		# Pega a textura em tempo real gerada pelo seu SubViewport
		var textura_viewport = interface_telao.get_texture()
		
		# Pega o material que está aplicado no seu telão 3D
		# (Se estiver usando Material Override, mude para get_material_override())
		var material_3d = mesh_telao.get_material_override() as StandardMaterial3D
		
		if material_3d:
			# Injeta a textura no canal de cor (Albedo) e de luz (Emission)
			material_3d.albedo_texture = textura_viewport
			material_3d.emission_enabled = true
			material_3d.emission_texture = textura_viewport
			print("Conexão de vídeo do telão realizada com sucesso via código!")

	# 3. Inicializa os textos dos placares
	if interface_hud:
		interface_hud.atualizar_placar(gols_time_A, gols_time_B)
		
	atualizar_interface_telao()

func _on_goal_brasil_body_entered(body: Node3D) -> void:
	print("Algo entrou no gol do Brasil! (Time A)")
	if body == ball:
		gols_time_B += 1 # Gol da Argentina
		computar_gol()

func _on_goal_argentina_body_entered(body: Node3D) -> void:
	print("Algo entrou no gol da Argentina! (Time B)")
	if body == ball:
		gols_time_A += 1 # Gol do Brasil
		computar_gol()

func computar_gol() -> void:
	print("GOOOOL registrado pelo PartidaManager!")
	
	# 1. Atualiza as duas interfaces simultaneamente
	if interface_hud:
		interface_hud.atualizar_placar(gols_time_A, gols_time_B)
		interface_hud.mostrar_aviso_gol() # Mostra o "GOOOOL!" apenas na tela do jogador
		
	atualizar_interface_telao()
		
	# 2. Pausa dramática de 3 segundos para comemoração
	await get_tree().create_timer(3.0).timeout
	
	# 3. O tempo acabou! Fazemos o reset do jogo:
	if interface_hud:
		interface_hud.esconder_aviso_gol()
		
	# Reseta a física da bola no centro
	if ball is RigidBody3D:
		ball.global_position = Vector3(35, 1, 54.4)
		ball.linear_velocity = Vector3.ZERO
		ball.angular_velocity = Vector3.ZERO
		
	# --- RESET DOS ATLETAS EM CAMPO ---
	if team_manager_jogador and team_manager_jogador.has_method("resetar_posicoes_time"):
		team_manager_jogador.resetar_posicoes_time()
		
	if team_manager_adversario and team_manager_adversario.has_method("resetar_posicoes_time"):
		team_manager_adversario.resetar_posicoes_time()

# --- FUNÇÃO AUXILIAR PARA O TELÃO 3D ---
func atualizar_interface_telao() -> void:
	if interface_telao:
		# Acessa o nó de script da interface que está dentro do SubViewport
		# NOTA: Certifique-se de que o nó filho do seu SubViewport se chama "Control_Espelho"
		var script_espelho = interface_telao.get_node_or_null("Control_Espelho")
		if script_espelho and script_espelho.has_method("atualizar_placar"):
			script_espelho.atualizar_placar(gols_time_A, gols_time_B)
