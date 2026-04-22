extends GraphNode

const AssemblerScript := preload("res://assembler.gd")

signal delete_pressed(node: GraphNode)
signal text_updated

var file_path: String = ""
var enabled: bool = true
var enable_port: int = -1
var trigger_port: int = -1
var _search_text: String = ""

@onready var result: Label = $Result


func _ready() -> void:
	title = "Find File"
	AssemblerScript.configure_slots(self, "find_file")
	_add_control_ports()


func _add_control_ports() -> void:
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
	var trigger_lbl := Label.new()
	trigger_lbl.text = "Trigger"
	add_child(trigger_lbl)
	move_child(trigger_lbl, insert_at + 1)
	trigger_port = insert_at + 1
	set_slot(trigger_port, true, 0, Color.RED, false, 0, Color.WHITE)


func set_input(port: int, text: String) -> void:
	if port == enable_port:
		enabled = text.strip_edges() != "" and text.strip_edges().to_lower() != "false"
		return
	if port == trigger_port:
		if enabled and _search_text != "":
			_do_search(_search_text)
		return
	if not enabled:
		return
	if port == 0:
		_search_text = text.strip_edges()


func _do_search(fname: String) -> void:
	if fname == "":
		file_path = "false"
		result.text = "(empty)"
		return
	var found := _search_for_file(fname)
	file_path = found if found != "" else "false"
	result.text = found if found != "" else "false"
	text_updated.emit()


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


func get_node_type() -> String:
	return "find_file"


func serialize_data() -> Dictionary:
	return {"file_path": file_path}


func deserialize_data(d: Dictionary) -> void:
	if d.has("file_path") and d.file_path != "":
		file_path = d.file_path
		if result != null:
			result.text = file_path


func get_gal_props(_nd: Dictionary) -> Dictionary:
	return {}
