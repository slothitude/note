extends GraphNode

const AssemblerScript := preload("res://assembler.gd")

signal delete_pressed(node: GraphNode)
signal text_updated

var _token: String = ""
var _last_update_id: int = 0
var _polling: bool = false
var _msg_count: int = 0
var _message_text: String = ""
var _chat_id: String = ""
var _from_user: String = ""
var enabled: bool = true
var enable_port: int = -1
var trigger_port: int = -1

var _poll_timer: Timer
var _http: HTTPRequest

@onready var token_edit: LineEdit = $TokenEdit
@onready var interval_spin: SpinBox = $IntervalSpin
@onready var status_label: Label = $StatusLabel


func _ready() -> void:
	if enable_port >= 0:
		return
	title = "Telegram Receive"
	AssemblerScript.configure_slots(self, "tg_receive")
	_add_control_ports()

	_http = HTTPRequest.new()
	_http.name = "HTTPRequest"
	add_child(_http)
	_http.request_completed.connect(_on_poll_completed)

	_poll_timer = Timer.new()
	_poll_timer.name = "PollTimer"
	add_child(_poll_timer)
	_poll_timer.timeout.connect(_on_poll_tick)


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
	match port:
		1: return _message_text
		2: return _chat_id
		3: return _from_user
	return ""


func set_input(port: int, text: String) -> void:
	if port == enable_port:
		enabled = text.strip_edges() != "" and text.strip_edges().to_lower() != "false"
		if not enabled and _polling:
			_stop_polling()
		return
	if port == trigger_port:
		if enabled:
			_poll_once()
		return
	if not enabled:
		return
	if port == 0:
		_token = text.strip_edges()
		if token_edit != null:
			token_edit.text = _token


func _on_toggle_polling() -> void:
	if _polling:
		_stop_polling()
	else:
		_start_polling()


func _start_polling() -> void:
	_read_fields()
	if _token == "":
		status_label.text = "No token"
		return
	_polling = true
	_msg_count = 0
	var interval := 3.0
	if interval_spin != null:
		interval = interval_spin.value
	_poll_timer.wait_time = maxf(interval, 1.0)
	_poll_timer.start()
	status_label.text = "Polling..."
	_poll_once()


func _stop_polling() -> void:
	_polling = false
	if _poll_timer:
		_poll_timer.stop()
	status_label.text = "Stopped"


func _poll_once() -> void:
	_read_fields()
	if _token == "":
		return
	var url := "https://api.telegram.org/bot%s/getUpdates?offset=%d&timeout=10" % [_token, _last_update_id + 1]
	_http.request(url, [], HTTPClient.METHOD_GET)


func _on_poll_tick() -> void:
	if _polling and enabled:
		_poll_once()


func _on_poll_completed(_result: int, _code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if not enabled:
		return
	var text := body.get_string_from_utf8()
	if text == "":
		return
	var json := JSON.new()
	if json.parse(text) != OK:
		return
	var data: Dictionary = json.data
	if not data.has("result"):
		return
	var results: Array = data.result
	if results.is_empty():
		return

	for update in results:
		var update_id: int = int(update.get("update_id", 0))
		if update_id >= _last_update_id:
			_last_update_id = update_id
		if not update.has("message"):
			continue
		var msg: Dictionary = update.message
		if not msg.has("text"):
			continue
		_message_text = str(msg.text)
		_chat_id = str(msg.get("chat", {}).get("id", ""))
		_from_user = str(msg.get("from", {}).get("username", ""))
		_msg_count += 1
		status_label.text = "%d messages" % _msg_count
		text_updated.emit()


func _read_fields() -> void:
	if token_edit != null:
		_token = token_edit.text.strip_edges()


func _on_delete_pressed() -> void:
	if _poll_timer:
		_poll_timer.stop()
	delete_pressed.emit(self)


func get_node_type() -> String:
	return "tg_receive"


func serialize_data() -> Dictionary:
	var d: Dictionary = {"token": _token, "last_update_id": _last_update_id}
	if interval_spin != null:
		d["interval"] = interval_spin.value
	return d


func deserialize_data(d: Dictionary) -> void:
	if d.has("token"):
		_token = d.token
		if token_edit != null:
			token_edit.text = _token
	if d.has("last_update_id"):
		_last_update_id = int(d.last_update_id)
	if d.has("interval") and interval_spin != null:
		interval_spin.value = float(d.interval)


func get_gal_props(nd: Dictionary) -> Dictionary:
	var props: Dictionary = {}
	if nd.has("token") and nd.token != "":
		props["token"] = nd.token
	if nd.has("interval"):
		props["interval"] = str(nd.interval)
	return props
