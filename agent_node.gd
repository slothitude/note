extends GraphNode

signal delete_pressed(node: GraphNode)
signal text_updated

var prompt_text: String = ""
var system_text: String = ""
var url_text: String = ""
var result_text: String = ""
var log_text: String = ""
var model: String = "llama3.2"
var max_turns: int = 5
var enabled: bool = true
var enable_port: int = -1
var trigger_port: int = -1
var _messages: Array = []
var _log: String = ""
var _running: bool = false
var _turn: int = 0

var model_edit: LineEdit
var turns_spin: SpinBox
var status_label: Label

const DEFAULT_SYSTEM := "You are a helpful assistant. You have access to these tools:\n- exec(command): Run a shell command and return stdout\n- read_file(path): Read a file's contents\n- write_file(path): Write content to a file (input is \"path\\ncontent\")\n\nRespond with JSON:\n- To use a tool: {\"thought\":\"...\",\"tool\":\"exec\",\"input\":\"command here\"}\n- To answer: {\"thought\":\"...\",\"answer\":\"your answer\"}"


func _ready() -> void:
	if enable_port >= 0:
		return
	title = "Agent"
	model_edit = get_node_or_null("ModelEdit")
	turns_spin = get_node_or_null("TurnsSpin")
	status_label = get_node_or_null("StatusLabel")
	# Ports: 0=Prompt(in,WHITE), 1=System(in,MAGENTA), 2=URL(in,CYAN)
	set_slot(0, true, 0, Color.WHITE, false, 0, Color.WHITE)
	set_slot(1, true, 0, Color.MAGENTA, false, 0, Color.WHITE)
	set_slot(2, true, 0, Color.CYAN, false, 0, Color.WHITE)
	# Ports: 3=Result(out,GREEN), 4=Log(out,RED)
	set_slot(3, false, 0, Color.WHITE, true, 0, Color.GREEN)
	set_slot(4, false, 0, Color.WHITE, true, 0, Color.RED)
	_add_control_ports()
	var http := HTTPRequest.new()
	http.name = "HTTPRequest"
	add_child(http)
	http.request_completed.connect(_on_request_completed)


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
		return result_text
	if port == 4:
		return log_text
	return ""


func set_input(port: int, text: String) -> void:
	if port == enable_port:
		enabled = text.strip_edges() != "" and text.strip_edges().to_lower() != "false"
		return
	if port == trigger_port:
		if enabled and not _running:
			_start_loop()
		return
	if not enabled:
		return
	if port == 0:
		prompt_text = text
	elif port == 1:
		system_text = text
	elif port == 2:
		url_text = text.strip_edges()


func _start_loop() -> void:
	if _running:
		return
	_running = true
	_turn = 0
	_log = ""
	_messages.clear()

	if model_edit:
		model = model_edit.text.strip_edges()
	if turns_spin:
		max_turns = int(turns_spin.value)

	var sys := system_text if system_text != "" else DEFAULT_SYSTEM
	_messages.append({"role": "system", "content": sys})
	if prompt_text != "":
		_messages.append({"role": "user", "content": prompt_text})

	if status_label:
		status_label.text = "Running..."
	_send_llm_request()


func _send_llm_request() -> void:
	var api_url := url_text if url_text != "" else "http://localhost:11434/api/chat"
	var http: HTTPRequest = get_node_or_null("HTTPRequest")
	if http == null:
		_finish("Error: no HTTPRequest node", "Error: HTTPRequest not found")
		return

	http.timeout = 30.0
	var body := JSON.stringify({
		"model": model,
		"messages": _messages,
		"stream": false,
	})
	var err := http.request(api_url, ["Content-Type: application/json"], HTTPClient.METHOD_POST, body)
	if err != OK:
		var hint := "Request error %d. " % err
		if err == ERR_CANT_CONNECT:
			hint += "Is Ollama running at %s?" % api_url
		_finish("Error: %s" % hint, _log + "\n%s" % hint)


