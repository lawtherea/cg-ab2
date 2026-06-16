extends CharacterBody3D

const SPEED = 150.0
const JUMP_VELOCITY = 10.0

@onready var animator = get_node("model_player_brasil/AnimationPlayer") as AnimationPlayer

@export var view : Node3D
var gravity = 0
var moviment_velocity : Vector3
var rotation_direction : float

# --- VARIÁVEIS DE CONTROLE E IA BASEADA EM ZONAS ---
@export var is_controlled : bool = false      # Define se este jogador recebe inputs do teclado
var formation_target_position : Vector3       # Posição ideal enviada pelo Manager (se aplicável)
var ball_node: Bola = null                  # Referência para a bola do jogo
var ball_possession: bool = false
var kick_force: int
var pode_dominar: bool = true
@export var min_distance_to_ball : float = 3  # Distância física ideal para cercar a bola

@export var patrol_radius : float = 10.0       # Raio da área/zona que o jogador protege e monitora
var home_position : Vector3                    # Guarda o ponto inicial onde o jogador começou no campo
# --------------------------------------------------

var blocked : bool = false

func _ready() -> void:
	animator.animation_finished.connect(_on_animation_finished)
	# Salva a posição exata onde o jogador foi instanciado como sua "casa"
	home_position = global_position
	formation_target_position = global_position

func _physics_process(delta: float) -> void:
	if not blocked:
		if is_controlled:
			handle_input(delta)
			handle_user_actions()
		else:
			handle_ai_zone(delta) # Nova IA baseada em Zonas de Atuação
			
		jump(delta)
		handle_animations()
		
		if Vector2(velocity.z, velocity.x).length() > 0:
			rotation_direction = Vector2(velocity.z, velocity.x).angle()
		rotation.y = lerp_angle(rotation.y, rotation_direction, delta * 10)
		
	else:
		moviment_velocity = Vector3.ZERO
		velocity.x = 0
		velocity.z = 0

	apply_gravity(delta)
	
	var applied_velocity : Vector3
	applied_velocity = velocity.lerp(moviment_velocity, delta * 10)
	applied_velocity.y = -gravity
	
	velocity = applied_velocity
	move_and_slide()

func handle_input(delta):
	var input := Vector3.ZERO
	input.x = Input.get_axis("move_left", "move_right")
	input.z = Input.get_axis("move_forward", "move_backward")
	
	if view:
		input = input.rotated(Vector3.UP, view.rotation.y).normalized()
	
	moviment_velocity = input * SPEED * delta     

func handle_user_actions():
	if not is_on_floor():
		return 
		
	if Input.is_action_just_pressed("fall"):
		iniciar_queda()
	elif Input.is_action_just_pressed("weak_kick") and ball_possession:
		weak_kick()
	elif Input.is_action_just_pressed("medium_kick") and ball_possession:
		medium_kick()
	elif Input.is_action_just_pressed("strong_kick") and ball_possession:
		strong_kick()
	elif Input.is_action_just_pressed("victory"):
		victory()

# --- LÓGICA DE IA POR ZONA DE ATUAÇÃO COM DESLOCAMENTO DINÂMICO DO EIXO Z ---
func handle_ai_zone(delta: float):
	if not ball_node:
		moviment_velocity = Vector3.ZERO
		return

	var target_pos : Vector3
	var ball_pos = ball_node.global_position
	
	# CALCULO DA DINÂMICA DE RECUO/AVANÇO DA LINHA TÁTICA
	var dynamic_home = home_position
	
	if ball_pos.z > 54.5:
		# Calcula a distância da bola para o limite tático no eixo Z
		var z_distance_from_limit = ball_pos.z - 54.5
		# Move a posição base de referência temporariamente acompanhando esse deslocamento
		dynamic_home.z = home_position.z + z_distance_from_limit
	else:
		# Se a bola estiver abaixo ou igual a 35, respeita estritamente a home padrão
		dynamic_home = home_position

	# 1. Verifica a distância usando a 'dynamic_home' atualizada
	var ball_distance_from_home = dynamic_home.distance_to(ball_pos)
	var distance_to_ball = global_position.distance_to(ball_pos)

	# CONDIÇÃO: A bola está dentro do raio de cobertura da minha zona modificada?
	if ball_distance_from_home <= patrol_radius:
		
		# Se eu já cheguei perto da bola dentro do meu raio, eu paro e cerco
		if distance_to_ball <= min_distance_to_ball:
			moviment_velocity = column_decay_stop(delta)
			focar_olhar(ball_pos)
			return
			
		# Antecipação tática da bola
		var ball_vel = Vector3.ZERO
		if ball_node is RigidBody3D:
			ball_vel = ball_node.linear_velocity
		
		var ponto_futuro_da_bola = ball_pos + (ball_vel * 0.2)
		var direcao_da_bola_ao_jogador = (global_position - ponto_futuro_da_bola).normalized()
		
		# Define o alvo como a borda da bola
		target_pos = ponto_futuro_da_bola + (direcao_da_bola_ao_jogador * min_distance_to_ball)
		
	else:
		# CASO CONTRÁRIO: Fora do raio, retorna e defende a posição tática dinâmica corrigida
		target_pos = dynamic_home

	# 2. Executa a movimentação física até o alvo determinado
	var direction = (target_pos - global_position)
	direction.y = 0

	if direction.length() > 0.1:
		direction = direction.normalized()
		
		# Mantém as proporções originais de velocidade da sua zona de patrulha
		var speed_multiplier = 0.65 if ball_distance_from_home <= patrol_radius else 0.55
		moviment_velocity = direction * (SPEED * speed_multiplier) * delta
	else:
		moviment_velocity = Vector3.ZERO
		focar_olhar(ball_pos)

