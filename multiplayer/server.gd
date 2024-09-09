extends Node

signal new_player_connected
signal player_list_changed

var player_list:Array[PlayerData]

var enet_peer:ENetMultiplayerPeer

func host_server(port:int = 9999):
	enet_peer = ENetMultiplayerPeer.new()
	var error = enet_peer.create_server(port)
	if error != OK:
		printerr("Cannot host: " + str(error))
		return
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(handle_connect)
	
	print("Server hosted on port " + str(port))
	
	Client.player_data.peer_id = multiplayer.get_unique_id()
	if Client.player_data.username == "":
		Client.player_data.username = str(Client.player_data.peer_id)
	add_player_list(Client.player_data)

func handle_connect(peer_id):
	print_debug(str(peer_id) +  " CONNECTED TO SERVER")
	emit_signal("new_player_connected")
	Client.rpc("send_player_data")
	#rpc("call_func_group_all_hosts", "player", "update_peer_status")

func add_player_list(data:PlayerData):
	if !multiplayer.is_server(): return
	
	var index = get_player_list_player_index(data.peer_id)
	if index == -1:
		player_list.append(data)
	else:
		if player_list[index].username == data.username:
			return
		player_list[index] = data
	
	print_users()
	split_and_sync_player_list()

func remove_from_player_list(peer_id:int):
	if !multiplayer.is_server(): return
	
	var index = get_player_list_player_index(peer_id)
	if index == -1:
		return
	
	player_list.remove_at(index)
	
	print_users()
	split_and_sync_player_list()

func print_users():
	print("Users:")
	for user in player_list:
		print(user.username + " - " + str(user.peer_id))

func split_and_sync_player_list():
	if !multiplayer.is_server(): return
	emit_signal("player_list_changed")
	
	var peer_id_list:Array[int]
	var username_list:Array[String]
	var color_list:Array[Color]
	
	for player in player_list:
		peer_id_list.append(player.peer_id)
		username_list.append(player.username)
		color_list.append(player.color)
	
	rpc("sync_player_list", peer_id_list, username_list, color_list)

@rpc("reliable")
func sync_player_list(peer_id:Array, username:Array, color:Array):
	player_list = []
	
	for i in len(peer_id):
		var data := PlayerData.new()
		data.peer_id = peer_id[i]
		data.username = username[i]
		data.color = color[i]
		
		player_list.append(data)
	
	emit_signal("player_list_changed")

func get_player_list_player_index(peer_id:int) -> int:
	for i in len(player_list):
		if player_list[i].peer_id == peer_id:
			return i
	
	return -1

func get_player_data_from_peer_id(peer_id:int):
	var index = get_player_list_player_index(peer_id)
	if index == -1:
		return
	
	return player_list[index]

@rpc("any_peer", "reliable")
func receive_player_data(peer_id:int, username:String, color:Color):
	if !multiplayer.is_server(): return
	var data = PlayerData.new()
	data.peer_id = peer_id
	data.username = username
	data.color = color
	
	add_player_list(data)

@rpc("call_local", "any_peer")
func call_signal_all_hosts(sig:String):
	#if !multiplayer.is_server(): return
	print_debug("CALL SIGNAL ALL HOSTS")
	emit_signal(sig)

@rpc("call_local", "any_peer")
func call_func_group_all_hosts(group:String, function:String):
	get_tree().call_group(group, function)
