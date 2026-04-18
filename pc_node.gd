extends GraphNode

signal delete_pressed(node: GraphNode)
signal text_updated

var counter: int = 0

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
	_update_display()


func set_input(port: int, text: String) -> void:
	var max_val: int = int(max_spin.value)
	match port:
		0:  # increment
			counter += 1
			if counter >= max_val:
				counter = 0
		1:  # restart
			counter = 0
		2:  # jump
			if text.is_valid_int():
				counter = int(text) % max_val if max_val > 0 else 0
	_update_display()
	text_updated.emit()


func get_port_output(port: int) -> String:
	if port == 3 + counter:
		return "true"
	return "false"


func _update_display() -> void:
	count_label.text = "Count: %d" % counter


func _on_delete_pressed() -> void:
	delete_pressed.emit(self)
