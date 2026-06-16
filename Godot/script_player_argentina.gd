extends CharacterBody3D

const SPEED = 200


@onready var animator = get_node("model_player_argentina/AnimationPlayer") as AnimationPlayer

var gravity = 0
var moviment_velocity : Vector3
var rotation_direction : float

# --- VARIÁVEIS DE CONTROLE E IA BASEADA EM ZONAS ---
var ball_node : Node3D                        
var min_distance_to_ball : float = 1.5        # Menor para a IA de fato tocar/chutar a bola
var patrol_radius : float = 15.0              # Raio de patrulha ligeiramente maior para cobertura adversária
var home_position : Vector3                   # Ponto inicial/tático do jogador
var formation_target_position : Vector3
var pode_dominar: bool = true
var ball_possession: bool = false
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

# --- LÓGICA DE IA DA ARGENTINA ---
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
		# Verifica se um brasileiro está com a posse da bola
		var portador = null
		if "jogador_atual" in ball_node:
			portador = ball_node.jogador_atual

		if portador != null:
			# MODO INTERCEPÇÃO: vai direto no portador sem desacelerar para garantir o roubo
			target_pos = portador.global_position
			target_pos.y = global_position.y
			var dir = (target_pos - global_position)
			dir.y = 0
			if dir.length() > 0.1:
				moviment_velocity = dir.normalized() * (SPEED * 0.90) * delta
			focar_olhar(target_pos)
			return
		else:
			# Bola livre: posiciona atrás da bola em direção ao gol adversário
			var gol_alvo = Vector3(35, 0, 0)
			var direcao_para_o_gol = (gol_alvo - ball_pos).normalized()
			var distancia_atras_da_bola = 1.3
			target_pos = ball_pos - (direcao_para_o_gol * distancia_atras_da_bola)
			target_pos.y = global_position.y

			if distance_to_ball <= min_distance_to_ball:
				moviment_velocity = column_decay_stop(delta)
				focar_olhar(ball_pos)
				return
			
	# --- SE NÃO FOR MAIS ELEGÍVEL / NÃO FOR O CHASER ---
	else:
		# O alvo principal passa a ser OBRIGATORIAMENTE a sua posição na formação
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

func aplicar_cooldown_dominio():
	pode_dominar = false
	await get_tree().create_timer(0.8).timeout 
	pode_dominar = true

func _on_possession_area_area_entered(area: Area3D) -> void:
	var jogador_rival = area.get_parent()
	if "ball_possession" in jogador_rival and jogador_rival.ball_possession == true:
		print("Dividida! Argentina desarmou o Brasil!")
		jogador_rival.aplicar_cooldown_dominio()
		
		var direcao_para_gol = (Vector3(35, 0, 0) - ball_node.global_position).normalized()
		var lateral = direcao_para_gol.cross(Vector3.UP).normalized()
		var direcao_dividida = (direcao_para_gol + lateral * 0.5).normalized()
		direcao_dividida.y += 0.15
		direcao_dividida = direcao_dividida.normalized()

		ball_node.chutar(direcao_dividida, 5.0)
			
		aplicar_cooldown_dominio()


func _on_possession_area_body_entered(body: Node3D) -> void:
	print("--- RELATÓRIO DE COLISÃO ARGENTINA ---")
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
