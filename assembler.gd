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
	"json": {"json": 0, "path": 1, "enable": "enable_port", "trigger": "trigger_port"},
	"agent": {"prompt": 0, "system": 1, "url": 2, "enable": "enable_port", "trigger": "trigger_port"},
	"watcher": {"value": 0, "enable": "enable_port", "trigger": "trigger_port"},
	"text": {"input": 0, "param": 1, "enable": "enable_port", "trigger": "trigger_port"},
	"array": {"input": 0, "param": 1, "enable": "enable_port", "trigger": "trigger_port"},
	"switch": {"value": 0, "enable": "enable_port", "trigger": "trigger_port"},
	"random": {"min": 0, "max": 1, "enable": "enable_port", "trigger": "trigger_port"},
	"dict": {"input": 0, "param": 1, "enable": "enable_port", "trigger": "trigger_port"},
	"date": {"input": 0, "param": 1, "enable": "enable_port", "trigger": "trigger_port"},
	"loop": {"input": 0, "param": 1, "enable": "enable_port", "trigger": "trigger_port"},
	"regex": {"input": 0, "param": 1, "enable": "enable_port", "trigger": "trigger_port"},
	"csv": {"input": 0, "param": 1, "enable": "enable_port", "trigger": "trigger_port"},
	"merge": {"a": 0, "b": 1, "param": 2, "enable": "enable_port", "trigger": "trigger_port"},
	"filter": {"input": 0, "param": 1, "enable": "enable_port", "trigger": "trigger_port"},
	"tg_receive": {"token": 0, "enable": "enable_port", "trigger": "trigger_port"},
	"tg_send": {"token": 0, "chat_id": 1, "message": 2, "enable": "enable_port", "trigger": "trigger_port"},
	"file_watch": {"file_path": 0, "enable": "enable_port", "trigger": "trigger_port"},
	"log": {"value": 0, "enable": "enable_port", "trigger": "trigger_port"},
	"store": {"key": 0, "value": 1, "enable": "enable_port", "trigger": "trigger_port"},
	"bar_chart": {"data": 0, "enable": "enable_port", "trigger": "trigger_port"},
	"pie_chart": {"data": 0, "enable": "enable_port", "trigger": "trigger_port"},
	"line_graph": {"data": 0, "enable": "enable_port", "trigger": "trigger_port"},
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
	"json": {"result": 2, "error": 3},
	"agent": {"result": 3, "log": 4},
	"watcher": {"value": 0},
	"text": {"result": 2},
	"array": {"result": 2},
	"switch": {"default": 1, "case0": 2, "case1": 3, "case2": 4},
	"random": {"result": 2},
	"dict": {"result": 2},
	"date": {"result": 2},
	"loop": {"result": 2},
	"regex": {"result": 2},
	"csv": {"result": 2},
	"merge": {"result": 3},
	"filter": {"result": 2},
	"tg_receive": {"message": 1, "chat_id": 2, "from": 3},
	"tg_send": {"result": 3},
	"file_watch": {"content": 1, "path": 2},
	"log": {"log": 1},
	"store": {"result": 2},
	"bar_chart": {"data": 3},
	"pie_chart": {"data": 3},
	"line_graph": {"data": 3},
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
	"text": {"REPLACE": 0, "SPLIT": 1, "UPPER": 2, "LOWER": 3, "TRIM": 4, "LENGTH": 5, "TEMPLATE": 6},
	"array": {"JOIN": 0, "SPLIT": 1, "INDEX": 2, "LENGTH": 3, "PUSH": 4, "SORT": 5},
	"random": {"NUMBER": 0, "FLOAT": 1, "PICK": 2, "UUID": 3},
	"dict": {"CREATE": 0, "GET": 1, "SET": 2, "KEYS": 3, "VALUES": 4, "MERGE": 5},
	"date": {"NOW": 0, "FORMAT": 1, "ADD": 2, "DIFF": 3},
	"loop": {"EACH": 0, "RANGE": 1, "ENUMERATE": 2},
	"regex": {"MATCH": 0, "REPLACE": 1, "REPLACE_ALL": 2, "SPLIT": 3, "TEST": 4},
	"csv": {"PARSE": 0, "HEADER": 1, "GET_COL": 2, "GET_ROW": 3, "FILTER": 4, "COUNT": 5},
	"merge": {"CONCAT": 0, "ZIP": 1, "JOIN": 2, "INTERLEAVE": 3, "TEMPLATE": 4},
	"filter": {"CONTAINS": 0, "NOT_CONTAINS": 1, "STARTS_WITH": 2, "ENDS_WITH": 3, "REGEX": 4, "COUNT_GT": 5, "COUNT_LT": 6, "UNIQUE": 7, "HEAD": 8, "TAIL": 9},
	"store": {"GET": 0, "SET": 1, "DELETE": 2, "LIST": 3, "CLEAR": 4},
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
	"json": ["json_text", "path"],
	"agent": ["model", "max_turns", "api_key", "timeout_secs", "context_limit"],
	"watcher": [],
	"text": ["mode"],
	"array": ["mode", "param"],
	"switch": ["cases"],
	"random": ["mode"],
	"dict": ["mode", "param"],
	"date": ["mode", "param"],
	"loop": ["mode", "param"],
	"regex": ["mode", "param"],
	"csv": ["mode", "param"],
	"merge": ["mode", "param"],
	"filter": ["mode", "param"],
	"tg_receive": ["token", "interval"],
	"tg_send": ["token", "chat_id"],
	"file_watch": ["file_path", "interval"],
	"log": ["max"],
	"store": ["mode", "key"],
	"bar_chart": ["data", "title"],
	"pie_chart": ["data", "title"],
	"line_graph": ["data", "title"],
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
	"json": "Json",
	"agent": "Agent",
	"watcher": "Watcher",
	"text": "Text",
	"array": "Array",
	"switch": "Switch",
	"random": "Random",
	"dict": "Dict",
	"date": "Date",
	"loop": "Loop",
	"regex": "Regex",
	"csv": "CSV",
	"merge": "Merge",
	"filter": "Filter",
	"tg_receive": "TGRecv",
	"tg_send": "TGSend",
	"file_watch": "FileWatch",
	"log": "Log",
	"store": "Store",
	"bar_chart": "BarChart",
	"pie_chart": "PieChart",
	"line_graph": "LineGraph",
	"button": "Button",
	"subgraph": "SubGraph",
	"graph_input": "GInput",
	"graph_output": "GOutput",
}

