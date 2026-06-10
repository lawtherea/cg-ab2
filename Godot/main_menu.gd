extends Control

@export_file("*.tscn") var game_scene_path := "res://soccer_scene.tscn"

func _on_play_button_pressed():
	get_tree().change_scene_to_file(game_scene_path)

func _on_quit_button_pressed():
	get_tree().quit()
