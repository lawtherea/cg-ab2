extends CanvasLayer

@onready var texto_placar = $Control/scorebord_text
@onready var mensagem_gol = $Control/goal_image
@onready var aviso_iniciar = $Control/start
@onready var botao_incial = $Control/button

func _ready() -> void:
	# Garante que a imagem de GOOOOL comece escondida ao iniciar o jogo
	if mensagem_gol:
		mensagem_gol.visible = false
	
	# Garante que o letreiro de início comece visível para o jogador saber que deve apertar uma tecla
	if aviso_iniciar:
		aviso_iniciar.visible = true
		botao_incial.visible = true

func atualizar_placar(gols_A: int, gols_B: int) -> void:
	var placar_formatado = " BRA      " + str(gols_A) + " - " + str(gols_B) + "      ARG "
	
	if not texto_placar:
		var no_seguro = get_node_or_null("Control/scorebord_text")
		if no_seguro:
			no_seguro.text = placar_formatado
		return
		
	texto_placar.text = placar_formatado

# Controle de mendagem do gol 

func mostrar_aviso_gol() -> void:
	if mensagem_gol:
		mensagem_gol.visible = true

func esconder_aviso_gol() -> void:
	if mensagem_gol:
		mensagem_gol.visible = false

# Controle do Menu inicial 
func mostrar_aviso_iniciar() -> void:
	if aviso_iniciar:
		aviso_iniciar.visible = true
		botao_incial.visible = true

func esconder_aviso_iniciar() -> void:
	if aviso_iniciar:
		aviso_iniciar.visible = false
		botao_incial.visible = false
		
