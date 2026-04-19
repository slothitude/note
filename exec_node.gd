extends GraphNode

signal run_pressed(node: GraphNode)
signal delete_pressed(node: GraphNode)

var enabled: bool = true
var enable_port: int = -1

@onready var run_button: Button = $RunButton


func _ready() -> void:
	title = "Execute"
	set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)
	set_slot(1, false, 0, Color.WHITE, true, 0, Color.RED)
	set_slot(2, true, 0, Color.YELLOW, false, 0, Color.WHITE)
	_add_enable_port()
	print("ExecNode _ready called: ", name)


func _add_enable_port() -> void:
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


func set_input(port: int, text: String) -> void:
	if port == enable_port:
		enabled = text.strip_edges() != "" and text.strip_edges().to_lower() != "false"
		return
	if not enabled:
		return
	if port == 2:
		run_pressed.emit(self)


func _on_run_pressed() -> void:
	if not enabled:
		return
	print("Run button pressed on: ", name)
	run_pressed.emit(self)


func _on_delete_pressed() -> void:
	delete_pressed.emit(self)
