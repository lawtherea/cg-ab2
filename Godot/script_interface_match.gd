extends CanvasLayer

@onready var texto_placar = $Control/scorebord_text
@onready var mensagem_gol = $Control/goal_message

func _ready() -> void:
	# Mensagem comeca escondida via código
	if mensagem_gol:
		mensagem_gol.visible = false

func atualizar_placar(gols_A: int, gols_B: int) -> void:
	if not texto_placar:
		var no_seguro = get_node_or_null("Control/TextoPlacar")
		if no_seguro:
			no_seguro.text = " BRA      " + str(gols_A) + " - " + str(gols_B) + "      ARG "
		return
		
	texto_placar.text = " BRA      " + str(gols_A) + " - " + str(gols_B) + "      ARG "

func mostrar_aviso_gol() -> void:
	if mensagem_gol:
		mensagem_gol.visible = true

func esconder_aviso_gol() -> void:
	if mensagem_gol:
		mensagem_gol.visible = false
