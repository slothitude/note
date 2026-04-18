extends VBoxContainer

signal notepad_selected(node: GraphNode)

const NotepadNodeScene := preload("res://notepad_node.tscn")
const ExecNodeScene := preload("res://exec_node.tscn")
const FindFileNodeScene := preload("res://find_file_node.tscn")
const BoolNodeScene := preload("res://bool_node.tscn")

var _node_counter := 0
var _visited: Array[StringName] = []

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


func _on_connection_request(from: StringName, from_port: int, to: StringName, to_port: int) -> void:
	graph_edit.connect_node(from, from_port, to, to_port)
	var source := graph_edit.get_node_or_null(NodePath(from))
	if source and source.has_method("set_text"):
		_propagate_text(source)


func _on_disconnection_request(from: StringName, from_port: int, to: StringName, to_port: int) -> void:
	graph_edit.disconnect_node(from, from_port, to, to_port)


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
	node.position_offset = Vector2(100 + (_node_counter * 20), 100 + (_node_counter * 20))
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
	node.position_offset = Vector2(100 + (_node_counter * 20), 100 + (_node_counter * 20))
	node.open_pressed.connect(_on_notepad_open)
	node.delete_pressed.connect(_on_node_delete)
	node.text_updated.connect(_propagate_text.bind(node))
	graph_edit.add_child(node)


func add_notepad_node() -> void:
	var node := NotepadNodeScene.instantiate()
	node.name = "Notepad%d" % _node_counter
	_node_counter += 1
	node.position_offset = Vector2(100 + (_node_counter * 30), 100 + (_node_counter * 30))
	node.open_pressed.connect(_on_notepad_open)
	node.delete_pressed.connect(_on_node_delete)
	node.text_updated.connect(_propagate_text.bind(node))
	graph_edit.add_child(node)


func add_exec_node() -> void:
	var node := ExecNodeScene.instantiate()
	node.name = "Exec%d" % _node_counter
	_node_counter += 1
	node.position_offset = Vector2(400 + (_node_counter * 30), 100 + (_node_counter * 30))
	node.run_pressed.connect(_on_node_run)
	node.delete_pressed.connect(_on_node_delete)
	graph_edit.add_child(node)


func add_find_file_node() -> void:
	var node := FindFileNodeScene.instantiate()
	node.name = "FindFile%d" % _node_counter
	_node_counter += 1
	node.position_offset = Vector2(200 + (_node_counter * 30), 100 + (_node_counter * 30))
	node.delete_pressed.connect(_on_node_delete)
	node.text_updated.connect(_propagate_text.bind(node))
	graph_edit.add_child(node)


func add_bool_node() -> void:
	var node := BoolNodeScene.instantiate()
	node.name = "Bool%d" % _node_counter
	_node_counter += 1
	node.position_offset = Vector2(200 + (_node_counter * 30), 100 + (_node_counter * 30))
	node.delete_pressed.connect(_on_node_delete)
	node.text_updated.connect(_propagate_text.bind(node))
	graph_edit.add_child(node)(exec_node: GraphNode) -> void:
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
					1: target.set_text(stdout_text + "\n" + target.text_buffer)
					2: target.set_text(target.text_buffer + "\n" + stdout_text)
					_: target.set_text(stdout_text)

	if stderr_text != "":
		for conn in connections:
			if conn.from_node == exec_node.name and conn.from_port == 1:
				var target := graph_edit.get_node_or_null(NodePath(conn.to_node))
				if target and target.has_method("set_text"):
					match conn.to_port:
						1: target.set_text(stderr_text + "\n" + target.text_buffer)
						2: target.set_text(target.text_buffer + "\n" + stderr_text)
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
	if source.get("output_value") != null:
		return str(source.get("output_value"))
	if source.get("text_buffer") != null:
		return str(source.get("text_buffer"))
	if source.get("file_path") != null:
		return str(source.get("file_path"))
	return ""


