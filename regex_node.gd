extends GraphNode

const AssemblerScript := preload("res://assembler.gd")

signal delete_pressed(node: GraphNode)
signal text_updated

var input_text: String = ""
var param_text: String = ""
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
	title = "Regex"
	mode_option = get_node_or_null("ModeOption")
	param_edit = get_node_or_null("ParamEdit")
	result_label = get_node_or_null("ResultLabel")
	if mode_option:
		mode_option.add_item("Match")
		mode_option.add_item("Replace")
		mode_option.add_item("Replace All")
		mode_option.add_item("Split")
		mode_option.add_item("Test")
	AssemblerScript.configure_slots(self, "regex")
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
			text_updated.emit()
		return
	if not enabled:
		return
	if port == 0:
		input_text = text
	elif port == 1:
		param_text = text
		if param_edit:
			param_edit.text = text


func _evaluate() -> void:
	var regex := RegEx.new()
	var pattern: String = param_text.strip_edges()
	if param_edit and param_edit.text.strip_edges() != "":
		pattern = param_edit.text.strip_edges()
	var mode: int = 0
	if mode_option:
		mode = mode_option.selected
	if pattern == "" or input_text == "":
		result_text = ""
		_update_result()
		return
	var err := regex.compile(pattern)
	if err != OK:
		result_text = "Error: invalid regex (%d)" % err
		_update_result()
		return
	match mode:
		0:  # MATCH — find all matches, one per line
			var matches: PackedStringArray = []
			var results := regex.search_all(input_text)
			for r in results:
				matches.append(r.get_string())
			result_text = "\n".join(matches)
		1:  # REPLACE — replace first match with param (or empty)
			result_text = regex.sub(input_text, param_edit.text if param_edit else "", false) if mode_option else input_text
		2:  # REPLACE ALL
			result_text = regex.sub(input_text, param_edit.text if param_edit else "", true) if mode_option else input_text
		3:  # SPLIT
			var parts := input_text.split(pattern)
			# Use regex for split
			result_text = ""
			var remaining := input_text
			var split_results: PackedStringArray = []
			while true:
				var m := regex.search(remaining)
				if m == null:
					split_results.append(remaining)
					break
				split_results.append(remaining.left(m.get_start()))
				remaining = remaining.substr(m.get_end())
			result_text = "\n".join(split_results)
		4:  # TEST — returns "true" or "false"
			var m := regex.search(input_text)
			result_text = "true" if m != null else "false"
	_update_result()


func _update_result() -> void:
	if result_label:
		var display := result_text.left(80)
		if result_text.length() > 80:
			display += "..."
		result_label.text = display if display != "" else "(empty)"


func _on_mode_selected(_index: int) -> void:
	pass


func _on_param_changed(new_text: String) -> void:
	param_text = new_text


func _on_delete_pressed() -> void:
	delete_pressed.emit(self)


func get_node_type() -> String:
	return "regex"


func serialize_data() -> Dictionary:
	var d: Dictionary = {}
	if mode_option:
		d["mode"] = mode_option.selected
	if param_edit:
		d["param"] = param_edit.text
	d["result_text"] = result_text
	return d


func deserialize_data(d: Dictionary) -> void:
	if d.has("mode") and mode_option:
		mode_option.selected = int(d.mode)
	if d.has("param"):
		if param_edit:
			param_edit.text = d.param
		param_text = d.param
	if d.has("result_text"):
		result_text = d.result_text


func get_gal_props(nd: Dictionary) -> Dictionary:
	var props: Dictionary = {}
	if nd.has("mode"):
		props["mode"] = ["MATCH", "REPLACE", "REPLACE_ALL", "SPLIT", "TEST"][int(nd.mode)]
	if nd.has("param"):
		props["param"] = nd.param
	return props