# Centralized port definitions: type -> array of {idx, dir, color}
# dir: "in" or "out". Color as named Color constant.
# Nodes call configure_slots_from_defs() to set up ports from this table.
const PORT_DEFS := {
	"notepad": [
		{"idx": 0, "dir": "in", "color": "WHITE"},
		{"idx": 0, "dir": "out", "color": "WHITE"},
		{"idx": 1, "dir": "in", "color": "CYAN"},
		{"idx": 2, "dir": "in", "color": "GREEN"},
	],
	"exec": [
		{"idx": 0, "dir": "in", "color": "WHITE"},
		{"idx": 0, "dir": "out", "color": "WHITE"},
		{"idx": 1, "dir": "out", "color": "RED"},
	],
	"find_file": [
		{"idx": 0, "dir": "in", "color": "WHITE"},
		{"idx": 0, "dir": "out", "color": "GREEN"},
	],
	"bool": [
		{"idx": 0, "dir": "in", "color": "CYAN"},
		{"idx": 1, "dir": "in", "color": "CYAN"},
		{"idx": 2, "dir": "out", "color": "GREEN"},
	],
	"math": [
		{"idx": 0, "dir": "in", "color": "CYAN"},
		{"idx": 1, "dir": "in", "color": "CYAN"},
		{"idx": 2, "dir": "out", "color": "WHITE"},
		{"idx": 3, "dir": "out", "color": "GREEN"},
	],
	"if": [
		{"idx": 0, "dir": "in", "color": "YELLOW"},
		{"idx": 1, "dir": "in", "color": "CYAN"},
		{"idx": 2, "dir": "out", "color": "GREEN"},
		{"idx": 3, "dir": "out", "color": "RED"},
	],
	"binary": [
		{"idx": 0, "dir": "out", "color": "YELLOW"},
	],
	"pc": [
		{"idx": 0, "dir": "in", "color": "CYAN"},
		{"idx": 1, "dir": "in", "color": "CYAN"},
		{"idx": 2, "dir": "in", "color": "CYAN"},
		{"idx": 3, "dir": "out", "color": "GREEN"},
		{"idx": 4, "dir": "out", "color": "GREEN"},
		{"idx": 5, "dir": "out", "color": "GREEN"},
		{"idx": 6, "dir": "out", "color": "GREEN"},
		{"idx": 7, "dir": "out", "color": "GREEN"},
		{"idx": 8, "dir": "out", "color": "GREEN"},
	],
	"timer": [
		{"idx": 0, "dir": "in", "color": "CYAN"},
		{"idx": 1, "dir": "in", "color": "CYAN"},
		{"idx": 2, "dir": "in", "color": "CYAN"},
		{"idx": 5, "dir": "out", "color": "GREEN"},
	],
	"http": [
		{"idx": 0, "dir": "in", "color": "CYAN"},
		{"idx": 1, "dir": "in", "color": "YELLOW"},
		{"idx": 2, "dir": "in", "color": "MAGENTA"},
		{"idx": 3, "dir": "out", "color": "GREEN"},
		{"idx": 4, "dir": "out", "color": "RED"},
	],
	"json": [
		{"idx": 0, "dir": "in", "color": "CYAN"},
		{"idx": 1, "dir": "in", "color": "MAGENTA"},
		{"idx": 2, "dir": "out", "color": "GREEN"},
		{"idx": 3, "dir": "out", "color": "RED"},
	],
	"agent": [
		{"idx": 0, "dir": "in", "color": "WHITE"},
		{"idx": 1, "dir": "in", "color": "MAGENTA"},
		{"idx": 2, "dir": "in", "color": "CYAN"},
		{"idx": 3, "dir": "out", "color": "GREEN"},
		{"idx": 4, "dir": "out", "color": "RED"},
	],
	"watcher": [
		{"idx": 0, "dir": "in", "color": "WHITE"},
	],
	"text": [
		{"idx": 0, "dir": "in", "color": "WHITE"},
		{"idx": 1, "dir": "in", "color": "CYAN"},
		{"idx": 2, "dir": "out", "color": "GREEN"},
	],
	"array": [
		{"idx": 0, "dir": "in", "color": "WHITE"},
		{"idx": 1, "dir": "in", "color": "CYAN"},
		{"idx": 2, "dir": "out", "color": "GREEN"},
	],
	"switch": [
		{"idx": 0, "dir": "in", "color": "WHITE"},
		{"idx": 1, "dir": "out", "color": "GREEN"},
		{"idx": 2, "dir": "out", "color": "CYAN"},
		{"idx": 3, "dir": "out", "color": "CYAN"},
		{"idx": 4, "dir": "out", "color": "CYAN"},
	],
	"random": [
		{"idx": 0, "dir": "in", "color": "WHITE"},
		{"idx": 1, "dir": "in", "color": "CYAN"},
		{"idx": 2, "dir": "out", "color": "GREEN"},
	],
	"dict": [
		{"idx": 0, "dir": "in", "color": "WHITE"},
		{"idx": 1, "dir": "in", "color": "CYAN"},
		{"idx": 2, "dir": "out", "color": "GREEN"},
	],
	"date": [
		{"idx": 0, "dir": "in", "color": "WHITE"},
		{"idx": 1, "dir": "in", "color": "CYAN"},
		{"idx": 2, "dir": "out", "color": "GREEN"},
	],
	"loop": [
		{"idx": 0, "dir": "in", "color": "WHITE"},
		{"idx": 1, "dir": "in", "color": "CYAN"},
		{"idx": 2, "dir": "out", "color": "GREEN"},
	],
	"regex": [
		{"idx": 0, "dir": "in", "color": "WHITE"},
		{"idx": 1, "dir": "in", "color": "CYAN"},
		{"idx": 2, "dir": "out", "color": "GREEN"},
	],
	"csv": [
		{"idx": 0, "dir": "in", "color": "WHITE"},
		{"idx": 1, "dir": "in", "color": "CYAN"},
		{"idx": 2, "dir": "out", "color": "GREEN"},
	],
	"merge": [
		{"idx": 0, "dir": "in", "color": "CYAN"},
		{"idx": 1, "dir": "in", "color": "MAGENTA"},
		{"idx": 2, "dir": "in", "color": "WHITE"},
		{"idx": 3, "dir": "out", "color": "GREEN"},
	],
	"filter": [
		{"idx": 0, "dir": "in", "color": "WHITE"},
		{"idx": 1, "dir": "in", "color": "CYAN"},
		{"idx": 2, "dir": "out", "color": "GREEN"},
	],
	"tg_receive": [
		{"idx": 0, "dir": "in", "color": "CYAN"},
		{"idx": 1, "dir": "out", "color": "GREEN"},
		{"idx": 2, "dir": "out", "color": "CYAN"},
		{"idx": 3, "dir": "out", "color": "WHITE"},
	],
	"tg_send": [
		{"idx": 0, "dir": "in", "color": "CYAN"},
		{"idx": 1, "dir": "in", "color": "MAGENTA"},
		{"idx": 2, "dir": "in", "color": "WHITE"},
		{"idx": 3, "dir": "out", "color": "GREEN"},
	],
	"file_watch": [
		{"idx": 0, "dir": "in", "color": "CYAN"},
		{"idx": 1, "dir": "out", "color": "GREEN"},
		{"idx": 2, "dir": "out", "color": "CYAN"},
	],
	"log": [
		{"idx": 0, "dir": "in", "color": "WHITE"},
		{"idx": 1, "dir": "out", "color": "GREEN"},
	],
	"store": [
		{"idx": 0, "dir": "in", "color": "CYAN"},
		{"idx": 1, "dir": "in", "color": "WHITE"},
		{"idx": 2, "dir": "out", "color": "GREEN"},
	],
	"bar_chart": [
		{"idx": 0, "dir": "in", "color": "WHITE"},
		{"idx": 1, "dir": "in", "color": "MAGENTA"},
		{"idx": 2, "dir": "in", "color": "CYAN"},
		{"idx": 3, "dir": "out", "color": "GREEN"},
	],
	"pie_chart": [
		{"idx": 0, "dir": "in", "color": "WHITE"},
		{"idx": 1, "dir": "in", "color": "MAGENTA"},
		{"idx": 2, "dir": "in", "color": "CYAN"},
		{"idx": 3, "dir": "out", "color": "GREEN"},
	],
	"line_graph": [
		{"idx": 0, "dir": "in", "color": "WHITE"},
		{"idx": 1, "dir": "in", "color": "MAGENTA"},
		{"idx": 2, "dir": "in", "color": "CYAN"},
		{"idx": 3, "dir": "out", "color": "GREEN"},
	],
	"button": [
		{"idx": 0, "dir": "out", "color": "GREEN"},
	],
	"graph_input": [
		{"idx": 0, "dir": "out", "color": "CYAN"},
	],
	"graph_output": [
		{"idx": 0, "dir": "in", "color": "GREEN"},
	],
}

