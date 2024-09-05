extends RigidBody2D

var Bullet := preload("res://bullet.tscn")

@onready var camera := $Camera2D
@onready var health_bar := $CanvasLayer/MarginContainer/VBoxContainer/HealthBar
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
var player_name:String
var invulnerable := false
var in_control := true

var plr_color:Color
var plr_username:String

func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())

func _ready() -> void:
	if not is_multiplayer_authority(): 
		interface.hide()
		if plr_username == "":
			plr_username = str(name)
			username_label.text = plr_username
		return
	else:
		if plr_username == "":
			plr_username = str(multiplayer.get_unique_id())
	username_label.text = plr_username
	
	camera.make_current()
	sprite.modulate = plr_color

func _process(delta: float) -> void:
	data_control.rotation = -rotation

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority(): return
	var rotation_vector := Vector2(cos(rotation - PI / 2), sin(rotation - PI / 2)).normalized()
	
	if in_control:
		handle_control(rotation_vector)

func handle_control(rotation_vector:Vector2):
	if Input.is_action_pressed("accelerate"):
		apply_force(rotation_vector * SPEED)
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
	if !invulnerable: health -= damage
	
	if health <= 0:
		die()
	
	health_bar.value = health

func die():
	in_control = false
	invulnerable = true
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	respawn_timer.start()
	health = MAX_HEALTH
	sprite.modulate = Color(plr_color.r, plr_color.g, plr_color.b, 0.5)

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
	position = Vector2.ZERO
	sprite.modulate = plr_color
	invulnerable = false
	in_control = true
