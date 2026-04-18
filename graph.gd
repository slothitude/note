extends VBoxContainer

signal notepad_selected(node: GraphNode)

const NotepadNodeScene := preload("res://notepad_node.tscn")
const ExecNodeScene := preload("res://exec_node.tscn")

var _node_counter := 0

@onready var graph_edit: GraphEdit = %GraphEdit


func _ready() -> void:
	_setup_style()
	_connect_signals()
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
	graph_edit.add_child(node)


func add_notepad_node() -> void:
	var node := NotepadNodeScene.instantiate()
	node.name = "Notepad%d" % _node_counter
	_node_counter += 1
	node.position_offset = Vector2(100 + (_node_counter * 30), 100 + (_node_counter * 30))
	node.open_pressed.connect(_on_notepad_open)
	graph_edit.add_child(node)


func add_exec_node() -> void:
	var node := ExecNodeScene.instantiate()
	node.name = "Exec%d" % _node_counter
	_node_counter += 1
	node.position_offset = Vector2(400 + (_node_counter * 30), 100 + (_node_counter * 30))
	node.run_pressed.connect(_on_node_run)
	graph_edit.add_child(node)


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
				target.set_text(stdout_text)

	if stderr_text != "":
		for conn in connections:
			if conn.from_node == exec_node.name and conn.from_port == 1:
				var target := graph_edit.get_node_or_null(NodePath(conn.to_node))
				if target and target.has_method("set_text"):
					target.set_text(stderr_text)


func _on_notepad_open(node: GraphNode) -> void:
	notepad_selected.emit(node)
