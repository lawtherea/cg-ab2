extends RigidBody3D
class_name Bola

var jogador_atual: Node3D = null

# Referência à malha visual da bola e o raio dela
@onready var malha_visual = $PivotVisual 
@export var raio_da_bola: float = 0.11 # IMPORTANTE: Ajuste para o raio real do seu modelo 3D!

func _physics_process(delta):
	if jogador_atual != null:
		# 1. A bola (corpo físico) acompanha a posição do ponto de drible
		global_position = jogador_atual.get_node("DribblePoint").global_position
		
		# 2. Pega a velocidade atual do jogador
		# Assumindo que o jogador é um CharacterBody3D, ele tem a propriedade 'velocity'
		var velocidade_jogador = jogador_atual.velocity
		
		# 3. Só gira se o jogador estiver efetivamente se movendo
		if velocidade_jogador.length() > 0.1:
			
			# Calcula a distância teórica percorrida neste frame (v = d/t -> d = v * t)
			var distancia = velocidade_jogador.length() * delta
			
			# Encontra o eixo de rotação.
			# O eixo é perpendicular à direção do movimento e ao vetor Cima (Y)
			var direcao_movimento = velocidade_jogador.normalized()
			var eixo_rotacao = Vector3.UP.cross(direcao_movimento).normalized()
			
			# Aplica a fórmula matemática para descobrir o ângulo
			var angulo_rotacao = distancia / raio_da_bola
			
			# Gira APENAS a malha visual em espaço global
			malha_visual.global_rotate(eixo_rotacao, angulo_rotacao)

func dominar(jogador: Node3D):
	print("bola dominada por", jogador.name)
	jogador_atual = jogador
	
	freeze = true 
	$CollisionShape3D.set_deferred("disabled", true)

func chutar(direcao: Vector3, forca: float):
	jogador_atual = null
	
	freeze = false
	$CollisionShape3D.set_deferred("disabled", false)
	
	apply_central_impulse(direcao * forca)
	
