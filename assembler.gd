extends RefCounted

const INPUT_PORTS := {
	"notepad": {"set": 0, "prepend": 1, "append": 2, "enable": 3, "trigger": "trigger_port"},
	"exec": {"command": 0, "trigger": 2, "enable": "enable_port"},
	"find_file": {"query": 0, "enable": "enable_port", "trigger": "trigger_port"},
	"bool": {"a": 0, "b": 1, "enable": "enable_port", "trigger": "trigger_port"},
	"math": {"a": 0, "b": 1, "enable": "enable_port", "trigger": "trigger_port"},
	"if": {"condition": 0, "data": 1, "enable": "enable_port", "trigger": "trigger_port"},
	"binary": {"enable": "enable_port", "trigger": "trigger_port"},
	"pc": {"increment": 0, "restart": 1, "jump": 2, "enable": "enable_port"},
	"timer": {"prompt": 0, "start": 1, "interval": 2, "enable": "enable_port"},
	"http": {"url": 0, "body": 1, "headers": 2, "enable": "enable_port", "trigger": "trigger_port"},
	"button": {},
	"subgraph": {},
	"graph_input": {},
	"graph_output": {},
}

const OUTPUT_PORTS := {
	"notepad": {"out": 0},
	"exec": {"stdout": 0, "stderr": 1},
	"find_file": {"result": 0},
	"bool": {"result": 2},
	"math": {"raw": 2, "result": 3},
	"if": {"true": 2, "false": 3},
	"binary": {"out": 0},
	"pc": {"out0": 3, "out1": 4, "out2": 5, "out3": 6, "out4": 7, "out5": 8},
	"timer": {"out": 5},
	"http": {"response": 3, "error": 4},
	"button": {"out": 0},
	"subgraph": {},
	"graph_input": {"out": 0},
	"graph_output": {},
}

const MODE_NAMES := {
	"bool": {"AND": 0, "OR": 1, "NOT": 2},
	"math": {"ADD": 0, "SUB": 1, "MUL": 2, "DIV": 3, "MOD": 4, "POW": 5},
	"http": {"GET": 0, "POST": 1, "PUT": 2, "DELETE": 3},
	"timer": {"one-shot": 0, "oneshot": 0, "countdown": 1},
}

const VALID_PROPS := {
	"notepad": ["text", "file_path", "enabled"],
	"exec": ["enabled"],
	"find_file": [],
	"bool": ["mode"],
	"math": ["mode"],
	"if": ["condition_text", "data_text"],
	"binary": ["output_value"],
	"pc": ["counter", "max"],
	"timer": ["prompt_text", "interval", "mode", "count"],
	"http": ["url", "body", "headers", "method"],
	"button": ["title"],
	"subgraph": [],
	"graph_input": [],
	"graph_output": [],
}

const TYPE_PREFIXES := {
	"notepad": "Notepad",
	"exec": "Exec",
	"find_file": "FindFile",
	"bool": "Bool",
	"math": "Math",
	"if": "If",
	"binary": "Binary",
	"pc": "PC",
	"timer": "Timer",
	"http": "Http",
	"button": "Button",
	"subgraph": "SubGraph",
	"graph_input": "GInput",
	"graph_output": "GOutput",
}

var _errors: Array[String] = []
var _labels: Dictionary = {}
var _label_types: Dictionary = {}
var _node_data: Array = []
var _wire_data: Array = []
var _trigger_labels: Array = []
var _counters: Dictionary = {}


func parse(source: String) -> Dictionary:
	_errors.clear()
	_labels.clear()
	_label_types.clear()
	_node_data.clear()
	_wire_data.clear()
	_trigger_labels.clear()
	_counters.clear()

	var lines := source.split("\n")
	for i in range(lines.size()):
		var line := lines[i].strip_edges()
		if line == "" or line.begins_with("#"):
			continue
		_parse_line(line, i + 1)

	if _errors.size() > 0:
		return {"nodes": [], "connections": []}

	return {
		"nodes": _node_data,
		"connections": _wire_data,
		"triggers": _trigger_labels,
	}


func get_errors() -> Array[String]:
	return _errors


func _parse_line(line: String, line_num: int) -> void:
	var first_space := line.find(" ")
	var keyword: String
	var rest: String
	if first_space == -1:
		keyword = line
		rest = ""
	else:
		keyword = line.left(first_space)
		rest = line.substr(first_space + 1).strip_edges()

	match keyword:
		"node":
			_parse_node(rest, line_num)
		"set":
			_parse_set(rest, line_num)
		"wire":
			_parse_wire(rest, line_num)
		"trigger":
			_parse_trigger(rest, line_num)
		_:
			_errors.append("Line %d: Unknown keyword '%s'. Expected: node, set, wire, trigger" % [line_num, keyword])


