extends GraphNode

const AssemblerScript := preload("res://assembler.gd")

signal delete_pressed(node: GraphNode)
signal text_updated

var _entries: PackedStringArray = []
var _max_entries: int = 50
var _output_text: String = ""
var enabled: bool = true
var enable_port: int = -1
var trigger_port: int = -1

@onready var log_view: RichTextLabel = $LogView
@onready var max_spin: SpinBox = $MaxSpin
@onready var count_label: Label = $CountLabel


func _ready() -> void:
	if enable_port >= 0:
		return
	title = "Log"
	AssemblerScript.configure_slots(self, "log")
	_add_control_ports()
	_update_view()


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


func get_port_output(port: int) -> String:
	if port == 1:
		return _output_text
	return ""


func set_input(port: int, text: String) -> void:
	if port == enable_port:
		enabled = text.strip_edges() != "" and text.strip_edges().to_lower() != "false"
		return
	if port == trigger_port:
		if enabled:
			_output_text = "\n".join(_entries)
			text_updated.emit()
		return
	if not enabled:
		return
	if port == 0:
		_append(text)


func _append(text: String) -> void:
	if max_spin != null:
		_max_entries = int(max_spin.value)
	_entries.append(text)
	while _entries.size() > _max_entries:
		_entries.remove_at(0)
	_update_view()


func _update_view() -> void:
	if log_view != null:
		log_view.text = "\n".join(_entries)
	if count_label != null:
		count_label.text = "%d entries" % _entries.size()


func _on_clear() -> void:
	_entries.clear()
	_output_text = ""
	_update_view()


func _on_delete_pressed() -> void:
	delete_pressed.emit(self)


func get_node_type() -> String:
	return "log"


func serialize_data() -> Dictionary:
	var d: Dictionary = {"entries": "\n".join(_entries)}
	if max_spin != null:
		d["max"] = int(max_spin.value)
	return d


func deserialize_data(d: Dictionary) -> void:
	if d.has("entries") and d.entries != "":
		_entries = d.entries.split("\n")
	if d.has("max") and max_spin != null:
		max_spin.value = float(int(d.max))
		_max_entries = int(d.max)
	_update_view()


func get_gal_props(nd: Dictionary) -> Dictionary:
	var props: Dictionary = {}
	if nd.has("max"):
		props["max"] = str(nd.max)
	return props
