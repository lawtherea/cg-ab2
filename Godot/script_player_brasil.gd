extends CharacterBody3D

const SPEED = 500.0
const JUMP_VELOCITY = 10.0

@onready var animator = get_node("model_player_brasil/AnimationPlayer") as AnimationPlayer

@export var view : Node3D
var gravity = 0
var moviment_velocity : Vector3
var rotation_direction : float

# --- VARIÁVEIS DE CONTROLE E IA ---
@export var is_controlled : bool = false # Define se este jogador recebe inputs do teclado 
var formation_target_position : Vector3  # Posição ideal dele no campo de acordo com a tática 
var ball_node : Node3D                   # Referência para a bola do jogo 
@export var min_distance_to_ball : float = 2.0 # Distância que a IA manterá da bola ao persegui-la
# ----------------------------------

var blocked : bool = false 

func _ready() -> void:
	# Conecta o sinal para saber quando a animação de queda/chute terminou 
	animator.animation_finished.connect(_on_animation_finished) 
	# Garante que as variáveis de formação comecem na posição atual caso não sejam setadas externamente 
	formation_target_position = global_position 

func _physics_process(delta: float) -> void:
	if not blocked: 
		# DIFERENCIAÇÃO DE COMPORTAMENTO 
		if is_controlled: 
			handle_input(delta) 
			handle_user_actions() 
		else: 
			handle_ai(delta) # Movimentação programada (IA) 
			
		jump(delta) 
		handle_animations() 
		
		if Vector2(velocity.z, velocity.x).length() > 0: 
			rotation_direction = Vector2(velocity.z, velocity.x).angle() 
		rotation.y = lerp_angle(rotation.y, rotation_direction, delta * 10) 
		
	else: 
		# Se estiver bloqueado (chutando ou caindo), zera o movimento e a física residual imediatamente
		moviment_velocity = Vector3.ZERO 
		velocity.x = 0 
		velocity.z = 0 

	apply_gravity(delta) 
	
	var applied_velocity : Vector3 
	applied_velocity = velocity.lerp(moviment_velocity, delta * 10) 
	applied_velocity.y = -gravity 
	
	velocity = applied_velocity 

	move_and_slide() 

# Processa apenas o direcional do usuário conectado à câmera 
func handle_input(delta):
	var input := Vector3.ZERO 
	input.x = Input.get_axis("move_left", "move_right") 
	input.z = Input.get_axis("move_forward", "move_backward") 
	
	# Só calcula rotação baseada na câmera se a câmera estiver instanciada/associada 
	if view: 
		input = input.rotated(Vector3.UP, view.rotation.y).normalized() 
	
	moviment_velocity = input * SPEED * delta     

# Isola as ações de chute/ações para o jogador controlado pelo usuário
func handle_user_actions():
	if not is_on_floor():
		return # Se não estiver no chão, ignora todas as ações abaixo
		
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

# LÓGICA DA IA (Movimentação programada baseada na bola e formação) 
func handle_ai(delta):
	if not ball_node: 
		moviment_velocity = Vector3.ZERO 
		return 

	var target_pos = formation_target_position 
	var distance_to_ball = global_position.distance_to(ball_node.global_position) 
	
	# Se a bola estiver perto (menos de 8 metros), o jogador decide interagir com ela 
	if distance_to_ball < 8.0: 
		# Se ele atingir ou ultrapassar a distância mínima regulada, ele para de correr atrás dela
		if distance_to_ball <= min_distance_to_ball:
			moviment_velocity = Vector3.ZERO
			return
		
		target_pos = ball_node.global_position 
		
	# Calcula a direção até o ponto ideal (seja a bola ou a sua posição na tática) 
	var direction = (target_pos - global_position) 
	direction.y = 0 # Ignora eixo Y para movimentação no plano do campo 
	
	# Se estiver caçando a bola, ajustamos o vetor para ele desacelerar à distância correta
	if distance_to_ball < 8.0:
		var direction_to_player = (global_position - ball_node.global_position).normalized()
		target_pos = ball_node.global_position + (direction_to_player * min_distance_to_ball)
		direction = (target_pos - global_position)
		direction.y = 0

	# Se estiver longe do ponto ideal, corre em direção a ele 
	if direction.length() > 0.5: 
		direction = direction.normalized() 
		# Reduz ligeiramente a velocidade da IA para dar vantagem ao jogador controlado 
		moviment_velocity = direction * (SPEED * 0.8) * delta 
	else: 
		moviment_velocity = Vector3.ZERO 

# --- GERENCIAMENTO DE ANIMAÇÕES PADRÃO ---
func handle_animations():
	# Blindagem extra: se estiver executando uma ação de travamento, ignora atualizações de corrida/idle
	if blocked:
		return
		
	# Verificação da velocidade de movimentação real aplicada no corpo
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
	# Só processa a intenção de pulo se for o jogador controlado
	if not is_controlled:
		return
		
	if Input.is_action_just_pressed("jump") and is_on_floor():
		gravity = -JUMP_VELOCITY

# --- FUNÇÕES DA ANIMAÇÃO DE BLOQUEIO (Ações do Jogador) ---
# Limpar as variáveis de velocidade antes de rodar o .play() impede que a animação anterior atropele o comando

# --- FUNÇÕES DA ANIMAÇÃO DE BLOQUEIO (Ações do Jogador) ---

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

# --- SISTEMA INTELIGENTE DE DESTRAVAMENTO DE ANIMAÇÃO ---

func _on_animation_finished(anim_name: String):
	var blocking_animations = ["fall", "weak_kick", "medium_kick", "strong_kick", "victory"]
	
	# Loop seguro por índice numérico para evitar conflitos de sintaxe
	for i in range(blocking_animations.size()):
		var animacao_bloqueante = blocking_animations[i]
		if animacao_bloqueante in anim_name:
			blocked = false
			return
	
	# Usando busca parcial. Resolve problemas caso a animação venha com prefixos como "Player_Brasil/weak_kick"
	for block_anim in blocking_animations:
		if block_anim in anim_name:
			blocked = false
			return
