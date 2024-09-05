extends Node2D

@onready var main_menu := $CanvasLayer/Control/MainMenu
@onready var address_entry := $CanvasLayer/Control/MainMenu/VBoxContainer/AdressEntry
@onready var port_entry := $CanvasLayer/Control/MainMenu/VBoxContainer/PortEntry
@onready var username_entry := $CanvasLayer/Control/MainMenu/VBoxContainer/UsernameEntry
@onready var player_color_picker := $CanvasLayer/Control/MainMenu/VBoxContainer/ColorPicker

var Bullet := preload("res://bullet.tscn")
const Player := preload("res://player.tscn")

const DEFAULT_PORT := 9999
const DEFAULT_ADDRESS := "localhost"
var enet_peer = ENetMultiplayerPeer.new()

"""
func _process(delta: float) -> void:
	for child in get_children():
		if multiplayer.get_peers().has(int(str(child.name))):
			print(child.position)
"""

func remove_player(peer_id):
	for node in get_children():
		if node.name == str(peer_id):
			node.queue_free()

func add_player(peer_id):
	var player := Player.instantiate()
	player.name = str(peer_id)
	player.plr_color = player_color_picker.color
	if username_entry.text == "":
		player.plr_username = str(peer_id)
	else:
		player.plr_username = username_entry.text
	add_child(player)

func handle_connect(peer_id):
	add_player(peer_id)

func handle_disconnect(peer_id):
	remove_player(peer_id)

@rpc("any_peer")
func add_bullet(peer_id, bullet_id, bullet_position, bullet_rotation):
	var bullet := Bullet.instantiate()
	bullet.position = bullet_position
	bullet.rotation = bullet_rotation
	bullet.name = "bullet " + str(peer_id) + " " + str(bullet_id)
	bullet.peer_id = int(peer_id)
	
	bullet.direction = Vector2(cos(bullet_rotation - PI/2), sin(bullet_rotation - PI/2)).normalized()
	add_child(bullet)

func host_server():
	var port
	if port_entry.text == "":
		port = DEFAULT_PORT
	else:
		port = port_entry.text
	
	enet_peer.create_server(port)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(handle_connect)
	multiplayer.peer_disconnected.connect(handle_disconnect)
	
	handle_connect(multiplayer.get_unique_id())

func join_server():
	var port
	var address
	if address_entry.text == "":
		address = DEFAULT_ADDRESS
	else:
		address = address_entry.text
	if port_entry.text == "":
		port = DEFAULT_PORT
	else:
		port = port_entry.text
	
	enet_peer.create_client(address, port)
	multiplayer.multiplayer_peer = enet_peer

func _on_join_button_pressed() -> void:
	join_server()
	main_menu.hide()

func _on_host_button_pressed() -> void:
	host_server()
	main_menu.hide()
