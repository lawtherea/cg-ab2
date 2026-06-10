extends Control

@export_file("*.tscn") var game_scene_path := "res://soccer_scene.tscn"

@onready var night_toggle: CheckButton = $CheckButton


func _ready():
	# Faz o botão refletir o estado atual salvo no GameSettings
	night_toggle.set_pressed_no_signal(GameSettings.night_mode)


func _on_check_button_toggled(toggled_on: bool):
	GameSettings.night_mode = toggled_on


func _on_play_button_pressed():
	get_tree().change_scene_to_file(game_scene_path)


func _on_quit_button_pressed():
	get_tree().quit()
