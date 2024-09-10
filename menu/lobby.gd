extends Control

func _enter_tree() -> void:
	Server.started_game.connect(start_game)

func start_game():
	get_tree().change_scene_to_file("res://game/game.tscn")
