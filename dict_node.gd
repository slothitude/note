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
	title = "Dict"
	mode_option = get_node_or_null("ModeOption")
	param_edit = get_node_or_null("ParamEdit")
	result_label = get_node_or_null("ResultLabel")
	if mode_option:
		mode_option.add_item("Create")
		mode_option.add_item("Get")
		mode_option.add_item("Set")
		mode_option.add_item("Keys")
		mode_option.add_item("Values")
		mode_option.add_item("Merge")
	AssemblerScript.configure_slots(self, "dict")
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


func _parse_dict(text: String) -> Dictionary:
	var d: Dictionary = {}
	if text.strip_edges() == "":
		return d
	var lines := text.split("\n", false)
	for line in lines:
		line = line.strip_edges()
		var colon_idx := line.find(":")
		if colon_idx > 0:
			var key := line.left(colon_idx).strip_edges()
			var val := line.substr(colon_idx + 1).strip_edges()
			d[key] = val
	return d


func _dict_to_text(d: Dictionary) -> String:
	var lines: PackedStringArray = []
	for key in d:
		lines.append("%s: %s" % [key, str(d[key])])
	return "\n".join(lines)


func _evaluate() -> void:
	var mode := 0
	if mode_option:
		mode = mode_option.selected
	var p: String = param
	if param_edit:
		p = param_edit.text

	var d: Dictionary = _parse_dict(input_text)

	match mode:
		0:  # Create: parse key:value pairs from param into dict
			result_text = _dict_to_text(_parse_dict(p))
		1:  # Get: retrieve value by key
			var key: String = p.strip_edges()
			if d.has(key):
				result_text = str(d[key])
			else:
				result_text = ""
		2:  # Set: set key=value and output updated dict
			var eq_idx := p.find("=")
			if eq_idx > 0:
				var key := p.left(eq_idx).strip_edges()
				var val := p.substr(eq_idx + 1).strip_edges()
				d[key] = val
			result_text = _dict_to_text(d)
		3:  # Keys: list all keys
			var keys: PackedStringArray = []
			for key in d:
				keys.append(str(key))
			result_text = "\n".join(keys)
		4:  # Values: list all values
			var vals: PackedStringArray = []
			for key in d:
				vals.append(str(d[key]))
			result_text = "\n".join(vals)
		5:  # Merge: merge param dict into input dict
			var other: Dictionary = _parse_dict(p)
			for key in other:
				d[key] = other[key]
			result_text = _dict_to_text(d)
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
	return "dict"


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
	var mode_map: Dictionary = {0: "CREATE", 1: "GET", 2: "SET", 3: "KEYS", 4: "VALUES", 5: "MERGE"}
	var props: Dictionary = {"mode": mode_map.get(nd.get("mode", 0), "CREATE")}
	if nd.has("param_edit_text") and nd.param_edit_text != "":
		props["param"] = nd.param_edit_text
	return props
