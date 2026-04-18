extends VBoxContainer

signal notepad_selected(node: GraphNode)

const NotepadNodeScene := preload("res://notepad_node.tscn")
const ExecNodeScene := preload("res://exec_node.tscn")
const FindFileNodeScene := preload("res://find_file_node.tscn")
const BoolNodeScene := preload("res://bool_node.tscn")
const PCNodeScene := preload("res://pc_node.tscn")
const SubGraphNodeScene := preload("res://sub_graph_node.tscn")
const GraphInputNodeScene := preload("res://graph_input_node.tscn")
const GraphOutputNodeScene := preload("res://graph_output_node.tscn")
const TimerNodeScene := preload("res://timer_node.tscn")
const BinaryNodeScene := preload("res://binary_node.tscn")

var _node_counter := 0
var _visited: Array[StringName] = []
var graph_file_path: String = ""
var _graph_stack: Array = []
var _current_subgraph_name: String = ""

@onready var graph_edit: GraphEdit = %GraphEdit


func _ready() -> void:
	_setup_style()
	_connect_signals()
	if FileAccess.file_exists(SAVE_PATH):
		load_graph()
	else:
		_add_default_notepad()


func _setup_style() -> void:
	graph_edit.add_theme_color_override("background_color", Color(0.05, 0.05, 0.05, 1.0))
	graph_edit.add_theme_color_override("grid_major", Color(0.15, 0.15, 0.15, 1.0))
	graph_edit.add_theme_color_override("grid_minor", Color(0.08, 0.08, 0.08, 1.0))
	graph_edit.add_theme_color_override("activity", Color.WHITE)


func _connect_signals() -> void:
	graph_edit.connection_request.connect(_on_connection_request)
	graph_edit.disconnection_request.connect(_on_disconnection_request)
	graph_edit.delete_nodes_request.connect(_on_delete_nodes)
	graph_edit.gui_input.connect(_on_graph_input)


func _on_connection_request(from: StringName, from_port: int, to: StringName, to_port: int) -> void:
	graph_edit.connect_node(from, from_port, to, to_port)
	var source := graph_edit.get_node_or_null(NodePath(from))
	if source:
		_propagate_text(source)


func _on_disconnection_request(from: StringName, from_port: int, to: StringName, to_port: int) -> void:
	graph_edit.disconnect_node(from, from_port, to, to_port)


func _on_graph_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		var conn: Dictionary = graph_edit.get_closest_connection_at_point(event.position, 10.0)
		if not conn.is_empty():
			graph_edit.disconnect_node(conn.from_node, conn.from_port, conn.to_node, conn.to_port)


func _on_delete_nodes(nodes: Array[StringName]) -> void:
	for node_name in nodes:
		var node := graph_edit.get_node_or_null(NodePath(node_name))
		if node:
			_clear_connections_for(node_name)
			node.queue_free()


func _clear_connections_for(node_name: StringName) -> void:
	var all_connections := graph_edit.get_connection_list()
	for conn in all_connections:
		if conn.from_node == node_name or conn.to_node == node_name:
			graph_edit.disconnect_node(conn.from_node, conn.from_port, conn.to_node, conn.to_port)


func _add_default_notepad() -> void:
	var node := NotepadNodeScene.instantiate()
	node.name = "Notepad%d" % _node_counter
	_node_counter += 1
	node.position_offset = _get_next_node_position()
	node.open_pressed.connect(_on_notepad_open)
	node.delete_pressed.connect(_on_node_delete)
	node.text_updated.connect(_propagate_text.bind(node))
	graph_edit.add_child(node)
	var temp_path := OS.get_temp_dir().path_join("note_untitled.tmp")
	if FileAccess.file_exists(temp_path):
		var f := FileAccess.open(temp_path, FileAccess.READ)
		if f:
			node.set_text(f.get_as_text())
			f.close()


func add_default_notepad() -> void:
	var node := NotepadNodeScene.instantiate()
	node.name = "Notepad%d" % _node_counter
	_node_counter += 1
	node.position_offset = _get_next_node_position()
	node.open_pressed.connect(_on_notepad_open)
	node.delete_pressed.connect(_on_node_delete)
	node.text_updated.connect(_propagate_text.bind(node))
	graph_edit.add_child(node)


