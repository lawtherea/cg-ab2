extends CharacterBody3D

const SPEED = 500.0
const JUMP_VELOCITY = 10.0

@onready var animator = get_node("model_player_brasil/AnimationPlayer") as AnimationPlayer

@export var view : Node3D
var gravity = 0
var moviment_velocity : Vector3
var rotation_direction : float

# --- VARIÁVEIS DE CONTROLE E IA BASEADA EM ZONAS ---
@export var is_controlled : bool = false      # Define se este jogador recebe inputs do teclado
var formation_target_position : Vector3       # Posição ideal enviada pelo Manager (se aplicável)
var ball_node : Node3D                        # Referência para a bola do jogo
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
	elif Input.is_action_just_pressed("weak_kick"):
		weak_kick()
	elif Input.is_action_just_pressed("medium_kick"):
		medium_kick()
	elif Input.is_action_just_pressed("strong_kick"):
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
	
func medium_kick():
	blocked = true
	velocity = Vector3.ZERO
	moviment_velocity = Vector3.ZERO
	animator.play("medium_kick", 0.1)
	
func strong_kick():
	blocked = true
	velocity = Vector3.ZERO
	moviment_velocity = Vector3.ZERO
	animator.play("strong_kick", 0.1)
	
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
