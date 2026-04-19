extends GraphNode

signal delete_pressed(node: GraphNode)
signal text_updated

var output_value: String = "false"
var enabled: bool = true
var enable_port: int = -1
var trigger_port: int = -1

@onready var toggle_btn: Button = $ToggleBtn


func _ready() -> void:
	title = "Binary"
	set_slot(0, false, 0, Color.WHITE, true, 0, Color.YELLOW)
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


func set_input(port: int, text: String) -> void:
	if port == enable_port:
		enabled = text.strip_edges() != "" and text.strip_edges().to_lower() != "false"
		return
	if port == trigger_port:
		if enabled:
			text_updated.emit()
		return


func _on_toggle_pressed() -> void:
	output_value = "true" if output_value == "false" else "false"
	toggle_btn.text = output_value
	text_updated.emit()


func _on_delete_pressed() -> void:
	delete_pressed.emit(self)