func add_notepad_node() -> void:
	var node := NotepadNodeScene.instantiate()
	node.name = "Notepad%d" % _node_counter
	_node_counter += 1
	node.position_offset = _get_next_node_position()
	node.open_pressed.connect(_on_notepad_open)
	node.delete_pressed.connect(_on_node_delete)
	node.text_updated.connect(_propagate_text.bind(node))
	graph_edit.add_child(node)


func add_exec_node() -> void:
	var node := ExecNodeScene.instantiate()
	node.name = "Exec%d" % _node_counter
	_node_counter += 1
	node.position_offset = _get_next_node_position()
	node.run_pressed.connect(_on_node_run)
	node.delete_pressed.connect(_on_node_delete)
	graph_edit.add_child(node)


func add_find_file_node() -> void:
	var node := FindFileNodeScene.instantiate()
	node.name = "FindFile%d" % _node_counter
	_node_counter += 1
	node.position_offset = _get_next_node_position()
	node.delete_pressed.connect(_on_node_delete)
	node.text_updated.connect(_propagate_text.bind(node))
	graph_edit.add_child(node)


func add_bool_node() -> void:
	var node := BoolNodeScene.instantiate()
	node.name = "Bool%d" % _node_counter
	_node_counter += 1
	node.position_offset = _get_next_node_position()
	node.delete_pressed.connect(_on_node_delete)
	node.text_updated.connect(_propagate_text.bind(node))
	graph_edit.add_child(node)


func add_binary_node() -> void:
	var node := BinaryNodeScene.instantiate()
	node.name = "Binary%d" % _node_counter
	_node_counter += 1
	node.position_offset = _get_next_node_position()
	node.delete_pressed.connect(_on_node_delete)
	node.text_updated.connect(_propagate_text.bind(node))
	graph_edit.add_child(node)


func add_pc_node() -> void:
	var node := PCNodeScene.instantiate()
	node.name = "PC%d" % _node_counter
	_node_counter += 1
	node.position_offset = _get_next_node_position()
	node.delete_pressed.connect(_on_node_delete)
	node.text_updated.connect(_propagate_text.bind(node))
	graph_edit.add_child(node)


func add_timer_node() -> void:
	var node := TimerNodeScene.instantiate()
	node.name = "Timer%d" % _node_counter
	_node_counter += 1
	node.position_offset = _get_next_node_position()
	node.delete_pressed.connect(_on_node_delete)
	node.text_updated.connect(_propagate_text.bind(node))
	graph_edit.add_child(node)


func add_sub_graph_node() -> void:
	var node := SubGraphNodeScene.instantiate()
	node.name = "SubGraph%d" % _node_counter
	_node_counter += 1
	node.position_offset = _get_next_node_position()
	node.edit_pressed.connect(_on_enter_subgraph)
	node.delete_pressed.connect(_on_node_delete)
	node.text_updated.connect(_propagate_text.bind(node))
	graph_edit.add_child(node)


func add_graph_input_node() -> void:
	var node := GraphInputNodeScene.instantiate()
	var idx := _count_node_type("graph_input")
	node.name = "GInput%d" % _node_counter
	node.title = "Input %d" % idx
	_node_counter += 1
	node.position_offset = _get_next_node_position()
	node.delete_pressed.connect(_on_node_delete)
	node.text_updated.connect(_propagate_text.bind(node))
	graph_edit.add_child(node)


func add_graph_output_node() -> void:
	var node := GraphOutputNodeScene.instantiate()
	var idx := _count_node_type("graph_output")
	node.name = "GOutput%d" % _node_counter
	node.title = "Output %d" % idx
	_node_counter += 1
	node.position_offset = _get_next_node_position()
	node.delete_pressed.connect(_on_node_delete)
	node.text_updated.connect(_propagate_text.bind(node))
	graph_edit.add_child(node)


func _count_node_type(type: String) -> int:
	var count: int = 0
	for child in graph_edit.get_children():
		if child is GraphNode:
			var t := _get_node_type(child)
			if t == type:
				count += 1
	return count


