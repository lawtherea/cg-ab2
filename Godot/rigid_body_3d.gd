extends RigidBody3D
class_name Bola

var jogador_atual: Node3D = null

@onready var malha_visual = $PivotVisual
@export var raio_da_bola: float = 0.11 

func _ready() -> void:
	print("Camada da Bola é 2? ", self.get_collision_layer_value(2))
	print("Mascara da Bola é 2? ", self.get_collision_mask_value(2))

func _physics_process(delta):
	if jogador_atual != null:
		global_position = jogador_atual.get_node("DribblePoint").global_position
		
		var velocidade_jogador = jogador_atual.velocity
		
		if velocidade_jogador.length() > 0.1:
			var distancia = velocidade_jogador.length() * delta
			var direcao_movimento = velocidade_jogador.normalized()
			var eixo_rotacao = Vector3.UP.cross(direcao_movimento)
			
			if eixo_rotacao.length() > 0.001:
				eixo_rotacao = eixo_rotacao.normalized()
				var angulo_rotacao = distancia / raio_da_bola
				malha_visual.global_rotate(eixo_rotacao, angulo_rotacao)

func dominar(jogador: Node3D):
	print("bola dominada por", jogador.name)
	jogador_atual = jogador
	freeze = true 
	$CollisionShape3D.set_deferred("disabled", true)

func chutar(direcao: Vector3, forca: float):
	print("fui chutada")
	jogador_atual = null
	freeze = false
	$CollisionShape3D.set_deferred("disabled", false)
	apply_central_impulse(direcao * forca)
