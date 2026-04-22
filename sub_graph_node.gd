extends GraphNode

signal edit_pressed(node: GraphNode)
signal delete_pressed(node: GraphNode)
signal text_updated

var internal_data: Dictionary = {"nodes": [], "connections": []}
var stored_inputs: Array = []
var stored_outputs: Array = []
var enabled: bool = true
var enable_port: int = -1
var trigger_port: int = -1


func _ready() -> void:
	title = "SubGraph"
	set_slot(0, false, 0, Color.WHITE, false, 0, Color.WHITE)
	_rebuild_ports()


func _rebuild_ports() -> void:
	var inputs: int = 0
	var outputs: int = 0
	for n in internal_data.nodes:
		if n.type == "graph_input":
			inputs += 1
		elif n.type == "graph_output":
			outputs += 1

	# Ensure arrays match port counts
	while stored_inputs.size() < inputs:
		stored_inputs.append("")
	while stored_outputs.size() < outputs:
		stored_outputs.append("")

	# Remove old dynamic children
	for child in get_children():
		if child.name.begins_with("DynIn") or child.name.begins_with("DynOut") or child.name == "EnableLbl" or child.name == "TriggerLbl":
			remove_child(child)
			child.queue_free()

	# Rebuild after EditButton (index 0)
	var idx := 1
	for i in range(inputs):
		var label := Label.new()
		label.name = "DynIn%d" % i
		var iname := _get_input_name(i)
		label.text = "← %s" % iname
		label.layout_mode = 2
		add_child(label)
		move_child(label, idx)
		set_slot(idx, true, 0, Color.CYAN, false, 0, Color.WHITE)
		idx += 1
	for i in range(outputs):
		var label := Label.new()
		label.name = "DynOut%d" % i
		var oname := _get_output_name(i)
		label.text = "%s →" % oname
		label.layout_mode = 2
		add_child(label)
		move_child(label, idx)
		set_slot(idx, false, 0, Color.WHITE, true, 0, Color.GREEN)
		idx += 1

	# Add Enable and Trigger ports
	var enable_lbl := Label.new()
	enable_lbl.name = "EnableLbl"
	enable_lbl.text = "Enable"
	enable_lbl.layout_mode = 2
	add_child(enable_lbl)
	move_child(enable_lbl, idx)
	enable_port = idx
	set_slot(idx, true, 0, Color.YELLOW, false, 0, Color.WHITE)
	idx += 1

	var trigger_lbl := Label.new()
	trigger_lbl.name = "TriggerLbl"
	trigger_lbl.text = "Trigger"
	trigger_lbl.layout_mode = 2
	add_child(trigger_lbl)
	move_child(trigger_lbl, idx)
	trigger_port = idx
	set_slot(idx, true, 0, Color.RED, false, 0, Color.WHITE)
	idx += 1

	# Clear remaining slots
	while idx < 20:
		set_slot(idx, false, 0, Color.WHITE, false, 0, Color.WHITE)
		idx += 1


func _get_input_name(i: int) -> String:
	var count := -1
	for n in internal_data.nodes:
		if n.type == "graph_input":
			count += 1
			if count == i:
				return n.get("name", "in %d" % i) if n is Dictionary else "in %d" % i
	return "in %d" % i


func _get_output_name(i: int) -> String:
	var count := -1
	for n in internal_data.nodes:
		if n.type == "graph_output":
			count += 1
			if count == i:
				return n.get("name", "out %d" % i) if n is Dictionary else "out %d" % i
	return "out %d" % i


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
	while stored_inputs.size() <= port:
		stored_inputs.append("")
	stored_inputs[port] = text
	# Don't emit text_updated — wait for trigger


func get_port_output(port: int) -> String:
	if port >= 0 and port < stored_outputs.size():
		return stored_outputs[port]
	return ""


func _on_edit_pressed() -> void:
	edit_pressed.emit(self)


func _on_delete_pressed() -> void:
	delete_pressed.emit(self)


func get_node_type() -> String:
	return "subgraph"


func serialize_data() -> Dictionary:
	var d: Dictionary = {"internal": internal_data, "stored_inputs": stored_inputs, "stored_outputs": stored_outputs}
	return d


func deserialize_data(d: Dictionary) -> void:
	if d.has("internal"):
		internal_data = d.internal
		call("_rebuild_ports")
	if d.has("stored_inputs"):
		stored_inputs = d.stored_inputs
	if d.has("stored_outputs"):
		stored_outputs = d.stored_outputs


func get_gal_props(_nd: Dictionary) -> Dictionary:
	return {}
