extends GraphNode

const AssemblerScript := preload("res://assembler.gd")

signal delete_pressed(node: GraphNode)
signal text_updated

var input_text: String = ""
var param_text: String = ""
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
	title = "CSV"
	mode_option = get_node_or_null("ModeOption")
	param_edit = get_node_or_null("ParamEdit")
	result_label = get_node_or_null("ResultLabel")
	if mode_option:
		mode_option.add_item("Parse")      # 0 — parse CSV into JSON rows
		mode_option.add_item("Header")     # 1 — get header row
		mode_option.add_item("Get Col")    # 2 — extract column by name
		mode_option.add_item("Get Row")    # 3 — get row by index
		mode_option.add_item("Filter")     # 4 — filter rows by column value
		mode_option.add_item("Count")      # 5 — count rows
	AssemblerScript.configure_slots(self, "csv")
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
			text_updated.emit()
		return
	if not enabled:
		return
	if port == 0:
		input_text = text
	elif port == 1:
		param_text = text
		if param_edit:
			param_edit.text = text


func _evaluate() -> void:
	var mode: int = 0
	if mode_option:
		mode = mode_option.selected
	var param: String = param_text.strip_edges()
	if param_edit and param_edit.text.strip_edges() != "":
		param = param_edit.text.strip_edges()
	if input_text == "":
		result_text = ""
		_update_result()
		return

	var lines: PackedStringArray = input_text.split("\n")
	# Filter empty lines
	var rows: PackedStringArray = []
	for line in lines:
		if line.strip_edges() != "":
			rows.append(line.strip_edges())

	if rows.is_empty():
		result_text = ""
		_update_result()
		return

	match mode:
		0:  # Parse — convert to JSON array of objects
			_parse_csv(rows)
		1:  # Header — return first row
			result_text = rows[0] if rows.size() > 0 else ""
		2:  # Get Col — extract column values
			_get_column(rows, param)
		3:  # Get Row — get specific row by index
			var idx := param.to_int() if param.is_valid_int() else 0
			if idx >= 0 and idx < rows.size():
				result_text = rows[idx]
			else:
				result_text = ""
		4:  # Filter — rows where column contains value
			_filter_rows(rows, param)
		5:  # Count — number of data rows
			result_text = str(rows.size() - 1)  # exclude header
	_update_result()


func _parse_csv(rows: PackedStringArray) -> void:
	if rows.size() < 2:
		result_text = "[]"
		return
	var headers: PackedStringArray = rows[0].split(",")
	var result: Array = []
	for i in range(1, rows.size()):
		var cols: PackedStringArray = rows[i].split(",")
		var row_dict: Dictionary = {}
		for j in range(mini(headers.size(), cols.size())):
			row_dict[headers[j].strip_edges()] = cols[j].strip_edges()
		result.append(row_dict)
	result_text = JSON.stringify(result)


func _get_column(rows: PackedStringArray, col_name: String) -> void:
	if rows.is_empty() or col_name == "":
		result_text = ""
		return
	var headers: PackedStringArray = rows[0].split(",")
	var col_idx := -1
	for i in range(headers.size()):
		if headers[i].strip_edges() == col_name:
			col_idx = i
			break
	if col_idx < 0:
		result_text = "Error: column '%s' not found" % col_name
		return
	var values: PackedStringArray = []
	for i in range(1, rows.size()):
		var cols: PackedStringArray = rows[i].split(",")
		if col_idx < cols.size():
			values.append(cols[col_idx].strip_edges())
	result_text = "\n".join(values)


func _filter_rows(rows: PackedStringArray, filter_expr: String) -> void:
	# Format: column=value
	var eq_pos := filter_expr.find("=")
	if eq_pos < 0:
		result_text = "Error: filter requires column=value"
		return
	var col_name: String = filter_expr.left(eq_pos).strip_edges()
	var match_val: String = filter_expr.substr(eq_pos + 1).strip_edges()
	var headers: PackedStringArray = rows[0].split(",")
	var col_idx := -1
	for i in range(headers.size()):
		if headers[i].strip_edges() == col_name:
			col_idx = i
			break
	if col_idx < 0:
		result_text = "Error: column '%s' not found" % col_name
		return
	var filtered: PackedStringArray = [rows[0]]  # keep header
	for i in range(1, rows.size()):
		var cols: PackedStringArray = rows[i].split(",")
		if col_idx < cols.size() and cols[col_idx].strip_edges() == match_val:
			filtered.append(rows[i])
	result_text = "\n".join(filtered)


func _update_result() -> void:
	if result_label:
		var display := result_text.left(80)
		if result_text.length() > 80:
			display += "..."
		result_label.text = display if display != "" else "(empty)"


func _on_mode_selected(_index: int) -> void:
	pass


func _on_param_changed(new_text: String) -> void:
	param_text = new_text


func _on_delete_pressed() -> void:
	delete_pressed.emit(self)


func get_node_type() -> String:
	return "csv"


func serialize_data() -> Dictionary:
	var d: Dictionary = {}
	if mode_option:
		d["mode"] = mode_option.selected
	if param_edit:
		d["param"] = param_edit.text
	d["result_text"] = result_text
	return d


func deserialize_data(d: Dictionary) -> void:
	if d.has("mode") and mode_option:
		mode_option.selected = int(d.mode)
	if d.has("param"):
		if param_edit:
			param_edit.text = d.param
		param_text = d.param
	if d.has("result_text"):
		result_text = d.result_text


func get_gal_props(nd: Dictionary) -> Dictionary:
	var props: Dictionary = {}
	if nd.has("mode"):
		var modes := ["PARSE", "HEADER", "GET_COL", "GET_ROW", "FILTER", "COUNT"]
		var m: int = int(nd.mode)
		if m >= 0 and m < modes.size():
			props["mode"] = modes[m]
	if nd.has("param"):
		props["param"] = nd.param
	return props
