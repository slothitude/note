extends GraphNode

signal delete_pressed(node: GraphNode)
signal text_updated

var input_a: String = ""
var input_b: String = ""
var output_value: String = "false"
var _last_port: int = 0

@onready var result_label: Label = $Result


func _ready() -> void:
	title = "Bool"
	set_slot(0, true, 0, Color.CYAN, false, 0, Color.WHITE)
	set_slot(1, true, 0, Color.CYAN, false, 0, Color.WHITE)
	set_slot(2, false, 0, Color.WHITE, true, 0, Color.GREEN)


func set_text(text: String) -> void:
	if _last_port == 0:
		input_a = text.strip_edges()
	else:
		input_b = text.strip_edges()
	_evaluate()


func set_input(port: int, text: String) -> void:
	if port == 0:
		input_a = text.strip_edges()
	else:
		input_b = text.strip_edges()
	_evaluate()


func _evaluate() -> void:
	var has_a := input_a != ""
	var has_b := input_b != ""
	output_value = "true" if (has_a and has_b) else "false"
	result_label.text = output_value
	text_updated.emit()


func _on_delete_pressed() -> void:
	delete_pressed.emit(self)