# Função auxiliar para frenagem suave nas bordas da bola
func column_decay_stop(delta: float) -> Vector3:
	return column_decay_stop_value(moviment_velocity, delta)

func column_decay_stop_value(current_vel: Vector3, delta: float) -> Vector3:
	return current_vel.lerp(Vector3.ZERO, delta * 10)

func focar_olhar(alvo: Vector3):
	var look_target = alvo
	look_target.y = global_position.y
	rotation_direction = Vector2(look_target.z - global_position.z, look_target.x - global_position.x).angle()

# --- ANIMAÇÕES E MÓDULOS DE FÍSICA ---
func handle_animations():
	if blocked:
		return
	if abs(velocity.x) > 0.2 or abs(velocity.z) > 0.2:
		animator.play("slow_run", 0.3)
	else :
		animator.play("idle", 0.3)
		
func apply_gravity(delta):
	if is_on_floor():
		if gravity > 0:
			gravity = 0
	else:
		gravity += 25.0 * delta
	
func jump(delta):
	if not is_controlled:
		return
	if Input.is_action_just_pressed("jump") and is_on_floor():
		gravity = -JUMP_VELOCITY

func aplicar_cooldown_dominio():
	ball_possession = false
	pode_dominar = false  
	await get_tree().create_timer(0.5).timeout
	pode_dominar = true

# --- FUNÇÕES DAS ANIMAÇÕES DE BLOQUEIO ---
func iniciar_queda():
	blocked = true
	velocity = Vector3.ZERO
	moviment_velocity = Vector3.ZERO
	animator.play("fall", 0.1)
	
func weak_kick():
	blocked = true
	velocity = Vector3.ZERO
	moviment_velocity = Vector3.ZERO
	animator.play("weak_kick", 0.1)
	
	kick_force = 2
	var direcao = global_transform.basis.z.normalized()
	direcao = direcao.normalized()
	ball_node.chutar(direcao, kick_force)
	aplicar_cooldown_dominio()
	
func medium_kick():
	blocked = true
	velocity = Vector3.ZERO
	moviment_velocity = Vector3.ZERO
	animator.play("medium_kick", 0.1)
	
	kick_force = 6
	var direcao = global_transform.basis.z.normalized()
	direcao = direcao.normalized()
	ball_node.chutar(direcao, kick_force)
	aplicar_cooldown_dominio()
	
func strong_kick():
	blocked = true
	velocity = Vector3.ZERO
	moviment_velocity = Vector3.ZERO
	animator.play("strong_kick", 0.1)
	
	kick_force = 8
	var direcao = global_transform.basis.z.normalized()
	direcao = direcao.normalized()
	ball_node.chutar(direcao, kick_force)
	aplicar_cooldown_dominio()
	
func victory():
	blocked = true
	velocity = Vector3.ZERO
	moviment_velocity = Vector3.ZERO
	animator.play("victory", 0.1)

func _on_animation_finished(anim_name: String):
	var blocking_animations = ["fall", "weak_kick", "medium_kick", "strong_kick", "victory"]
	for i in range(blocking_animations.size()):
		var animacao_bloqueante = blocking_animations[i]
		if animacao_bloqueante in anim_name:
			blocked = false
			return

func _on_possession_area_area_entered(area: Area3D) -> void:
	var jogador_rival = area.get_parent()
	if "ball_possession" in jogador_rival and jogador_rival.ball_possession == true:
		print("Dividida! Brasil desarmou a Argentina!")
		jogador_rival.aplicar_cooldown_dominio()
		
		var direcao_dividida = (ball_node.global_position - global_position).normalized()
		direcao_dividida.y += 0.2 # Dá uma leve levantada na bola
		direcao_dividida = direcao_dividida.normalized()
			
		ball_node.chutar(direcao_dividida, 2.0)
			
		aplicar_cooldown_dominio()

func _on_possession_area_body_entered(body: Node3D) -> void:
	print("--- RELATÓRIO DE COLISÃO ---")
	print("eu [PossesionArea] to na layer 2?", $PossessionArea.get_collision_layer_value(2))
	print("eu [PossesionArea] vejo a mascara 2?", $PossessionArea.get_collision_mask_value(2))
	print("1. Encostei no objeto chamado: ", body.name)
	
	# Verifica se o objeto tem a propriedade de colisão antes de checar
	if body is CollisionObject3D:
		# Checa as Layers do objeto que encostou (Bola)
		print("2. O objeto está na Layer 2 (Bola)? ", body.get_collision_layer_value(2))
		
		# Checa as Masks da sua própria Área (PossesionArea)
		# O $PossesionArea pressupõe que o nó se chama assim na árvore do jogador
		var minha_area = $PossessionArea
		print("3. A minha Área consegue enxergar a Layer 2? ", minha_area.get_collision_mask_value(2))
	
	print("4. O Godot reconhece a classe como Bola? ", body is Bola)
	print("----------------------------")

	# A sua lógica normal de domínio
	if body is Bola and pode_dominar:
		ball_possession = true
		ball_node.dominar(self)