# Port type annotations for type-checking wires.
# Format: type -> {port_name: type_string}. Types: "string", "number", "boolean", "any"
# Unlisted ports default to "any" (connects to anything).
const PORT_TYPE_MAP := {
	"notepad": {"out": "string", "set": "string", "prepend": "string", "append": "string"},
	"exec": {"stdout": "string", "stderr": "string", "command": "string"},
	"math": {"a": "number", "b": "number", "raw": "number", "result": "number"},
	"bool": {"a": "string", "b": "string", "result": "boolean"},
	"if": {"condition": "string", "data": "any", "true": "any", "false": "any"},
	"http": {"url": "string", "body": "string", "response": "string", "error": "string"},
	"json": {"json": "string", "path": "string", "result": "string", "error": "string"},
	"agent": {"prompt": "string", "system": "string", "url": "string", "result": "string", "log": "string"},
	"array": {"input": "string", "param": "string", "result": "string"},
	"dict": {"input": "string", "param": "string", "result": "string"},
	"date": {"input": "string", "param": "string", "result": "string"},
	"loop": {"input": "string", "param": "string", "result": "string"},
	"text": {"input": "string", "param": "string", "result": "string"},
	"regex": {"input": "string", "param": "string", "result": "string"},
	"csv": {"input": "string", "param": "string", "result": "string"},
	"merge": {"a": "string", "b": "string", "param": "string", "result": "string"},
	"filter": {"input": "string", "param": "string", "result": "string"},
	"random": {"min": "number", "max": "number", "result": "number"},
	"tg_receive": {"message": "string", "chat_id": "string", "from": "string"},
	"tg_send": {"token": "string", "chat_id": "string", "message": "string", "result": "string"},
	"file_watch": {"file_path": "string", "content": "string", "path": "string"},
	"log": {"value": "string", "log": "string"},
	"store": {"key": "string", "value": "string", "result": "string"},
	"bar_chart": {"data": "string", "title": "string"},
	"pie_chart": {"data": "string", "title": "string"},
	"line_graph": {"data": "string", "title": "string"},
}

