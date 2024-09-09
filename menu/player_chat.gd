extends VBoxContainer

var Message := preload("res://menu/chat_message.tscn")

@onready var message_content := $MarginContainer/HBoxContainer/Message
@onready var message_box := $ScrollContainer/VBoxContainer

func rpc_send_message(msg:String, peer_id:int):
	rpc("send_message", msg, peer_id)

@rpc("any_peer", "call_local")
func send_message(msg:String, peer_id:int):
	var chat_message := Message.instantiate()
	chat_message.text = "[" + str(peer_id) + "]: " + msg
	chat_message.custom_minimum_size.x = size.x
	
	message_box.add_child(chat_message)
	
	message_content.text = ""

func _on_send_pressed() -> void:
	rpc_send_message(message_content.text, multiplayer.get_unique_id())

func _on_message_text_submitted(new_text: String) -> void:
	rpc_send_message(new_text, multiplayer.get_unique_id())
