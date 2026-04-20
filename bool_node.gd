extends GraphNode

signal delete_pressed(node: GraphNode)
signal text_updated

var input_a: String = ""
var input_b: String = ""
var output_value: String = "false"
var enabled: bool = true
var enable_port: int = -1
var trigger_port: int = -1

var result_label: Label
var mode_option: OptionButton


func _ready() -> void:
	if enable_port >= 0:
		return
	result_label = get_node_or_null("Result")
	mode_option = get_node_or_null("ModeOption")
	title = "Bool"
	if mode_option != null:
		mode_option.add_item("AND")
		mode_option.add_item("OR")
		mode_option.add_item("NOT")
	set_slot(0, true, 0, Color.CYAN, false, 0, Color.WHITE)
	set_slot(1, true, 0, Color.CYAN, false, 0, Color.WHITE)
	set_slot(2, false, 0, Color.WHITE, true, 0, Color.GREEN)
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
		input_a = text.strip_edges()
	else:
		input_b = text.strip_edges()


func _evaluate() -> void:
	var has_a := input_a != ""
	var has_b := input_b != ""
	var mode := mode_option.selected if mode_option != null else 0
	match mode:
		0: output_value = "true" if (has_a and has_b) else "false"
		1: output_value = "true" if (has_a or has_b) else "false"
		2: output_value = "true" if not has_a else "false"
	if result_label != null:
		result_label.text = output_value
	text_updated.emit()


func _on_mode_changed(_index: int) -> void:
	_evaluate()


func _on_delete_pressed() -> void:
	delete_pressed.emit(self)
