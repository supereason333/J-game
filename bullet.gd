extends Area2D

const SPEED := 20.0
const DAMAGE := 10.0
var direction := Vector2(1, 0)
var peer_id:int
var active := true

func _enter_tree() -> void:
	set_multiplayer_authority(peer_id)

func _process(delta: float) -> void:
	if direction:
		position += direction * SPEED

func _on_timer_timeout() -> void:
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if str(body.name) != str(peer_id) and body.has_method("damage"):
		#if is_multiplayer_authority():
		#	print("is multiplayer authority")
		#	queue_free()
		#	return
		if !active: 
			queue_free()
			return
		
		body.damage(DAMAGE)
		queue_free()
