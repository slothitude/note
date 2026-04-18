extends GraphNode

signal delete_pressed(node: GraphNode)
signal text_updated

var output_value: String = "false"

@onready var toggle_btn: Button = $ToggleBtn


func _ready() -> void:
	title = "Binary"
	set_slot(0, false, 0, Color.WHITE, true, 0, Color.YELLOW)


func _on_toggle_pressed() -> void:
	output_value = "true" if output_value == "false" else "false"
	toggle_btn.text = output_value
	text_updated.emit()


func _on_delete_pressed() -> void:
	delete_pressed.emit(self)