func _get_next_node_position() -> Vector2:
	var existing := 0
	for child in graph_edit.get_children():
		if child is GraphNode:
			existing += 1
	var view_center := graph_edit.scroll_offset + graph_edit.size / (2.0 * graph_edit.zoom)
	var col := existing % 3
	var row := existing / 3
	return view_center + Vector2(col * 250.0, row * 150.0)


func _on_enter_subgraph(sub_graph_node: GraphNode) -> void:
	# Save current graph state
	var parent_data := _serialize_current_graph()
	_graph_stack.append({"data": parent_data, "subgraph_name": _current_subgraph_name})
	_current_subgraph_name = sub_graph_node.name
	# Grab data before clearing (node gets queued for free)
	var internal: Dictionary = sub_graph_node.internal_data.duplicate(true)
	var inputs: Array = sub_graph_node.stored_inputs.duplicate()
	# Clear and load sub-graph
	_clear_all_nodes()
	_node_counter = 0
	_build_nodes_from_data(internal)
	# Push stored inputs into GraphInputNodes
	_feed_subgraph_inputs(inputs)
	_show_subgraph_nav(true)


func _feed_subgraph_inputs(inputs: Array) -> void:
	var idx := 0
	for child in graph_edit.get_children():
		if child is GraphNode and _get_node_type(child) == "graph_input":
			if idx < inputs.size() and inputs[idx] != "":
				child.set_text(inputs[idx])
			idx += 1


func _capture_subgraph_outputs() -> Array:
	var outputs: Array = []
	for child in graph_edit.get_children():
		if child is GraphNode and _get_node_type(child) == "graph_output":
			outputs.append(child.text_buffer if child.get("text_buffer") != null else "")
	return outputs


func _on_exit_subgraph() -> void:
	if _graph_stack.is_empty():
		return
	# Save current sub-graph state and capture outputs
	var subgraph_data := _serialize_current_graph()
	var captured_outputs := _capture_subgraph_outputs()
	var exited_name := _current_subgraph_name
	# Pop parent state
	var parent: Dictionary = _graph_stack.pop_back()
	_current_subgraph_name = parent["subgraph_name"]
	_clear_all_nodes()
	_node_counter = 0
	_build_nodes_from_data(parent["data"])
	# Find the SubGraph node we just exited and update its internal data
	if exited_name != "":
		var node := graph_edit.get_node_or_null(NodePath(exited_name))
		if node and node.has_signal("edit_pressed"):
			node.internal_data = subgraph_data
			node.stored_outputs = captured_outputs
			node.call("_rebuild_ports")
			node.text_updated.emit()
	_show_subgraph_nav(_graph_stack.size() > 0)


func _show_subgraph_nav(show: bool) -> void:
	var back_btn: Button = get_node_or_null("Toolbar/BackBtn")
	if back_btn:
		back_btn.visible = show
	var add_input: Button = get_node_or_null("Toolbar/AddGInput")
	var add_output: Button = get_node_or_null("Toolbar/AddGOutput")
	if add_input:
		add_input.visible = show
	if add_output:
		add_output.visible = show


func _get_node_type(child: Node) -> String:
	if child.has_signal("edit_pressed"):
		return "subgraph"
	if child.has_signal("open_pressed"):
		return "notepad"
	if child.has_method("get_port_output"):
		return "pc"
	if child.get("interval_secs") != null and child.has_method("set_input"):
		return "timer"
	if child.has_method("set_input") and not child.has_method("get_port_output"):
		return "bool"
	if child.get("output_value") != null and not child.has_method("set_input"):
		return "binary"
	if child.get("file_path") != null and not child.has_signal("open_pressed") and not child.has_signal("edit_pressed"):
		return "find_file"
	if child.has_signal("text_updated") and child.title.begins_with("Input"):
		return "graph_input"
	if child.has_signal("text_updated") and child.title.begins_with("Output"):
		return "graph_output"
	return "exec"


