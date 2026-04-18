extends GraphNode

signal delete_pressed(node: GraphNode)
signal text_updated

var input_a: String = ""
var input_b: String = ""
var output_value: String = "false"

@onready var result_label: Label = $Result
@onready var mode_option: OptionButton = $ModeOption


func _ready() -> void:
	title = "Bool"
	mode_option.add_item("AND")
	mode_option.add_item("OR")
	mode_option.add_item("NOT")
	set_slot(0, true, 0, Color.CYAN, false, 0, Color.WHITE)
	set_slot(1, true, 0, Color.CYAN, false, 0, Color.WHITE)
	set_slot(2, false, 0, Color.WHITE, true, 0, Color.GREEN)
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
	var mode := mode_option.selected
	match mode:
		0: output_value = "true" if (has_a and has_b) else "false"
		1: output_value = "true" if (has_a or has_b) else "false"
		2: output_value = "true" if not has_a else "false"
	result_label.text = output_value
	text_updated.emit()


func _on_mode_changed(_index: int) -> void:
	_evaluate()


func _on_delete_pressed() -> void:
	delete_pressed.emit(self)