static func get_color_by_name(name: String) -> Color:
	match name:
		"WHITE": return Color.WHITE
		"RED": return Color.RED
		"GREEN": return Color.GREEN
		"BLUE": return Color.BLUE
		"YELLOW": return Color.YELLOW
		"CYAN": return Color.CYAN
		"MAGENTA": return Color.MAGENTA
		_: return Color.WHITE

## Configure a GraphNode's slots from PORT_DEFS. Call in _ready().
static func configure_slots(node: GraphNode, type: String) -> void:
	var defs: Array = PORT_DEFS.get(type, [])
	# Build per-index slot state
	var max_idx: int = -1
	for d in defs:
		if int(d.idx) > max_idx:
			max_idx = int(d.idx)
	if max_idx < 0:
		return
	# Track enabled ports per index
	var has_input: Array = []
	var has_output: Array = []
	var in_color: Array = []
	var out_color: Array = []
	for i in range(max_idx + 1):
		has_input.append(false)
		has_output.append(false)
		in_color.append(Color.WHITE)
		out_color.append(Color.WHITE)
	for d in defs:
		var idx: int = int(d.idx)
		var c: Color = get_color_by_name(String(d.color))
		if String(d.dir) == "in":
			has_input[idx] = true
			in_color[idx] = c
		else:
			has_output[idx] = true
			out_color[idx] = c
	for i in range(max_idx + 1):
		node.set_slot(i, has_input[i], 0, in_color[i], has_output[i], 0, out_color[i])

var _errors: Array[String] = []
var _labels: Dictionary = {}
var _label_types: Dictionary = {}
var _node_data: Array = []
var _wire_data: Array = []
var _trigger_labels: Array = []
var _expect_data: Array[Dictionary] = []
var _counters: Dictionary = {}
var _variables: Dictionary = {}
var _functions: Dictionary = {}  # name -> {params: [], body: []}
var _func_call_counter: int = 0
var _break_labels: Array = []  # labels with breakpoints


