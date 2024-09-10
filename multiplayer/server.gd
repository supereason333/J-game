extends Node

signal new_player_connected
signal player_list_changed
signal started_game
signal ended_game

var player_list:Array[PlayerData]
var ready_list:Array[Array]		# [[peer_id, status], [peer_id, status]]

var enet_peer:ENetMultiplayerPeer

func host_server(port:int = 9999):
	enet_peer = ENetMultiplayerPeer.new()
	var error = enet_peer.create_server(port)
	if error != OK:
		printerr("Cannot host: " + str(error))
		return
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(handle_connect)
	multiplayer.peer_disconnected.connect(handle_disconnect)
	
	print("Server hosted on port " + str(port))
	
	Client.player_data.peer_id = multiplayer.get_unique_id()
	if Client.player_data.username == "":
		Client.player_data.username = str(Client.player_data.peer_id)
	add_player_list(Client.player_data)

func handle_connect(peer_id):
	print(str(peer_id) +  " Connected to server")
	emit_signal("new_player_connected")
	Client.rpc("send_player_data")
	#rpc("call_func_group_all_hosts", "player", "update_peer_status")

func handle_disconnect(peer_id:int):
	remove_from_player_list(peer_id)
	remove_player_ready_list(peer_id)



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

@rpc("any_peer", "call_local")
func set_player_ready_status(peer_id:int, status:bool):
	for i in ready_list:
		if i[0] == peer_id:
			i[1] = status
			emit_signal("player_list_changed")
			return
	
	ready_list.append([peer_id, status])
	emit_signal("player_list_changed")

@rpc("call_local")
func remove_player_ready_list(peer_id:int):
	for i in len(ready_list):
		if ready_list[i][0] == peer_id:
			ready_list.remove_at(i)
	
	emit_signal("player_list_changed")

func get_player_list_player_index(peer_id:int) -> int:
	for i in len(player_list):
		if player_list[i].peer_id == peer_id:
			return i
	
	return -1

func get_ready_players() -> Array[int]:
	var list:Array[int]
	for i in ready_list:
		if i[1] == true:
			list.append(i[0])
	
	return list

func get_unready_players() -> Array[int]:
	var list:Array[int]
	for i in ready_list:
		if i[1] == false:
			list.append(i[0])
	
	return list

func get_player_ready_status(peer_id:int) -> bool:
	for i in ready_list:
		if i[0] == peer_id:
			return i[1]
	
	return false

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

@rpc("call_local", "any_peer", "reliable")
func call_signal_all_hosts(sig:String):
	#if !multiplayer.is_server(): return\
	emit_signal(sig)

@rpc("call_local", "any_peer", "reliable")
func call_func_group_all_hosts(group:String, function:String):
	get_tree().call_group(group, function)
