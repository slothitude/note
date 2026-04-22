extends GraphNode

const AssemblerScript := preload("res://assembler.gd")

signal delete_pressed(node: GraphNode)
signal text_updated

var input_text: String = ""
var param: String = ""
var result_text: String = ""
var enabled: bool = true
var enable_port: int = -1
var trigger_port: int = -1

var mode_option: OptionButton
var param_edit: LineEdit
var result_label: Label


func _ready() -> void:
	if enable_port >= 0:
		return
	title = "Text"
	mode_option = get_node_or_null("ModeOption")
	param_edit = get_node_or_null("ParamEdit")
	result_label = get_node_or_null("ResultLabel")
	if mode_option:
		mode_option.add_item("Replace")
		mode_option.add_item("Split")
		mode_option.add_item("Upper")
		mode_option.add_item("Lower")
		mode_option.add_item("Trim")
		mode_option.add_item("Length")
		mode_option.add_item("Template")
	AssemblerScript.configure_slots(self, "text")
	_add_control_ports()


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
	if port == 2:
		return result_text
	return ""


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
		input_text = text
	elif port == 1:
		param = text
	_evaluate()


func _evaluate() -> void:
	var mode := 0
	if mode_option:
		mode = mode_option.selected
	var p: String = param
	if param_edit:
		p = param_edit.text

	match mode:
		0:  # Replace: param is "old|new"
			var sep_pos := p.find("|")
			if sep_pos != -1:
				result_text = input_text.replace(p.left(sep_pos), p.substr(sep_pos + 1))
			else:
				result_text = input_text
		1:  # Split: param is delimiter, output first part
			var parts := input_text.split(p, false)
			if parts.size() > 0:
				result_text = str(parts[0])
			else:
				result_text = ""
		2:  # Upper
			result_text = input_text.to_upper()
		3:  # Lower
			result_text = input_text.to_lower()
		4:  # Trim
			result_text = input_text.strip_edges()
		5:  # Length
			result_text = str(input_text.length())
		6:  # Template: replace $1, $2... with split of param by "|"
			var args := p.split("|", false)
			result_text = input_text
			for i in range(args.size()):
				result_text = result_text.replace("$%d" % (i + 1), str(args[i]))
		_:
			result_text = input_text

	if result_label:
		var display := result_text
		if display.length() > 80:
			display = display.left(80) + "..."
		result_label.text = display
	text_updated.emit()


func _on_mode_selected(_idx: int) -> void:
	_evaluate()


func _on_param_changed(_new_text: String) -> void:
	_evaluate()


func _on_delete_pressed() -> void:
	delete_pressed.emit(self)


func get_node_type() -> String:
	return "text"


func serialize_data() -> Dictionary:
	var d: Dictionary = {"input_text": input_text, "param": param, "result_text": result_text}
	if mode_option:
		d["mode"] = mode_option.selected
	if param_edit:
		d["param_edit_text"] = param_edit.text
	return d


func deserialize_data(d: Dictionary) -> void:
	if d.has("input_text"):
		input_text = d.input_text
	if d.has("param"):
		param = d.param
	if d.has("result_text"):
		result_text = d.result_text
	if d.has("mode") and mode_option:
		mode_option.selected = int(d.mode)
	if d.has("param_edit_text") and param_edit:
		param_edit.text = d.param_edit_text


func get_gal_props(nd: Dictionary) -> Dictionary:
	var mode_map: Dictionary = {0: "REPLACE", 1: "SPLIT", 2: "UPPER", 3: "LOWER", 4: "TRIM", 5: "LENGTH", 6: "TEMPLATE"}
	var props: Dictionary = {"mode": mode_map.get(nd.get("mode", 0), "REPLACE")}
	if nd.has("param_edit_text") and nd.param_edit_text != "":
		props["param"] = nd.param_edit_text
	return props
