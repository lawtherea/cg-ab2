extends CharacterBody3D

const SPEED = 500.0
const JUMP_VELOCITY = 10.0

@onready var animator = get_node("soccer_player/AnimationPlayer") as AnimationPlayer

@export var view : Node3D
var gravity = 0
var moviment_velocity : Vector3
var rotation_direction : float

# --- SISTEMA DE QUEDA SIMPLIFICADO ---
var blocked : bool = false
# -------------------------------------

func _ready() -> void:
	# Conecta o sinal para saber quando a animação de queda terminou
	animator.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	# Só processa inputs, pulo e rotação se NÃO estiver caindo
	if not blocked:
		handle_input(delta)
		jump(delta)
		handle_animations()
		
		if Vector2(velocity.z, velocity.x).length() > 0:
			rotation_direction = Vector2(velocity.z, velocity.x).angle()
		rotation.y = lerp_angle(rotation.y, rotation_direction, delta * 10)
		
		# Verifica se a tecla de cair foi pressionada
		if Input.is_action_just_pressed("fall") and is_on_floor():
			iniciar_queda()
		elif Input.is_action_just_pressed("weak_kick") and is_on_floor():
			weak_kick()
		elif Input.is_action_just_pressed("medium_kick") and is_on_floor():
			medium_kick()
		elif Input.is_action_just_pressed("strong_kick") and is_on_floor():
			strong_kick()
		elif Input.is_action_just_pressed("victory") and is_on_floor():
			victory()
	else:
		# Se estiver caindo, zera o movimento para ele ficar parado no lugar
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
	
	moviment_velocity = input * SPEED * delta     
	
func handle_animations():
	if abs(velocity.x) > 1 or abs(velocity.z) > 1:
		animator.play("slow_run", 0.3)
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

# --- FUNÇÕES DA ANIMAÇÃO DE QUEDA ---

func iniciar_queda():
	blocked = true
	moviment_velocity = Vector3.ZERO
	animator.play("fall", 0.2)
	
func weak_kick():
	blocked = true
	animator.play("weak_kick", 0.2)
	
func medium_kick():
	blocked = true
	animator.play("medium_kick", 0.2)
	
func strong_kick():
	blocked = true
	animator.play("strong_kick", 0.2)
	
func victory():
	blocked = true
	animator.play("victory", 0.2)

func _on_animation_finished(anim_name: String):
	# Quando a animação única de queda terminar, devolve o controle ao jogador
	if anim_name != "idle" and anim_name != "slow_run":
		blocked = false
