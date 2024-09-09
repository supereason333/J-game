extends PanelContainer

var Player_entry := preload("res://menu/player_data.tscn")

@onready var list := $ScrollContainer/List

func _enter_tree() -> void:
	Server.player_list_changed.connect(set_list)

func _ready() -> void:
	set_list()

func set_list():
	for child in list.get_children():
		child.queue_free()
	for player in Server.player_list:
		add_player(player)

func add_player(player:PlayerData):
	var player_entry := Player_entry.instantiate()
	list.add_child(player_entry)
	
	player_entry.username_label.text = player.username
	player_entry.color_rect.color = player.color
	player_entry.peer_id_label.text = str(player.peer_id)
	player_entry.name = str(player.peer_id)

func remove_player(peer_id:int):
	pass
