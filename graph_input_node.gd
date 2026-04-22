extends GraphNode

const AssemblerScript := preload("res://assembler.gd")

signal delete_pressed(node: GraphNode)
signal text_updated

var output_value: String = ""


func _ready() -> void:
	title = "Input"
	AssemblerScript.configure_slots(self, "graph_input")


func set_text(text: String) -> void:
	output_value = text
	text_updated.emit()


func _on_delete_pressed() -> void:
	delete_pressed.emit(self)


func get_node_type() -> String:
	return "graph_input"


func serialize_data() -> Dictionary:
	return {"title": title}


func deserialize_data(d: Dictionary) -> void:
	if d.has("title"):
		title = d.title


func get_gal_props(_nd: Dictionary) -> Dictionary:
	return {}
