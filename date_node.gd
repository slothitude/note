extends GraphNode

const AssemblerScript := preload("res://assembler.gd")

signal delete_pressed(node: GraphNode)
signal text_updated

var input_text: String = ""
var param: String = ""
var result_text: String = ""
var enabled: bool = true
var enable_port: int = -1
var trigger_port: int = -1

var mode_option: OptionButton
var param_edit: LineEdit
var result_label: Label


func _ready() -> void:
	if enable_port >= 0:
		return
	title = "Date"
	mode_option = get_node_or_null("ModeOption")
	param_edit = get_node_or_null("ParamEdit")
	result_label = get_node_or_null("ResultLabel")
	if mode_option:
		mode_option.add_item("Now")
		mode_option.add_item("Format")
		mode_option.add_item("Add")
		mode_option.add_item("Diff")
	AssemblerScript.configure_slots(self, "date")
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
		input_text = text
	elif port == 1:
		param = text
	_evaluate()


func _parse_unix_time(text: String) -> int:
	var s := text.strip_edges()
	if s.is_valid_int():
		return int(s)
	# Try ISO format: YYYY-MM-DD HH:MM:SS or YYYY-MM-DD
	var parts := s.split(" ")
	var date_part := parts[0].split("-")
	if date_part.size() < 3:
		return 0
	var year := int(date_part[0])
	var month := int(date_part[1])
	var day := int(date_part[2])
	var hour := 0
	var minute := 0
	var second := 0
	if parts.size() > 1:
		var time_part := parts[1].split(":")
		if time_part.size() >= 3:
			hour = int(time_part[0])
			minute = int(time_part[1])
			second = int(time_part[2])
		elif time_part.size() >= 2:
			hour = int(time_part[0])
			minute = int(time_part[1])
	var dict := {"year": year, "month": month, "day": day, "hour": hour, "minute": minute, "second": second}
	return Time.get_unix_time_from_datetime_dict(dict)


func _evaluate() -> void:
	var mode := 0
	if mode_option:
		mode = mode_option.selected
	var p: String = param
	if param_edit:
		p = param_edit.text

	var now_dict := Time.get_datetime_dict_from_system()
	var now_unix: int = Time.get_unix_time_from_datetime_dict(now_dict)

	match mode:
		0:  # Now: output current unix timestamp
			result_text = str(now_unix)
		1:  # Format: format timestamp using param as format string
			var ts: int = _parse_unix_time(input_text) if input_text.strip_edges() != "" else now_unix
			var fmt: String = p if p != "" else "%Y-%m-%d %H:%M:%S"
			result_text = Time.get_datetime_string_from_unix_time(ts, false)
		2:  # Add: add duration (e.g. "1d", "2h", "30m") to input timestamp
			var ts: int = _parse_unix_time(input_text) if input_text.strip_edges() != "" else now_unix
			var duration: int = _parse_duration(p)
			result_text = str(ts + duration)
		3:  # Diff: difference between input timestamp and param timestamp
			var ts1: int = _parse_unix_time(input_text) if input_text.strip_edges() != "" else now_unix
			var ts2: int = _parse_unix_time(p) if p.strip_edges() != "" else now_unix
			result_text = str(ts2 - ts1)
		_:
			result_text = input_text

	if result_label:
		var display := result_text
		if display.length() > 80:
			display = display.left(80) + "..."
		result_label.text = display
	text_updated.emit()


func _parse_duration(text: String) -> int:
	var t := text.strip_edges().to_lower()
	if t.is_valid_int():
		return int(t)
	var total := 0
	var current_num := ""
	for c in t:
		if c >= '0' and c <= '9':
			current_num += c
		else:
			if current_num != "":
				var val := int(current_num)
				match c:
					's': total += val
					'm': total += val * 60
					'h': total += val * 3600
					'd': total += val * 86400
					'w': total += val * 604800
				current_num = ""
	if current_num != "" and current_num.is_valid_int():
		total += int(current_num)
	return total


func _on_mode_selected(_idx: int) -> void:
	_evaluate()


func _on_param_changed(_new_text: String) -> void:
	_evaluate()


func _on_delete_pressed() -> void:
	delete_pressed.emit(self)


func get_node_type() -> String:
	return "date"


func serialize_data() -> Dictionary:
	var d: Dictionary = {"input_text": input_text, "param": param, "result_text": result_text}
	if mode_option:
		d["mode"] = mode_option.selected
	if param_edit:
		d["param_edit_text"] = param_edit.text
	return d


func deserialize_data(d: Dictionary) -> void:
	if d.has("input_text"):
		input_text = d.input_text
	if d.has("param"):
		param = d.param
	if d.has("result_text"):
		result_text = d.result_text
	if d.has("mode") and mode_option:
		mode_option.selected = int(d.mode)
	if d.has("param_edit_text") and param_edit:
		param_edit.text = d.param_edit_text


func get_gal_props(nd: Dictionary) -> Dictionary:
	var mode_map: Dictionary = {0: "NOW", 1: "FORMAT", 2: "ADD", 3: "DIFF"}
	var props: Dictionary = {"mode": mode_map.get(nd.get("mode", 0), "NOW")}
	if nd.has("param_edit_text") and nd.param_edit_text != "":
		props["param"] = nd.param_edit_text
	return props