func parse(source: String) -> Dictionary:
	_errors.clear()
	_labels.clear()
	_label_types.clear()
	_node_data.clear()
	_wire_data.clear()
	_trigger_labels.clear()
	_expect_data.clear()
	_counters.clear()
	_variables.clear()
	_functions.clear()
	_func_call_counter = 0
	_break_labels.clear()

	var lines := _expand_imports(source.split("\n"))
	# Collapse triple-quoted strings into single lines
	lines = _collapse_triple_quotes(lines)
	# First pass: collect function definitions
	var processed_lines: Array = []
	var in_func: String = ""
	var func_body: Array = []
	for i in range(lines.size()):
		var line: String = str(lines[i]).strip_edges()
		if line == "" or line.begins_with("#"):
			if in_func == "":
				processed_lines.append(line)
			continue
		if in_func != "":
			if line == "end":
				_functions[in_func]["body"] = func_body
				in_func = ""
				func_body = []
			else:
				func_body.append(line)
			continue
		if line.begins_with("func "):
			_parse_func_header(line, i + 1)
			in_func = line.split(" ")[1].split("(")[0]
			continue
		processed_lines.append(line)

	# Strip inline comments from all processed lines
	for i in range(processed_lines.size()):
		var pline: String = str(processed_lines[i])
		var cpos := pline.find(" #")
		if cpos >= 0:
			processed_lines[i] = pline.left(cpos)

	# Pre-pass: collect top-level var declarations for conditional evaluation
	# Skip var lines inside while/for blocks (they get evaluated at expansion time)
	var _block_depth := 0
	for i in range(processed_lines.size()):
		var line: String = str(processed_lines[i]).strip_edges()
		if line.begins_with("for ") or line.begins_with("while "):
			_block_depth += 1
			continue
		if line == "endfor" or line == "end for" or line == "endwhile" or line == "end while":
			_block_depth -= 1
			continue
		if _block_depth == 0 and line.begins_with("var "):
			_parse_var(line.substr(4), i + 1)

	# Second pass: parse non-func lines, handling if/else/end, for/endfor, while/endwhile
	var cond_stack: Array = []  # [{active: bool, any_taken: bool}]
	var for_stack: Array = []   # [{var_name: String, values: [], body: []}]
	var while_stack: Array = [] # [{condition: String, body: [], line_num: int}]
	var final_lines: Array = []
	for i in range(processed_lines.size()):
		var line: String = str(processed_lines[i]).strip_edges()
		if line == "" or line.begins_with("#"):
			if for_stack.is_empty() and while_stack.is_empty() and (cond_stack.is_empty() or _cond_active(cond_stack)):
				final_lines.append(line)
			continue
		# Handle for loops
		if line.begins_with("for ") and for_stack.is_empty() and while_stack.is_empty():
			# Parse: for <var> in <values>
			var in_pos := line.find(" in ")
			if in_pos == -1:
				_errors.append("Line %d: for requires 'for <var> in <values>'" % (i + 1))
				continue
			var var_name: String = line.substr(4, in_pos - 4).strip_edges()
			var values_str: String = line.substr(in_pos + 4).strip_edges()
			var values: PackedStringArray = values_str.split(",")
			for_stack.append({"var_name": var_name, "values": values, "body": []})
			continue
		# Handle while loops
		if line.begins_with("while ") and for_stack.is_empty() and while_stack.is_empty():
			var condition: String = line.substr(6).strip_edges()
			while_stack.append({"condition": condition, "body": [], "line_num": i + 1})
			continue
		if not for_stack.is_empty():
			# Inside a for loop — collect body lines
			if line == "endfor" or line == "end for":
				var for_data: Dictionary = for_stack.pop_back()
				var var_name: String = for_data.var_name
				var body: Array = for_data.body
				var values: PackedStringArray = for_data.values
				# Expand body for each value
				for val in values:
					val = str(val).strip_edges()
					for body_line in body:
						var expanded_line: String = str(body_line).replace("$" + var_name, val)
						final_lines.append(expanded_line)
			else:
				for_stack[-1].body.append(line)
		elif not while_stack.is_empty():
			# Inside a while loop — collect body lines
			if line == "endwhile" or line == "end while":
				var w_data: Dictionary = while_stack.pop_back()
				_expand_while(w_data, final_lines)
			else:
				while_stack[-1].body.append(line)
		else:
			# Not in a loop — handle conditionals normally
			if line.begins_with("if "):
				var cond_result := _eval_condition(line.substr(3))
				cond_stack.append({"active": cond_result, "any_taken": cond_result})
				continue
			if line == "else":
				if not cond_stack.is_empty():
					var parent_active: bool = cond_stack.size() < 2 or cond_stack[cond_stack.size() - 2].active
					cond_stack[-1].active = parent_active and not cond_stack[-1].any_taken
					if cond_stack[-1].active:
						cond_stack[-1].any_taken = true
				continue
			if line == "endif" or line == "end if":
				if not cond_stack.is_empty():
					cond_stack.pop_back()
				continue
			if not _cond_active(cond_stack):
				continue
			final_lines.append(line)

	# Third pass: parse the filtered lines
	for i in range(final_lines.size()):
		var line: String = str(final_lines[i]).strip_edges()
		if line == "" or line.begins_with("#"):
			continue
		_parse_line(line, i + 1)

	return {
		"nodes": _node_data,
		"connections": _wire_data,
		"triggers": _trigger_labels,
		"expects": _expect_data,
		"breaks": _break_labels,
	}


func _cond_active(stack: Array) -> bool:
	if stack.is_empty():
		return true
	for entry in stack:
		if not entry.active:
			return false
	return true


func _expand_while(w_data: Dictionary, final_lines: Array) -> void:
	var condition: String = w_data.condition
	var body: Array = w_data.body
	var line_num: int = w_data.line_num
	var max_iter := 20
	var hit_break := false
	# Iterate: evaluate condition, expand body with current vars, update vars from body
	for _iter in range(max_iter):
		if not _eval_condition(condition):
			hit_break = true
			break
		# Expand body lines with current variable values
		for body_line in body:
			var expanded: String = str(body_line)
			expanded = _expand_vars(expanded)
			# Detect var assignments in body to update state
			if expanded.begins_with("var "):
				var eq_pos := expanded.find("=")
				if eq_pos >= 0:
					var vname := expanded.substr(4, eq_pos - 4).strip_edges()
					var vval := expanded.substr(eq_pos + 1).strip_edges()
					_variables[vname] = vval
			final_lines.append(expanded)
	if not hit_break:
		_errors.append("Line %d: while loop exceeded %d iterations" % [line_num, max_iter])


func _eval_condition(expr: String) -> bool:
	# Expand both $var and bare var names
	var expanded := _expand_vars(expr)
	# Also expand bare variable names (not just $var)
	for var_name in _variables:
		var var_val: String = String(_variables[var_name])
		# Replace bare var name only if it's a whole word (not inside another word)
		var pattern: String = var_name
		var idx: int = 0
		while true:
			var pos: int = expanded.find(pattern, idx)
			if pos == -1:
				break
			# Check if it's a whole word
			var before_ok: bool = pos == 0 or not expanded[pos - 1].is_valid_identifier()
			var after_pos: int = pos + pattern.length()
			var after_ok: bool = after_pos >= expanded.length() or not expanded[after_pos].is_valid_identifier()
			if before_ok and after_ok:
				expanded = expanded.left(pos) + var_val + expanded.substr(after_pos)
				idx = pos + var_val.length()
			else:
				idx = pos + 1
	expanded = expanded.strip_edges()
	# Check for != operator
	var neq_pos := expanded.find("!=")
	if neq_pos >= 0:
		var lhs := expanded.left(neq_pos).strip_edges()
		var rhs := expanded.substr(neq_pos + 2).strip_edges()
		return lhs != rhs
	# Check for == operator
	var eq_pos := expanded.find("==")
	if eq_pos >= 0:
		var lhs := expanded.left(eq_pos).strip_edges()
		var rhs := expanded.substr(eq_pos + 2).strip_edges()
		return lhs == rhs
	# Check for > operator
	var gt_pos := expanded.find(">")
	if gt_pos >= 0:
		var lhs := expanded.left(gt_pos).strip_edges()
		var rhs := expanded.substr(gt_pos + 1).strip_edges()
		return lhs.to_float() > rhs.to_float()
	# Check for < operator
	var lt_pos := expanded.find("<")
	if lt_pos >= 0:
		var lhs := expanded.left(lt_pos).strip_edges()
		var rhs := expanded.substr(lt_pos + 1).strip_edges()
		return lhs.to_float() < rhs.to_float()
	# Truthy check: non-empty, not "false", not "0"
	return expanded != "" and expanded != "false" and expanded != "0"


