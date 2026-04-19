extends GraphNode

signal delete_pressed(node: GraphNode)
signal text_updated

var counter: int = 0
var enabled: bool = true
var enable_port: int = -1

@onready var count_label: Label = $CountLabel
@onready var max_spin: SpinBox = $MaxSpin


func _ready() -> void:
	title = "PC"
	set_slot(0, true, 0, Color.CYAN, false, 0, Color.WHITE)
	set_slot(1, true, 0, Color.CYAN, false, 0, Color.WHITE)
	set_slot(2, true, 0, Color.CYAN, false, 0, Color.WHITE)
	set_slot(3, false, 0, Color.WHITE, true, 0, Color.GREEN)
	set_slot(4, false, 0, Color.WHITE, true, 0, Color.GREEN)
	set_slot(5, false, 0, Color.WHITE, true, 0, Color.GREEN)
	set_slot(6, false, 0, Color.WHITE, true, 0, Color.GREEN)
	set_slot(7, false, 0, Color.WHITE, true, 0, Color.GREEN)
	set_slot(8, false, 0, Color.WHITE, true, 0, Color.GREEN)
	_add_enable_port()
	_update_display()


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
	var max_val: int = int(max_spin.value)
	match port:
		0:  # increment
			counter += 1
			if counter >= max_val:
				counter = 0
		1:  # restart
			counter = 0
		2:  # jump
			var val := text.strip_edges()
			if val.is_valid_int():
				counter = int(val) % max_val if max_val > 0 else 0
			elif val.is_valid_float():
				counter = int(float(val)) % max_val if max_val > 0 else 0
	_update_display()
	text_updated.emit()


func get_port_output(port: int) -> String:
	if port == 3 + counter:
		return "true"
	return "false"


func _update_display() -> void:
	count_label.text = "%d" % counter
	count_label.add_theme_font_size_override("font_size", 48)
	for i in range(6):
		var label: Label = get_node_or_null("Out%d" % i)
		if label:
			var state := "true" if i == counter else "false"
			label.text = "→ %d %s" % [i, state]
			label.add_theme_color_override("font_color", Color.GREEN if i == counter else Color.GRAY)


func _on_delete_pressed() -> void:
	delete_pressed.emit(self)
