extends GraphNode

signal delete_pressed(node: GraphNode)
signal text_updated

var text_buffer: String = ""


func _ready() -> void:
	title = "Output"
	set_slot(0, true, 0, Color.GREEN, false, 0, Color.WHITE)


func set_text(text: String) -> void:
	text_buffer = text
	text_updated.emit()


func _on_delete_pressed() -> void:
	delete_pressed.emit(self)
