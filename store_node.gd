extends GraphNode

const AssemblerScript := preload("res://assembler.gd")

signal delete_pressed(node: GraphNode)
signal text_updated

var key_text: String = ""
var value_text: String = ""
var result_text: String = ""
var enabled: bool = true
var enable_port: int = -1
var trigger_port: int = -1

var mode_option: OptionButton
var key_edit: LineEdit
var result_label: Label

# Shared key-value store across all Store nodes
static var _store: Dictionary = {}


func _ready() -> void:
	if enable_port >= 0:
		return
	title = "Store"
	mode_option = get_node_or_null("ModeOption")
	key_edit = get_node_or_null("KeyEdit")
	result_label = get_node_or_null("ResultLabel")
	AssemblerScript.configure_slots(self, "store")
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


func get_port_output(port: int) -> String:
	if port == 2:
		return result_text
	return ""


func set_input(port: int, text: String) -> void:
	if port == enable_port:
		enabled = text.strip_edges() != "" and text.strip_edges().to_lower() != "false"
		return
	if port == trigger_port:
		if enabled:
			_evaluate()
		return
	if not enabled:
		return
	if port == 0:
		key_text = text
	elif port == 1:
		value_text = text
	_evaluate()


func _evaluate() -> void:
	var mode := 0
	if mode_option:
		mode = mode_option.selected
	var key: String = key_text.strip_edges()
	if key_edit and key_edit.text.strip_edges() != "":
		key = key_edit.text.strip_edges()

	match mode:
		0:  # GET
			if _store.has(key):
				result_text = str(_store[key])
			else:
				result_text = ""
		1:  # SET
			_store[key] = value_text
			result_text = "OK"
		2:  # DELETE
			_store.erase(key)
			result_text = "OK"
		3:  # LIST
			var keys: PackedStringArray = []
			for k in _store:
				keys.append(str(k))
			result_text = "\n".join(keys)
		4:  # CLEAR
			_store.clear()
			result_text = "OK"

	if result_label:
		var display := result_text
		if display.length() > 80:
			display = display.left(80) + "..."
		result_label.text = display
	text_updated.emit()


func _on_mode_selected(_idx: int) -> void:
	_evaluate()


func _on_delete_pressed() -> void:
	delete_pressed.emit(self)


func get_node_type() -> String:
	return "store"


func serialize_data() -> Dictionary:
	var d: Dictionary = {"key_text": key_text, "value_text": value_text, "result_text": result_text}
	if mode_option:
		d["mode"] = mode_option.selected
	if key_edit:
		d["key_edit_text"] = key_edit.text
	return d


func deserialize_data(d: Dictionary) -> void:
	if d.has("key_text"):
		key_text = d.key_text
	if d.has("value_text"):
		value_text = d.value_text
	if d.has("result_text"):
		result_text = d.result_text
	if d.has("mode") and mode_option:
		mode_option.selected = int(d.mode)
	if d.has("key_edit_text") and key_edit:
		key_edit.text = d.key_edit_text


func get_gal_props(nd: Dictionary) -> Dictionary:
	var mode_map: Dictionary = {0: "GET", 1: "SET", 2: "DELETE", 3: "LIST", 4: "CLEAR"}
	var props: Dictionary = {"mode": mode_map.get(nd.get("mode", 0), "GET")}
	if nd.has("key_edit_text") and nd.key_edit_text != "":
		props["key"] = nd.key_edit_text
	return props
