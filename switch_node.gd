extends GraphNode

const AssemblerScript := preload("res://assembler.gd")

signal delete_pressed(node: GraphNode)
signal text_updated

var input_value: String = ""
var cases_text: String = ""
var enabled: bool = true
var enable_port: int = -1
var trigger_port: int = -1

var case_edit: LineEdit


func _ready() -> void:
	if enable_port >= 0:
		return
	title = "Switch"
	case_edit = get_node_or_null("CaseEdit")
	AssemblerScript.configure_slots(self, "switch")
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
	if port == 1:
		# Default output: the input value if no case matched
		if input_value != "" and not _matched():
			return input_value
		return ""
	if port >= 2:
		# Case outputs: input value if this case matched
		var case_list := _get_cases()
		var idx: int = port - 2
		if idx < case_list.size() and input_value.strip_edges() == case_list[idx].strip_edges():
			return input_value
		return ""
	return ""


func _matched() -> bool:
	var case_list := _get_cases()
	for c in case_list:
		if input_value.strip_edges() == c.strip_edges():
			return true
	return false


func _get_cases() -> PackedStringArray:
	var text: String = cases_text
	if case_edit:
		text = case_edit.text
	if text == "":
		return []
	return text.split(",", false)


func set_input(port: int, text: String) -> void:
	if port == enable_port:
		enabled = text.strip_edges() != "" and text.strip_edges().to_lower() != "false"
		return
	if port == trigger_port:
		if enabled:
			text_updated.emit()
		return
	if not enabled:
		return
	if port == 0:
		input_value = text.strip_edges()
		text_updated.emit()


func _on_cases_changed(_new_text: String) -> void:
	cases_text = case_edit.text if case_edit else ""


func _on_delete_pressed() -> void:
	delete_pressed.emit(self)


func get_node_type() -> String:
	return "switch"


func serialize_data() -> Dictionary:
	var d: Dictionary = {"input_value": input_value}
	if case_edit:
		d["cases"] = case_edit.text
	else:
		d["cases"] = cases_text
	return d


func deserialize_data(d: Dictionary) -> void:
	if d.has("input_value"):
		input_value = d.input_value
	if d.has("cases"):
		cases_text = d.cases
		if case_edit:
			case_edit.text = d.cases


func get_gal_props(nd: Dictionary) -> Dictionary:
	var props: Dictionary = {}
	if nd.has("cases") and nd.cases != "":
		props["cases"] = nd.cases
	return props
