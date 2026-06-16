
extends Control

# Buscas automáticas dos nós filhos. 
# Como este script está no nó pai ("Control_Espelho"), o caminho é direto pelo nome do filho.
@onready var texto_placar: Label = $scorebord_text

# Caso você tenha colocado os nós de imagem dos escudos (opcional)
@onready var escudo_brasil: TextureRect = get_node_or_null("brasil_flag2")
@onready var escudo_argentina: TextureRect = get_node_or_null("argentina_flag2")

func _ready() -> void:
	# Configuração inicial de segurança para garantir que o texto não comece vazio
	# e que use o tamanho total do SubViewport
	custom_minimum_size = Vector2(1024, 512) # Ajuste esses números se o seu SubViewport tiver outro tamanho
	
	if texto_placar:
		texto_placar.text = " BRA 0 - 0 ARG "
	else:
		# Se por um erro de milissegundo o @onready falhar, tentamos uma busca manual de segurança
		var no_seguro = get_node_or_null("TextoPlacar")
		if no_seguro:
			no_seguro.text = " BRA 0 - 0 ARG "

# Função principal que será chamada pelo seu PartidaManager
func atualizar_placar(gols_A: int, gols_B: int) -> void:
	var texto_formatado = " BRA " + str(gols_A) + " - " + str(gols_B) + " ARG "
	
	# Atualiza o texto de forma blindada
	if texto_placar:
		texto_placar.text = texto_formatado
	else:
		var no_seguro = get_node_or_null("TextoPlacar")
		if no_seguro:
			no_seguro.text = texto_formatado
			
	# Print de debug no console para você ter certeza de que o telão 3D recebeu a ordem
	print("[Telão 3D] Placar atualizado na memória: ", texto_formatado)
