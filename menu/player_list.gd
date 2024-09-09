extends PanelContainer

var Player_entry := preload("res://menu/player_data.tscn")

@onready var list := $ScrollContainer/List

func _enter_tree() -> void:
	multiplayer.connect("peer_connected", add_player)

func add_player(peer_id:int):
	if !multiplayer.is_server(): return
	return
	var player_entry = Player_entry.instantiate()
	player_entry.get_child(1).text = str(peer_id)
	
	list.add_child(player_entry)

func remove_player(peer_id:int):
	pass
