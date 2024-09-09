extends Node

signal connected_to_server

var enet_peer = ENetMultiplayerPeer.new()

var peer_id:int
var username:String

func join_server(port:int = 9999, address:String = "localhost"):
	enet_peer.create_client(address, port)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.connected_to_server.connect(connected_successfully)

@rpc("call_local", "any_peer")
func call_signal_all_hosts(sig:String):
	#if !multiplayer.is_server(): return
	
	emit_signal(sig)

func connected_successfully():
	#Server.rpc("update_player_list", Server.connected_players)
	emit_signal("connected_to_server")
