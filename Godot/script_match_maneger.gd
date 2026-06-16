extends Node

const SOM_TORCIDA_FUNDO := preload("res://Sounds/torcida_fundo_2_otimizado.wav")
const SOM_TORCIDA_GOL := preload("res://Sounds/torcida_gol_2_otimizado.wav")
const SOM_APITO := preload("res://Sounds/apito.wav")

@export var ball : Node3D              
@export var interface_hud : CanvasLayer  # Placar que fica colado na tela do jogador

@export var interface_telao : SubViewport # O SubViewport que alimenta o material do telão

# Gerenciadores de=os times
@export var team_manager_jogador : Node  
@export var team_manager_adversario : Node 

@export var mesh_telao : MeshInstance3D # nó 3D do telão 

var gols_time_A : int = 0
var gols_time_B : int = 0

# Controle do estado da partida
var jogo_iniciado : bool = false

var player_torcida_fundo : AudioStreamPlayer
var player_torcida_gol : AudioStreamPlayer
var player_apito : AudioStreamPlayer

func _ready() -> void:
	_inicializar_sons()

	# Espera um frame para garantir que todos os nós nasceram na memória
	await get_tree().process_frame
	
	# Congela os times e a bola antes do input inicial
	congelar_partida(true)

	# Inicializa os textos dos placares e avisos
	if interface_hud:
		interface_hud.atualizar_placar(gols_time_A, gols_time_B)
		# Garante que o texto de "Pressione para iniciar" apareça na HUD
		if interface_hud.has_method("mostrar_aviso_iniciar"):
			interface_hud.mostrar_aviso_iniciar()

	atualizar_interface_telao()
	await _forcar_render_telao()
	_aplicar_textura_telao()

# Captura click pra começar o jogo
func _unhandled_input(event: InputEvent) -> void:
	if not jogo_iniciado and (event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton):
		if event.is_pressed():
			iniciar_partida()

func iniciar_partida() -> void:
	print("Partida Iniciada! Jogadores liberados.")
	jogo_iniciado = true
	_tocar_apito()
	
	# Esconde o texto de aviso "Pressione qualquer tecla"
	if interface_hud and interface_hud.has_method("esconder_aviso_iniciar"):
		interface_hud.esconder_aviso_iniciar()
	
	# Libera a movimentação e física do campo
	congelar_partida(false)

# Funcao de controle fisico e logico
func congelar_partida(deve_congelar: bool) -> void:
	var modo = PROCESS_MODE_DISABLED if deve_congelar else PROCESS_MODE_INHERIT
	
	# Desativa/Ativa os scripts e IA dos gerenciadores de time
	if team_manager_jogador:
		team_manager_jogador.process_mode = modo
	if team_manager_adversario:
		team_manager_adversario.process_mode = modo
		
	# Trava/Libera a bola física no cenário
	if ball:
		ball.process_mode = modo
		if ball is RigidBody3D and deve_congelar:
			ball.linear_velocity = Vector3.ZERO
			ball.angular_velocity = Vector3.ZERO

func _on_goal_brasil_body_entered(body: Node3D) -> void:
	if body == ball:
		gols_time_B += 1 # Gol da Argentina
		computar_gol()

func _on_goal_argentina_body_entered(body: Node3D) -> void:
	if body == ball:
		gols_time_A += 1 # Gol do Brasil
		team_manager_jogador.time_comemorar()
		computar_gol()

func computar_gol() -> void:
	if player_torcida_gol:
		player_torcida_gol.play()

	# Atualiza as duas interfaces simultaneamente
	if interface_hud:
		interface_hud.atualizar_placar(gols_time_A, gols_time_B)
		interface_hud.mostrar_aviso_gol()
		
	atualizar_interface_telao()
	
	# Pausa para comemoração
	await get_tree().create_timer(3.0).timeout
	
	# reset do jogo:
	if interface_hud:
		interface_hud.esconder_aviso_gol()
		
	# Reseta a física da bola na sua posição customizada
	if ball is RigidBody3D:
		ball.global_position = Vector3(35, 1, 54.4)
		ball.linear_velocity = Vector3.ZERO
		ball.angular_velocity = Vector3.ZERO
		
	# reset dos jogadores
	if team_manager_jogador and team_manager_jogador.has_method("resetar_posicoes_time"):
		team_manager_jogador.resetar_posicoes_time()
		
	if team_manager_adversario and team_manager_adversario.has_method("resetar_posicoes_time"):
		team_manager_adversario.resetar_posicoes_time()

	_tocar_apito()

func _inicializar_sons() -> void:
	player_torcida_fundo = _criar_player("TorcidaFundo", SOM_TORCIDA_FUNDO, -4.0)
	player_torcida_gol = _criar_player("TorcidaGol", SOM_TORCIDA_GOL)
	player_apito = _criar_player("Apito", SOM_APITO)

	player_torcida_fundo.finished.connect(_repetir_torcida_fundo)
	player_torcida_fundo.play()

func _repetir_torcida_fundo() -> void:
	if player_torcida_fundo:
		player_torcida_fundo.play()

func _criar_player(nome: String, stream: AudioStream, volume_db: float = 0.0) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = nome
	player.stream = stream
	player.volume_db = volume_db
	add_child(player)
	return player

func _tocar_apito() -> void:
	if player_apito:
		player_apito.play()

# funcao para telao
func atualizar_interface_telao() -> void:
	if interface_telao:
		var script_espelho = interface_telao.get_node_or_null("Control")
		if script_espelho and script_espelho.has_method("atualizar_placar"):
			script_espelho.atualizar_placar(gols_time_A, gols_time_B)

func _aplicar_textura_telao() -> void:
	if not mesh_telao or not interface_telao:
		return
	var textura_viewport = interface_telao.get_texture()
	var material_3d = mesh_telao.get_material_override() as StandardMaterial3D
	if material_3d:
		material_3d.albedo_texture = textura_viewport
		material_3d.emission_enabled = true
		material_3d.emission_texture = textura_viewport

# O ViewportTexture só aparece no telão 3D após forçar um refresh do SubViewport
func _forcar_render_telao() -> void:
	if not interface_telao:
		return
	interface_telao.render_target_update_mode = SubViewport.UPDATE_DISABLED
	await get_tree().process_frame
	interface_telao.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	await get_tree().process_frame
