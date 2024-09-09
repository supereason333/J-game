extends Control

@onready var address_entry := $PanelContainer/MarginContainer/VBoxContainer/AddressEntry
@onready var port_entry := $PanelContainer/MarginContainer/VBoxContainer/PortEntry
@onready var username_entry := $PanelContainer/MarginContainer/VBoxContainer/UsernameEntry
@onready var color_entry := $PanelContainer/MarginContainer/VBoxContainer/ColorEntry

func _on_host_pressed() -> void:
	set_client_data()
	Server.host_server(int(port_entry.text))
	get_tree().change_scene_to_file("res://menu/lobby.tscn")

func _on_join_pressed() -> void:
	set_client_data()
	Client.join_server(int(port_entry.text), address_entry.text)
	get_tree().change_scene_to_file("res://menu/lobby.tscn")

func set_client_data():
	username_entry.text = username_entry.text.strip_edges(true, true)
	username_entry.text = username_entry.text.strip_escapes()
	
	Client.player_data.username = username_entry.text
	Client.player_data.color = color_entry.color