func _on_request_completed(_result: int, _code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if not _running:
		return

	var response_str := body.get_string_from_utf8()
	if _result != HTTPRequest.RESULT_SUCCESS:
		var hint := "HTTP error (result=%d, code=%d)" % [_result, _code]
		if _result == HTTPRequest.RESULT_CANT_CONNECT:
			hint += "\nIs Ollama running? Try: ollama serve"
		elif _result == HTTPRequest.RESULT_REQUEST_FAILED:
			hint += "\nModel '%s' not found. Try: ollama pull %s" % [model, model]
		_finish("Error: %s" % hint, _log + "\n%s" % hint)
		return

	var json := JSON.new()
	var err := json.parse(response_str)
	if err != OK:
		_finish("Parse error", _log + "\nJSON parse error: " + response_str)
		return

	var data: Dictionary = json.data
	var content: String = data.get("message", {}).get("content", "")
	if content == "":
		_finish("Empty response", _log + "\nEmpty LLM response")
		return

	# Parse the LLM's structured response
	var resp_json := JSON.new()
	var resp_err := resp_json.parse(content.strip_edges())
	if resp_err != OK:
		# Not valid JSON - treat as plain text answer
		_log += "\n[Turn %d] Raw: %s" % [_turn, content]
		_finish(content, _log)
		return

	var resp: Dictionary = resp_json.data

	if resp.has("answer"):
		var thought: String = resp.get("thought", "")
		var answer: String = resp.get("answer", "")
		_log += "\n[Turn %d] Thought: %s\n  Answer: %s" % [_turn, thought, answer]
		_finish(answer, _log)
		return

	if resp.has("tool"):
		var thought: String = resp.get("thought", "")
		var tool: String = resp.get("tool", "")
		var tool_input: String = resp.get("input", "")
		_log += "\n[Turn %d] Thought: %s\n  Tool: %s(%s)" % [_turn, thought, tool, tool_input]

		# Append assistant message
		_messages.append({"role": "assistant", "content": content})

		# Execute tool
		var tool_result := _execute_tool(tool, tool_input)
		_log += "\n  Result: %s" % tool_result

		# Append tool result as user message
		_messages.append({"role": "user", "content": "Tool result:\n%s" % tool_result})

		_turn += 1
		if _turn >= max_turns:
			_finish("Max turns reached", _log + "\nMax turns (%d) reached" % max_turns)
			return

		if status_label:
			status_label.text = "Turn %d..." % _turn
		_send_llm_request()
		return

	# Has neither answer nor tool - treat as plain answer
	_log += "\n[Turn %d] Response: %s" % [_turn, content]
	_finish(content, _log)


func _execute_tool(tool: String, input_text: String) -> String:
	if tool == "exec":
		var output := []
		var exit_code := OS.execute("cmd", PackedStringArray(["/C", input_text]), output)
		var result := ""
		for line in output:
			result += str(line)
		if exit_code != 0:
			result += "\n(exit code: %d)" % exit_code
		return result
	if tool == "read_file":
		var path := input_text.strip_edges()
		if not FileAccess.file_exists(path):
			return "Error: file not found: %s" % path
		var f := FileAccess.open(path, FileAccess.READ)
		if f == null:
			return "Error: cannot open file: %s" % path
		var content := f.get_as_text()
		f.close()
		return content
	if tool == "write_file":
		var newline_pos := input_text.find("\n")
		if newline_pos == -1:
			return "Error: write_file input must be \"path\\ncontent\""
		var path := input_text.left(newline_pos).strip_edges()
		var content := input_text.substr(newline_pos + 1)
		var f := FileAccess.open(path, FileAccess.WRITE)
		if f == null:
			return "Error: cannot write to file: %s" % path
		f.store_string(content)
		f.close()
		return "OK: wrote %d bytes to %s" % [content.length(), path]
	return "Unknown tool: %s" % tool


func _finish(result: String, log: String) -> void:
	result_text = result
	log_text = log
	_running = false
	if status_label:
		status_label.text = "Done"
	text_updated.emit()


func _on_run_pressed() -> void:
	if not enabled:
		return
	_start_loop()


func _on_stop_pressed() -> void:
	if not _running:
		return
	_running = false
	var http: HTTPRequest = get_node_or_null("HTTPRequest")
	if http:
		http.cancel_request()
	_finish("Stopped", _log + "\nStopped by user")


func _on_delete_pressed() -> void:
	delete_pressed.emit(self)