func _propagate_text(source: GraphNode) -> void:
	if source.name in _visited:
		return
	_visited.append(source.name)
	var connections := graph_edit.get_connection_list()
	for conn in connections:
		if conn.from_node == source.name:
			var out_text := _get_output_text(source, conn.from_port)
			if out_text == "" and conn.from_port != 0:
				continue
			var target := graph_edit.get_node_or_null(NodePath(conn.to_node))
			if target and target.has_method("set_input"):
				target.set_input(conn.to_port, out_text)
			elif target and target.has_method("set_text") and out_text != "":
				match conn.to_port:
					1: target.set_text(out_text + "\n" + target.text_buffer)
					2: target.set_text(target.text_buffer + "\n" + out_text)
					_: target.set_text(out_text)
			elif target and not target.has_method("set_text") and conn.to_port == 2:
				_execute_node(target)
	_visited.erase(source.name)


func _on_notepad_open(node: GraphNode) -> void:
	notepad_selected.emit(node)


const SAVE_PATH := "user://graph.json"


func save_graph() -> void:
	var data := {"nodes": [], "connections": []}
	for child in graph_edit.get_children():
		if child is GraphNode:
			var node_type := "exec"
			if child.has_signal("open_pressed"):
				node_type = "notepad"
			elif child.has_method("set_input"):
				node_type = "bool"
			elif child.get("file_path") != null and not child.has_signal("open_pressed"):
				node_type = "find_file"
			var node_data := {
				"name": child.name,
				"type": node_type,
				"x": child.position_offset.x,
				"y": child.position_offset.y,
			}
			if child.has_signal("open_pressed"):
				node_data["text"] = child.text_buffer
				node_data["file_path"] = child.file_path
			elif child.has_method("set_input"):
				node_data["input_a"] = child.input_a
				node_data["input_b"] = child.input_b
			elif child.get("file_path") != null:
				node_data["file_path"] = child.file_path
			data.nodes.append(node_data)
	for conn in graph_edit.get_connection_list():
		data.connections.append({
			"from_node": String(conn.from_node),
			"from_port": conn.from_port,
			"to_node": String(conn.to_node),
			"to_port": conn.to_port,
		})
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))
		f.close()


func load_graph() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var json := JSON.new()
	if json.parse(f.get_as_text()) != OK:
		f.close()
		return
	f.close()
	var data: Dictionary = json.data
	for node_data in data.nodes:
		var node: GraphNode
		if node_data.type == "notepad":
			node = NotepadNodeScene.instantiate()
			node.name = node_data.name
			node.position_offset = Vector2(node_data.x, node_data.y)
			node.open_pressed.connect(_on_notepad_open)
			node.delete_pressed.connect(_on_node_delete)
			node.text_updated.connect(_propagate_text.bind(node))
			graph_edit.add_child(node)
			if node_data.has("text"):
				node.set_text(node_data.text)
			if node_data.has("file_path") and node_data.file_path != "":
				node.set_file(node_data.file_path)
		elif node_data.type == "bool":
		node = BoolNodeScene.instantiate()
		node.name = node_data.name
		node.position_offset = Vector2(node_data.x, node_data.y)
		node.delete_pressed.connect(_on_node_delete)
		node.text_updated.connect(_propagate_text.bind(node))
		graph_edit.add_child(node)
		if node_data.has("input_a"):
			node.input_a = node_data.input_a
		if node_data.has("input_b"):
			node.input_b = node_data.input_b
		node._evaluate()
	elif node_data.type == "find_file":
			node = FindFileNodeScene.instantiate()
			node.name = node_data.name
			node.position_offset = Vector2(node_data.x, node_data.y)
			node.delete_pressed.connect(_on_node_delete)
			node.text_updated.connect(_propagate_text.bind(node))
			graph_edit.add_child(node)
			if node_data.has("file_path") and node_data.file_path != "":
				node.file_path = node_data.file_path
				node.result.text = node_data.file_path
		else:
			node = ExecNodeScene.instantiate()
			node.name = node_data.name
			node.position_offset = Vector2(node_data.x, node_data.y)
			node.run_pressed.connect(_on_node_run)
			node.delete_pressed.connect(_on_node_delete)
			graph_edit.add_child(node)
		_node_counter = maxi(_node_counter, int(node_data.name.to_int()) + 1)
	for conn_data in data.connections:
		graph_edit.connect_node(
			StringName(conn_data.from_node), conn_data.from_port,
			StringName(conn_data.to_node), conn_data.to_port
		)