func get_errors() -> Array[String]:
	return _errors


func _collapse_triple_quotes(lines: Array) -> Array:
	var result: Array = []
	var in_triple := false
	var buffer: String = ""
	var start_line := ""
	for i in range(lines.size()):
		var line: String = str(lines[i])
		if in_triple:
			var end_pos := line.find('"""')
			if end_pos >= 0:
				# End of triple-quoted string
				if end_pos > 0:
					buffer += line.left(end_pos)
				# Replace \n literal with escaped newline for GAL
				start_line = start_line + buffer.replace("\n", "\\n")
				result.append(start_line)
				in_triple = false
				buffer = ""
				start_line = ""
				# Add remainder after closing """
				var remainder := line.substr(end_pos + 3).strip_edges()
				if remainder != "":
					result.append(remainder)
			else:
				buffer += line + "\n"
		else:
			var pos := line.find('"""')
			if pos >= 0:
				var before := line.left(pos)
				var after := line.substr(pos + 3)
				# Check if closing """ is on same line
				var close_pos := after.find('"""')
				if close_pos >= 0:
					var content := after.left(close_pos)
					result.append(before + content.replace("\n", "\\n"))
					var rem := after.substr(close_pos + 3).strip_edges()
					if rem != "":
						result.append(rem)
				else:
					# Start multiline: save the part before """ and collect
					start_line = before
					buffer = after + "\n"
					in_triple = true
			else:
				result.append(line)
	return result


func _expand_imports(lines: Array) -> Array:
	var result: Array = []
	for i in range(lines.size()):
		var trimmed: String = str(lines[i]).strip_edges()
		if trimmed.begins_with("import ") or trimmed.begins_with("include "):
			var prefix_len := 7 if trimmed.begins_with("import ") else 8
			var path: String = trimmed.substr(prefix_len).strip_edges()
			if not FileAccess.file_exists(path):
				_errors.append("Import file not found: %s" % path)
				result.append(lines[i])
				continue
			var f := FileAccess.open(path, FileAccess.READ)
			if f == null:
				_errors.append("Cannot open import: %s" % path)
				result.append(lines[i])
				continue
			var imported: String = f.get_as_text()
			f.close()
			result.append_array(imported.split("\n"))
		else:
			result.append(lines[i])
	return result


func _parse_line(line: String, line_num: int) -> void:
	# Strip inline comments (# not inside strings)
	var comment_pos := line.find(" #")
	if comment_pos >= 0:
		line = line.left(comment_pos)
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
		"var":
			_parse_var(rest, line_num)
		"call":
			_parse_call(rest, line_num)
		"return":
			_parse_return(rest, line_num)
		"node":
			_parse_node(_expand_vars(rest), line_num)
		"set":
			_parse_set(_expand_vars(rest), line_num)
		"wire":
			_parse_wire(rest, line_num)
		"trigger":
			_parse_trigger(rest, line_num)
		"expect":
			_parse_expect(_expand_vars(rest), line_num)
		"break":
			_parse_break(rest, line_num)
		"eval":
			_parse_eval(rest, line_num)
		"template":
			_parse_template(rest, line_num)
		"instance":
			_parse_instance(rest, line_num)
		_:
			_errors.append("Line %d: Unknown keyword '%s'. Expected: node, set, wire, trigger, expect, var" % [line_num, keyword])


func _parse_var(rest: String, line_num: int) -> void:
	# Format: <name> = <value>
	var eq_pos := rest.find("=")
	if eq_pos == -1:
		_errors.append("Line %d: var requires <name> = <value>" % line_num)
		return
	var name := rest.left(eq_pos).strip_edges()
	var value := rest.substr(eq_pos + 1).strip_edges()
	if name == "":
		_errors.append("Line %d: var name cannot be empty" % line_num)
		return
	# Handle: var x = call name(args) — execute call, then capture return value
	if value.begins_with("call "):
		_parse_call(value.substr(5), line_num)
		_variables[name] = String(_variables.get("_return", ""))
		_variables.erase("_return")
		return
	_variables[name] = value


func _expand_vars(text: String) -> String:
	var result := text
	# Evaluate ${expr} inline expressions first (expand vars inside them)
	var start := result.find("${")
	while start >= 0:
		var end := result.find("}", start)
		if end == -1:
			break
		var expr := result.substr(start + 2, end - start - 2).strip_edges()
		# Expand variables within the expression ($varname and bare varname)
		for var_name in _variables:
			expr = expr.replace("$" + var_name, String(_variables[var_name]))
			expr = expr.replace(var_name, String(_variables[var_name]))
		var evaluated := _eval_expr(expr)
		result = result.left(start) + evaluated + result.substr(end + 1)
		start = result.find("${")
	# Then expand remaining $var references
	for var_name in _variables:
		result = result.replace("$" + var_name, String(_variables[var_name]))
	return result


