extends Node2D

var Bullet := preload("res://bullet.tscn")
var Player := preload("res://player.tscn")

func _enter_tree() -> void:
	multiplayer.peer_disconnected.connect(handle_disconnect)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if !multiplayer.is_server(): return
	for player in Server.player_list:
		add_player(player)

func handle_disconnect(peer_id:int):
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



func remove_player(peer_id:int):
	for node in get_children():
		if node.name == str(peer_id):
			node.queue_free()

func add_player(player_data:PlayerData):
	var player := Player.instantiate()
	player.position = Vector2(100, 100)
	player.name = str(player_data.peer_id)
	add_child(player)


func get_player_node(peer_id:int):
	for node in get_children():
		if str(node.name) == str(peer_id):
			return node
	
	return
