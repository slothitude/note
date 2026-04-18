extends GraphNode

signal edit_pressed(node: GraphNode)
signal delete_pressed(node: GraphNode)

var internal_data: Dictionary = {"nodes": [], "connections": []}


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

	# Remove old dynamic children
	for child in get_children():
		if child.name.begins_with("In") or child.name.begins_with("Out"):
			remove_child(child)
			child.queue_free()

	# Rebuild after EditButton (index 0)
	var edit_btn: Control = $EditButton
	var idx := 1
	for i in range(inputs):
		var label := Label.new()
		label.name = "In%d" % i
		label.text = "← in %d" % i
		label.layout_mode = 2
		add_child(label)
		move_child(label, idx)
		set_slot(idx, true, 0, Color.CYAN, false, 0, Color.WHITE)
		idx += 1
	for i in range(outputs):
		var label := Label.new()
		label.name = "Out%d" % i
		label.text = "out %d →" % i
		label.layout_mode = 2
		add_child(label)
		move_child(label, idx)
		set_slot(idx, false, 0, Color.WHITE, true, 0, Color.GREEN)
		idx += 1

	# Clear remaining slots
	while idx < 20:
		set_slot(idx, false, 0, Color.WHITE, false, 0, Color.WHITE)
		idx += 1


func get_input_count() -> int:
	var count: int = 0
	for n in internal_data.nodes:
		if n.type == "graph_input":
			count += 1
	return count


func _on_edit_pressed() -> void:
	edit_pressed.emit(self)


func _on_delete_pressed() -> void:
	delete_pressed.emit(self)
