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
	title = "Loop"
	mode_option = get_node_or_null("ModeOption")
	param_edit = get_node_or_null("ParamEdit")
	result_label = get_node_or_null("ResultLabel")
	if mode_option:
		mode_option.add_item("Each")
		mode_option.add_item("Range")
		mode_option.add_item("Enumerate")
	AssemblerScript.configure_slots(self, "loop")
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


func _apply_template(template: String, item: String, index: int, total: int) -> String:
	return template.replace("${item}", item).replace("${index}", str(index)).replace("${total}", str(total))


func _evaluate() -> void:
	var mode := 0
	if mode_option:
		mode = mode_option.selected
	var p: String = param
	if param_edit:
		p = param_edit.text

	var items: PackedStringArray = []
	match mode:
		0:  # Each: iterate over lines
			items = input_text.split("\n", false)
			for i in range(items.size()):
				items[i] = items[i].strip_edges()
		1:  # Range: iterate N times
			var count := p.to_int() if p.is_valid_int() else 0
			if input_text.strip_edges() != "" and input_text.strip_edges().is_valid_int():
				count = int(input_text.strip_edges())
			for i in range(count):
				items.append(str(i))
		2:  # Enumerate: iterate with index prefix "0: item"
			var lines := input_text.split("\n", false)
			var indexed: PackedStringArray = []
			for i in range(lines.size()):
				indexed.append("%d: %s" % [i, lines[i].strip_edges()])
			items = indexed

	# Build output: apply template if provided, otherwise join items
	var template: String = p
	var results: PackedStringArray = []
	for i in range(items.size()):
		if template != "" and (template.find("${") >= 0):
			results.append(_apply_template(template, items[i], i, items.size()))
		else:
			results.append(items[i])

	result_text = "\n".join(results)

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
	return "loop"


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
	var mode_map: Dictionary = {0: "EACH", 1: "RANGE", 2: "ENUMERATE"}
	var props: Dictionary = {"mode": mode_map.get(nd.get("mode", 0), "EACH")}
	if nd.has("param_edit_text") and nd.param_edit_text != "":
		props["param"] = nd.param_edit_text
	return props
