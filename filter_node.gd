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
	title = "Filter"
	mode_option = get_node_or_null("ModeOption")
	param_edit = get_node_or_null("ParamEdit")
	result_label = get_node_or_null("ResultLabel")
	if mode_option:
		mode_option.add_item("Contains")
		mode_option.add_item("Not Contains")
		mode_option.add_item("Starts With")
		mode_option.add_item("Ends With")
		mode_option.add_item("Regex Match")
		mode_option.add_item("Line Count >")
		mode_option.add_item("Line Count <")
		mode_option.add_item("Unique")
		mode_option.add_item("Head")
		mode_option.add_item("Tail")
	AssemblerScript.configure_slots(self, "filter")
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
	match port:
		0:
			input_text = text
			_evaluate()
		1:
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

	var lines: PackedStringArray = input_text.split("\n")
	var filtered: Array = []

	match mode_option.selected:
		0:  # Contains — keep lines containing param
			for line in lines:
				if line.find(param) >= 0:
					filtered.append(line)
		1:  # Not Contains — keep lines NOT containing param
			for line in lines:
				if line.find(param) == -1:
					filtered.append(line)
		2:  # Starts With
			for line in lines:
				if line.begins_with(param):
					filtered.append(line)
		3:  # Ends With
			for line in lines:
				if line.ends_with(param):
					filtered.append(line)
		4:  # Regex Match
			var regex := RegEx.new()
			if regex.compile(param) == OK:
				for line in lines:
					if regex.search(line) != null:
						filtered.append(line)
			else:
				result_text = "Error: invalid regex"
				if result_label:
					result_label.text = result_text
				text_updated.emit()
				return
		5:  # Line Count >
			var threshold := param.to_int() if param.is_valid_int() else 0
			if lines.size() > threshold:
				filtered = Array(lines)
			else:
				filtered = []
		6:  # Line Count <
			var threshold := param.to_int() if param.is_valid_int() else 0
			if lines.size() < threshold:
				filtered = Array(lines)
			else:
				filtered = []
		7:  # Unique — remove duplicate lines
			var seen: Dictionary = {}
			for line in lines:
				if not seen.has(line):
					seen[line] = true
					filtered.append(line)
		8:  # Head — first N lines
			var n := param.to_int() if param.is_valid_int() else 10
			for i in range(mini(lines.size(), n)):
				filtered.append(lines[i])
		9:  # Tail — last N lines
			var n := param.to_int() if param.is_valid_int() else 10
			var start := maxi(lines.size() - n, 0)
			for i in range(start, lines.size()):
				filtered.append(lines[i])

	result_text = "\n".join(filtered)
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
	return "filter"


func serialize_data() -> Dictionary:
	var d: Dictionary = {
		"input_text": input_text,
		"param": param,
		"result_text": result_text,
	}
	if mode_option != null:
		d["mode"] = mode_option.selected
	return d


func deserialize_data(d: Dictionary) -> void:
	if d.has("input_text"):
		input_text = d.input_text
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
	var mode_map: Dictionary = {0: "CONTAINS", 1: "NOT_CONTAINS", 2: "STARTS_WITH", 3: "ENDS_WITH", 4: "REGEX", 5: "COUNT_GT", 6: "COUNT_LT", 7: "UNIQUE", 8: "HEAD", 9: "TAIL"}
	props["mode"] = mode_map.get(nd.get("mode", 0), "CONTAINS")
	if nd.has("param") and nd.param != "":
		props["param"] = nd.param
	return props