func _serialize_node_data(child: Node, node_data: Dictionary) -> void:
	var t: String = node_data.type
	if t == "notepad":
		node_data["text"] = child.text_buffer
		node_data["file_path"] = child.file_path
		node_data["enabled"] = child.enabled
	elif t == "pc":
		node_data["counter"] = child.counter
		node_data["max_val"] = int(child.max_spin.value)
	elif t == "bool":
		node_data["input_a"] = child.input_a
		node_data["input_b"] = child.input_b
		node_data["mode"] = child.mode_option.selected
	elif t == "binary":
		node_data["output_value"] = child.output_value
	elif t == "timer":
		node_data["prompt_text"] = child.prompt_text
		node_data["interval_secs"] = child.interval_secs
		node_data["mode"] = child.mode_option.selected
		node_data["count"] = int(child.count_spin.value)
	elif t == "find_file":
		node_data["file_path"] = child.file_path
	elif t == "subgraph":
		node_data["internal"] = child.internal_data
		node_data["stored_inputs"] = child.stored_inputs
		node_data["stored_outputs"] = child.stored_outputs
	elif t == "graph_input" or t == "graph_output":
		node_data["title"] = child.title


func _serialize_current_graph() -> Dictionary:
	var data := {"nodes": [], "connections": []}
	for child in graph_edit.get_children():
		if child is GraphNode:
			var node_type := _get_node_type(child)
			var node_data := {
				"name": child.name,
				"type": node_type,
				"x": child.position_offset.x,
				"y": child.position_offset.y,
			}
			_serialize_node_data(child, node_data)
			data.nodes.append(node_data)
	for conn in graph_edit.get_connection_list():
		data.connections.append({
			"from_node": String(conn.from_node),
			"from_port": conn.from_port,
			"to_node": String(conn.to_node),
			"to_port": conn.to_port,
		})
	return data


func _on_node_run(exec_node: GraphNode) -> void:
	_execute_node(exec_node)


func _execute_node(exec_node: GraphNode) -> void:
	print("=== EXEC NODE RUN ===")
	var input_text := ""
	var connections := graph_edit.get_connection_list()
	print("Connections: ", connections)
	for conn in connections:
		if conn.to_node == exec_node.name and conn.to_port == 0:
			var source := graph_edit.get_node_or_null(NodePath(conn.from_node))
			if source and source.has_method("set_text"):
				input_text = source.text_buffer
			break

	if input_text == "":
		return

	var output := []
	var args := PackedStringArray(["/C", input_text])
	print("About to execute: cmd /C ", input_text)
	var error := OS.execute("cmd", args, output)
	print("OS.execute result: error=", error, " output=", output)

	var stdout_text := ""
	for line in output:
		stdout_text += str(line)
	var stderr_text := "Error: exit code %d" % error if error != 0 else ""

	for conn in connections:
		if conn.from_node == exec_node.name and conn.from_port == 0:
			var target := graph_edit.get_node_or_null(NodePath(conn.to_node))
			if target and target.has_method("set_text"):
				match conn.to_port:
					1: target.set_text(stdout_text + target.text_buffer)
					2: target.set_text(target.text_buffer + stdout_text)
					_: target.set_text(stdout_text)

	if stderr_text != "":
		for conn in connections:
			if conn.from_node == exec_node.name and conn.from_port == 1:
				var target := graph_edit.get_node_or_null(NodePath(conn.to_node))
				if target and target.has_method("set_text"):
					match conn.to_port:
						1: target.set_text(stderr_text + target.text_buffer)
						2: target.set_text(target.text_buffer + stderr_text)
						_: target.set_text(stderr_text)


var _pending_delete_node: GraphNode = null
var _delete_dialog: AcceptDialog = null


func _on_node_delete(node: GraphNode) -> void:
	if node.has_method("set_text") and node.file_path == "":
		# Unsaved notepad — ask save or delete
		_pending_delete_node = node
		if _delete_dialog == null:
			_delete_dialog = AcceptDialog.new()
			_delete_dialog.title = "Unsaved Notepad"
			_delete_dialog.dialog_text = "Save or delete?"
			_delete_dialog.ok_button_text = "Delete"
			_delete_dialog.add_button("Save", false, "save")
			_delete_dialog.confirmed.connect(_confirm_delete)
			_delete_dialog.custom_action.connect(_on_delete_action)
			add_child(_delete_dialog)
		_delete_dialog.popup_centered()
	else:
		_do_delete(node)


