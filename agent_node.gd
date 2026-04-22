extends GraphNode

const AssemblerScript := preload("res://assembler.gd")

signal delete_pressed(node: GraphNode)
signal text_updated

var prompt_text: String = ""
var system_text: String = ""
var url_text: String = ""
var result_text: String = ""
var log_text: String = ""
var model: String = "llama3.2"
var max_turns: int = 5
var api_key: String = ""
var timeout_secs: float = 60.0
var context_limit: int = 20
var enabled: bool = true
var enable_port: int = -1
var trigger_port: int = -1
var _messages: Array = []
var _log: String = ""
var _running: bool = false
var _turn: int = 0
var memory: Array = []  # persists across runs
var _pending_trigger: String = ""  # stores trigger data for multi-agent use
var _chat_target: GraphNode = null  # target agent for chat callback
var _retry_count: int = 0  # auto-retry counter for timeouts

var model_edit: LineEdit
var turns_spin: SpinBox
var key_edit: LineEdit
var status_label: Label

const DEFAULT_SYSTEM := "You are a helpful assistant. You have access to these tools:\n- exec(command): Run a shell command and return stdout\n- read_file(path): Read a file's contents\n- write_file(path): Write content to a file (input is \"path\\ncontent\")\n- append_file(path): Append content to a file (input is \"path\\ncontent\")\n- list_dir(path): List files and directories at path. Returns one per line.\n- list_files(path): List directory contents with file sizes.\n- search_files(pattern, path): Search for text pattern in files under path. Returns matches.\n- web_fetch(url): Fetch a URL and return its text content (up to 4000 chars).\n- set_model(name): Switch to a different LLM model mid-conversation.\n- set_system(prompt): Update your own system prompt for self-improvement.\n- export_gal(): Get the current graph as GAL text for inspection or modification.\n- query_graph(): Get info about all nodes and connections in the current graph.\n- list_agents(): Find all agent nodes in the graph and their models.\n- send_message(target|message): Send a message to another agent node by name.\n- modify_node(name|prop|value): Change a property on any node in the graph.\n- schedule(target|seconds[|message]): Create a timer that triggers a node after a delay.\n- chat(target|message): Send a message to another agent and wait for its response.\n- base64(encode|text or decode|text): Encode or decode base64 strings.\n- hash(algo|text_or_path): Compute MD5 or SHA256 hash of a string or file.\n- json_extract(json_text|path): Extract a value from JSON using dot-notation path.\n- math_eval(expression): Evaluate a mathematical expression (e.g. 2+3*4).\n- image_decode(base64_data): Decode base64 image data and return format/size info.\n\nRespond with JSON:\n- To use a tool: {\"thought\":\"...\",\"tool\":\"exec\",\"input\":\"command here\"}\n- To answer: {\"thought\":\"...\",\"answer\":\"your answer\"}"


