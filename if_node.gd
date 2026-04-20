extends GraphNode

signal delete_pressed(node: GraphNode)
signal text_updated

var condition_text: String = ""
var data_text: String = ""
var output_true: String = ""
var output_false: String = ""
var enabled: bool = true
var enable_port: int = -1
var trigger_port: int = -1

var result_label: Label


func _ready() -> void:
	if enable_port >= 0:
		return
	result_label = get_node_or_null("Result")
	title = "If"
	set_slot(0, true, 0, Color.YELLOW, false, 0, Color.WHITE)
	set_slot(1, true, 0, Color.CYAN, false, 0, Color.WHITE)
	set_slot(2, false, 0, Color.WHITE, true, 0, Color.GREEN)
	set_slot(3, false, 0, Color.WHITE, true, 0, Color.RED)
	_add_control_ports()
	_evaluate()


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
		condition_text = text.strip_edges()
	elif port == 1:
		data_text = text.strip_edges()


func get_port_output(port: int) -> String:
	if port == 2:
		return output_true
	if port == 3:
		return output_false
	return ""


func _evaluate() -> void:
	var cond := condition_text != "" and condition_text.to_lower() != "false"
	if cond:
		output_true = data_text
		output_false = ""
	else:
		output_true = ""
		output_false = data_text
	if result_label != null:
		result_label.text = "→ true" if cond else "→ false"
	text_updated.emit()


func _on_delete_pressed() -> void:
	delete_pressed.emit(self)
