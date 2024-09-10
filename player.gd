extends RigidBody2D

var Bullet := preload("res://bullet.tscn")

@onready var camera := $Camera2D
@onready var health_bar := $CanvasLayer/MarginContainer/Control/VBoxContainer/HealthBar
@onready var display_health_bar := $DataControl/HealthBar
@onready var interface := $CanvasLayer
@onready var player_menu := $CanvasLayer/PlayerMenu
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
var dead := false

var data := PlayerData.new()

func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())

func _ready() -> void:
	data = Server.get_player_data_from_peer_id(str(name).to_int())
	username_label.text = data.username
	sprite.modulate = data.color
	
	if not is_multiplayer_authority(): 
		interface.hide()
		return
	camera.make_current()

func _process(delta: float) -> void:
	data_control.rotation = -rotation
	
	if !is_multiplayer_authority(): return
	
	if Input.is_action_just_pressed("ui_cancel"):
		if player_menu.visible:
			player_menu.hide()
			in_control = true
		else:
			player_menu.show()
			in_control = false

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority(): return
	var rotation_vector := Vector2(cos(rotation - PI / 2), sin(rotation - PI / 2)).normalized()
	
	if in_control and !dead:
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
	
	if Input.is_action_just_pressed("brake"):
		linear_damp = BRAKE_LINEAR_DAMP
		angular_damp = BRAKE_ANGULAR_DAMP
	if Input.is_action_just_released("brake"):
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

func die():
	if not is_multiplayer_authority(): return
	set_collision_layer_value(2, false)
	dead = true
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
	set_collision_layer_value(2, true)
	rotation = 0
	health = MAX_HEALTH
	position = Vector2(100, 100)
	sprite.modulate = data.color
	invulnerable = false
	dead = false
	
	rpc("update_health", health)
