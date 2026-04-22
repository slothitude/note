extends GraphNode

const AssemblerScript := preload("res://assembler.gd")

signal delete_pressed(node: GraphNode)
signal text_updated

var text_buffer: String = ""


func _ready() -> void:
	title = "Output"
	AssemblerScript.configure_slots(self, "graph_output")


func set_text(text: String) -> void:
	text_buffer = text
	text_updated.emit()


func _on_delete_pressed() -> void:
	delete_pressed.emit(self)


func get_node_type() -> String:
	return "graph_output"


func serialize_data() -> Dictionary:
	return {"title": title}


func deserialize_data(d: Dictionary) -> void:
	if d.has("title"):
		title = d.title


func get_gal_props(_nd: Dictionary) -> Dictionary:
	return {}
