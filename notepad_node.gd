extends GraphNode

signal open_pressed(node: GraphNode)

var text_buffer: String = ""
var file_path: String = ""

@onready var preview: Label = $Preview


func _ready() -> void:
	_update_title()
	set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)


func set_file(path: String) -> void:
	file_path = path
	_update_title()


func _update_title() -> void:
	title = file_path.get_file() if file_path != "" else "Notepad"


func set_text(text: String) -> void:
	text_buffer = text
	_update_preview()


func _update_preview() -> void:
	var lines := text_buffer.split("\n")
	var preview_lines := lines.slice(0, 3)
	var display := "".join(preview_lines)
	if lines.size() > 3:
		display += "..."
	preview.text = display if display != "" else "(empty)"


func _on_open_pressed() -> void:
	open_pressed.emit(self)