func _do_delete(node: GraphNode) -> void:
	if node.has_method("set_text") and node.file_path != "":
		var f := FileAccess.open(node.file_path, FileAccess.WRITE)
		if f:
			f.store_string(node.text_buffer)
			f.close()
	_clear_connections_for(node.name)
	node.queue_free()


func _confirm_delete() -> void:
	if _pending_delete_node:
		_do_delete(_pending_delete_node)
		_pending_delete_node = null


func _on_delete_action(action: StringName) -> void:
	if action == &"save" and _pending_delete_node:
		notepad_selected.emit(_pending_delete_node)
		_pending_delete_node = null
	_delete_dialog.hide()


func _get_output_text(source: GraphNode, from_port: int) -> String:
	if source.has_method("get_port_output"):
		return source.get_port_output(from_port)
	if source.get("output_value") != null:
		return str(source.get("output_value"))
	if source.get("text_buffer") != null:
		if source.get("enabled") != null and not source.get("enabled"):
			return ""
		return str(source.get("text_buffer"))
	if source.get("file_path") != null:
		return str(source.get("file_path"))
	return ""


func _propagate_text(source: GraphNode) -> void:
	if source.has_signal("edit_pressed") and source.has_method("set_input"):
		_evaluate_subgraph_internals(source)
	_propagate_in(graph_edit, source)


func _propagate_in(gedit: GraphEdit, source: GraphNode) -> void:
	if source.name in _visited:
		return
	_visited.append(source.name)
	if source.has_signal("edit_pressed") and source.has_method("set_input"):
		_evaluate_subgraph_internals(source)
	var connections := gedit.get_connection_list()
	for conn in connections:
		if conn.from_node == source.name:
			var out_text := _get_output_text(source, conn.from_port)
			if out_text == "" and conn.from_port != 0:
				continue
			var target := gedit.get_node_or_null(NodePath(conn.to_node))
			if target and target.has_method("set_input"):
				target.set_input(conn.to_port, out_text)
			elif target and target.has_method("set_text") and out_text != "":
				match conn.to_port:
					1: target.set_text(out_text + target.text_buffer)
					2: target.set_text(target.text_buffer + out_text)
					_: target.set_text(out_text)
			elif target and not target.has_method("set_text") and conn.to_port == 1:
				_execute_node(target)
	_visited.erase(source.name)


func _on_notepad_open(node: GraphNode) -> void:
	notepad_selected.emit(node)


const SAVE_PATH := "user://graph.json"


func _on_new_graph() -> void:
	_clear_all_nodes()
	graph_file_path = ""
	_node_counter = 0


func _clear_all_nodes() -> void:
	for conn in graph_edit.get_connection_list():
		graph_edit.disconnect_node(conn.from_node, conn.from_port, conn.to_node, conn.to_port)
	var to_remove: Array[Node] = []
	for child in graph_edit.get_children():
		if child is GraphNode:
			to_remove.append(child)
	for child in to_remove:
		child.queue_free()


func _on_open_graph() -> void:
	var dialog := FileDialog.new()
	dialog.use_native_dialog = true
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.filters = PackedStringArray(["*.json"])
	dialog.file_selected.connect(_on_graph_file_opened)
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered(Vector2i(600, 400))


func _on_graph_file_opened(path: String) -> void:
	graph_file_path = path
	_clear_all_nodes()
	_node_counter = 0
	_load_from_file(path)


func _on_save_graph() -> void:
	if graph_file_path == "":
		_on_save_graph_as()
	else:
		_save_to_file(graph_file_path)


func _on_save_graph_as() -> void:
	var dialog := FileDialog.new()
	dialog.use_native_dialog = true
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.filters = PackedStringArray(["*.json"])
	dialog.file_selected.connect(_on_graph_file_saved)
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered(Vector2i(600, 400))


