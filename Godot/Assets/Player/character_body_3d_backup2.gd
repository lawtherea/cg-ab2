extends CharacterBody3D

const SPEED = 500.0
const JUMP_VELOCITY = 10.0

@onready var animator = get_node("teste1jogador/AnimationPlayer") as AnimationPlayer

@export var view : Node3D
var gravity = 0
var moviment_velocity : Vector3
var rotation_direction : float

# --- NOVAS VARIÁVEIS PARA O SISTEMA DE QUEDA ---
enum Estado { NORMAL, CAINDO, NO_CHAO, LEVANTANDO }
var estado_atual = Estado.NORMAL

# Tempo (em segundos) que o jogador vai ficar caído antes de começar a levantar
@export var tempo_no_chao : float = 2.0 
# ----------------------------------------------

func _ready() -> void:
	# Conecta o sinal do AnimationPlayer para sabermos quando uma animação termina
	animator.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	# Só processa inputs, pulo e rotação se o jogador estiver no estado NORMAL
	if estado_atual == Estado.NORMAL:
		handle_input(delta)
		jump(delta)
		handle_animations()
		
		if Vector2(velocity.z, velocity.x).length() > 0:
			rotation_direction = Vector2(velocity.z, velocity.x).angle()
		rotation.y = lerp_angle(rotation.y, rotation_direction, delta * 10)
		
		# Verifica se a tecla de cair foi pressionada
		# MODIFIQUE AQUI: Substitua "fall" pelo nome correto da sua ação no Mapa de Inputs
		if Input.is_action_just_pressed("fall") and is_on_floor():
			iniciar_queda()
	else:
		# Se não estiver no estado normal (está caído/caindo), ele fica parado
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
	
	input = input.rotated(Vector3.UP, view.rotation.y).normalized()
	
	# Corrigido: alimentando a moviment_velocity para o lerp do physics_process
	moviment_velocity = input * SPEED * delta	 
	
func handle_animations():
	if abs(velocity.x) > 1 or abs(velocity.z) > 1:
		animator.play("slow run", 0.3)
	else :
		animator.play("idle", 0.3)
		
func apply_gravity(delta):
	if not is_on_floor():
		gravity += 25 * delta
	
func jump(delta):
	if Input.is_action_just_pressed("jump") and is_on_floor():
		gravity = -JUMP_VELOCITY
		
	if gravity > 0 and is_on_floor():
		gravity = 0

# --- NOVAS FUNÇÕES PARA GERENCIAR A QUEDA ---

func iniciar_queda():
	estado_atual = Estado.CAINDO
	moviment_velocity = Vector3.ZERO
	
	# MODIFIQUE AQUI: Substitua "animacao_cair" pelo nome da sua animação de queda
	animator.play("fall", 0.2)

func _on_animation_finished(anim_name: String):
	# Se terminou a animação de cair, ele vai para o chão e inicia o tempo de espera
	# MODIFIQUE AQUI: Substitua "animacao_cair" pelo nome da sua animação de queda
	if anim_name == "fall" and estado_atual == Estado.CAINDO:
		estado_atual = Estado.NO_CHAO
		
		# MODIFIQUE AQUI: Substitua "idle_fall" pelo nome da sua animação de deitado no chão
		animator.play("idle fall", 0.2)
		
		# Cria um timer temporário para esperar o tempo determinado
		await get_tree().create_timer(tempo_no_chao).timeout
		
		# Após o tempo acabar, começa a levantar
		if estado_atual == Estado.NO_CHAO: # Garante que ainda está no chão
			estado_atual = Estado.LEVANTANDO
			
			# MODIFIQUE AQUI: Substitua "animacao_levantar" pelo nome da sua animação de levantar
			animator.play("lift", 0.2)

	# Se terminou a animação de levantar, o jogador volta ao controle normal
	# MODIFIQUE AQUI: Substitua "animacao_levantar" pelo nome da sua animação de levantar
	elif anim_name == "lift" and estado_atual == Estado.LEVANTANDO:
		estado_atual = Estado.NORMAL
