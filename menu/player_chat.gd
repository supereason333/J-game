extends VBoxContainer

const MAX_MSGS := 100

var Message := preload("res://menu/chat_message.tscn")

var msgs := 0

@onready var message_content := $MarginContainer/HBoxContainer/Message
@onready var message_box := $ScrollContainer/VBoxContainer
@onready var scroll_box := $ScrollContainer

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("chat"):
		message_content.grab_focus()

func rpc_send_message(msg:String, peer_id:int):
	msg = msg.strip_edges(true, true)
	msg = msg.strip_escapes()
	if msg == "":
		return
	
	rpc("send_message", msg, peer_id)

@rpc("any_peer", "call_local")
func send_message(msg:String, peer_id:int):
	msgs += 1
	if len(msg) >= 500:
		msg = str(msg.hash()) + " (Message shortened to hash because you're a YAPPER)"
	
	var chat_message := Message.instantiate()
	chat_message.text = "[" + Server.get_player_data_from_peer_id(peer_id).username + "]: " + msg
	#chat_message.custom_minimum_size.x = scroll_box.size.x
	
	message_box.add_child(chat_message)
	
	if msgs > MAX_MSGS:
		message_box.get_child(0).queue_free()
		msgs -= 1
	
	message_content.clear()

func _on_send_pressed() -> void:
	rpc_send_message(message_content.text, multiplayer.get_unique_id())

func _on_message_text_submitted(new_text: String) -> void:
	rpc_send_message(new_text, multiplayer.get_unique_id())
