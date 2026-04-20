extends GraphNode

signal delete_pressed(node: GraphNode)
signal text_updated

var input_a: String = ""
var input_b: String = ""
var output_value: String = "0"
var is_math_node := true
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
	title = "Math"
	if mode_option != null:
		mode_option.add_item("ADD")
		mode_option.add_item("SUB")
		mode_option.add_item("MUL")
		mode_option.add_item("DIV")
		mode_option.add_item("MOD")
		mode_option.add_item("POW")
	set_slot(0, true, 0, Color.CYAN, false, 0, Color.WHITE)
	set_slot(1, true, 0, Color.CYAN, false, 0, Color.WHITE)
	set_slot(2, false, 0, Color.WHITE, false, 0, Color.WHITE)
	set_slot(3, false, 0, Color.WHITE, true, 0, Color.GREEN)
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
	var a: float = input_a.to_float() if input_a != "" else 0.0
	var b: float = input_b.to_float() if input_b != "" else 0.0
	var mode := mode_option.selected if mode_option != null else 0
	match mode:
		0: output_value = _fmt(a + b)
		1: output_value = _fmt(a - b)
		2: output_value = _fmt(a * b)
		3: output_value = "ERROR" if b == 0.0 else _fmt(a / b)
		4: output_value = "ERROR" if b == 0.0 else _fmt(fmod(a, b))
		5: output_value = _fmt(pow(a, b))
	if result_label != null:
		result_label.text = output_value
	text_updated.emit()


func _fmt(v: float) -> String:
	if is_nan(v) or is_inf(v):
		return "ERROR"
	if v == floor(v) and abs(v) < 9007199254740992.0:
		return str(int(v))
	return str(v)


func _on_mode_changed(_index: int) -> void:
	_evaluate()


func _on_delete_pressed() -> void:
	delete_pressed.emit(self)
