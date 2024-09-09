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

"""
func _process(delta: float) -> void:
	for child in get_children():
		if multiplayer.get_peers().has(int(str(child.name))):
			print(child.position)
"""

@rpc("any_peer")
func add_bullet(peer_id, bullet_id, bullet_position, bullet_rotation):
	var bullet := Bullet.instantiate()
	bullet.position = bullet_position
	bullet.rotation = bullet_rotation
	bullet.name = "bullet " + str(peer_id) + " " + str(bullet_id)
	bullet.peer_id = int(peer_id)
	
	bullet.direction = Vector2(cos(bullet_rotation - PI/2), sin(bullet_rotation - PI/2)).normalized()
	add_child(bullet)



func remove_player(peer_id):
	for node in get_children():
		if node.name == str(peer_id):
			node.queue_free()

func add_player(peer_id):
	var player := Player.instantiate()
	var data := PlayerData.new()
	data.peer_id = int(peer_id)
	
	player.name = str(peer_id)
	player.data = data
	
	add_child(player)

func handle_connect(peer_id):
	var pdata := PlayerData.new()
	
	add_player(peer_id)
	var peer = get_player_node(peer_id) as Node
	
	if !peer.is_multiplayer_authority(): 
		peer.rpc("send_player_data")
	else: 
		peer.send_player_data()
	#Server.add_player_list(get_player_node(peer_id).rpc("get_player_data"))

func get_player_node(peer_id:int):
	for node in get_children():
		if str(node.name) == str(peer_id):
			return node
	
	return

func handle_disconnect(peer_id):
	remove_player(peer_id)

func _on_join_button_pressed() -> void:
	Client.join_server()
	main_menu.hide()

func _on_host_button_pressed() -> void:
	Server.host_server()
	multiplayer.peer_connected.connect(handle_connect)
	multiplayer.peer_disconnected.connect(handle_disconnect)
	
	handle_connect(multiplayer.get_unique_id())
	main_menu.hide()