func _on_graph_file_saved(path: String) -> void:
	graph_file_path = path
	_save_to_file(path)


func _save_to_file(path: String) -> void:
	var data := _serialize_current_graph()
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))
		f.close()


func _load_from_file(path: String) -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return
	var json := JSON.new()
	if json.parse(f.get_as_text()) != OK:
		f.close()
		return
	f.close()
	var data: Dictionary = json.data
	_build_nodes_from_data(data)


func save_graph() -> void:
	if _graph_stack.is_empty():
		_save_to_file(SAVE_PATH)
		return
	# Inside a subgraph — merge current state up to root, then save root
	var current_data := _serialize_current_graph()
	for i in range(_graph_stack.size() - 1, -1, -1):
		var entry: Dictionary = _graph_stack[i]
		var parent_data: Dictionary = entry["data"]
		var sg_name: String = entry["subgraph_name"]
		for n in parent_data.nodes:
			if n.name == sg_name and n.has("internal"):
				n.internal = current_data
				break
		current_data = parent_data
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(current_data, "\t"))
		f.close()


func load_graph() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	_load_from_file(SAVE_PATH)


func _build_nodes_from_data(data: Dictionary, parent: Node = graph_edit, connect_signals: bool = true) -> void:
	for node_data in data.nodes:
		var node: GraphNode
		if node_data.type == "notepad":
			node = NotepadNodeScene.instantiate()
			node.name = node_data.name
			node.position_offset = Vector2(node_data.x, node_data.y)
			if connect_signals:
				node.open_pressed.connect(_on_notepad_open)
				node.delete_pressed.connect(_on_node_delete)
				node.text_updated.connect(_propagate_text.bind(node))
			parent.add_child(node)
			if node_data.has("text"):
				node.set_text(node_data.text)
			if node_data.has("file_path") and node_data.file_path != "":
				node.set_file(node_data.file_path)
			if node_data.has("enabled"):
				node.enabled = node_data.enabled
		elif node_data.type == "pc":
			node = PCNodeScene.instantiate()
			node.name = node_data.name
			node.position_offset = Vector2(node_data.x, node_data.y)
			if connect_signals:
				node.delete_pressed.connect(_on_node_delete)
				node.text_updated.connect(_propagate_text.bind(node))
			parent.add_child(node)
			if node_data.has("counter"):
				node.counter = int(node_data.counter)
			if node_data.has("max_val"):
				node.max_spin.value = int(node_data.max_val)
			node.call("_update_display")
		elif node_data.type == "bool":
			node = BoolNodeScene.instantiate()
			node.name = node_data.name
			node.position_offset = Vector2(node_data.x, node_data.y)
			if connect_signals:
				node.delete_pressed.connect(_on_node_delete)
				node.text_updated.connect(_propagate_text.bind(node))
			parent.add_child(node)
			if node_data.has("input_a"):
				node.input_a = node_data.input_a
			if node_data.has("input_b"):
				node.input_b = node_data.input_b
			if node_data.has("mode"):
				node.mode_option.selected = int(node_data.mode)
			node.call("_evaluate")
		elif node_data.type == "timer":
			node = TimerNodeScene.instantiate()
			node.name = node_data.name
			node.position_offset = Vector2(node_data.x, node_data.y)
			if connect_signals:
				node.delete_pressed.connect(_on_node_delete)
				node.text_updated.connect(_propagate_text.bind(node))
			parent.add_child(node)
			if node_data.has("prompt_text"):
				node.prompt_text = node_data.prompt_text
				node.output_value = node_data.prompt_text
			if node_data.has("interval_secs"):
				node.interval_secs = float(node_data.interval_secs)
			if node_data.has("mode"):
				node.mode_option.selected = int(node_data.mode)
			if node_data.has("count"):
				node.count_spin.value = int(node_data.count)
			node.call("_update_status")
		elif node_data.type == "find_file":
			node = FindFileNodeScene.instantiate()
			node.name = node_data.name
			node.position_offset = Vector2(node_data.x, node_data.y)
			if connect_signals:
				node.delete_pressed.connect(_on_node_delete)
				node.text_updated.connect(_propagate_text.bind(node))
			parent.add_child(node)
			if node_data.has("file_path") and node_data.file_path != "":
				node.file_path = node_data.file_path
				node.result.text = node_data.file_path
		elif node_data.type == "binary":
			node = BinaryNodeScene.instantiate()
			node.name = node_data.name
			node.position_offset = Vector2(node_data.x, node_data.y)
			if connect_signals:
				node.delete_pressed.connect(_on_node_delete)
				node.text_updated.connect(_propagate_text.bind(node))
			parent.add_child(node)
			if node_data.has("output_value"):
				node.output_value = node_data.output_value
				node.toggle_btn.text = node_data.output_value
		elif node_data.type == "subgraph":
			node = SubGraphNodeScene.instantiate()
			node.name = node_data.name
			node.position_offset = Vector2(node_data.x, node_data.y)
			if connect_signals:
				node.edit_pressed.connect(_on_enter_subgraph)
				node.delete_pressed.connect(_on_node_delete)
				node.text_updated.connect(_propagate_text.bind(node))
			parent.add_child(node)
			if node_data.has("internal"):
				node.internal_data = node_data.internal
				node.call("_rebuild_ports")
			if node_data.has("stored_inputs"):
				node.stored_inputs = node_data.stored_inputs
			if node_data.has("stored_outputs"):
				node.stored_outputs = node_data.stored_outputs
		elif node_data.type == "graph_input":
			node = GraphInputNodeScene.instantiate()
			node.name = node_data.name
			node.position_offset = Vector2(node_data.x, node_data.y)
			if connect_signals:
				node.delete_pressed.connect(_on_node_delete)
				node.text_updated.connect(_propagate_text.bind(node))
			parent.add_child(node)
			if node_data.has("title"):
				node.title = node_data.title
		elif node_data.type == "graph_output":
			node = GraphOutputNodeScene.instantiate()
			node.name = node_data.name
			node.position_offset = Vector2(node_data.x, node_data.y)
			if connect_signals:
				node.delete_pressed.connect(_on_node_delete)
				node.text_updated.connect(_propagate_text.bind(node))
			parent.add_child(node)
			if node_data.has("title"):
				node.title = node_data.title
		else:
			node = ExecNodeScene.instantiate()
			node.name = node_data.name
			node.position_offset = Vector2(node_data.x, node_data.y)
			if connect_signals:
				node.run_pressed.connect(_on_node_run)
				node.delete_pressed.connect(_on_node_delete)
			parent.add_child(node)
		if connect_signals:
			_node_counter = maxi(_node_counter, int(node_data.name.to_int()) + 1)
	if parent is GraphEdit:
		for conn_data in data.connections:
			parent.connect_node(
				StringName(conn_data.from_node), conn_data.from_port,
				StringName(conn_data.to_node), conn_data.to_port
			)


func _evaluate_subgraph_internals(sg_node: GraphNode) -> void:
	var nodes_data: Array = sg_node.internal_data.get("nodes", [])
	if nodes_data.is_empty():
		return
	# 1. Create temp GraphEdit, build real nodes
	var temp := GraphEdit.new()
	add_child(temp)
	temp.visible = false
	_build_nodes_from_data(sg_node.internal_data, temp, false)
	# 2. Connect each node's text_updated to propagate within temp graph
	for child in temp.get_children():
		if child is GraphNode and child.has_signal("text_updated"):
			child.text_updated.connect(_propagate_in.bind(temp, child))
	# 3. Feed stored inputs → triggers propagation naturally
	var idx := 0
	for child in temp.get_children():
		if child is GraphNode and _get_node_type(child) == "graph_input":
			if idx < sg_node.stored_inputs.size():
				child.set_text(sg_node.stored_inputs[idx])
			idx += 1
	# 4. Read outputs
	var outputs: Array = []
	for child in temp.get_children():
		if child is GraphNode and _get_node_type(child) == "graph_output":
			outputs.append(child.text_buffer if child.get("text_buffer") != null else "")
	sg_node.stored_outputs = outputs
	# 5. Clean up
	temp.queue_free()