func _eval_expr(expr: String) -> String:
	# Simple arithmetic: handle +, -, *, / on numbers
	expr = expr.strip_edges()
	# Try addition (rightmost to preserve left-to-right)
	var plus_pos := expr.rfind(" + ")
	if plus_pos > 0:
		var left := _eval_expr(expr.left(plus_pos))
		var right := _eval_expr(expr.substr(plus_pos + 3))
		if left.is_valid_float() and right.is_valid_float():
			return _format_num(left.to_float() + right.to_float())
	var minus_pos := expr.rfind(" - ")
	if minus_pos > 0:
		var left := _eval_expr(expr.left(minus_pos))
		var right := _eval_expr(expr.substr(minus_pos + 3))
		if left.is_valid_float() and right.is_valid_float():
			return _format_num(left.to_float() - right.to_float())
	var mul_pos := expr.find(" * ")
	if mul_pos > 0:
		var left := _eval_expr(expr.left(mul_pos))
		var right := _eval_expr(expr.substr(mul_pos + 3))
		if left.is_valid_float() and right.is_valid_float():
			return _format_num(left.to_float() * right.to_float())
	var div_pos := expr.find(" / ")
	if div_pos > 0:
		var left := _eval_expr(expr.left(div_pos))
		var right := _eval_expr(expr.substr(div_pos + 3))
		if left.is_valid_float() and right.is_valid_float() and right.to_float() != 0.0:
			return _format_num(left.to_float() / right.to_float())
	return expr


func _format_num(val: float) -> String:
	if val == floor(val):
		return str(int(val))
	return str(val)


func _parse_func_header(line: String, line_num: int) -> void:
	# Format: func name(param1, param2):
	var colon_pos := line.find(":")
	if colon_pos == -1:
		_errors.append("Line %d: func requires name(params):" % line_num)
		return
	var header: String = line.left(colon_pos).strip_edges()
	var paren_open := header.find("(")
	if paren_open == -1:
		_errors.append("Line %d: func requires name(params):" % line_num)
		return
	var fname: String = header.left(paren_open).strip_edges().substr(5)  # skip "func "
	var params_str: String = header.substr(paren_open + 1).rstrip(")")
	var params: Array = params_str.split(",", false)
	for i in range(params.size()):
		params[i] = str(params[i]).strip_edges()
	_functions[fname] = {"params": params, "body": []}


func _parse_call(rest: String, line_num: int) -> void:
	# Format: call name(arg1, arg2)
	var paren_open: int = rest.find("(")
	if paren_open == -1:
		_errors.append("Line %d: call requires name(args)" % line_num)
		return
	var fname: String = rest.left(paren_open).strip_edges()
	if not _functions.has(fname):
		_errors.append("Line %d: Unknown function '%s'" % [line_num, fname])
		return
	var args_str: String = rest.substr(paren_open + 1).rstrip(")")
	var args: Array = args_str.split(",", false)
	for i in range(args.size()):
		args[i] = str(args[i]).strip_edges()

	var func_def: Dictionary = _functions[fname]
	var params: Array = func_def.params
	var body: Array = func_def.body

	if args.size() != params.size():
		_errors.append("Line %d: Function '%s' expects %d args, got %d" % [line_num, fname, params.size(), args.size()])
		return

	# Generate unique prefix for this call instance
	_func_call_counter += 1
	var prefix_str: String = "_f%d_" % _func_call_counter

	# Expand body with param->arg substitution and label prefixing
	for body_line in body:
		var expanded: String = str(body_line)
		# Substitute $param with arg value
		for j in range(params.size()):
			expanded = expanded.replace("$" + str(params[j]), str(args[j]))
		# Handle return: convert to var _return and stop expanding
		if expanded.begins_with("return "):
			var ret_val: String = _expand_vars(expanded.substr(7))
			_variables["_return"] = ret_val
			break
		if expanded == "return":
			_variables["_return"] = ""
			break
		# Prefix all labels with unique identifier
		if expanded.begins_with("node "):
			# "node LABEL TYPE..." -> "node _f1_LABEL TYPE..."
			var after_node: String = expanded.substr(5)
			var space_pos: int = after_node.find(" ")
			if space_pos != -1:
				expanded = "node " + prefix_str + after_node.left(space_pos) + after_node.substr(space_pos)
		else:
			# For wire/set/trigger/expect, prefix all occurrences of arg labels
			for j in range(args.size()):
				var arg_label: String = str(args[j])
				expanded = expanded.replace(arg_label + ".", prefix_str + arg_label + ".")
				expanded = expanded.replace(" " + arg_label + " ", " " + prefix_str + arg_label + " ")
				if expanded.ends_with(" " + arg_label):
					expanded = expanded.left(expanded.length() - arg_label.length()) + prefix_str + arg_label
		_parse_line(expanded, line_num)


