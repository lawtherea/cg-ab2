extends Node3D

@export var fbx_models: Array[PackedScene] # Arraste os 2 FBXs aqui no Inspector

@onready var visual_pivot = $VisualPivot
@onready var anim_player: AnimationPlayer

func _ready():
	# 1. Escolhe e instancia um modelo aleatório
	if fbx_models.size() > 0:
		var chosen_model = fbx_models.pick_random().instantiate()
		visual_pivot.add_child(chosen_model)
		
		# Procura o AnimationPlayer que veio junto com o FBX
		anim_player = chosen_model.get_node_or_null("AnimationPlayer")
	
	# 2. Inicia as animações independentes
	play_random_animation()

func play_random_animation():
	if anim_player and anim_player.get_animation_list().size() > 0:
		var animations = anim_player.get_animation_list()
		var chosen_anim = animations[randi() % animations.size()]
		
		# Evita sincronia perfeita atrasando o início randomicamente
		await get_tree().create_timer(randf_range(0.0, 0.5)).timeout
		
		# Toca a animação com velocidade levemente alterada para naturalidade
		anim_player.play(chosen_anim)
		anim_player.speed_scale = randf_range(0.9, 1.1)
		
		# Quando a animação terminar, escolhe outra
		if not anim_player.animation_finished.is_connected(_on_animation_finished):
			anim_player.animation_finished.connect(_on_animation_finished)

func _on_animation_finished(_anim_name):
	play_random_animation()
