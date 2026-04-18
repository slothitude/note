extends GraphNode

signal open_pressed(node: GraphNode)
signal delete_pressed(node: GraphNode)
signal text_updated

var text_buffer: String = ""
var file_path: String = ""
var enabled: bool = true

@onready var preview: Label = $Preview


func _ready() -> void:
	_update_title()
	set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)
	set_slot(1, true, 0, Color.CYAN, false, 0, Color.WHITE)
	set_slot(2, true, 0, Color.GREEN, false, 0, Color.WHITE)
	set_slot(3, true, 0, Color.YELLOW, false, 0, Color.WHITE)


func set_file(path: String) -> void:
	file_path = path
	_update_title()


func _update_title() -> void:
	title = file_path.get_file() if file_path != "" else "Notepad"


func set_text(text: String) -> void:
	if not enabled:
		return
	text_buffer = text
	_update_preview()
	text_updated.emit()


func set_input(port: int, text: String) -> void:
	if port == 3:
		enabled = text.strip_edges().to_lower() != "false" and text.strip_edges() != ""
		return
	if not enabled:
		return
	match port:
		0: set_text(text)
		1: set_text(text + text_buffer)
		2: set_text(text_buffer + text)


func _update_preview() -> void:
	var lines := text_buffer.split("\n")
	var preview_lines := lines.slice(0, 3)
	var display := "".join(preview_lines)
	if lines.size() > 3:
		display += "..."
	preview.text = display if display != "" else "(empty)"


func _on_open_pressed() -> void:
	open_pressed.emit(self)


func _on_delete_pressed() -> void:
	delete_pressed.emit(self)
