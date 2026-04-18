extends GraphNode

signal delete_pressed(node: GraphNode)
signal text_updated

var output_value: String = ""


func _ready() -> void:
	title = "Input"
	set_slot(0, false, 0, Color.WHITE, true, 0, Color.CYAN)


func set_text(text: String) -> void:
	output_value = text
	text_updated.emit()


func _on_delete_pressed() -> void:
	delete_pressed.emit(self)
