extends GraphNode

const AssemblerScript := preload("res://assembler.gd")

signal delete_pressed(node: GraphNode)
signal text_updated

var _token: String = ""
var _chat_id: String = ""
var _message: String = ""
var _result_text: String = ""
var enabled: bool = true
var enable_port: int = -1
var trigger_port: int = -1

var _http: HTTPRequest

@onready var token_edit: LineEdit = $TokenEdit
@onready var chat_edit: LineEdit = $ChatEdit
@onready var status_label: Label = $StatusLabel


func _ready() -> void:
	if enable_port >= 0:
		return
	title = "Telegram Send"
	AssemblerScript.configure_slots(self, "tg_send")
	_add_control_ports()

	_http = HTTPRequest.new()
	_http.name = "HTTPRequest"
	add_child(_http)
	_http.request_completed.connect(_on_send_completed)


func _add_control_ports() -> void:
	var insert_at := get_child_count()
	for i in range(get_child_count()):
		if get_child(i).name == "DeleteButton":
			insert_at = i
			break
	var enable_lbl := Label.new()
	enable_lbl.text = "Enable"
	add_child(enable_lbl)
	move_child(enable_lbl, insert_at)
	enable_port = insert_at
	set_slot(enable_port, true, 0, Color.YELLOW, false, 0, Color.WHITE)
	var trigger_lbl := Label.new()
	trigger_lbl.text = "Trigger"
	add_child(trigger_lbl)
	move_child(trigger_lbl, insert_at + 1)
	trigger_port = insert_at + 1
	set_slot(trigger_port, true, 0, Color.RED, false, 0, Color.WHITE)


func get_port_output(port: int) -> String:
	if port == 3:
		return _result_text
	return ""


func set_input(port: int, text: String) -> void:
	if port == enable_port:
		enabled = text.strip_edges() != "" and text.strip_edges().to_lower() != "false"
		return
	if port == trigger_port:
		if enabled:
			_send_message()
		return
	if not enabled:
		return
	match port:
		0:
			_token = text.strip_edges()
			if token_edit != null:
				token_edit.text = _token
		1:
			_chat_id = text.strip_edges()
			if chat_edit != null:
				chat_edit.text = _chat_id
		2:
			_message = text
			_send_message()


func _send_message() -> void:
	_read_fields()
	if _token == "":
		status_label.text = "No token"
		return
	if _chat_id == "":
		status_label.text = "No chat ID"
		return
	if _message == "":
		status_label.text = "No message"
		return

	var url := "https://api.telegram.org/bot%s/sendMessage" % _token
	var body := JSON.stringify({"chat_id": _chat_id, "text": _message})
	var headers: PackedStringArray = ["Content-Type: application/json"]
	status_label.text = "Sending..."
	_http.request(url, headers, HTTPClient.METHOD_POST, body)


func _on_send_completed(_result: int, _code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var text := body.get_string_from_utf8()
	if _result != HTTPRequest.RESULT_SUCCESS:
		_result_text = "HTTP error: %d" % _code
		status_label.text = "Error: %d" % _code
	else:
		_result_text = "OK"
		status_label.text = "Sent"
	text_updated.emit()


func _on_send() -> void:
	if not enabled:
		return
	_send_message()


func _read_fields() -> void:
	if token_edit != null:
		_token = token_edit.text.strip_edges()
	if chat_edit != null:
		_chat_id = chat_edit.text.strip_edges()


func _on_delete_pressed() -> void:
	delete_pressed.emit(self)


func get_node_type() -> String:
	return "tg_send"


func serialize_data() -> Dictionary:
	return {"token": _token, "chat_id": _chat_id}


func deserialize_data(d: Dictionary) -> void:
	if d.has("token"):
		_token = d.token
		if token_edit != null:
			token_edit.text = _token
	if d.has("chat_id"):
		_chat_id = d.chat_id
		if chat_edit != null:
			chat_edit.text = _chat_id


func get_gal_props(nd: Dictionary) -> Dictionary:
	var props: Dictionary = {}
	if nd.has("token") and nd.token != "":
		props["token"] = nd.token
	if nd.has("chat_id") and nd.chat_id != "":
		props["chat_id"] = nd.chat_id
	return props