func _parse_node(rest: String, line_num: int) -> void:
	# Format: <label> <type> [at <x> <y>]
	var parts := rest.split(" ", false)
	if parts.size() < 2:
		_errors.append("Line %d: node requires <label> <type>" % line_num)
		return

	var label := parts[0]
	var type := parts[1]

	if not TYPE_PREFIXES.has(type):
		_errors.append("Line %d: Unknown node type '%s'. Valid: %s" % [line_num, type, str(TYPE_PREFIXES.keys())])
		return

	if _labels.has(label):
		_errors.append("Line %d: Label '%s' already declared" % [line_num, label])
		return

	# Generate Godot node name
	var prefix: String = TYPE_PREFIXES[type]
	if not _counters.has(prefix):
		_counters[prefix] = 0
	var gen_name := "%s%d" % [prefix, _counters[prefix]]
	_counters[prefix] += 1

	_labels[label] = gen_name
	_label_types[label] = type

	# Parse optional position
	var pos_x := 0.0
	var pos_y := 0.0
	var has_pos := false
	if parts.size() >= 5 and parts[2] == "at":
		if parts[3].is_valid_float() and parts[4].is_valid_float():
			pos_x = float(parts[3])
			pos_y = float(parts[4])
			has_pos = true
		else:
			_errors.append("Line %d: Invalid position values" % line_num)
			return

	_node_data.append({
		"name": gen_name,
		"_label": label,
		"type": type,
		"x": pos_x,
		"y": pos_y,
		"_has_pos": has_pos,
		"_props": {},
	})


func _parse_set(rest: String, line_num: int) -> void:
	# Format: <label>.<prop> <value>
	var dot_pos := rest.find(".")
	if dot_pos == -1:
		_errors.append("Line %d: set requires <label>.<property> <value>" % line_num)
		return

	var label := rest.left(dot_pos)
	var remaining := rest.substr(dot_pos + 1)
	var space_pos := remaining.find(" ")
	var prop: String
	var value: String
	if space_pos == -1:
		prop = remaining
		value = ""
	else:
		prop = remaining.left(space_pos)
		value = remaining.substr(space_pos + 1).strip_edges()

	if not _labels.has(label):
		_errors.append("Line %d: Unknown label '%s'" % [line_num, label])
		return

	var type: String = _label_types[label]
	if not VALID_PROPS[type].has(prop):
		_errors.append("Line %d: Unknown property '%s' for %s node. Valid: %s" % [line_num, prop, type, str(VALID_PROPS[type])])
		return

	# Validate mode values
	if prop == "mode":
		var mode_map: Dictionary = MODE_NAMES.get(type, {})
		if not mode_map.has(value) and not value.is_valid_int():
			_errors.append("Line %d: Invalid mode '%s' for %s. Valid: %s" % [line_num, value, type, str(mode_map.keys())])
			return

	# Attach to the node data
	for nd in _node_data:
		if nd._label == label:
			nd._props[prop] = value
			return


func _parse_wire(rest: String, line_num: int) -> void:
	# Format: <label>[.<port>] -> <label>[.<port>]
	var arrow_pos := rest.find(" -> ")
	if arrow_pos == -1:
		_errors.append("Line %d: wire requires <source>[.<port>] -> <target>[.<port>]" % line_num)
		return

	var src_part := rest.left(arrow_pos).strip_edges()
	var dst_part := rest.substr(arrow_pos + 4).strip_edges()

	var src_label: String
	var src_port_name: String
	var dot := src_part.find(".")
	if dot == -1:
		src_label = src_part
		src_port_name = "out"
	else:
		src_label = src_part.left(dot)
		src_port_name = src_part.substr(dot + 1)

	var dst_label: String
	var dst_port_name: String
	dot = dst_part.find(".")
	if dot == -1:
		dst_label = dst_part
		dst_port_name = "set"
	else:
		dst_label = dst_part.left(dot)
		dst_port_name = dst_part.substr(dot + 1)

	if not _labels.has(src_label):
		_errors.append("Line %d: Unknown source label '%s'" % [line_num, src_label])
		return
	if not _labels.has(dst_label):
		_errors.append("Line %d: Unknown target label '%s'" % [line_num, dst_label])
		return

	var src_type: String = _label_types[src_label]
	var dst_type: String = _label_types[dst_label]

	# Validate port names
	if not OUTPUT_PORTS[src_type].has(src_port_name):
		_errors.append("Line %d: Unknown output port '%s' for %s" % [line_num, src_port_name, src_type])
		return
	if not INPUT_PORTS[dst_type].has(dst_port_name):
		_errors.append("Line %d: Unknown input port '%s' for %s" % [line_num, dst_port_name, dst_type])
		return

	_wire_data.append({
		"_src_label": src_label,
		"_src_port": src_port_name,
		"_dst_label": dst_label,
		"_dst_port": dst_port_name,
	})


func _parse_trigger(rest: String, line_num: int) -> void:
	var label := rest.strip_edges()
	if not _labels.has(label):
		_errors.append("Line %d: Unknown label '%s'" % [line_num, label])
		return
	_trigger_labels.append(label)
