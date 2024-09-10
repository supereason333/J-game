extends PanelContainer

var Player_entry := preload("res://menu/player_data.tscn")

@onready var list := $MarginContainer/VBoxContainer/ScrollContainer/List
@onready var ready_button := $MarginContainer/VBoxContainer/HBoxContainer/ReadyButton
@onready var ready_label := $MarginContainer/VBoxContainer/HBoxContainer/Label

func _enter_tree() -> void:
	Server.player_list_changed.connect(set_list)
	multiplayer.peer_connected.connect(player_joined)

func _ready() -> void:
	set_list()

func set_list():
	for child in list.get_children():
		child.queue_free()
	for player in Server.player_list:
		add_player(player)
	
	ready_label.text = str(len(Server.get_ready_players())) + "/" + str(len(Server.ready_list))

func add_player(player:PlayerData):
	var player_entry := Player_entry.instantiate()
	list.add_child(player_entry)
	
	player_entry.username_label.text = player.username
	player_entry.color_rect.color = player.color
	player_entry.peer_id_label.text = str(player.peer_id)
	if Server.get_player_ready_status(player.peer_id):
		player_entry.ready_label.text = "Ready"
		player_entry.ready_label.modulate = Color(0, 1, 0)
	else:
		player_entry.ready_label.text = "Not ready"
		player_entry.ready_label.modulate = Color(1, 0, 0)
	
	player_entry.name = str(player.peer_id)

func remove_player(peer_id:int):
	pass

func player_joined(peer_id:int):
	Server.rpc("set_player_ready_status", Client.player_data.peer_id, Client.game_ready)

func _on_button_pressed() -> void:
	Client.game_ready = !Client.game_ready
	Server.rpc("set_player_ready_status", Client.player_data.peer_id, Client.game_ready)
	
	if Client.game_ready:
		ready_button.text = "Unready"
	else:
		ready_button.text = "Ready!"
