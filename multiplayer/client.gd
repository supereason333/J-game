extends Node

signal connected_to_server

var enet_peer:ENetMultiplayerPeer

var player_data := PlayerData.new()

func join_server(port:int = 9999, address:String = "localhost"):
	enet_peer = ENetMultiplayerPeer.new()
	enet_peer.create_client(address, port)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.connected_to_server.connect(connected_successfully)
	multiplayer.connection_failed.connect(connection_failed)

@rpc("call_local", "any_peer")
func call_signal_all_hosts(sig:String):
	#if !multiplayer.is_server(): return
	
	emit_signal(sig)

@rpc("any_peer")
func send_player_data():
	Server.rpc("receive_player_data", player_data.peer_id, player_data.username, player_data.color)

func connected_successfully():
	player_data.peer_id = multiplayer.get_unique_id()
	print_debug("Client " + str(player_data.peer_id) + " connected successfully")
	#Server.rpc("update_player_list", Server.connected_players)
	emit_signal("connected_to_server")
	
	if player_data.username == "":
		player_data.username = str(player_data.peer_id)

func connection_failed():
	print_debug("Connection failed")
