extends CharacterBody3D

const SPEED = 500.0

@onready var animator = get_node("model_player_argentina/AnimationPlayer") as AnimationPlayer

var gravity = 0
var moviment_velocity : Vector3
var rotation_direction : float

# --- VARIÁVEIS DE CONTROLE E IA BASEADA EM ZONAS ---
var ball_node : Node3D                        
var min_distance_to_ball : float = 1.5        # Menor para a IA de fato tocar/chutar a bola
var patrol_radius : float = 15.0              # Raio de patrulha ligeiramente maior para cobertura adversária
var home_position : Vector3                    # Ponto inicial/tático do jogador
var formation_target_position : Vector3

# Nova variável controlada pelo Manager da Argentina
var is_chaser : bool = false                  

var blocked : bool = false

func _ready() -> void:
	animator.animation_finished.connect(_on_animation_finished)
	home_position = global_position
	formation_target_position = global_position

func _physics_process(delta: float) -> void:
	if not blocked:
		handle_ai_zone_argentina(delta)
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

# --- LÓGICA DE IA DA ARGENTINA (ESPELHADA E ADVERSÁRIA) ---
# --- LÓGICA DE IA DA ARGENTINA (ATUALIZADA) ---
# --- LÓGICA DE IA DA ARGENTINA (ATUALIZADA PARA REPOSIÇÃO DE POSIÇÃO) ---
func handle_ai_zone_argentina(delta: float):
	if not ball_node:
		moviment_velocity = Vector3.ZERO
		return

	var target_pos : Vector3
	var ball_pos = ball_node.global_position
	var dynamic_home = home_position
	
	# Recuo e avanço da linha tática da Argentina (Z < 54.5)
	if ball_pos.z < 54.5:
		var z_distance_from_limit = ball_pos.z - 54.5
		dynamic_home.z = home_position.z + z_distance_from_limit
	else:
		dynamic_home = home_position

	var distance_to_ball = global_position.distance_to(ball_pos)

	# --- SE FOR O CAÇADOR (CHASER) ELEITO ---
	if is_chaser:
		# Coordenada do centro do gol do adversário (Brasil)
		var gol_alvo = Vector3(35, 0, 0)
		
		# Calcula a direção da bola para o gol
		var direcao_para_o_gol = (gol_alvo - ball_pos).normalized()
		
		# O jogador se posiciona atrás da bola na linha do gol para empurrá-la para frente
		var distancia_atras_da_bola = 1.3
		target_pos = ball_pos - (direcao_para_o_gol * distancia_atras_da_bola)
		target_pos.y = global_position.y
		
		# Se já colidiu ou está colado na bola, diminui a velocidade para processar a física do impacto
		if distance_to_ball <= min_distance_to_ball:
			moviment_velocity = column_decay_stop(delta)
			focar_olhar(ball_pos)
			return
			
	# --- SE NÃO FOR MAIS ELEGÍVEL / NÃO FOR O CHASER ---
	else:
		# MODIFICAÇÃO: O alvo principal passa a ser OBRIGATORIAMENTE a sua posição na formação
		target_pos = dynamic_home
		
		# Se ele já chegou muito perto da sua posição tática na formação (ex: menos de 1 metro)
		# e a bola estiver por perto, ele vira para olhar para a bola e defender a zona
		if global_position.distance_to(dynamic_home) < 1.0:
			moviment_velocity = column_decay_stop(delta)
			focar_olhar(ball_pos)
			return

	# Executa a movimentação física até o alvo (seja a bola ou a formação)
	var direction = (target_pos - global_position)
	direction.y = 0

	if direction.length() > 0.1:
		direction = direction.normalized()
		
		# Defensores voltando para a formação correm um pouco mais devagar (0.55) 
		# do que o jogador que está correndo em direção à bola de forma agressiva (0.80)
		var speed_multiplier = 0.80 if is_chaser else 0.55 
		moviment_velocity = direction * (SPEED * speed_multiplier) * delta
	else:
		moviment_velocity = Vector3.ZERO
		focar_olhar(ball_pos)

func column_decay_stop(delta: float) -> Vector3:
	return moviment_velocity.lerp(Vector3.ZERO, delta * 10)

func focar_olhar(alvo: Vector3):
	var look_target = alvo
	look_target.y = global_position.y
	rotation_direction = Vector2(look_target.z - global_position.z, look_target.x - global_position.x).angle()

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

func _on_animation_finished(anim_name: String):
	var blocking_animations = ["fall", "weak_kick", "medium_kick", "strong_kick"]
	for i in range(blocking_animations.size()):
		if blocking_animations[i] in anim_name:
			blocked = false
			return