func _ready() -> void:
	if enable_port >= 0:
		return
	title = "Agent"
	model_edit = get_node_or_null("ModelEdit")
	turns_spin = get_node_or_null("TurnsSpin")
	key_edit = get_node_or_null("KeyEdit")
	status_label = get_node_or_null("StatusLabel")
	AssemblerScript.configure_slots(self, "agent")
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
			# If trigger carries data, use it as prompt when prompt is empty
			if text.strip_edges() != "" and prompt_text == "":
				prompt_text = text.strip_edges()
			# Use call_deferred to allow other ports (e.g. prompt) to arrive first
			call_deferred("_start_loop")
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
	_retry_count = 0
	_log = ""

	if model_edit:
		model = model_edit.text.strip_edges()
	if turns_spin:
		max_turns = int(turns_spin.value)
	if key_edit and key_edit.text.strip_edges() != "":
		api_key = key_edit.text.strip_edges()

	var sys := system_text if system_text != "" else DEFAULT_SYSTEM
	# Start with system prompt, then carry forward memory
	_messages = [{"role": "system", "content": sys}]
	for msg in memory:
		_messages.append(msg)
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

	http.timeout = timeout_secs

	# Trim context window if messages exceed limit (keep system prompt)
	while _messages.size() > context_limit + 1:
		_messages.remove_at(1)  # Remove oldest after system prompt
	var is_openai := api_url.find("/v1/chat") >= 0 or api_url.find("/chat/completions") >= 0
	var headers := ["Content-Type: application/json"]
	if api_key != "":
		headers.append("Authorization: Bearer %s" % api_key)

	var body: String
	if is_openai:
		body = JSON.stringify({
			"model": model,
			"messages": _messages,
			"stream": false,
		})
	else:
		body = JSON.stringify({
			"model": model,
			"messages": _messages,
			"stream": false,
		})

	var err := http.request(api_url, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		var hint := "Request error %d. " % err
		if err == ERR_CANT_CONNECT:
			hint += "Is the API running at %s?" % api_url
		_finish("Error: %s" % hint, _log + "\n%s" % hint)


func _on_request_completed(_result: int, _code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if not _running:
		return

	var response_str := body.get_string_from_utf8()
	if _result != HTTPRequest.RESULT_SUCCESS:
		var hint := "HTTP error (result=%d, code=%d)" % [_result, _code]
		# Auto-retry once on timeout
		if _result == HTTPRequest.RESULT_REQUEST_FAILED and _retry_count < 1:
			_retry_count += 1
			if status_label:
				status_label.text = "Retrying... (attempt %d)" % (_retry_count + 1)
			_send_llm_request()
			return
		if _result == HTTPRequest.RESULT_CANT_CONNECT:
			hint += "\nIs the API running? For Ollama: ollama serve"
		elif _result == HTTPRequest.RESULT_REQUEST_FAILED:
			hint += "\nModel '%s' not found." % model
		_finish("Error: %s" % hint, _log + "\n%s" % hint)
		return

	var json := JSON.new()
	var err := json.parse(response_str)
	if err != OK:
		_finish("Parse error", _log + "\nJSON parse error: " + response_str)
		return

	var data: Dictionary = json.data
	# Handle OpenAI-compatible format: {choices: [{message: {content: "..."}}]}
	var content: String = ""
	if data.has("choices") and data.choices.size() > 0:
		content = data.choices[0].get("message", {}).get("content", "")
	# Handle Ollama format: {message: {content: "..."}}
	elif data.has("message"):
		content = data.message.get("content", "")

	if content == "":
		_finish("Empty response", _log + "\nEmpty LLM response: " + response_str.left(200))
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

		# If waiting for async response (e.g. chat tool), pause the loop
		if tool_result == "__waiting__":
			return

		_log += "\n  Result: %s" % tool_result

		# Progressive output — update result_text so watchers can see progress
		result_text = "Working... (turn %d/%d)" % [_turn + 1, max_turns]
		text_updated.emit()

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
	if tool == "gal":
		var graph := _get_graph()
		if graph == null:
			return "Error: graph controller not found"
		var result: Dictionary = graph.assemble(input_text)
		if result.is_empty():
			return "Error: assembly failed (check GAL syntax)"
		var node_count: int = result.get("nodes", 0)
		var wire_count: int = result.get("wires", 0)
		return "OK: assembled %d nodes, %d wires" % [node_count, wire_count]
	if tool == "list_dir":
		var path := input_text.strip_edges()
		var dir := DirAccess.open(path)
		if dir == null:
			return "Error: cannot open directory: %s" % path
		var entries: String = ""
		dir.list_dir_begin()
		var fname: String = dir.get_next()
		while fname != "":
			if not fname.begins_with("."):
				var full_path := path.path_join(fname)
				if dir.current_is_dir():
					entries += fname + "/\n"
				else:
					entries += fname + "\n"
			fname = dir.get_next()
		dir.list_dir_end()
		if entries == "":
			return "(empty directory)"
		return entries.strip_edges()
	if tool == "search_files":
		var sep_pos := input_text.find(",")
		if sep_pos == -1:
			return "Error: search_files requires pattern,path"
		var pattern: String = input_text.left(sep_pos).strip_edges()
		var search_path: String = input_text.substr(sep_pos + 1).strip_edges()
		var output := []
		var exit_code := OS.execute("cmd", PackedStringArray(["/C", "findstr /s /n /i \"%s\" %s\\*" % [pattern, search_path]]), output)
		var result_str := ""
		for line in output:
			result_str += str(line)
		if result_str.length() > 2000:
			result_str = result_str.left(2000) + "\n... (truncated)"
		if exit_code != 0 and result_str == "":
			return "No matches found for '%s' in %s" % [pattern, search_path]
		return result_str
	if tool == "web_fetch":
		var url := input_text.strip_edges()
		var output := []
		var exit_code := OS.execute("cmd", PackedStringArray(["/C", "curl -s -L --max-time 15 \"%s\"" % url]), output)
		var content := ""
		for line in output:
			content += str(line)
		if content.length() > 4000:
			content = content.left(4000) + "\n... (truncated)"
		if exit_code != 0:
			return "Error: fetch failed (exit code %d)" % exit_code
		if content == "":
			return "Error: empty response from %s" % url
		return content
	if tool == "set_model":
		var new_model := input_text.strip_edges()
		if new_model == "":
			return "Error: set_model requires a model name"
		var old := model
		model = new_model
		if model_edit:
			model_edit.text = new_model
		return "Model changed from '%s' to '%s'" % [old, new_model]
	if tool == "set_system":
		var new_system := input_text.strip_edges()
		if new_system == "":
			return "Error: set_system requires system prompt text"
		_messages[0] = {"role": "system", "content": new_system}
		return "System prompt updated (%d chars)" % new_system.length()
	if tool == "export_gal":
		var graph := _get_graph()
		if graph == null:
			return "Error: graph controller not found"
		if not graph.has_method("export_gal"):
			return "Error: graph does not support export_gal"
		var gal_text: String = graph.export_gal()
		if gal_text == "":
			return "(empty graph)"
		if gal_text.length() > 4000:
			gal_text = gal_text.left(4000) + "\n... (truncated)"
		return gal_text
	if tool == "query_graph":
		var graph := _get_graph()
		if graph == null:
			return "Error: graph controller not found"
		if not graph.has_method("get_graph_info"):
			return "Error: graph does not support query_graph"
		var info: Dictionary = graph.get_graph_info()
		return JSON.stringify(info, "\t")
	if tool == "list_agents":
		var graph := _get_graph()
		if graph == null:
			return "Error: graph controller not found"
		if not graph.has_method("get_graph_info"):
			return "Error: graph does not support query_graph"
		var info: Dictionary = graph.get_graph_info()
		var agents: Array = []
		for nd in info.nodes:
			if nd.type == "agent":
				agents.append({"name": nd.name, "title": nd.title, "model": nd.get("model", "")})
		if agents.is_empty():
			return "No other agent nodes found in the graph"
		return JSON.stringify(agents, "\t")
	if tool == "send_message":
		var sep_pos := input_text.find("|")
		if sep_pos == -1:
			return "Error: send_message requires target_name|message"
		var target_name: String = input_text.left(sep_pos).strip_edges()
		var message: String = input_text.substr(sep_pos + 1).strip_edges()
		var graph := _get_graph()
		if graph == null:
			return "Error: graph controller not found"
		var gedit: Node = graph.get("graph_edit")
		if gedit == null:
			return "Error: no GraphEdit found"
		for child in gedit.get_children():
			if child is GraphNode and child.has_method("get_node_type") and child.get_node_type() == "agent":
				if String(child.name) == target_name or child.title == target_name:
					child.set_input(0, message)
					return "Message sent to %s" % target_name
		return "Error: agent '%s' not found" % target_name
	if tool == "modify_node":
		var parts: PackedStringArray = input_text.split("|")
		if parts.size() < 3:
			return "Error: modify_node requires node_name|prop|value"
		var node_name: String = parts[0].strip_edges()
		var prop: String = parts[1].strip_edges()
		var value: String = parts[2].strip_edges()
		var graph := _get_graph()
		if graph == null:
			return "Error: graph controller not found"
		var gedit: Node = graph.get("graph_edit")
		if gedit == null:
			return "Error: no GraphEdit found"
		for child in gedit.get_children():
			if child is GraphNode and (String(child.name) == node_name or child.title == node_name):
				if child.has_method("set_input"):
					# Try to find the right input port for the prop
					var type: String = child.get_node_type() if child.has_method("get_node_type") else ""
					var port_map: Dictionary = AssemblerScript.INPUT_PORTS.get(type, {})
					var port_idx = port_map.get(prop)
					if port_idx != null:
						child.set_input(int(port_idx), value)
						return "Set %s.%s on %s" % [prop, value, node_name]
				child.set(prop, value)
				return "Set property %s=%s on %s" % [prop, value, node_name]
		return "Error: node '%s' not found" % node_name
	if tool == "schedule":
		# schedule target_name|seconds[|message]
		var parts: PackedStringArray = input_text.split("|")
		if parts.size() < 2:
			return "Error: schedule requires target_name|seconds[|message]"
		var target_name: String = parts[0].strip_edges()
		var secs_str: String = parts[1].strip_edges()
		var message: String = parts[2].strip_edges() if parts.size() > 2 else ""
		if not secs_str.is_valid_float():
			return "Error: seconds must be a number, got '%s'" % secs_str
		var secs := float(secs_str)
		var graph := _get_graph()
		if graph == null:
			return "Error: graph controller not found"
		var gedit: Node = graph.get("graph_edit")
		if gedit == null:
			return "Error: no GraphEdit found"
		# Find the target node
		var target: GraphNode = null
		for child in gedit.get_children():
			if child is GraphNode and (String(child.name) == target_name or child.title == target_name):
				target = child
				break
		if target == null:
			return "Error: node '%s' not found" % target_name
		# Create timer node
		var timer_scene := load("res://timer_node.tscn")
		if timer_scene == null:
			return "Error: timer scene not found"
		var timer: GraphNode = timer_scene.instantiate()
		timer.name = "ScheduleTimer_%d" % randi_range(1000, 9999)
		timer.position_offset = position_offset + Vector2(300, 200)
		if message != "":
			timer.set("prompt_text", message)
			timer.set("output_value", message)
		timer.set("interval_secs", maxf(secs, 0.1))
		gedit.add_child(timer)
		if timer.has_method("_ready"):
			timer._ready()
		# Connect signals for propagation
		if timer.has_signal("text_updated"):
			timer.text_updated.connect(graph._propagate_text.bind(timer))
		if timer.has_signal("delete_pressed"):
			timer.delete_pressed.connect(graph._on_node_delete)
		# Connect timer output -> target trigger
		var trigger_idx = target.get("trigger_port")
		if trigger_idx == null:
			trigger_idx = -1
		if trigger_idx < 0:
			# Try to send to first input as fallback
			trigger_idx = 0
		gedit.connect_node(timer.name, 0, target.name, int(trigger_idx))
		# Start the timer by sending to its start port
		timer.set_input(1, "true")
		return "Scheduled: timer '%s' will fire in %gs, targeting %s" % [timer.name, secs, target_name]
	if tool == "chat":
		# chat target_name|message — trigger another agent, wait for response
		var sep_pos := input_text.find("|")
		if sep_pos == -1:
			return "Error: chat requires target_name|message"
		var target_name: String = input_text.left(sep_pos).strip_edges()
		var message: String = input_text.substr(sep_pos + 1).strip_edges()
		var graph := _get_graph()
		if graph == null:
			return "Error: graph controller not found"
		var gedit: Node = graph.get("graph_edit")
		if gedit == null:
			return "Error: no GraphEdit found"
		# Find the target agent
		var target: GraphNode = null
		for child in gedit.get_children():
			if child is GraphNode and child.has_method("get_node_type") and child.get_node_type() == "agent":
				if String(child.name) == target_name or child.title == target_name:
					target = child
					break
		if target == null:
			return "Error: agent '%s' not found" % target_name
		if target.get("_running") == true:
			return "Error: agent '%s' is already running" % target_name
		# Set prompt and connect one-shot callback
		target.set("prompt_text", message)
		_chat_target = target
		target.text_updated.connect(_on_chat_response, ConnectFlags.CONNECT_ONE_SHOT)
		# Trigger the target agent
		var tp = target.get("trigger_port")
		if tp != null and int(tp) >= 0:
			target.set_input(int(tp), message)
		else:
			target.set_input(0, message)
			if target.has_method("_start_loop"):
				target.call("_start_loop")
		if status_label:
			status_label.text = "Waiting for %s..." % target_name
		# Return sentinel — _on_chat_response will continue the loop
		return "__waiting__"
	if tool == "base64":
		var parts: PackedStringArray = input_text.split("|", false, 1)
		var mode: String = parts[0].strip_edges().to_lower() if parts.size() > 1 else "encode"
		var data: String = parts[1].strip_edges() if parts.size() > 1 else parts[0].strip_edges() if parts.size() > 0 else ""
		if mode == "decode":
			return Marshalls.base64_to_utf8(data)
		return Marshalls.utf8_to_base64(data)
	if tool == "hash":
		var parts: PackedStringArray = input_text.split("|", false, 1)
		var algo: String = parts[0].strip_edges().to_lower() if parts.size() > 1 else "md5"
		var data: String = parts[1].strip_edges() if parts.size() > 1 else parts[0].strip_edges() if parts.size() > 0 else ""
		var output := []
		if algo == "sha256":
			OS.execute("cmd", PackedStringArray(["/C", "powershell -Command \"([System.BitConverter]::ToString([System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes('%s')))).Replace('-','').ToLower()\"" % data.replace("'", "''")]), output)
		else:
			OS.execute("cmd", PackedStringArray(["/C", "powershell -Command \"([System.BitConverter]::ToString([System.Security.Cryptography.MD5]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes('%s')))).Replace('-','').ToLower()\"" % data.replace("'", "''")]), output)
		var result := ""
		for line in output:
			result += str(line)
		return "%s: %s" % [algo, result.strip_edges()]
	if tool == "json_extract":
		var parts: PackedStringArray = input_text.split("|", false, 1)
		if parts.size() < 2:
			return "Error: json_extract requires json_text|path"
		var json_text: String = parts[0].strip_edges()
		var path: String = parts[1].strip_edges()
		var json := JSON.new()
		if json.parse(json_text) != OK:
			return "Error: invalid JSON"
		var current = json.data
		for key in path.split("."):
			if current is Dictionary and current.has(key):
				current = current[key]
			elif current is Array and key.is_valid_int():
				var idx := key.to_int()
				if idx >= 0 and idx < current.size():
					current = current[idx]
				else:
					return "Error: array index %d out of bounds" % idx
			else:
				return "Error: path '%s' not found" % key
		if current is String or current is float or current is int or current is bool:
			return str(current)
		return JSON.stringify(current, "\t")
	if tool == "math_eval":
		var expr := Expression.new()
		var err := expr.parse(input_text.strip_edges(), [])
		if err != OK:
			return "Error: %s" % expr.get_error_text()
		var result = expr.execute([], null, true)
		if not expr.has_execute_failed():
			return str(result)
		return "Error: %s" % expr.get_error_text()
	if tool == "list_files":
		var path := input_text.strip_edges()
		var dir := DirAccess.open(path)
		if dir == null:
			return "Error: cannot open directory: %s" % path
		var entries: String = ""
		dir.list_dir_begin()
		var fname: String = dir.get_next()
		while fname != "":
			if not fname.begins_with("."):
				if dir.current_is_dir():
					entries += fname + "/\n"
				else:
					var fp := path.path_join(fname)
					if FileAccess.file_exists(fp):
						var size := FileAccess.open(fp, FileAccess.READ).get_length()
						entries += fname + " (%d bytes)\n" % size
					else:
						entries += fname + "\n"
			fname = dir.get_next()
		dir.list_dir_end()
		if entries == "":
			return "(empty directory)"
		return entries.strip_edges()
	if tool == "append_file":
		var newline_pos := input_text.find("\n")
		if newline_pos == -1:
			return "Error: append_file input must be \"path\\ncontent\""
		var path := input_text.left(newline_pos).strip_edges()
		var content := input_text.substr(newline_pos + 1)
		# Read existing content
		var existing := ""
		if FileAccess.file_exists(path):
			var fr := FileAccess.open(path, FileAccess.READ)
			if fr:
				existing = fr.get_as_text()
				fr.close()
		# Write combined content
		var fw := FileAccess.open(path, FileAccess.WRITE)
		if fw == null:
			return "Error: cannot open file: %s" % path
		fw.store_string(existing + content)
		fw.close()
		return "OK: appended %d bytes to %s" % [content.length(), path]
	if tool == "image_decode":
		# image_decode base64_data — returns description of image size/format
		var b64: String = input_text.strip_edges()
		var raw := Marshalls.base64_to_raw(b64)
		if raw.is_empty():
			return "Error: invalid base64 data"
		# Detect image format from magic bytes
		var format := "unknown"
		if raw.size() >= 3 and raw[0] == 0xFF and raw[1] == 0xD8 and raw[2] == 0xFF:
			format = "JPEG"
		elif raw.size() >= 8 and raw[0] == 0x89 and raw[1] == 0x50 and raw[2] == 0x4E and raw[3] == 0x47:
			format = "PNG"
		elif raw.size() >= 4 and raw[0] == 0x47 and raw[1] == 0x49 and raw[2] == 0x46:
			format = "GIF"
		elif raw.size() >= 4 and raw[0] == 0x52 and raw[1] == 0x49 and raw[2] == 0x46 and raw[3] == 0x46:
			format = "WEBP"
		return "Image: %s format, %d bytes" % [format, raw.size()]
	return "Unknown tool: %s" % tool


func _finish(result: String, log: String) -> void:
	result_text = result
	log_text = log
	_running = false
	# Save new messages to persistent memory (skip system prompt at index 0)
	for i in range(1, _messages.size()):
		memory.append(_messages[i].duplicate())
	if status_label:
		status_label.text = "Done (%d msgs)" % memory.size()
	text_updated.emit()


func _on_chat_response() -> void:
	# Called when target agent finishes — feed its result back into our loop
	if _chat_target == null:
		return
	var response: String = _chat_target.get("result_text")
	var target_name: String = String(_chat_target.name)
	_chat_target = null
	if status_label:
		status_label.text = "Chat response from %s" % target_name
	_log += "\n  Chat response from %s: %s" % [target_name, response.left(500)]
	# Feed the response back as a user message and continue
	_messages.append({"role": "user", "content": "Agent %s responded:\n%s" % [target_name, response]})
	_turn += 1
	if _turn >= max_turns:
		_finish("Max turns reached", _log + "\nMax turns (%d) reached" % max_turns)
		return
	if status_label:
		status_label.text = "Turn %d..." % _turn
	_send_llm_request()


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


func _on_clear_pressed() -> void:
	memory.clear()
	if status_label:
		status_label.text = "Memory cleared"


func _on_retry_pressed() -> void:
	if _running:
		return
	_start_loop()


func _on_delete_pressed() -> void:
	delete_pressed.emit(self)


func _get_graph() -> Node:
	var p := get_parent()
	while p:
		if p.has_method("assemble"):
			return p
		p = p.get_parent()
	return null


func get_node_type() -> String:
	return "agent"


func serialize_data() -> Dictionary:
	var d: Dictionary = {"model": model, "max_turns": max_turns, "result_text": result_text, "log_text": log_text, "timeout_secs": timeout_secs, "context_limit": context_limit}
	if api_key != "":
		d["api_key"] = api_key
	if memory.size() > 0:
		d["memory"] = memory
	return d


func deserialize_data(d: Dictionary) -> void:
	if d.has("model"):
		model = d.model
		if model_edit:
			model_edit.text = d.model
	if d.has("max_turns"):
		max_turns = int(d.max_turns)
		if turns_spin:
			turns_spin.value = int(d.max_turns)
	if d.has("api_key"):
		api_key = d.api_key
		if key_edit:
			key_edit.text = d.api_key
	if d.has("result_text"):
		result_text = d.result_text
	if d.has("log_text"):
		log_text = d.log_text
	if d.has("memory"):
		memory = d.memory
	if d.has("timeout_secs"):
		timeout_secs = float(d.timeout_secs)
	if d.has("context_limit"):
		context_limit = int(d.context_limit)


func get_gal_props(nd: Dictionary) -> Dictionary:
	var props: Dictionary = {}
	if nd.has("model"):
		props["model"] = nd.model
	if nd.has("max_turns"):
		props["max_turns"] = str(nd.max_turns)
	if nd.has("timeout_secs") and float(nd.timeout_secs) != 60.0:
		props["timeout_secs"] = str(nd.timeout_secs)
	if nd.has("context_limit") and int(nd.context_limit) != 20:
		props["context_limit"] = str(nd.context_limit)
	return props