func _parse_return(rest: String, line_num: int) -> void:
	# Format: return <value> — only valid inside function bodies
	# At top level, just set _return variable
	var val: String = _expand_vars(rest.strip_edges())
	_variables["_return"] = val


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
	# "comment" is a universal property for all node types
	if prop != "comment" and not VALID_PROPS[type].has(prop):
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

	# Type check: warn (not error) on type mismatches
	var src_port_type: String = PORT_TYPE_MAP.get(src_type, {}).get(src_port_name, "any")
	var dst_port_type: String = PORT_TYPE_MAP.get(dst_type, {}).get(dst_port_name, "any")
	if src_port_type != "any" and dst_port_type != "any" and src_port_type != dst_port_type:
		# Type mismatch is a warning, not an error — still add the wire
		_wire_data.append({
			"_src_label": src_label,
			"_src_port": src_port_name,
			"_dst_label": dst_label,
			"_dst_port": dst_port_name,
			"_type_warn": src_port_type + " -> " + dst_port_type,
		})
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


func _parse_break(rest: String, line_num: int) -> void:
	# break [label] — mark a label as a breakpoint, or mark all following operations
	var label := rest.strip_edges()
	if label != "" and not _labels.has(label):
		_errors.append("Line %d: Unknown label '%s' in break" % [line_num, label])
		return
	_break_labels.append(label)


func _parse_eval(rest: String, line_num: int) -> void:
	# eval <expression> — evaluate GDScript expression, store result in _ variable
	var expr := rest.strip_edges()
	if expr == "":
		_errors.append("Line %d: eval requires an expression" % line_num)
		return
	# Expand vars in expression
	expr = _expand_vars(expr)
	var gdexpr := Expression.new()
	var err := gdexpr.parse(expr, [])
	if err != OK:
		_errors.append("Line %d: eval parse error: %s" % [line_num, gdexpr.get_error_text()])
		return
	var result = gdexpr.execute([], null, true)
	if gdexpr.has_execute_failed():
		_errors.append("Line %d: eval error: %s" % [line_num, gdexpr.get_error_text()])
		return
	_variables["_"] = str(result)


var _templates: Dictionary = {}  # name -> {type, props: {key: val}, x: float, y: float}


func _parse_template(rest: String, line_num: int) -> void:
	# template <name> <type> [at x y] — define a reusable node configuration
	var parts: PackedStringArray = rest.split(" ")
	if parts.size() < 2:
		_errors.append("Line %d: template requires <name> <type>" % line_num)
		return
	var tname: String = parts[0].strip_edges()
	var ttype: String = parts[1].strip_edges()
	var tpl: Dictionary = {"type": ttype, "props": {}}
	# Check for "at x y"
	var at_idx := -1
	for i in range(parts.size()):
		if parts[i] == "at":
			at_idx = i
			break
	if at_idx >= 0 and at_idx + 2 < parts.size():
		tpl["x"] = parts[at_idx + 1].to_float()
		tpl["y"] = parts[at_idx + 2].to_float()
	_templates[tname] = tpl


func _parse_instance(rest: String, line_num: int) -> void:
	# instance <label> <template_name> [at x y] [set prop val ...]
	var parts: PackedStringArray = rest.split(" ")
	if parts.size() < 2:
		_errors.append("Line %d: instance requires <label> <template_name>" % line_num)
		return
	var label: String = parts[0].strip_edges()
	var tname: String = parts[1].strip_edges()
	if not _templates.has(tname):
		_errors.append("Line %d: Unknown template '%s'" % [line_num, tname])
		return
	var tpl: Dictionary = _templates[tname]
	var node_rest: String = label + " " + String(tpl.type)
	# Parse position from instance or template
	var x: float = tpl.get("x", 0.0)
	var y: float = tpl.get("y", 0.0)
	var i := 2
	while i < parts.size():
		if parts[i] == "at" and i + 2 < parts.size():
			x = parts[i + 1].to_float()
			y = parts[i + 2].to_float()
			i += 3
		else:
			break
	node_rest += " at %s %s" % [str(x), str(y)]
	_parse_node(node_rest, line_num)
	# Apply template default props
	if _labels.has(label):
		for prop_key in tpl.props:
			# Add to pending props for this node
			var nd := _get_node_data(label)
			if nd:
				nd._props[prop_key] = tpl.props[prop_key]


func _get_node_data(label: String) -> Dictionary:
	for nd in _node_data:
		if nd._label == label:
			return nd
	return {}


func _parse_expect(rest: String, line_num: int) -> void:
	# Format: <label>.<port> <op> <value>  where op is ==, !=, >, <, contains
	var ops := [" != ", " == ", " contains ", " > ", " < "]
	var op_found := ""
	var op_pos := -1
	for op in ops:
		var idx := rest.find(op)
		if idx >= 0:
			op_found = op.strip_edges()
			op_pos = idx
			break
	if op_pos == -1:
		_errors.append("Line %d: expect requires <label>.<port> <op> <value>. Operators: ==, !=, >, <, contains" % line_num)
		return

	var left := rest.left(op_pos).strip_edges()
	var op_len := op_found.length() + 2  # +2 for surrounding spaces
	var value := rest.substr(op_pos + op_len).strip_edges().replace("\\n", "\n")

	var dot_pos := left.find(".")
	if dot_pos == -1:
		_errors.append("Line %d: expect requires <label>.<port>" % line_num)
		return

	var label := left.left(dot_pos)
	var port_name := left.substr(dot_pos + 1)

	if not _labels.has(label):
		_errors.append("Line %d: Unknown label '%s'" % [line_num, label])
		return

	var type: String = _label_types[label]
	if not OUTPUT_PORTS[type].has(port_name):
		_errors.append("Line %d: Unknown output port '%s' for %s" % [line_num, port_name, type])
		return

	_expect_data.append({
		"label": label,
		"port": port_name,
		"value": value,
		"op": op_found,
	})
