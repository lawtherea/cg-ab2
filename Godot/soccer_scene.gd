extends Node3D

@onready var sun: DirectionalLight3D = $DirectionalLight3D
@onready var world_environment: WorldEnvironment = $WorldEnvironment

var original_sun_visible: bool
var original_sun_energy: float
var original_sun_rotation: Vector3
var original_sun_color: Color

var original_background_mode
var original_background_color: Color
var original_background_energy: float
var original_ambient_color: Color
var original_ambient_energy: float
var original_sky_contribution: float

func _ready():
	# Salva a aparência original da cena, ou seja, o "dia bonito" que você já tinha
	original_sun_visible = sun.visible
	original_sun_energy = sun.light_energy
	original_sun_rotation = sun.rotation_degrees
	original_sun_color = sun.light_color

	if world_environment.environment:
		var env = world_environment.environment
		original_background_mode = env.background_mode
		original_background_color = env.background_color
		original_background_energy = env.background_energy_multiplier
		original_ambient_color = env.ambient_light_color
		original_ambient_energy = env.ambient_light_energy
		original_sky_contribution = env.ambient_light_sky_contribution

	if GameSettings.night_mode:
		apply_night()
	else:
		apply_day()


func apply_day():
	# Restaura exatamente o que a cena tinha antes
	sun.visible = original_sun_visible
	sun.light_energy = original_sun_energy
	sun.rotation_degrees = original_sun_rotation
	sun.light_color = original_sun_color

	if world_environment.environment:
		var env = world_environment.environment
		env.background_mode = original_background_mode
		env.background_color = original_background_color
		env.background_energy_multiplier = original_background_energy
		env.ambient_light_color = original_ambient_color
		env.ambient_light_energy = original_ambient_energy
		env.ambient_light_sky_contribution = original_sky_contribution

	# Desliga as luzes dos postes durante o dia
	set_night_lights(false)
	set_lamp_emission(false)


func apply_night():
	# Luz da lua
	sun.visible = true
	sun.light_energy = 0.18
	sun.light_color = Color(0.55, 0.65, 1.0) # azul suave
	sun.rotation_degrees = Vector3(-35, -40, 0)

	if world_environment.environment:
		var env = world_environment.environment

		# Céu noturno, mas não totalmente preto
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.015, 0.02, 0.06)
		env.background_energy_multiplier = 0.12

		# Luz ambiente azulada fraca
		env.ambient_light_color = Color(0.12, 0.16, 0.30)
		env.ambient_light_energy = 0.18
		env.ambient_light_sky_contribution = 0.2

	# Liga as luzes dos postes durante a noite
	set_night_lights(true)
	set_lamp_emission(true)


func set_night_lights(enabled: bool):
	for node in get_tree().get_nodes_in_group("night_lights"):
		if node is Light3D:
			node.visible = enabled


func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://main_menu.tscn")

func set_lamp_emission(enabled: bool):
	for node in get_tree().get_nodes_in_group("lamp_emission"):
		_apply_emission_to_node(node, enabled)


func _apply_emission_to_node(node: Node, enabled: bool):
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D

		if mesh_instance.mesh:
			for i in range(mesh_instance.mesh.get_surface_count()):
				var material := mesh_instance.get_surface_override_material(i)

				if material == null:
					material = mesh_instance.get_active_material(i)

				if material == null:
					continue

				# Duplica o material importado e coloca como override editável
				if not material.resource_local_to_scene:
					var duplicated_material := material.duplicate(true)

					if duplicated_material is Material:
						material = duplicated_material as Material
						material.resource_local_to_scene = true
						mesh_instance.set_surface_override_material(i, material)

				# Funciona para StandardMaterial3D e ORMMaterial3D
				if material is BaseMaterial3D:
					var mat := material as BaseMaterial3D

					if enabled:
						mat.emission_enabled = true
						mat.emission = Color(1.0, 0.966, 0.847, 1.0)
						mat.emission_energy_multiplier = 2.0
					else:
						mat.emission_energy_multiplier = 0.0
						mat.emission_enabled = false

	for child in node.get_children():
		_apply_emission_to_node(child, enabled)

	for child in node.get_children():
		_apply_emission_to_node(child, enabled)
