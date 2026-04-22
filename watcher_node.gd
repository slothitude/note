extends GraphNode

const AssemblerScript := preload("res://assembler.gd")

signal delete_pressed(node: GraphNode)
signal text_updated

var value: String = ""
var enabled: bool = true
var enable_port: int = -1
var trigger_port: int = -1

var value_label: RichTextLabel


func _ready() -> void:
	if enable_port >= 0:
		return
	title = "Watcher"
	value_label = get_node_or_null("ValueLabel")
	AssemblerScript.configure_slots(self, "watcher")
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
	if port == 0:
		return value
	return ""


func set_input(port: int, text: String) -> void:
	if port == enable_port:
		enabled = text.strip_edges() != "" and text.strip_edges().to_lower() != "false"
		return
	if port == trigger_port:
		return
	if not enabled:
		return
	if port == 0:
		value = text
		if value_label:
			value_label.text = value


func _on_delete_pressed() -> void:
	delete_pressed.emit(self)


func get_node_type() -> String:
	return "watcher"


func serialize_data() -> Dictionary:
	return {"value": value}


func deserialize_data(d: Dictionary) -> void:
	if d.has("value"):
		value = d.value
		if value_label:
			value_label.text = value


func get_gal_props(_nd: Dictionary) -> Dictionary:
	return {}
