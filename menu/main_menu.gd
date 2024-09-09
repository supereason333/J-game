extends Control



func _on_host_pressed() -> void:
	Server.host_server()
	get_tree().change_scene_to_file("res://menu/lobby.tscn")

func _on_join_pressed() -> void:
	Client.join_server()
	get_tree().change_scene_to_file("res://menu/lobby.tscn")
