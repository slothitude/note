extends GraphNode

signal delete_pressed(node: GraphNode)

var file_path: String = ""

@onready var result: Label = $Result


func _ready() -> void:
	title = "Find File"
	set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)
	set_slot(1, false, 0, Color.WHITE, true, 0, Color.GREEN)


func set_text(text: String) -> void:
	file_path = ""
	var fname := text.strip_edges()
	if fname == "":
		result.text = "(empty)"
		return
	var found := _search_for_file(fname)
	file_path = found
	result.text = found if found != "" else "Not found"


func _search_for_file(fname: String) -> String:
	var output := []
	var search_root := "C:\\Users\\aaron\\exploring"
	var args := PackedStringArray(["/C", "where /R " + search_root + " " + fname])
	OS.execute("cmd", args, output)
	for line in output:
		var path := str(line).strip_edges()
		if path != "" and not path.begins_with("INFO:") and not path.begins_with("ERROR:"):
			return path
	return ""


func _on_delete_pressed() -> void:
	delete_pressed.emit(self)
