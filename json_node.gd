extends GraphNode

signal delete_pressed(node: GraphNode)
signal text_updated

var json_text: String = ""
var path: String = ""
var result_value: String = ""
var error_text: String = ""
var enabled: bool = true
var enable_port: int = -1
var trigger_port: int = -1

var result_label: Label


func _ready() -> void:
	if enable_port >= 0:
		return
	result_label = get_node_or_null("Result")
	title = "JSON"
	set_slot(0, true, 0, Color.CYAN, false, 0, Color.WHITE)
	set_slot(1, true, 0, Color.MAGENTA, false, 0, Color.WHITE)
	set_slot(2, false, 0, Color.WHITE, true, 0, Color.GREEN)
	set_slot(3, false, 0, Color.WHITE, true, 0, Color.RED)
	_add_control_ports()
	_update_display()


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


func set_input(port: int, text: String) -> void:
	if port == enable_port:
		enabled = text.strip_edges() != "" and text.strip_edges().to_lower() != "false"
		return
	if port == trigger_port:
		if enabled:
			_evaluate()
		return
	if not enabled:
		return
	if port == 0:
		json_text = text
	elif port == 1:
		path = text.strip_edges()


func get_port_output(port: int) -> String:
	if port == 2:
		return result_value
	if port == 3:
		return error_text
	return ""


func _evaluate() -> void:
	result_value = ""
	error_text = ""

	if json_text.strip_edges() == "":
		error_text = "No JSON input"
		_update_display()
		text_updated.emit()
		return

	var parsed = JSON.parse_string(json_text)
	if parsed == null:
		error_text = "Invalid JSON"
		_update_display()
		text_updated.emit()
		return

	if path == "":
		result_value = _value_to_string(parsed)
		_update_display()
		text_updated.emit()
		return

	var current = parsed
	var parts := path.split(".")
	for part in parts:
		if current == null:
			error_text = "Path not found: %s" % path
			result_value = ""
			_update_display()
			text_updated.emit()
			return
		if current is Dictionary:
			if not current.has(part):
				error_text = "Key not found: %s" % part
				result_value = ""
				_update_display()
				text_updated.emit()
				return
			current = current[part]
		elif current is Array:
			if not part.is_valid_int():
				error_text = "Invalid array index: %s" % part
				result_value = ""
				_update_display()
				text_updated.emit()
				return
			var idx := int(part)
			if idx < 0 or idx >= current.size():
				error_text = "Index out of range: %d" % idx
				result_value = ""
				_update_display()
				text_updated.emit()
				return
			current = current[idx]
		else:
			error_text = "Cannot traverse into %s" % part
			result_value = ""
			_update_display()
			text_updated.emit()
			return

	result_value = _value_to_string(current)
	_update_display()
	text_updated.emit()


func _value_to_string(value) -> String:
	if value == null:
		return "null"
	if value is bool:
		return "true" if value else "false"
	if value is float or value is int:
		return str(value)
	if value is String:
		return value
	return JSON.stringify(value)


func _update_display() -> void:
	if result_label:
		if error_text != "":
			result_label.text = "ERR: %s" % error_text
		elif result_value != "":
			var display := result_value
			if display.length() > 40:
				display = display.left(40) + "..."
			result_label.text = display
		else:
			result_label.text = ""


func _on_delete_pressed() -> void:
	delete_pressed.emit(self)
