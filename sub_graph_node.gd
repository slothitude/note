extends GraphNode

signal edit_pressed(node: GraphNode)
signal delete_pressed(node: GraphNode)
signal text_updated

var internal_data: Dictionary = {"nodes": [], "connections": []}
var stored_inputs: Array = []
var stored_outputs: Array = []


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
		if child.name.begins_with("DynIn") or child.name.begins_with("DynOut"):
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
	while stored_inputs.size() <= port:
		stored_inputs.append("")
	stored_inputs[port] = text
	text_updated.emit()


func get_port_output(port: int) -> String:
	if port >= 0 and port < stored_outputs.size():
		return stored_outputs[port]
	return ""


func _on_edit_pressed() -> void:
	edit_pressed.emit(self)


func _on_delete_pressed() -> void:
	delete_pressed.emit(self)
