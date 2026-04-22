extends GraphNode

const AssemblerScript := preload("res://assembler.gd")

signal delete_pressed(node: GraphNode)
signal text_updated

var input_a: String = ""
var input_b: String = ""
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
	title = "Merge"
	mode_option = get_node_or_null("ModeOption")
	param_edit = get_node_or_null("ParamEdit")
	result_label = get_node_or_null("ResultLabel")
	if mode_option:
		mode_option.add_item("Concat")
		mode_option.add_item("Zip")
		mode_option.add_item("Join")
		mode_option.add_item("Interleave")
		mode_option.add_item("Template")
	AssemblerScript.configure_slots(self, "merge")
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
	if port == 3:
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
	match port:
		0:
			input_a = text
			_evaluate()
		1:
			input_b = text
			_evaluate()
		2:
			param = text
			if param_edit:
				param_edit.text = text
			_evaluate()


func _evaluate() -> void:
	if mode_option == null:
		return
	# Sync param from edit if needed
	if param_edit and param_edit.text != "" and param == "":
		param = param_edit.text
	var sep := param if param != "" else ","
	var a_lines: PackedStringArray = input_a.split("\n")
	var b_lines: PackedStringArray = input_b.split("\n")
	# Strip empty trailing entries
	while a_lines.size() > 0 and a_lines[-1] == "":
		a_lines.remove_at(a_lines.size() - 1)
	while b_lines.size() > 0 and b_lines[-1] == "":
		b_lines.remove_at(b_lines.size() - 1)

	match mode_option.selected:
		0:  # Concat — A + B joined by separator
			result_text = input_a + sep + input_b
		1:  # Zip — pair lines: a1,b1\na2,b2
			var lines: PackedStringArray = []
			var max_len := maxi(a_lines.size(), b_lines.size())
			for i in range(max_len):
				var a_val := a_lines[i] if i < a_lines.size() else ""
				var b_val := b_lines[i] if i < b_lines.size() else ""
				lines.append(a_val + sep + b_val)
			result_text = "\n".join(lines)
		2:  # Join — join all lines with separator
			var all_lines: Array = []
			for l in a_lines:
				all_lines.append(l)
			for l in b_lines:
				all_lines.append(l)
			result_text = sep.join(all_lines)
		3:  # Interleave — a1,b1,a2,b2
			var lines: PackedStringArray = []
			var max_len := maxi(a_lines.size(), b_lines.size())
			for i in range(max_len):
				if i < a_lines.size():
					lines.append(a_lines[i])
				if i < b_lines.size():
					lines.append(b_lines[i])
			result_text = "\n".join(lines)
		4:  # Template — replace {} in param with A, {2} with B
			result_text = param.replace("{}", input_a).replace("{1}", input_a).replace("{2}", input_b)

	if result_label:
		result_label.text = result_text.left(80) + ("..." if result_text.length() > 80 else "")
	text_updated.emit()


func _on_mode_selected(_index: int) -> void:
	_evaluate()


func _on_param_changed(text: String) -> void:
	param = text
	_evaluate()


func _on_delete_pressed() -> void:
	delete_pressed.emit(self)


func get_node_type() -> String:
	return "merge"


func serialize_data() -> Dictionary:
	var d: Dictionary = {
		"input_a": input_a,
		"input_b": input_b,
		"param": param,
		"result_text": result_text,
	}
	if mode_option != null:
		d["mode"] = mode_option.selected
	return d


func deserialize_data(d: Dictionary) -> void:
	if d.has("input_a"):
		input_a = d.input_a
	if d.has("input_b"):
		input_b = d.input_b
	if d.has("param"):
		param = d.param
		if param_edit:
			param_edit.text = d.param
	if d.has("result_text"):
		result_text = d.result_text
	if d.has("mode") and mode_option != null:
		mode_option.selected = int(d.mode)


func get_gal_props(nd: Dictionary) -> Dictionary:
	var props: Dictionary = {}
	var mode_map: Dictionary = {0: "CONCAT", 1: "ZIP", 2: "JOIN", 3: "INTERLEAVE", 4: "TEMPLATE"}
	props["mode"] = mode_map.get(nd.get("mode", 0), "CONCAT")
	if nd.has("param") and nd.param != "":
		props["param"] = nd.param
	return props
