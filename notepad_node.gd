extends GraphNode

signal open_pressed(node: GraphNode)
signal delete_pressed(node: GraphNode)
signal text_updated

var text_buffer: String = ""
var file_path: String = ""
var enabled: bool = true
var trigger_port: int = -1

var _pending_op: String = ""
var _pending_text: String = ""

var preview: Label


func _ready() -> void:
	if trigger_port >= 0:
		return
	preview = get_node_or_null("Preview")
	_update_title()
	set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)
	set_slot(1, true, 0, Color.CYAN, false, 0, Color.WHITE)
	set_slot(2, true, 0, Color.GREEN, false, 0, Color.WHITE)
	set_slot(3, true, 0, Color.YELLOW, false, 0, Color.WHITE)
	_add_trigger_port()


func _add_trigger_port() -> void:
	var insert_at := get_child_count()
	for i in range(get_child_count()):
		if get_child(i).name == "OpenButton":
			insert_at = i
			break
	var trigger_lbl := Label.new()
	trigger_lbl.text = "Trigger"
	add_child(trigger_lbl)
	move_child(trigger_lbl, insert_at)
	trigger_port = insert_at
	set_slot(trigger_port, true, 0, Color.RED, false, 0, Color.WHITE)


func set_file(path: String) -> void:
	file_path = path
	_update_title()


func _update_title() -> void:
	title = file_path.get_file() if file_path != "" else "Notepad"


func set_text(text: String) -> void:
	if not enabled:
		return
	text_buffer = text
	_update_preview()
	text_updated.emit()


func set_input(port: int, text: String) -> void:
	if port == 3:
		enabled = text.strip_edges().to_lower() != "false" and text.strip_edges() != ""
		return
	if port == trigger_port:
		if enabled and _pending_op != "":
			_apply_pending()
			text_updated.emit()
		return
	if not enabled:
		return
	# Data ports: store pending, don't apply yet
	match port:
		0: _pending_op = "set"; _pending_text = text
		1: _pending_op = "prepend"; _pending_text = text
		2: _pending_op = "append"; _pending_text = text


func _apply_pending() -> void:
	match _pending_op:
		"set": text_buffer = _pending_text
		"prepend": text_buffer = _pending_text + text_buffer
		"append": text_buffer = text_buffer + _pending_text
	_pending_op = ""
	_pending_text = ""
	_update_preview()


func _update_preview() -> void:
	if preview == null:
		return
	var lines := text_buffer.split("\n")
	var preview_lines := lines.slice(0, 3)
	var display := "".join(preview_lines)
	if lines.size() > 3:
		display += "..."
	preview.text = display if display != "" else "(empty)"


func _on_open_pressed() -> void:
	open_pressed.emit(self)


func _on_delete_pressed() -> void:
	delete_pressed.emit(self)
