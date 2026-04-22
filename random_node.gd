extends GraphNode

const AssemblerScript := preload("res://assembler.gd")

signal delete_pressed(node: GraphNode)
signal text_updated

var input_min: String = ""
var input_max: String = ""
var result_text: String = ""
var enabled: bool = true
var enable_port: int = -1
var trigger_port: int = -1

var mode_option: OptionButton
var result_label: Label


func _ready() -> void:
	if enable_port >= 0:
		return
	title = "Random"
	mode_option = get_node_or_null("ModeOption")
	result_label = get_node_or_null("ResultLabel")
	if mode_option:
		mode_option.add_item("Number")
		mode_option.add_item("Float")
		mode_option.add_item("Pick")
		mode_option.add_item("UUID")
	AssemblerScript.configure_slots(self, "random")
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
		input_min = text.strip_edges()
	elif port == 1:
		input_max = text.strip_edges()
	_evaluate()


func _evaluate() -> void:
	var mode := 0
	if mode_option:
		mode = mode_option.selected

	match mode:
		0:  # Number: random int between min and max
			var lo := int(input_min.to_float()) if input_min != "" else 0
			var hi := int(input_max.to_float()) if input_max != "" else 100
			if hi <= lo:
				hi = lo + 1
			result_text = str(randi_range(lo, hi - 1))
		1:  # Float: random float between min and max
			var lo: float = input_min.to_float() if input_min != "" else 0.0
			var hi: float = input_max.to_float() if input_max != "" else 1.0
			if hi <= lo:
				hi = lo + 1.0
			result_text = str(randf_range(lo, hi)).left(8)
		2:  # Pick: random pick from newline-separated input_min
			var items := input_min.split("\n", false)
			if items.is_empty():
				result_text = ""
			else:
				var idx := randi() % items.size()
				result_text = str(items[idx]).strip_edges()
		3:  # UUID
			result_text = _generate_uuid()
		_:
			result_text = ""

	if result_label:
		result_label.text = result_text
	text_updated.emit()


func _generate_uuid() -> String:
	var hex := "0123456789abcdef"
	var uuid := ""
	for i in range(36):
		if i == 8 or i == 13 or i == 18 or i == 23:
			uuid += "-"
		else:
			uuid += hex[randi() % 16]
	# Set version 4
	uuid = uuid.left(14) + "4" + uuid.right(-15)
	# Set variant
	var variant_char := hex[8 + randi() % 4]
	uuid = uuid.left(19) + variant_char + uuid.right(-20)
	return uuid


func _on_mode_selected(_idx: int) -> void:
	_evaluate()


func _on_delete_pressed() -> void:
	delete_pressed.emit(self)


func get_node_type() -> String:
	return "random"


func serialize_data() -> Dictionary:
	var d: Dictionary = {"input_min": input_min, "input_max": input_max, "result_text": result_text}
	if mode_option:
		d["mode"] = mode_option.selected
	return d


func deserialize_data(d: Dictionary) -> void:
	if d.has("input_min"):
		input_min = d.input_min
	if d.has("input_max"):
		input_max = d.input_max
	if d.has("result_text"):
		result_text = d.result_text
	if d.has("mode") and mode_option:
		mode_option.selected = int(d.mode)
	if result_label:
		result_label.text = result_text


func get_gal_props(nd: Dictionary) -> Dictionary:
	var mode_map: Dictionary = {0: "NUMBER", 1: "FLOAT", 2: "PICK", 3: "UUID"}
	return {"mode": mode_map.get(nd.get("mode", 0), "NUMBER")}
