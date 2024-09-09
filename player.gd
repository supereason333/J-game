extends RigidBody2D

var Bullet := preload("res://bullet.tscn")

@onready var camera := $Camera2D
@onready var health_bar := $CanvasLayer/MarginContainer/VBoxContainer/HealthBar
@onready var display_health_bar := $DataControl/HealthBar
@onready var interface := $CanvasLayer
@onready var respawn_timer := $RespawnTimer
@onready var username_label := $DataControl/UsernameLabel
@onready var sprite := $Sprite
@onready var data_control := $DataControl

const SPEED := 1200.0
const TURN_SPEED := 10000.0
const MAX_HEALTH := 100.0
const DEFAULT_LINEAR_DAMP := 1.0
const DEFAULT_ANGULAR_DAMP := 0.0
const BRAKE_LINEAR_DAMP := 5.0
const BRAKE_ANGULAR_DAMP := 5.0

var health := MAX_HEALTH
var bullet_number := 0
var invulnerable := false
var in_control := true

var data := PlayerData.new()

func _enter_tree() -> void:
	#Server.connect("player_list_updated", update_data)
	#Server.connect("new_player_connected", on_player_connected)
	Client.connect("connected_to_server", on_player_connected)
	
	set_multiplayer_authority(str(name).to_int())
	if is_multiplayer_authority():
		data.username = $"..".username_entry.text
		data.color = $"..".player_color_picker.color
		data.peer_id = str(name).to_int()

func _ready() -> void:
	if not is_multiplayer_authority(): 
		interface.hide()
		return
	
	if data.username == "":
		data.username = str(name)
	
	camera.make_current()
	
	update_peer_status()
	#rpc("update_status", data.username)
	
	username_label.text = data.username
	sprite.modulate = data.color

func _process(delta: float) -> void:
	data_control.rotation = -rotation

func on_player_connected():
	pass

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority(): return
	var rotation_vector := Vector2(cos(rotation - PI / 2), sin(rotation - PI / 2)).normalized()
	
	if in_control:
		handle_control(rotation_vector)

func handle_control(rotation_vector:Vector2):
	if Input.is_action_pressed("accelerate"):
		apply_force(rotation_vector * SPEED)
	if Input.is_action_pressed("accelerate_backwards"):
		apply_force(-rotation_vector * (SPEED / 2))
	if Input.is_action_pressed("left"):
		apply_torque(-TURN_SPEED)
	if Input.is_action_pressed("right"):
		apply_torque(TURN_SPEED)
	
	if Input.is_action_just_pressed("shoot"):
		shoot_bullet(rotation_vector)
	
	if Input.is_action_pressed("brake"):
		linear_damp = BRAKE_LINEAR_DAMP
		angular_damp = BRAKE_ANGULAR_DAMP
	else:
		linear_damp = DEFAULT_LINEAR_DAMP
		angular_damp = DEFAULT_ANGULAR_DAMP

func damage(damage:float):
	if !invulnerable:
		health -= damage
		if health <= 0:
			die()
	
	rpc("update_health", health)

@rpc("call_local", "any_peer")
func update_health(n_health):			# updates the health from multiplayer authority to other ones
	health = n_health
	display_health_bar.value = health
	health_bar.value = health

func update_peer_status():
	if !is_multiplayer_authority(): return
	rpc("update_status", data.username)
	print_debug("UPDATED STATUS ON PEER " + str(data.peer_id))

@rpc()
func update_status(username:String):					# updates the username and other stuff from multiplayer auth to other ones
	#if !is_multiplayer_authority(): return
	
	username_label.text = username

@rpc("any_peer")
func send_player_data():
	if !is_multiplayer_authority(): return
	
	print_debug("PLAYER DATA SENT FROM PEER " + name)
	
	if multiplayer.is_server():
		Server.receive_player_data(data.peer_id, data.username, data.color)
	else:
		Server.rpc("receive_player_data", data.peer_id, data.username, data.color)

func update_data():		# DONT CALL THIS IT CONTAINS STUFF THAT DONT WORK
	data = Server.get_player_data_from_peer_id(str(name).to_int())
	
	print_debug("USERNAME " + data.username)
	username_label.text = data.username

func die():
	if not is_multiplayer_authority(): return
	in_control = false
	invulnerable = true
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	respawn_timer.start()
	sprite.modulate = Color(data.color.r, data.color.g, data.color.b, 0.5)

func shoot_bullet(rotation_vector:Vector2):
	var bullet := Bullet.instantiate()
	bullet.position = position
	bullet.rotation = rotation
	bullet.direction = rotation_vector
	bullet.active = false
	bullet.peer_id = int(str(name))
	
	$"..".rpc("add_bullet", str(name), bullet_number, position, rotation)
	$"..".add_child(bullet)
	bullet_number += 1

func _on_respawn_timer_timeout() -> void:
	rotation = 0
	health = MAX_HEALTH
	position = Vector2.ZERO
	sprite.modulate = data.color
	invulnerable = false
	in_control = true
	
	rpc("update_health", health)
