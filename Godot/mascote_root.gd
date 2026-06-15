extends Node3D

@export var tempo_entre_animacoes: float = 4.0
@export var tempo_blend: float = 0.5

@onready var anim_player: AnimationPlayer = $animacoes_mascote/AnimationPlayer

var animacoes := [
	"rumba",
	"dance_001",
	"capoeira"
]

var indice_animacao := 0

func _ready():
	tocar_animacao_atual()
	iniciar_loop_animacoes()

func iniciar_loop_animacoes():
	while true:
		await get_tree().create_timer(tempo_entre_animacoes).timeout

		indice_animacao += 1

		if indice_animacao >= animacoes.size():
			indice_animacao = 0

		tocar_animacao_atual()

func tocar_animacao_atual():
	var nome_animacao = animacoes[indice_animacao]

	if anim_player.has_animation(nome_animacao):
		anim_player.play(nome_animacao, tempo_blend)
	else:
		print("Animação não encontrada: ", nome_animacao)
