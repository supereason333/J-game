extends Node

signal player_list_updated
signal new_player_connected

var player_list:Array[PlayerData]

var enet_peer = ENetMultiplayerPeer.new()

func host_server(port:int = 9999):
	enet_peer.create_server(port)
	multiplayer.multiplayer_peer = enet_peer
	
	multiplayer.peer_connected.connect(handle_connect)

@rpc("call_local", "any_peer")
func call_signal_all_hosts(sig:String):
	#if !multiplayer.is_server(): return
	print_debug("CALL SIGNAL ALL HOSTS")
	emit_signal(sig)

@rpc("call_local", "any_peer")
func call_func_group_all_hosts(group:String, function:String):
	get_tree().call_group(group, function)

func player_list_changed():
	if !multiplayer.is_server(): return
	
	#sync_player_list()
	#rpc("call_signal_all_hosts", "player_list_updated")
	
	if multiplayer.is_server(): print_users()

func sync_player_list():
	var username_list:Array[String]
	var peer_id_list:Array[int]
	var color_list:Array[Color]
	
	for i in player_list:
		username_list.append(i.username)
		peer_id_list.append(i.peer_id)
		color_list.append(i.color)
	
	rpc("sync_player_list_length", len(player_list))
	rpc("sync_username_list", username_list)
	rpc("sync_peer_id_list", peer_id_list)
	rpc("sync_color_list", color_list)

@rpc()
func sync_player_list_length(len:int):
	player_list = []
	player_list.resize(len)
	player_list.fill(PlayerData.new())

@rpc()
func sync_username_list(list:Array):
	for i in len(list):
		player_list[i].username = list[i]

@rpc()
func sync_peer_id_list(list:Array):
	for i in len(list):
		player_list[i].peer_id = list[i]

@rpc()
func sync_color_list(list:Array):
	for i in len(list):
		player_list[i].color = list[i]

func handle_connect(peer_id):
	print_debug(str(peer_id) +  " CONNECTED")
	#rpc("call_signal_all_hosts", "new_player_connected")
	emit_signal("new_player_connected")
	rpc("call_func_group_all_hosts", "player", "update_peer_status")
	print_users()

func add_player_list(data:PlayerData):
	if !multiplayer.is_server(): return
	
	var index = get_player_list_player_index(data.peer_id)
	if index == -1:
		player_list.append(data)
	else:
		player_list[index] = data
	
	player_list_changed()

func remove_from_player_list(peer_id:int):
	if !multiplayer.is_server(): return
	
	var index = get_player_list_player_index(peer_id)
	if index == -1:
		return
	
	player_list.remove_at(index)

func print_users():
	print("Users:")
	for user in player_list:
		print(user.username + " - " + str(user.peer_id))

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

@rpc("any_peer")
func receive_player_data(peer_id:int, username:String, color:Color):
	var data = PlayerData.new()
	data.peer_id = peer_id
	data.username = username
	data.color = color
	
	add_player_list(data)
