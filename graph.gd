extends VBoxContainer

signal notepad_selected(node: GraphNode)

const AssemblerScript := preload("res://assembler.gd")

# Node registry: type -> { scene, prefix, menu_label }
# Adding a new node type = one entry here + assembler.gd constants
var _NODE_REGISTRY: Dictionary = {}

func _init_registry() -> void:
	_NODE_REGISTRY = {
		"notepad": { "scene": preload("res://notepad_node.tscn"), "prefix": "Notepad", "menu": "Notepad" },
		"exec": { "scene": preload("res://exec_node.tscn"), "prefix": "Exec", "menu": "Execute" },
		"find_file": { "scene": preload("res://find_file_node.tscn"), "prefix": "FindFile", "menu": "Find File" },
		"bool": { "scene": preload("res://bool_node.tscn"), "prefix": "Bool", "menu": "Bool" },
		"math": { "scene": preload("res://math_node.tscn"), "prefix": "Math", "menu": "Math" },
		"binary": { "scene": preload("res://binary_node.tscn"), "prefix": "Binary", "menu": "Binary" },
		"if": { "scene": preload("res://if_node.tscn"), "prefix": "If", "menu": "If" },
		"pc": { "scene": preload("res://pc_node.tscn"), "prefix": "PC", "menu": "PC" },
		"timer": { "scene": preload("res://timer_node.tscn"), "prefix": "Timer", "menu": "Timer" },
		"subgraph": { "scene": preload("res://sub_graph_node.tscn"), "prefix": "SubGraph", "menu": "Sub-Graph" },
		"http": { "scene": preload("res://http_node.tscn"), "prefix": "Http", "menu": "HTTP" },
		"button": { "scene": preload("res://button_node.tscn"), "prefix": "Button", "menu": "Button" },
		"json": { "scene": preload("res://json_node.tscn"), "prefix": "Json", "menu": "JSON" },
		"agent": { "scene": preload("res://agent_node.tscn"), "prefix": "Agent", "menu": "Agent" },
		"watcher": { "scene": preload("res://watcher_node.tscn"), "prefix": "Watcher", "menu": "Watcher" },
		"text": { "scene": preload("res://text_node.tscn"), "prefix": "Text", "menu": "Text" },
		"array": { "scene": preload("res://array_node.tscn"), "prefix": "Array", "menu": "Array" },
		"switch": { "scene": preload("res://switch_node.tscn"), "prefix": "Switch", "menu": "Switch" },
		"random": { "scene": preload("res://random_node.tscn"), "prefix": "Random", "menu": "Random" },
		"dict": { "scene": preload("res://dict_node.tscn"), "prefix": "Dict", "menu": "Dict" },
		"date": { "scene": preload("res://date_node.tscn"), "prefix": "Date", "menu": "Date" },
		"loop": { "scene": preload("res://loop_node.tscn"), "prefix": "Loop", "menu": "Loop" },
		"regex": { "scene": preload("res://regex_node.tscn"), "prefix": "Regex", "menu": "Regex" },
		"csv": { "scene": preload("res://csv_node.tscn"), "prefix": "CSV", "menu": "CSV" },
		"merge": { "scene": preload("res://merge_node.tscn"), "prefix": "Merge", "menu": "Merge" },
		"filter": { "scene": preload("res://filter_node.tscn"), "prefix": "Filter", "menu": "Filter" },
		"tg_receive": { "scene": preload("res://telegram_receive_node.tscn"), "prefix": "TGRecv", "menu": "TG Receive" },
		"tg_send": { "scene": preload("res://telegram_send_node.tscn"), "prefix": "TGSend", "menu": "TG Send" },
		"file_watch": { "scene": preload("res://file_watch_node.tscn"), "prefix": "FileWatch", "menu": "File Watch" },
		"log": { "scene": preload("res://log_node.tscn"), "prefix": "Log", "menu": "Log" },
		"store": { "scene": preload("res://store_node.tscn"), "prefix": "Store", "menu": "Store" },
		"bar_chart": { "scene": preload("res://bar_chart_node.tscn"), "prefix": "BarChart", "menu": "Bar Chart" },
		"pie_chart": { "scene": preload("res://pie_chart_node.tscn"), "prefix": "PieChart", "menu": "Pie Chart" },
		"line_graph": { "scene": preload("res://line_graph_node.tscn"), "prefix": "LineGraph", "menu": "Line Graph" },
		"graph_input": { "scene": preload("res://graph_input_node.tscn"), "prefix": "GInput", "menu": "" },
		"graph_output": { "scene": preload("res://graph_output_node.tscn"), "prefix": "GOutput", "menu": "" },
	}

var _node_counter := 0
var _assembling := false
var _visited: Array[StringName] = []
var graph_file_path: String = ""
var _graph_stack: Array = []
var _current_subgraph_name: String = ""
var _use_context_pos := false
var _context_spawn_pos := Vector2.ZERO
var _undo_redo := UndoRedo.new()
var _flow_events: Array = []  # {from_node, from_port, to_node, to_port, time, value}
var _flow_overlay: Control = null
var _hovered_connection: Dictionary = {}  # cached connection near cursor
var _clipboard: Dictionary = {"nodes": [], "connections": []}
var _node_colors: Dictionary = {}  # node_name -> Color
var _groups: Array[Dictionary] = []  # [{name, color, nodes: [StringName], label: String}]
var _conn_labels: Dictionary = {}  # "from:from_port->to:to_port" -> value string
var _type_warnings: Dictionary = {}  # "from:from_port->to:to_port" -> "src_type -> dst_type"
var _last_gal_path: String = ""  # path of last loaded .gal file for reload
var _recent_files: PackedStringArray = []  # recently opened files
const _RECENT_PATH := "user://recent_files.json"
const MAX_RECENT := 10
var _gal_watcher: Timer = null  # timer for file change detection
var _gal_watcher_mtime: int = 0  # last modification time of watched file
var _debug_mode: bool = false
var _debug_triggers: Array = []  # list of trigger labels
var _debug_idx: int = 0  # current trigger index
var _debug_label_map: Dictionary = {}  # label -> GraphNode
var _selected_node: GraphNode = null
var _wire_bends: Dictionary = {}  # "from:from_port->to:to_port" -> [Vector2]
var _wire_style: int = 0  # 0=dot flow, 1=pulse, 2=static
var _port_history: Dictionary = {}  # "node_name:port" -> [String] (last 5 values)
var _grid_sizes: Array[int] = [10, 20, 40]
var _grid_size_idx: int = 1  # default 20
var _color_palette := [
	Color(1.0, 0.4, 0.4),  # Red
	Color(0.4, 1.0, 0.4),  # Green
	Color(0.4, 0.6, 1.0),  # Blue
	Color(1.0, 0.8, 0.2),  # Yellow
	Color(1.0, 0.5, 1.0),  # Pink
	Color(0.4, 1.0, 1.0),  # Cyan
	Color(1.0, 0.6, 0.2),  # Orange
	Color(0.7, 0.5, 1.0),  # Purple
]

@onready var graph_edit: GraphEdit = %GraphEdit


func _ready() -> void:
	_init_registry()
	_setup_style()
	_connect_signals()
	_build_node_menus()
	_setup_flow_overlay()
	_load_recent_files()
	if FileAccess.file_exists(SAVE_PATH):
		load_graph()
	else:
		_add_default_notepad()


func _setup_style() -> void:
	graph_edit.add_theme_color_override("background_color", Color(0.05, 0.05, 0.05, 1.0))
	graph_edit.add_theme_color_override("grid_major", Color(0.15, 0.15, 0.15, 1.0))
	graph_edit.add_theme_color_override("grid_minor", Color(0.08, 0.08, 0.08, 1.0))
	graph_edit.add_theme_color_override("activity", Color.WHITE)
	graph_edit.minimap_enabled = true
	graph_edit.minimap_size = Vector2(200, 140)
	graph_edit.minimap_opacity = 0.7
	graph_edit.snapping_enabled = true
	graph_edit.snapping_distance = 20


func _setup_flow_overlay() -> void:
	_flow_overlay = Control.new()
	_flow_overlay.name = "FlowOverlay"
	_flow_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	graph_edit.add_child(_flow_overlay)
	_flow_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flow_overlay.draw.connect(_flow_overlay_draw)


func _process(_delta: float) -> void:
	if _flow_overlay == null:
		return
	if not _flow_events.is_empty():
		var now := Time.get_ticks_msec() / 1000.0
		_flow_events = _flow_events.filter(func(e): return now - e.time < 0.6)
	_flow_overlay.queue_redraw()


func export_gal() -> String:
	var lines: PackedStringArray = []
	# Build name -> type and name -> data maps
	var name_to_type: Dictionary = {}
	var nodes_data: Array = []
	for child in graph_edit.get_children():
		if child is GraphNode:
			var t := _get_node_type(child)
			name_to_type[String(child.name)] = t
			var nd := _serialize_single_node(child, t)
			nodes_data.append({"node": child, "data": nd, "type": t})

	# Build reverse port maps from assembler constants
	var in_reverse: Dictionary = {}   # type -> {port_idx -> port_name}
	var out_reverse: Dictionary = {}  # type -> {port_idx -> port_name}
	for type in AssemblerScript.INPUT_PORTS:
		in_reverse[type] = {}
		for pname in AssemblerScript.INPUT_PORTS[type]:
			var val = AssemblerScript.INPUT_PORTS[type][pname]
			if val is int:
				in_reverse[type][val] = pname
	for type in AssemblerScript.OUTPUT_PORTS:
		out_reverse[type] = {}
		for pname in AssemblerScript.OUTPUT_PORTS[type]:
			var val = AssemblerScript.OUTPUT_PORTS[type][pname]
			if val is int:
				out_reverse[type][val] = pname

	# Emit node declarations
	for entry in nodes_data:
		var child: GraphNode = entry.node
		var nd: Dictionary = entry.data
		var t: String = entry.type
		# Use node name as label, type as type
		lines.append("node %s %s at %d %d" % [String(child.name), t, int(child.position_offset.x), int(child.position_offset.y)])

	# Emit set lines for properties
	for entry in nodes_data:
		var nd: Dictionary = entry.data
		var t: String = entry.type
		var label: String = String(entry.node.name)
		# Map serialized fields to GAL set properties
		var prop_map: Dictionary = _get_gal_props(t, nd)
		for prop in prop_map:
			var val: String = str(prop_map[prop]).replace("\n", "\\n")
			lines.append("set %s.%s %s" % [label, prop, val])
		if nd.has("comment"):
			var c: String = str(nd.comment).replace("\n", "\\n")
			lines.append("set %s.comment %s" % [label, c])

	# Emit wire lines
	for conn in graph_edit.get_connection_list():
		var from_name: String = String(conn.from_node)
		var to_name: String = String(conn.to_node)
		var from_type: String = name_to_type.get(from_name, "")
		var to_type: String = name_to_type.get(to_name, "")
		var from_port_name: String = str(out_reverse.get(from_type, {}).get(conn.from_port, conn.from_port))
		var to_port_name: String = str(in_reverse.get(to_type, {}).get(conn.to_port, conn.to_port))
		lines.append("wire %s.%s -> %s.%s" % [from_name, from_port_name, to_name, to_port_name])

	return "\n".join(lines)


func _get_gal_props(type: String, nd: Dictionary) -> Dictionary:
	# Find any node of matching type in the graph to call get_gal_props on
	for child in graph_edit.get_children():
		if child is GraphNode and child.has_method("get_node_type") and child.get_node_type() == type:
			var props: Dictionary = child.get_gal_props(nd)
			if nd.has("enabled") and not nd.enabled and type != "notepad":
				props["enabled"] = "false"
			return props
	# Fallback: no matching node instance found
	if nd.has("enabled") and not nd.enabled and type != "notepad":
		return {"enabled": "false"}
	return {}


func toggle_dashboard() -> void:
	var panel: PanelContainer = get_node_or_null("DashboardPanel")
	if panel:
		panel.queue_free()
		return
	panel = PanelContainer.new()
	panel.name = "DashboardPanel"
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_top = -150
	panel.offset_left = 0
	panel.offset_right = 0
	# Style
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.05, 0.05, 0.05, 0.95)
	ps.border_color = Color.WHITE
	ps.set_border_width_all(1)
	ps.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", ps)
	# Content
	var vbox := VBoxContainer.new()
	panel.add_child(vbox)
	var header := Label.new()
	header.text = "Dashboard"
	header.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(header)
	# Gather watcher values with live-updating labels
	var has_watchers := false
	for child in graph_edit.get_children():
		if child is GraphNode and child.get("value_label") != null:
			has_watchers = true
			var row := HBoxContainer.new()
			var name_lbl := Label.new()
			name_lbl.text = child.title + " (" + String(child.name) + "):"
			name_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
			name_lbl.custom_minimum_size.x = 150
			row.add_child(name_lbl)
			var val_lbl := Label.new()
			val_lbl.text = child.get("value") if child.get("value") != null else "—"
			val_lbl.add_theme_color_override("font_color", Color.GREEN)
			# Store watcher node reference for live updates
			val_lbl.set_meta("watcher_node", child)
			row.add_child(val_lbl)
			vbox.add_child(row)
	if not has_watchers:
		var empty := Label.new()
		empty.text = "No watcher nodes. Add a Watcher node to monitor values."
		empty.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1.0))
		vbox.add_child(empty)
	add_child(panel)


func _refresh_dashboard() -> void:
	var panel: PanelContainer = get_node_or_null("DashboardPanel")
	if panel == null:
		return
	var vbox: VBoxContainer = panel.get_child(0)
	if vbox == null:
		return
	# Skip header label (child 0), update value labels in rows
	for i in range(1, vbox.get_child_count()):
		var row: HBoxContainer = vbox.get_child(i)
		if row.get_child_count() < 2:
			continue
		var val_lbl: Label = row.get_child(1)
		var watcher: Node = val_lbl.get_meta("watcher_node") if val_lbl.has_meta("watcher_node") else null
		if watcher and is_instance_valid(watcher):
			var val = watcher.get("value")
			val_lbl.text = val if val != null else "—"


func get_graph_info() -> Dictionary:
	var nodes: Array = []
	var connections: Array = []
	for child in graph_edit.get_children():
		if child is GraphNode:
			var ntype: String = child.get_node_type() if child.has_method("get_node_type") else "unknown"
			var nd: Dictionary = {"name": String(child.name), "title": child.title, "type": ntype, "position": [child.position_offset.x, child.position_offset.y]}
			if child.has_method("serialize_data"):
				var data: Dictionary = child.serialize_data()
				for key in data:
					nd[key] = data[key]
			nodes.append(nd)
	for conn in graph_edit.get_connection_list():
		connections.append({"from": String(conn.from_node), "from_port": int(conn.from_port), "to": String(conn.to_node), "to_port": int(conn.to_port)})
	return {"nodes": nodes, "connections": connections, "node_count": nodes.size(), "wire_count": connections.size()}


func _safe_output_pos(node: GraphNode, port: int) -> Vector2:
	if port < node.get_output_port_count():
		return node.get_output_port_position(port)
	return node.get_size() / 2.0


func _safe_input_pos(node: GraphNode, port: int) -> Vector2:
	if port < node.get_input_port_count():
		return node.get_input_port_position(port)
	return node.get_size() / 2.0


func _draw_flow_dot(from_pos: Vector2, to_pos: Vector2, progress: float, color: Color) -> void:
	var pos := from_pos.lerp(to_pos, progress)
	var radius := 3.0
	_flow_overlay.draw_circle(pos, radius, color)


func _draw_groups() -> void:
	for group in _groups:
		var nodes: Array = group.get("nodes", [])
		if nodes.is_empty():
			continue
		# Find bounding box of all group nodes
		var min_pos := Vector2(INF, INF)
		var max_pos := Vector2(-INF, -INF)
		for node_name in nodes:
			var node: GraphNode = graph_edit.get_node_or_null(NodePath(node_name))
			if node == null:
				continue
			var pos := node.position_offset * graph_edit.zoom + graph_edit.global_position - _flow_overlay.global_position
			var size := node.size * graph_edit.zoom
			min_pos = min_pos.min(pos)
			max_pos = max_pos.max(pos + size)
		if min_pos.x >= max_pos.x:
			continue
		var padding := Vector2(20, 30) * graph_edit.zoom
		var rect := Rect2(min_pos - padding, max_pos - min_pos + padding * 2)
		var color: Color = group.get("color", Color(0.2, 0.3, 0.5))
		_flow_overlay.draw_rect(rect, Color(color.r, color.g, color.b, 0.15))
		_flow_overlay.draw_rect(rect, Color(color.r, color.g, color.b, 0.5), false, 1.0)
		# Label
		var label: String = group.get("label", "Group")
		var font: Font = ThemeDB.fallback_font
		var font_size := int(maxi(10, 12 * graph_edit.zoom))
		_flow_overlay.draw_string(font, rect.position + Vector2(8, font_size + 4), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(color.r, color.g, color.b, 0.8))


func group_selected(label_text: String, color: Color) -> void:
	var selected: Array[GraphNode] = []
	for child in graph_edit.get_children():
		if child is GraphNode and child.selected:
			selected.append(child)
	if selected.is_empty():
		return
	var node_names: Array[StringName] = []
	for node in selected:
		node_names.append(node.name)
	_groups.append({"label": label_text, "color": color, "nodes": node_names})


func _toggle_selected_enabled() -> void:
	for child in graph_edit.get_children():
		if child is GraphNode and child.selected and "enabled" in child:
			child.enabled = not child.enabled


func _flow_overlay_draw() -> void:
	# Draw group boxes behind everything
	_draw_groups()
	# Draw flow animation events
	var now: float = Time.get_ticks_msec() / 1000.0
	for event in _flow_events:
		var elapsed: float = now - event.time
		var progress: float = elapsed / 0.6
		var from_node: GraphNode = graph_edit.get_node_or_null(NodePath(event.from_node))
		var to_node: GraphNode = graph_edit.get_node_or_null(NodePath(event.to_node))
		if from_node == null or to_node == null:
			continue
		var from_pos: Vector2 = _safe_output_pos(from_node, event.from_port) + from_node.position_offset
		var to_pos: Vector2 = _safe_input_pos(to_node, event.to_port) + to_node.position_offset
		from_pos = from_pos * graph_edit.zoom + graph_edit.global_position - _flow_overlay.global_position
		to_pos = to_pos * graph_edit.zoom + graph_edit.global_position - _flow_overlay.global_position
		var alpha: float = 1.0 - progress
		if _wire_style == 0:  # Dot flow
			_draw_flow_dot(from_pos, to_pos, progress, Color(1, 1, 1, alpha))
		# Draw value label at midpoint
		var val: String = event.value
		if val != "" and alpha > 0.3:
			var display := val.left(30)
			if val.length() > 30:
				display += "..."
			var mid := from_pos.lerp(to_pos, 0.5)
			var font: Font = ThemeDB.fallback_font
			var font_size: int = int(maxi(10, 12 * graph_edit.zoom))
			var text_size := font.get_string_size(display, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
			var padding := Vector2(4, 2)
			# Background pill
			var bg_rect := Rect2(mid - text_size / 2 - padding, text_size + padding * 2)
			_flow_overlay.draw_rect(bg_rect, Color(0.0, 0.0, 0.0, alpha * 0.8))
			_flow_overlay.draw_rect(bg_rect, Color(1, 1, 1, alpha * 0.5), false, 1)
			# Text
			_flow_overlay.draw_string(font, mid - text_size / 2 + Vector2(0, font_size * 0.35), display, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.7, 1.0, 0.7, alpha))
	# Draw persistent connection labels
	for key in _conn_labels:
		var val: String = _conn_labels[key]
		if val == "":
			continue
		var parts: PackedStringArray = key.split("->")
		if parts.size() != 2:
			continue
		var from_parts: PackedStringArray = parts[0].split(":")
		var to_parts: PackedStringArray = parts[1].split(":")
		if from_parts.size() != 2 or to_parts.size() != 2:
			continue
		var from_node: GraphNode = graph_edit.get_node_or_null(NodePath(from_parts[0]))
		var to_node: GraphNode = graph_edit.get_node_or_null(NodePath(to_parts[0]))
		if from_node == null or to_node == null:
			continue
		var from_port := int(from_parts[1])
		var to_port := int(to_parts[1])
		var from_pos: Vector2 = _safe_output_pos(from_node, from_port) + from_node.position_offset
		var to_pos: Vector2 = _safe_input_pos(to_node, to_port) + to_node.position_offset
		from_pos = from_pos * graph_edit.zoom + graph_edit.global_position - _flow_overlay.global_position
		to_pos = to_pos * graph_edit.zoom + graph_edit.global_position - _flow_overlay.global_position
		var display := val.left(25)
		if val.length() > 25:
			display += "..."
		var mid := from_pos.lerp(to_pos, 0.5)
		var font: Font = ThemeDB.fallback_font
		var font_size := int(maxi(9, 10 * graph_edit.zoom))
		var text_size := font.get_string_size(display, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		var padding := Vector2(3, 1)
		var bg_rect := Rect2(mid - text_size / 2 - padding, text_size + padding * 2)
		_flow_overlay.draw_rect(bg_rect, Color(0.0, 0.0, 0.0, 0.7))
		_flow_overlay.draw_string(font, mid - text_size / 2 + Vector2(0, font_size * 0.35), display, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.5, 0.9, 0.5, 0.6))
	# Draw type warning indicators on mismatched connections
	for key in _type_warnings:
		var warn_text: String = _type_warnings[key]
		var parts: PackedStringArray = key.split("->")
		if parts.size() != 2:
			continue
		var from_parts: PackedStringArray = parts[0].split(":")
		var to_parts: PackedStringArray = parts[1].split(":")
		if from_parts.size() != 2 or to_parts.size() != 2:
			continue
		var from_node: GraphNode = graph_edit.get_node_or_null(NodePath(from_parts[0]))
		var to_node: GraphNode = graph_edit.get_node_or_null(NodePath(to_parts[0]))
		if from_node == null or to_node == null:
			continue
		var from_port := int(from_parts[1])
		var to_port := int(to_parts[1])
		var from_pos: Vector2 = _safe_output_pos(from_node, from_port) + from_node.position_offset
		var to_pos: Vector2 = _safe_input_pos(to_node, to_port) + to_node.position_offset
		from_pos = from_pos * graph_edit.zoom + graph_edit.global_position - _flow_overlay.global_position
		to_pos = to_pos * graph_edit.zoom + graph_edit.global_position - _flow_overlay.global_position
		# Draw yellow warning line along the connection
		var points := [from_pos, Vector2(from_pos.x + 50, from_pos.y).lerp(Vector2(to_pos.x - 50, to_pos.y), 0.5), Vector2(to_pos.x - 50, to_pos.y).lerp(from_pos, 0.5), to_pos]
		_flow_overlay.draw_polyline(points, Color(1.0, 0.8, 0.0, 0.5), 2.0, true)
		# Warning label
		var mid := from_pos.lerp(to_pos, 0.5)
		var wfont: Font = ThemeDB.fallback_font
		var wsize := int(maxi(9, 10 * graph_edit.zoom))
		var wtext := "⚠ " + warn_text
		var wtsize := wfont.get_string_size(wtext, HORIZONTAL_ALIGNMENT_LEFT, -1, wsize)
		var wrect := Rect2(mid - wtsize / 2 - Vector2(3, 1), wtsize + Vector2(6, 2))
		_flow_overlay.draw_rect(wrect, Color(0.2, 0.15, 0.0, 0.8))
		_flow_overlay.draw_string(wfont, mid - wtsize / 2 + Vector2(0, wsize * 0.35), wtext, HORIZONTAL_ALIGNMENT_LEFT, -1, wsize, Color(1.0, 0.85, 0.0, 0.9))
	# Draw hovered connection highlight
	if not _hovered_connection.is_empty():
		var from_node: GraphNode = graph_edit.get_node_or_null(NodePath(_hovered_connection.from_node))
		var to_node: GraphNode = graph_edit.get_node_or_null(NodePath(_hovered_connection.to_node))
		if from_node and to_node:
			var from_pos: Vector2 = _safe_output_pos(from_node, _hovered_connection.from_port) + from_node.position_offset
			var to_pos: Vector2 = _safe_input_pos(to_node, _hovered_connection.to_port) + to_node.position_offset
			from_pos = from_pos * graph_edit.zoom + graph_edit.global_position - _flow_overlay.global_position
			to_pos = to_pos * graph_edit.zoom + graph_edit.global_position - _flow_overlay.global_position
			# Draw thick highlighted line along the connection
			var points := [from_pos, Vector2(from_pos.x + 50, from_pos.y).lerp(Vector2(to_pos.x - 50, to_pos.y), 0.5), Vector2(to_pos.x - 50, to_pos.y).lerp(from_pos, 0.5), to_pos]
			_flow_overlay.draw_polyline(points, Color(1.0, 0.3, 0.3, 0.7), 3.0, true)
			# "Right-click for options" hint
			var mid := from_pos.lerp(to_pos, 0.5)
			var hint_font: Font = ThemeDB.fallback_font
			var hint_size := int(maxi(9, 10 * graph_edit.zoom))
			_flow_overlay.draw_string(hint_font, mid + Vector2(0, 14), "Right-click for options", HORIZONTAL_ALIGNMENT_CENTER, -1, hint_size, Color(1.0, 0.6, 0.6, 0.8))
	# Draw bend points on connections
	for key in _wire_bends:
		var bends: Array = _wire_bends[key]
		if bends.is_empty():
			continue
		var parts: PackedStringArray = key.split("->")
		if parts.size() != 2:
			continue
		var from_parts: PackedStringArray = parts[0].split(":")
		var to_parts: PackedStringArray = parts[1].split(":")
		if from_parts.size() != 2 or to_parts.size() != 2:
			continue
		var fn: GraphNode = graph_edit.get_node_or_null(NodePath(from_parts[0]))
		var tn: GraphNode = graph_edit.get_node_or_null(NodePath(to_parts[0]))
		if fn == null or tn == null:
			continue
		for bend in bends:
			var bpos: Vector2 = bend * graph_edit.zoom + graph_edit.global_position - _flow_overlay.global_position
			# Draw small diamond at bend point
			var s := 5.0 * graph_edit.zoom
			var pts := PackedVector2Array([bpos + Vector2(0, -s), bpos + Vector2(s, 0), bpos + Vector2(0, s), bpos + Vector2(-s, 0)])
			_flow_overlay.draw_colored_polygon(pts, Color(0.8, 0.8, 1.0, 0.7))
	# Draw pulse-style animation for active connections when _wire_style == 1
	if _wire_style == 1 and not _flow_events.is_empty():
		var now_pulse: float = Time.get_ticks_msec() / 1000.0
		for event in _flow_events:
			var elapsed: float = now_pulse - event.time
			if elapsed > 1.5:
				continue
			var fn: GraphNode = graph_edit.get_node_or_null(NodePath(event.from_node))
			var tn: GraphNode = graph_edit.get_node_or_null(NodePath(event.to_node))
			if fn == null or tn == null:
				continue
			var from_pos: Vector2 = _safe_output_pos(fn, event.from_port) + fn.position_offset
			var to_pos: Vector2 = _safe_input_pos(tn, event.to_port) + tn.position_offset
			from_pos = from_pos * graph_edit.zoom + graph_edit.global_position - _flow_overlay.global_position
			to_pos = to_pos * graph_edit.zoom + graph_edit.global_position - _flow_overlay.global_position
			var alpha := 1.0 - elapsed / 1.5
			# Draw pulsing glow line
			var pulse_width := 2.0 + sin(elapsed * 8.0) * 2.0
			_flow_overlay.draw_line(from_pos, to_pos, Color(0.5, 1.0, 0.7, alpha * 0.6), pulse_width)
	# Draw alignment guides for selected nodes
	var guide_nodes: Array[GraphNode] = []
	var all_nodes: Array[GraphNode] = []
	for child in graph_edit.get_children():
		if child is GraphNode:
			all_nodes.append(child)
			if child.selected:
				guide_nodes.append(child)
	if guide_nodes.size() == 1:
		var sel := guide_nodes[0]
		var sel_cx := sel.position_offset.x + sel.size.x / 2.0
		var sel_cy := sel.position_offset.y + sel.size.y / 2.0
		var threshold := 8.0
		for other in all_nodes:
			if other == sel or other.selected:
				continue
			var o_cx := other.position_offset.x + other.size.x / 2.0
			var o_cy := other.position_offset.y + other.size.y / 2.0
			# Vertical center alignment
			if absf(sel_cy - o_cy) < threshold:
				var y_screen := sel_cy * graph_edit.zoom + graph_edit.global_position.y - _flow_overlay.global_position.y
				var x1 := minf(sel.position_offset.x, other.position_offset.x) * graph_edit.zoom + graph_edit.global_position.x - _flow_overlay.global_position.x
				var x2 := maxf(sel.position_offset.x + sel.size.x, other.position_offset.x + other.size.x) * graph_edit.zoom + graph_edit.global_position.x - _flow_overlay.global_position.x
				_flow_overlay.draw_line(Vector2(x1, y_screen), Vector2(x2, y_screen), Color(0.3, 0.8, 1.0, 0.4), 1.0)
			# Horizontal center alignment
			if absf(sel_cx - o_cx) < threshold:
				var x_screen := sel_cx * graph_edit.zoom + graph_edit.global_position.x - _flow_overlay.global_position.x
				var y1 := minf(sel.position_offset.y, other.position_offset.y) * graph_edit.zoom + graph_edit.global_position.y - _flow_overlay.global_position.y
				var y2 := maxf(sel.position_offset.y + sel.size.y, other.position_offset.y + other.size.y) * graph_edit.zoom + graph_edit.global_position.y - _flow_overlay.global_position.y
				_flow_overlay.draw_line(Vector2(x_screen, y1), Vector2(x_screen, y2), Color(0.3, 0.8, 1.0, 0.4), 1.0)


func _connect_signals() -> void:
	graph_edit.connection_request.connect(_on_connection_request)
	graph_edit.disconnection_request.connect(_on_disconnection_request)
	graph_edit.delete_nodes_request.connect(_on_delete_nodes)
	graph_edit.gui_input.connect(_on_graph_input)
	graph_edit.node_selected.connect(_on_node_selected)
	graph_edit.node_deselected.connect(_on_node_deselected)


func _build_node_menus() -> void:
	var popup: PopupMenu = $Toolbar/AddNodeMenu.get_popup()
	_populate_node_menu(popup)
	popup.id_pressed.connect(_on_add_node_menu)
	var context: PopupMenu = $ContextMenu
	_populate_node_menu(context)
	context.id_pressed.connect(_on_add_node_menu)
	context.popup_hide.connect(func(): _use_context_pos = false)


func _populate_node_menu(menu: PopupMenu) -> void:
	var id := 0
	for type in _NODE_REGISTRY:
		var label: String = _NODE_REGISTRY[type].get("menu", "")
		if label != "":
			menu.add_item(label, id)
			id += 1


func _on_add_node_menu(id: int) -> void:
	var idx := 0
	for type in _NODE_REGISTRY:
		var label: String = _NODE_REGISTRY[type].get("menu", "")
		if label == "":
			continue
		if idx == id:
			_add_node(type)
			return
		idx += 1


func _on_connection_request(from: StringName, from_port: int, to: StringName, to_port: int) -> void:
	_undo_redo.create_action("Connect nodes")
	_undo_redo.add_do_method(graph_edit.connect_node.bind(from, from_port, to, to_port))
	_undo_redo.add_undo_method(graph_edit.disconnect_node.bind(from, from_port, to, to_port))
	_undo_redo.commit_action()
	# Check for type mismatch and store warning
	var key := "%s:%d->%s:%d" % [from, from_port, to, to_port]
	var type_warn := _check_connection_types(String(from), from_port, String(to), to_port)
	if type_warn != "":
		_type_warnings[key] = type_warn
	# Clean up warning if connection was re-made without mismatch
	if type_warn == "" and _type_warnings.has(key):
		_type_warnings.erase(key)
	var source := graph_edit.get_node_or_null(NodePath(from))
	if source:
		_propagate_text(source)


func _on_disconnection_request(from: StringName, from_port: int, to: StringName, to_port: int) -> void:
	_undo_redo.create_action("Disconnect nodes")
	_undo_redo.add_do_method(graph_edit.disconnect_node.bind(from, from_port, to, to_port))
	_undo_redo.add_undo_method(graph_edit.connect_node.bind(from, from_port, to, to_port))
	_undo_redo.commit_action()
	var key := "%s:%d->%s:%d" % [from, from_port, to, to_port]
	_conn_labels.erase(key)
	_type_warnings.erase(key)
	_wire_bends.erase(key)


func _on_graph_input(event: InputEvent) -> void:
	# Track hovered connection for visual feedback
	if event is InputEventMouseMotion:
		var conn: Dictionary = graph_edit.get_closest_connection_at_point(event.position, 12.0)
		if conn != _hovered_connection:
			_hovered_connection = conn
			if _flow_overlay:
				_flow_overlay.queue_redraw()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		# Check if right-clicking on a node
		for child in graph_edit.get_children():
			if child is GraphNode and child.get_rect().has_point(event.position):
				_show_color_popup(child)
				return
		var conn: Dictionary = graph_edit.get_closest_connection_at_point(event.position, 10.0)
		if not conn.is_empty():
			_show_wire_popup(conn, event.position)
		else:
			_use_context_pos = true
			_context_spawn_pos = graph_edit.scroll_offset + event.position / graph_edit.zoom
			var context: PopupMenu = $ContextMenu
			context.position = DisplayServer.mouse_get_position()
			context.popup()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
		var conn: Dictionary = graph_edit.get_closest_connection_at_point(event.position, 10.0)
		if not conn.is_empty():
			_edit_conn_label(conn)
		else:
			for child in graph_edit.get_children():
				if child is GraphNode and child.get_global_rect().has_point(child.get_global_mouse_position()):
					# Check if click is on the title bar
					var titlebar: Control = child.get_titlebar_hbox()
					if titlebar and titlebar.get_global_rect().has_point(titlebar.get_global_mouse_position()):
						_start_rename(child)
					elif child.has_signal("open_pressed"):
						notepad_selected.emit(child)
					break
	# Quick-add nodes: number keys 1-9
	if event is InputEventKey and event.pressed and not event.ctrl_pressed and not event.shift_pressed:
		var quick_types := {
			KEY_1: "notepad", KEY_2: "math", KEY_3: "if", KEY_4: "text",
			KEY_5: "array", KEY_6: "bool", KEY_7: "http", KEY_8: "exec", KEY_9: "agent",
		}
		if quick_types.has(event.keycode):
			var type: String = quick_types[event.keycode]
			var mouse_pos := graph_edit.get_local_mouse_position()
			var pos := graph_edit.scroll_offset + mouse_pos / graph_edit.zoom
			add_node_at(type, pos)
			get_viewport().set_input_as_handled()
	# Delete selected nodes
	if event is InputEventKey and event.pressed and event.keycode == KEY_DELETE:
		var selected: Array[StringName] = []
		for child in graph_edit.get_children():
			if child is GraphNode and child.selected:
				selected.append(child.name)
		if not selected.is_empty():
			_on_delete_nodes(selected)
			get_viewport().set_input_as_handled()
	# Ctrl+A select all
	if event is InputEventKey and event.pressed and event.ctrl_pressed and event.keycode == KEY_A:
		for child in graph_edit.get_children():
			if child is GraphNode:
				child.selected = true
		get_viewport().set_input_as_handled()
	# Alignment shortcuts (Ctrl+Shift+L/T/H/V)
	if event is InputEventKey and event.pressed and event.ctrl_pressed and event.shift_pressed:
		if event.keycode == KEY_L:
			_align_selected("left")
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_T:
			_align_selected("top")
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_H:
			_align_selected("distribute_h")
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_V:
			_align_selected("distribute_v")
			get_viewport().set_input_as_handled()


func _start_rename(node: GraphNode) -> void:
	# Don't rename if already editing
	if get_node_or_null("RenameEdit"):
		return
	var edit := LineEdit.new()
	edit.name = "RenameEdit"
	edit.text = node.title
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.mouse_filter = Control.MOUSE_FILTER_STOP
	# Style to match theme
	edit.add_theme_color_override("background_color", Color(0.15, 0.15, 0.15, 1.0))
	edit.add_theme_color_override("font_color", Color.WHITE)
	edit.add_theme_color_override("caret_color", Color.WHITE)
	edit.text_submitted.connect(_on_rename_submitted.bind(node, edit))
	edit.focus_exited.connect(_on_rename_submitted.bind("", node, edit))
	# Add to title bar
	var titlebar: HBoxContainer = node.get_titlebar_hbox()
	if titlebar:
		titlebar.add_child(edit)
		edit.grab_focus()
		edit.select_all()


func _on_rename_submitted(new_title: String, node: GraphNode, edit: LineEdit) -> void:
	if new_title != "" and new_title != node.title:
		node.title = new_title
	edit.queue_free()


func _show_color_popup(node: GraphNode) -> void:
	var popup := PopupMenu.new()
	popup.name = "ColorPopup"
	popup.add_item("None", -1)
	for i in range(_color_palette.size()):
		popup.add_item("", i)
		# Style the item with the color
		var style := StyleBoxFlat.new()
		style.bg_color = _color_palette[i]
		style.set_corner_radius_all(2)
		style.set_content_margin_all(4)
		popup.set_item_icon_max_width(i + 1, 40)
		# Use icon to show color swatch
		var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
		img.fill(_color_palette[i])
		var tex := ImageTexture.create_from_image(img)
		popup.set_item_icon(i + 1, tex)
	# Add separator + batch actions
	popup.add_separator()
	popup.add_item("Toggle Enabled (selected)", 100)
	popup.add_item("Group Selected", 101)
	popup.id_pressed.connect(_on_color_selected.bind(node))
	popup.popup_hide.connect(popup.queue_free)
	add_child(popup)
	popup.position = DisplayServer.mouse_get_position()
	popup.popup()


func _on_color_selected(id: int, node: GraphNode) -> void:
	match id:
		-1:
			_node_colors.erase(node.name)
			_update_node_style(node)
		100:
			_toggle_selected_enabled()
		101:
			group_selected("Group", Color(0.3, 0.5, 0.8))
		var idx:
			if idx >= 0 and idx < _color_palette.size():
				_node_colors[node.name] = _color_palette[idx]
				_update_node_style(node)


func _conn_key(conn: Dictionary) -> String:
	return "%s:%d->%s:%d" % [conn.from_node, conn.from_port, conn.to_node, conn.to_port]


func _show_wire_popup(conn: Dictionary, click_pos: Vector2) -> void:
	var popup := PopupMenu.new()
	popup.name = "WirePopup"
	add_child(popup)
	var key := _conn_key(conn)
	popup.add_item("Add Bend Point", 0)
	if _wire_bends.has(key) and _wire_bends[key].size() > 0:
		popup.add_item("Remove Bend Points", 1)
	popup.add_item("Edit Label", 2)
	popup.add_item("Disconnect", 3)
	popup.id_pressed.connect(func(id: int) -> void:
		match id:
			0:  # Add bend
				var graph_pos := graph_edit.scroll_offset + click_pos / graph_edit.zoom
				if not _wire_bends.has(key):
					_wire_bends[key] = []
				_wire_bends[key].append(graph_pos)
				if _flow_overlay:
					_flow_overlay.queue_redraw()
			1:  # Remove bends
				_wire_bends.erase(key)
				if _flow_overlay:
					_flow_overlay.queue_redraw()
			2:  # Edit label
				_edit_conn_label(conn)
			3:  # Disconnect
				_undo_redo.create_action("Disconnect nodes")
				_undo_redo.add_do_method(graph_edit.disconnect_node.bind(conn.from_node, conn.from_port, conn.to_node, conn.to_port))
				_undo_redo.add_undo_method(graph_edit.connect_node.bind(conn.from_node, conn.from_port, conn.to_node, conn.to_port))
				_undo_redo.commit_action()
		popup.queue_free()
	)
	popup.popup_on_parent(Rect2i(DisplayServer.mouse_get_position(), Vector2i.ZERO))


func _edit_conn_label(conn: Dictionary) -> void:
	var key := _conn_key(conn)
	var dialog := ConfirmationDialog.new()
	dialog.title = "Connection Label"
	var edit := LineEdit.new()
	edit.placeholder_text = "Label for this wire..."
	edit.text = _conn_labels.get(key, "")
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var vbox := VBoxContainer.new()
	vbox.add_child(edit)
	dialog.add_child(vbox)
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	dialog.min_size = Vector2(300, 80)
	dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_SCREEN_WITH_MOUSE_FOCUS
	add_child(dialog)
	dialog.confirmed.connect(func() -> void:
		var text := edit.text.strip_edges()
		if text == "":
			_conn_labels.erase(key)
		else:
			_conn_labels[key] = text
		if _flow_overlay:
			_flow_overlay.queue_redraw()
		dialog.queue_free()
	)
	dialog.canceled.connect(func() -> void:
		dialog.queue_free()
	)
	dialog.popup()


func _on_delete_nodes(nodes: Array[StringName]) -> void:
	_undo_redo.create_action("Delete nodes")
	for node_name in nodes:
		var node := graph_edit.get_node_or_null(NodePath(node_name))
		if not node:
			continue
		# Save connections for undo
		var node_conns: Array = []
		for conn in graph_edit.get_connection_list():
			if conn.from_node == node_name or conn.to_node == node_name:
				node_conns.append({"from": conn.from_node, "from_port": conn.from_port, "to": conn.to_node, "to_port": conn.to_port})
		# Save serialized data for undo
		var node_type := _get_node_type(node)
		var saved_data := {"name": String(node_name), "type": node_type, "x": node.position_offset.x, "y": node.position_offset.y}
		_serialize_node_data(node, saved_data)
		_undo_redo.add_do_method(_clear_connections_for.bind(node_name))
		_undo_redo.add_do_method(node.queue_free)
		_undo_redo.add_undo_method(_undo_restore_node.bind(saved_data, node_conns))
	_undo_redo.commit_action()


func _on_node_selected(node: Node) -> void:
	if node is GraphNode:
		_selected_node = node
		_show_node_info(node)


func _on_node_deselected(_node: Node) -> void:
	_selected_node = null
	_hide_node_info()


func _show_node_info(node: GraphNode) -> void:
	_hide_node_info()
	var panel := PanelContainer.new()
	panel.name = "NodeInfoPanel"
	panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	panel.offset_left = -280
	panel.offset_top = 40
	panel.offset_right = -10
	panel.offset_bottom = -10
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.06, 0.06, 0.1, 0.95)
	ps.border_color = Color(0.3, 0.6, 1.0)
	ps.set_border_width_all(1)
	ps.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", ps)
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(scroll)
	var vbox := VBoxContainer.new()
	scroll.add_child(vbox)
	# Title
	var type := _get_node_type(node)
	var header := Label.new()
	header.text = "%s (%s)" % [node.title, type]
	header.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	vbox.add_child(header)
	# Name
	var name_lbl := Label.new()
	name_lbl.text = "Name: %s" % node.name
	name_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(name_lbl)
	# Position
	var pos_lbl := Label.new()
	pos_lbl.text = "Position: %.0f, %.0f" % [node.position_offset.x, node.position_offset.y]
	pos_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(pos_lbl)
	# Connections
	var conns := graph_edit.get_connection_list()
	var incoming: int = 0
	var outgoing: int = 0
	for conn in conns:
		if str(conn.to_node) == String(node.name):
			incoming += 1
		if str(conn.from_node) == String(node.name):
			outgoing += 1
	var conn_lbl := Label.new()
	conn_lbl.text = "Connections: %d in, %d out" % [incoming, outgoing]
	conn_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(conn_lbl)
	# Output values
	var out_map: Dictionary = AssemblerScript.OUTPUT_PORTS.get(type, {})
	if out_map.size() > 0:
		var out_header := Label.new()
		out_header.text = "Outputs:"
		out_header.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
		vbox.add_child(out_header)
		for port_name in out_map:
			var port_idx: int = int(out_map[port_name])
			var val := _get_output_text(node, port_idx)
			var val_lbl := Label.new()
			val_lbl.text = "  %s: %s" % [port_name, val.left(80)]
			val_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
			vbox.add_child(val_lbl)
	# Connection list
	if incoming > 0 or outgoing > 0:
		var wire_header := Label.new()
		wire_header.text = "Wires:"
		wire_header.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
		vbox.add_child(wire_header)
		for conn in conns:
			if str(conn.from_node) == String(node.name):
				var wire_lbl := Label.new()
				wire_lbl.text = "  -> %s:%d" % [conn.to_node, conn.to_port]
				wire_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
				vbox.add_child(wire_lbl)
			if str(conn.to_node) == String(node.name):
				var wire_lbl := Label.new()
				wire_lbl.text = "  <- %s:%d" % [conn.from_node, conn.from_port]
				wire_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
				vbox.add_child(wire_lbl)
	add_child(panel)


func _hide_node_info() -> void:
	var panel: Node = get_node_or_null("NodeInfoPanel")
	if panel:
		panel.queue_free()


func _clear_connections_for(node_name: StringName) -> void:
	var all_connections := graph_edit.get_connection_list()
	for conn in all_connections:
		if conn.from_node == node_name or conn.to_node == node_name:
			graph_edit.disconnect_node(conn.from_node, conn.from_port, conn.to_node, conn.to_port)


func _undo_restore_node(saved_data: Dictionary, connections: Array) -> void:
	# Rebuild just this one node from its serialized data
	_build_nodes_from_data({"nodes": [saved_data], "connections": []})
	# Restore connections
	for conn in connections:
		graph_edit.connect_node(conn.from, conn.from_port, conn.to, conn.to_port)


func undo() -> void:
	_undo_redo.undo()


func redo() -> void:
	_undo_redo.redo()


func copy_selected() -> void:
	_clipboard = {"nodes": [], "connections": []}
	var selected_names: Array[StringName] = []
	for child in graph_edit.get_children():
		if child is GraphNode and child.selected:
			selected_names.append(child.name)
			var t := _get_node_type(child)
			var nd := _serialize_single_node(child, t)
			_clipboard.nodes.append(nd)
	# Copy connections between selected nodes
	for conn in graph_edit.get_connection_list():
		if conn.from_node in selected_names and conn.to_node in selected_names:
			_clipboard.connections.append({
				"from_node": String(conn.from_node),
				"from_port": conn.from_port,
				"to_node": String(conn.to_node),
				"to_port": conn.to_port,
			})


func paste_nodes() -> void:
	if _clipboard.nodes.is_empty():
		return
	_undo_redo.create_action("Paste nodes")
	var offset := Vector2(50, 50)
	var old_to_new: Dictionary = {}
	for nd in _clipboard.nodes:
		var node: GraphNode = _create_node_by_type(nd.type)
		var new_name: String = "%s%d" % [_NODE_REGISTRY[nd.type].prefix, _node_counter]
		_node_counter += 1
		old_to_new[nd.name] = new_name
		node.name = new_name
		node.position_offset = Vector2(nd.x, nd.y) + offset
		_connect_node_signals(node)
		_undo_redo.add_do_method(graph_edit.add_child.bind(node))
		_undo_redo.add_undo_method(graph_edit.remove_child.bind(node))
		# Store node data for property restoration after commit
		node.set_meta("_paste_data", nd)
	# Reconnect internal wires
	for conn in _clipboard.connections:
		var new_from: String = old_to_new.get(conn.from_node, "")
		var new_to: String = old_to_new.get(conn.to_node, "")
		if new_from != "" and new_to != "":
			_undo_redo.add_do_method(graph_edit.connect_node.bind(StringName(new_from), conn.from_port, StringName(new_to), conn.to_port))
			_undo_redo.add_undo_method(graph_edit.disconnect_node.bind(StringName(new_from), conn.from_port, StringName(new_to), conn.to_port))
	_undo_redo.commit_action()
	# Restore properties on pasted nodes
	for nd in _clipboard.nodes:
		var new_name: String = old_to_new[nd.name]
		var node: GraphNode = graph_edit.get_node_or_null(NodePath(new_name))
		if node and node.has_meta("_paste_data"):
			var data: Dictionary = node.get_meta("_paste_data")
			_apply_props(node, data.type, data.get("_props", {}))
			if data.has("comment"):
				node.tooltip_text = data.comment
			node.remove_meta("_paste_data")


func duplicate_selected() -> void:
	copy_selected()
	paste_nodes()


func _ensure_registry() -> void:
	if _NODE_REGISTRY.is_empty():
		_init_registry()


func _add_node(type: String) -> GraphNode:
	_ensure_registry()
	var reg: Dictionary = _NODE_REGISTRY.get(type, {})
	if reg.is_empty():
		return null
	var node: GraphNode = reg.scene.instantiate()
	node.name = "%s%d" % [reg.prefix, _node_counter]
	_node_counter += 1
	node.position_offset = _get_next_node_position()
	_connect_node_signals(node)
	graph_edit.add_child(node)
	return node


func add_node_at(type: String, pos: Vector2) -> GraphNode:
	_ensure_registry()
	var reg: Dictionary = _NODE_REGISTRY.get(type, {})
	if reg.is_empty():
		return null
	var node: GraphNode = reg.scene.instantiate()
	node.name = "%s%d" % [reg.prefix, _node_counter]
	_node_counter += 1
	node.position_offset = pos
	_connect_node_signals(node)
	graph_edit.add_child(node)
	return node


func auto_layout() -> void:
	var nodes: Array[GraphNode] = []
	for child in graph_edit.get_children():
		if child is GraphNode:
			nodes.append(child)
	if nodes.is_empty():
		return
	# Build adjacency: which nodes feed into which
	var has_input: Dictionary = {}  # node_name -> bool (has any incoming connection)
	var connections := graph_edit.get_connection_list()
	for conn in connections:
		has_input[String(conn.to_node)] = true
	# Assign layers via topological sort (BFS from roots)
	var layers: Dictionary = {}  # node_name -> layer index
	var queue: Array[StringName] = []
	# Root nodes = no incoming connections
	for node in nodes:
		if not has_input.has(node.name):
			layers[node.name] = 0
			queue.append(node.name)
	# BFS to assign layers
	var visited: Dictionary = {}
	while not queue.is_empty():
		var current_name: StringName = queue.pop_front()
		if visited.has(current_name):
			continue
		visited[current_name] = true
		var current_layer: int = layers.get(current_name, 0)
		for conn in connections:
			if String(conn.from_node) == String(current_name):
				var target_name: String = String(conn.to_node)
				var new_layer: int = current_layer + 1
				if not layers.has(target_name) or layers[target_name] < new_layer:
					layers[target_name] = new_layer
				queue.append(StringName(target_name))
	# Assign layers to unvisited nodes (disconnected)
	for node in nodes:
		if not layers.has(node.name):
			layers[node.name] = 0
	# Position nodes by layer
	var layer_nodes: Dictionary = {}  # layer -> [nodes]
	for node in nodes:
		var layer: int = layers[node.name]
		if not layer_nodes.has(layer):
			layer_nodes[layer] = []
		layer_nodes[layer].append(node)
	var h_spacing := 300.0
	var v_spacing := 180.0
	for layer in layer_nodes:
		var nodes_in_layer: Array = layer_nodes[layer]
		for i in range(nodes_in_layer.size()):
			var node: GraphNode = nodes_in_layer[i]
			node.position_offset = Vector2(layer * h_spacing, i * v_spacing)


func _align_selected(mode: String) -> void:
	var selected: Array[GraphNode] = []
	for child in graph_edit.get_children():
		if child is GraphNode and child.selected:
			selected.append(child)
	if selected.size() < 2:
		return
	match mode:
		"left":
			var min_x := selected[0].position_offset.x
			for node in selected:
				min_x = mini(min_x, node.position_offset.x)
			for node in selected:
				node.position_offset.x = min_x
		"top":
			var min_y := selected[0].position_offset.y
			for node in selected:
				min_y = mini(min_y, node.position_offset.y)
			for node in selected:
				node.position_offset.y = min_y
		"distribute_h":
			var sorted: Array[GraphNode] = []
			sorted.assign(selected)
			sorted.sort_custom(func(a, b): return a.position_offset.x < b.position_offset.x)
			var first_x := sorted[0].position_offset.x
			var last_x := sorted[sorted.size() - 1].position_offset.x
			var step := (last_x - first_x) / float(sorted.size() - 1)
			for i in range(sorted.size()):
				sorted[i].position_offset.x = first_x + step * i
		"distribute_v":
			var sorted: Array[GraphNode] = []
			sorted.assign(selected)
			sorted.sort_custom(func(a, b): return a.position_offset.y < b.position_offset.y)
			var first_y := sorted[0].position_offset.y
			var last_y := sorted[sorted.size() - 1].position_offset.y
			var step := (last_y - first_y) / float(sorted.size() - 1)
			for i in range(sorted.size()):
				sorted[i].position_offset.y = first_y + step * i


func _connect_node_signals(node: GraphNode) -> void:
	if node.has_signal("delete_pressed"):
		node.delete_pressed.connect(_on_node_delete)
	if node.has_signal("text_updated"):
		node.text_updated.connect(_propagate_text.bind(node))
	if node.has_signal("run_pressed"):
		node.run_pressed.connect(_on_node_run)
	if node.has_signal("open_pressed"):
		node.open_pressed.connect(_on_notepad_open)
	if node.has_signal("edit_pressed"):
		node.edit_pressed.connect(_on_enter_subgraph)


func _update_node_style(node: GraphNode) -> void:
	var has_color: bool = _node_colors.has(node.name)
	var node_color: Color = _node_colors.get(node.name, Color.WHITE)
	# Error state takes priority
	if node.has_meta("_error") and node.get_meta("_error") != "":
		node.modulate = Color(1.0, 0.3, 0.3, 1.0)
		return
	# Breakpoint state — orange tint
	if node.has_meta("_breakpoint") and node.get_meta("_breakpoint"):
		# Breakpoint hit — bright red-orange (triggered)
		if node.has_meta("_bp_hit") and node.get_meta("_bp_hit"):
			node.modulate = Color(1.0, 0.4, 0.1, 1.0)
		else:
			node.modulate = Color(1.0, 0.65, 0.0, 1.0)
		return
	# Debug active state — cyan tint
	if node.has_meta("_debug_active") and node.get_meta("_debug_active"):
		node.modulate = Color(0.3, 0.8, 1.0, 1.0)
		return
	if node.get("enabled") == null:
		if has_color:
			node.modulate = Color(node_color.r, node_color.g, node_color.b, 0.8)
		return
	var is_enabled: bool = node.get("enabled")
	if not is_enabled:
		node.modulate = Color(0.5, 0.5, 0.5, 1.0)
	elif has_color:
		node.modulate = Color(node_color.r, node_color.g, node_color.b, 0.8)
	else:
		node.modulate = Color.WHITE
	# Update tooltip with node info
	var comment: String = node.tooltip_text
	if node.has_meta("_user_comment"):
		comment = node.get_meta("_user_comment")
	else:
		node.set_meta("_user_comment", comment)
	var info := _build_tooltip(node)
	node.tooltip_text = info if comment == "" else comment + "\n" + info


func _build_tooltip(node: GraphNode) -> String:
	var type := _get_node_type(node)
	var lines: PackedStringArray = ["[%s]" % type]
	if node.get("enabled") != null:
		var en: bool = node.get("enabled")
		lines.append("Enabled: %s" % str(en))
	# Show port info with types
	var type_map: Dictionary = AssemblerScript.PORT_TYPE_MAP.get(type, {})
	var in_map: Dictionary = AssemblerScript.INPUT_PORTS.get(type, {})
	var out_map: Dictionary = AssemblerScript.OUTPUT_PORTS.get(type, {})
	# Input ports
	if in_map.size() > 0:
		lines.append("Inputs:")
		for port_name in in_map:
			var pt: String = type_map.get(port_name, "any")
			lines.append("  %s (%s)" % [port_name, pt])
	# Output ports with values
	if out_map.size() > 0:
		lines.append("Outputs:")
		for port_name in out_map:
			var port_idx: int = int(out_map[port_name])
			var val := _get_output_text(node, port_idx)
			var pt: String = type_map.get(port_name, "any")
			if val != "":
				var display := val.left(60)
				if val.length() > 60:
					display += "..."
				lines.append("  %s (%s): %s" % [port_name, pt, display])
			else:
				lines.append("  %s (%s)" % [port_name, pt])
	return "\n".join(lines)


func _update_stats() -> void:
	var stats: Label = get_node_or_null("Toolbar/StatsLabel")
	if stats == null:
		return
	var node_count := 0
	var type_counts: Dictionary = {}
	for child in graph_edit.get_children():
		if child is GraphNode:
			node_count += 1
			var t: String = _get_node_type(child)
			type_counts[t] = type_counts.get(t, 0) + 1
	var conn_count := graph_edit.get_connection_list().size()
	# Show summary + most common types
	var summary := "%d nodes, %d wires" % [node_count, conn_count]
	if type_counts.size() > 0:
		var top_types: Array = type_counts.keys()
		top_types.sort_custom(func(a, b): return type_counts[a] > type_counts[b])
		var breakdown := ""
		for i in range(mini(3, top_types.size())):
			if i > 0: breakdown += ", "
			breakdown += "%s: %d" % [top_types[i], type_counts[top_types[i]]]
		if breakdown != "":
			summary += " | " + breakdown
	stats.text = summary
	stats.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1.0))


func _add_default_notepad() -> void:
	var node := _add_node("notepad")
	var temp_path := OS.get_temp_dir().path_join("note_untitled.tmp")
	if FileAccess.file_exists(temp_path):
		var f := FileAccess.open(temp_path, FileAccess.READ)
		if f:
			node.set_text(f.get_as_text())
			f.close()


func add_default_notepad() -> void:
	_add_node("notepad")


func add_notepad_node() -> void:
	_add_node("notepad")


func add_exec_node() -> void:
	_add_node("exec")


func add_find_file_node() -> void:
	_add_node("find_file")


func add_bool_node() -> void:
	_add_node("bool")


func add_binary_node() -> void:
	_add_node("binary")


func add_pc_node() -> void:
	_add_node("pc")


func add_timer_node() -> void:
	_add_node("timer")


func add_if_node() -> void:
	_add_node("if")


func add_http_node() -> void:
	_add_node("http")


func add_math_node() -> void:
	_add_node("math")


func add_button_node() -> void:
	_add_node("button")


func add_json_node() -> void:
	_add_node("json")


func add_agent_node() -> void:
	_add_node("agent")


func add_sub_graph_node() -> void:
	_add_node("subgraph")


func add_graph_input_node() -> void:
	var node := _add_node("graph_input")
	var idx := _count_node_type("graph_input")
	node.title = "Input %d" % idx


func add_graph_output_node() -> void:
	var node := _add_node("graph_output")
	var idx := _count_node_type("graph_output")
	node.title = "Output %d" % idx


func _count_node_type(type: String) -> int:
	var count: int = 0
	for child in graph_edit.get_children():
		if child is GraphNode:
			var t := _get_node_type(child)
			if t == type:
				count += 1
	return count


func _get_next_node_position() -> Vector2:
	if _use_context_pos:
		_use_context_pos = false
		return _context_spawn_pos
	var existing := 0
	for child in graph_edit.get_children():
		if child is GraphNode:
			existing += 1
	var view_center := graph_edit.scroll_offset + graph_edit.size / (2.0 * graph_edit.zoom)
	var col := existing % 3
	var row := existing / 3
	return view_center + Vector2(col * 250.0, row * 150.0)


func zoom_to_fit() -> void:
	var nodes: Array = []
	for child in graph_edit.get_children():
		if child is GraphNode:
			nodes.append(child)
	if nodes.is_empty():
		return
	# Compute bounding box of all nodes
	var min_x: float = 1e9
	var min_y: float = 1e9
	var max_x: float = -1e9
	var max_y: float = -1e9
	for node: GraphNode in nodes:
		var pos: Vector2 = node.position_offset
		var size: Vector2 = node.get_size()
		min_x = minf(min_x, pos.x)
		min_y = minf(min_y, pos.y)
		max_x = maxf(max_x, pos.x + size.x)
		max_y = maxf(max_y, pos.y + size.y)
	var content_size: Vector2 = Vector2(max_x - min_x, max_y - min_y)
	if content_size.x <= 0 or content_size.y <= 0:
		return
	# Add padding
	var padding := 80.0
	content_size.x += padding * 2
	content_size.y += padding * 2
	# Calculate zoom to fit
	var view_size: Vector2 = graph_edit.get_size()
	var zoom_x := view_size.x / content_size.x
	var zoom_y := view_size.y / content_size.y
	var new_zoom: float = minf(zoom_x, zoom_y)
	new_zoom = clampf(new_zoom, graph_edit.zoom_min, graph_edit.zoom_max)
	graph_edit.zoom = new_zoom
	# Center scroll on the content
	var content_center := Vector2((min_x + max_x) / 2.0, (min_y + max_y) / 2.0)
	graph_edit.scroll_offset = content_center * new_zoom - view_size / 2.0


func _on_zoom_in() -> void:
	graph_edit.zoom = clampf(graph_edit.zoom * 1.2, graph_edit.zoom_min, graph_edit.zoom_max)


func _on_zoom_out() -> void:
	graph_edit.zoom = clampf(graph_edit.zoom / 1.2, graph_edit.zoom_min, graph_edit.zoom_max)


func _on_wire_style_btn() -> void:
	_wire_style = (_wire_style + 1) % 3
	var labels: PackedStringArray = ["Wire: Dot", "Wire: Pulse", "Wire: Static"]
	var btn: Button = $Toolbar/WireStyleBtn
	if btn:
		btn.text = labels[_wire_style]
	if _flow_overlay:
		_flow_overlay.queue_redraw()


func _on_snap_btn() -> void:
	# Cycle: snap on with current size -> snap off -> snap on next size -> ...
	graph_edit.snapping_enabled = not graph_edit.snapping_enabled
	if graph_edit.snapping_enabled:
		_grid_size_idx = (_grid_size_idx + 1) % _grid_sizes.size()
		graph_edit.snapping_distance = _grid_sizes[_grid_size_idx]
	var btn: Button = $Toolbar/SnapBtn
	if btn:
		if graph_edit.snapping_enabled:
			btn.text = "Snap: %d" % _grid_sizes[_grid_size_idx]
		else:
			btn.text = "Snap: Off"


var _search_results: Array = []
var _search_index: int = -1

func search_nodes(query: String) -> void:
	_search_results.clear()
	_search_index = -1
	if query == "":
		return
	var q := query.to_lower()
	var matched_names: Dictionary = {}
	# Search nodes by name, title, type
	for child in graph_edit.get_children():
		if child is GraphNode:
			var name_match: bool = String(child.name).to_lower().find(q) != -1
			var title_match: bool = child.title.to_lower().find(q) != -1
			var type_match: bool = false
			if child.has_method("get_node_type"):
				type_match = child.get_node_type().find(q) != -1
			if name_match or title_match or type_match:
				_search_results.append(child)
				matched_names[String(child.name)] = true
	# Also search connections by source/target
	for conn in graph_edit.get_connection_list():
		var from_name: String = str(conn.from_node)
		var to_name: String = str(conn.to_node)
		if from_name.to_lower().find(q) != -1 or to_name.to_lower().find(q) != -1:
			var from_node: GraphNode = graph_edit.get_node_or_null(NodePath(from_name))
			if from_node and not matched_names.has(from_name):
				_search_results.append(from_node)
				matched_names[from_name] = true
	if _search_results.size() > 0:
		_search_index = 0
		_center_on_node(_search_results[0])

func search_next() -> void:
	if _search_results.is_empty():
		return
	_search_index = (_search_index + 1) % _search_results.size()
	_center_on_node(_search_results[_search_index])

func _center_on_node(node: GraphNode) -> void:
	# Deselect all, select target
	for child in graph_edit.get_children():
		if child is GraphNode:
			child.selected = false
	node.selected = true
	# Center view on the node
	var node_center: Vector2 = node.position_offset + node.get_size() / 2.0
	graph_edit.scroll_offset = node_center * graph_edit.zoom - graph_edit.get_size() / 2.0


func _on_enter_subgraph(sub_graph_node: GraphNode) -> void:
	# Save current graph state
	var parent_data := _serialize_current_graph()
	_graph_stack.append({"data": parent_data, "subgraph_name": _current_subgraph_name})
	_current_subgraph_name = sub_graph_node.name
	# Grab data before clearing (node gets queued for free)
	var internal: Dictionary = sub_graph_node.internal_data.duplicate(true)
	var inputs: Array = sub_graph_node.stored_inputs.duplicate()
	# Clear and load sub-graph
	_clear_all_nodes()
	_node_counter = 0
	_build_nodes_from_data(internal)
	# Push stored inputs into GraphInputNodes
	_feed_subgraph_inputs(inputs)
	_show_subgraph_nav(true)


func _feed_subgraph_inputs(inputs: Array) -> void:
	var idx := 0
	for child in graph_edit.get_children():
		if child is GraphNode and _get_node_type(child) == "graph_input":
			if idx < inputs.size() and inputs[idx] != "":
				child.set_text(inputs[idx])
			idx += 1


func _capture_subgraph_outputs() -> Array:
	var outputs: Array = []
	for child in graph_edit.get_children():
		if child is GraphNode and _get_node_type(child) == "graph_output":
			outputs.append(child.text_buffer if child.get("text_buffer") != null else "")
	return outputs


func _on_exit_subgraph() -> void:
	if _graph_stack.is_empty():
		return
	# Save current sub-graph state and capture outputs
	var subgraph_data := _serialize_current_graph()
	var captured_outputs := _capture_subgraph_outputs()
	var exited_name := _current_subgraph_name
	# Pop parent state
	var parent: Dictionary = _graph_stack.pop_back()
	_current_subgraph_name = parent["subgraph_name"]
	_clear_all_nodes()
	_node_counter = 0
	_build_nodes_from_data(parent["data"])
	# Find the SubGraph node we just exited and update its internal data
	if exited_name != "":
		var node := graph_edit.get_node_or_null(NodePath(exited_name))
		if node and node.has_signal("edit_pressed"):
			node.internal_data = subgraph_data
			node.stored_outputs = captured_outputs
			node.call("_rebuild_ports")
			node.text_updated.emit()
	_show_subgraph_nav(_graph_stack.size() > 0)


func _show_subgraph_nav(show: bool) -> void:
	var back_btn: Button = get_node_or_null("Toolbar/BackBtn")
	if back_btn:
		back_btn.visible = show
	var add_input: Button = get_node_or_null("Toolbar/AddGInput")
	var add_output: Button = get_node_or_null("Toolbar/AddGOutput")
	if add_input:
		add_input.visible = show
	if add_output:
		add_output.visible = show
	var save_tmpl: Button = get_node_or_null("Toolbar/SaveTemplateBtn")
	if save_tmpl:
		save_tmpl.visible = show


func save_subgraph_template(template_name: String) -> bool:
	if template_name == "":
		return false
	var dir := DirAccess.open("user://")
	if dir and not dir.dir_exists("templates"):
		dir.make_dir("templates")
	var gal_text := export_gal()
	if gal_text == "":
		return false
	var path := "user://templates/%s.gal" % template_name.replace(" ", "_")
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(gal_text)
	f.close()
	return true


func list_templates() -> PackedStringArray:
	var results: PackedStringArray = []
	var dir := DirAccess.open("user://templates")
	if dir == null:
		return results
	dir.list_dir_begin()
	var fname: String = dir.get_next()
	while fname != "":
		if fname.ends_with(".gal"):
			results.append(fname.left(fname.length() - 4))
		fname = dir.get_next()
	dir.list_dir_end()
	return results


func load_subgraph_template(template_name: String) -> bool:
	var path := "user://templates/%s.gal" % template_name.replace(" ", "_")
	if not FileAccess.file_exists(path):
		return false
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
	var gal_text := f.get_as_text()
	f.close()
	# Clear current graph and load template
	_clear_all_nodes()
	_node_counter = 0
	var result := assemble(gal_text)
	return not result.is_empty()


func _get_node_type(child: Node) -> String:
	if child is GraphNode and child.has_method("get_node_type"):
		return child.get_node_type()
	return "exec"


func _serialize_node_data(child: Node, node_data: Dictionary) -> void:
	if child.has_method("serialize_data"):
		var extra: Dictionary = child.serialize_data()
		for key in extra:
			node_data[key] = extra[key]
	var t: String = node_data.type
	if child.get("enabled") != null and t != "notepad":
		node_data["enabled"] = child.get("enabled")
	if child.tooltip_text != "":
		node_data["comment"] = child.tooltip_text
	if _node_colors.has(child.name):
		node_data["color"] = _node_colors[child.name].to_html(false)


func _serialize_single_node(child: GraphNode, type: String) -> Dictionary:
	var nd := {
		"name": String(child.name),
		"type": type,
		"x": child.position_offset.x,
		"y": child.position_offset.y,
	}
	_serialize_node_data(child, nd)
	return nd


func _serialize_current_graph() -> Dictionary:
	var data := {"nodes": [], "connections": []}
	for child in graph_edit.get_children():
		if child is GraphNode:
			var node_type := _get_node_type(child)
			var node_data := {
				"name": child.name,
				"type": node_type,
				"x": child.position_offset.x,
				"y": child.position_offset.y,
			}
			_serialize_node_data(child, node_data)
			data.nodes.append(node_data)
	for conn in graph_edit.get_connection_list():
		var key := "%s:%d->%s:%d" % [conn.from_node, conn.from_port, conn.to_node, conn.to_port]
		var conn_data := {
			"from_node": String(conn.from_node),
			"from_port": conn.from_port,
			"to_node": String(conn.to_node),
			"to_port": conn.to_port,
		}
		if _wire_bends.has(key):
			var bends: Array = []
			for b in _wire_bends[key]:
				bends.append({"x": b.x, "y": b.y})
			conn_data["bends"] = bends
		if _conn_labels.has(key):
			conn_data["label"] = _conn_labels[key]
		data.connections.append(conn_data)
	data["wire_style"] = _wire_style
	return data


func _on_node_run(exec_node: GraphNode) -> void:
	if exec_node.has_method("_start_loop"):
		exec_node._start_loop()
	else:
		_execute_node(exec_node)


func _execute_node(exec_node: GraphNode) -> void:
	print("=== EXEC NODE RUN ===")
	var input_text := ""
	var connections := graph_edit.get_connection_list()
	print("Connections: ", connections)
	for conn in connections:
		if conn.to_node == exec_node.name and conn.to_port == 0:
			var source := graph_edit.get_node_or_null(NodePath(conn.from_node))
			if source and source.has_method("set_text"):
				input_text = source.text_buffer
			break

	if input_text == "":
		return

	var output := []
	var args := PackedStringArray(["/C", input_text])
	print("About to execute: cmd /C ", input_text)
	var error := OS.execute("cmd", args, output)
	print("OS.execute result: error=", error, " output=", output)

	var stdout_text := ""
	for line in output:
		stdout_text += str(line)
	var stderr_text := "Error: exit code %d" % error if error != 0 else ""
	# Mark error state on exec node
	if error != 0:
		exec_node.set_meta("_error", stderr_text)
	else:
		if exec_node.has_meta("_error"):
			exec_node.remove_meta("_error")
	_update_node_style(exec_node)

	for conn in connections:
		if conn.from_node == exec_node.name and conn.from_port == 0:
			var target := graph_edit.get_node_or_null(NodePath(conn.to_node))
			if target and target.has_method("set_text"):
				match conn.to_port:
					1: target.set_text(stdout_text + target.text_buffer)
					2: target.set_text(target.text_buffer + stdout_text)
					_: target.set_text(stdout_text)

	if stderr_text != "":
		for conn in connections:
			if conn.from_node == exec_node.name and conn.from_port == 1:
				var target := graph_edit.get_node_or_null(NodePath(conn.to_node))
				if target and target.has_method("set_text"):
					match conn.to_port:
						1: target.set_text(stderr_text + target.text_buffer)
						2: target.set_text(target.text_buffer + stderr_text)
						_: target.set_text(stderr_text)


var _pending_delete_node: GraphNode = null
var _delete_dialog: AcceptDialog = null


func _on_node_delete(node: GraphNode) -> void:
	if node.has_method("set_text") and node.file_path == "":
		# Unsaved notepad — ask save or delete
		_pending_delete_node = node
		if _delete_dialog == null:
			_delete_dialog = AcceptDialog.new()
			_delete_dialog.title = "Unsaved Notepad"
			_delete_dialog.dialog_text = "Save or delete?"
			_delete_dialog.ok_button_text = "Delete"
			_delete_dialog.add_button("Save", false, "save")
			_delete_dialog.confirmed.connect(_confirm_delete)
			_delete_dialog.custom_action.connect(_on_delete_action)
			add_child(_delete_dialog)
		_delete_dialog.popup_centered()
	else:
		_do_delete(node)


func _do_delete(node: GraphNode) -> void:
	if node.has_method("set_text") and node.file_path != "":
		var f := FileAccess.open(node.file_path, FileAccess.WRITE)
		if f:
			f.store_string(node.text_buffer)
			f.close()
	_clear_connections_for(node.name)
	node.queue_free()


func _confirm_delete() -> void:
	if _pending_delete_node:
		_do_delete(_pending_delete_node)
		_pending_delete_node = null


func _on_delete_action(action: StringName) -> void:
	if action == &"save" and _pending_delete_node:
		notepad_selected.emit(_pending_delete_node)
		_pending_delete_node = null
	_delete_dialog.hide()


func _get_output_text(source: GraphNode, from_port: int) -> String:
	if source.get("enabled") != null and not source.get("enabled"):
		return ""
	var text := ""
	if source.has_method("get_port_output"):
		text = source.get_port_output(from_port)
	elif source.get("output_true") != null:
		text = source.output_true if from_port == 0 else source.output_false
	elif source.get("response_text") != null:
		text = source.response_text if from_port == 0 else source.error_text
	elif source.get("output_value") != null:
		text = str(source.get("output_value"))
	elif source.get("text_buffer") != null:
		text = str(source.get("text_buffer"))
	elif source.get("file_path") != null:
		text = str(source.get("file_path"))
	# Resolve ${NodeName.port} templates in notepad outputs
	if text.find("${") >= 0 and source.get("text_buffer") != null:
		text = resolve_template(text)
	return text


func _propagate_text(source: GraphNode) -> void:
	if _assembling:
		return
	if source.has_signal("edit_pressed") and source.has_method("set_input"):
		_evaluate_subgraph_internals(source)
	_propagate_in(graph_edit, source)
	_refresh_dashboard()


func _propagate_in(gedit: GraphEdit, source: GraphNode) -> void:
	if source.name in _visited:
		return
	_visited.append(source.name)
	if source.has_signal("edit_pressed") and source.has_method("set_input"):
		_evaluate_subgraph_internals(source)
	var connections := gedit.get_connection_list()
	for conn in connections:
		if conn.from_node == source.name:
			var out_text := _get_output_text(source, conn.from_port)
			if out_text == "" and conn.from_port != 0:
				continue
			# Detect error state on source node
			var src_error: String = ""
			if source.get("error_text") != null and str(source.get("error_text")) != "":
				src_error = str(source.get("error_text"))
			if src_error != "":
				source.set_meta("_error", src_error)
				_update_node_style(source)
			elif source.has_meta("_error"):
				source.remove_meta("_error")
				_update_node_style(source)
			# Record flow animation
			_flow_events.append({
				"from_node": String(conn.from_node),
				"from_port": int(conn.from_port),
				"to_node": String(conn.to_node),
				"to_port": int(conn.to_port),
				"time": Time.get_ticks_msec() / 1000.0,
				"value": out_text
			})
			# Persist connection label
			var key := "%s:%d->%s:%d" % [conn.from_node, conn.from_port, conn.to_node, conn.to_port]
			_conn_labels[key] = out_text
			var target := gedit.get_node_or_null(NodePath(conn.to_node))
			if target and target.has_method("set_input"):
				target.set_input(conn.to_port, out_text)
				_update_node_style(target)
			elif target and target.has_method("set_text") and out_text != "":
				match conn.to_port:
					1: target.set_text(out_text + target.text_buffer)
					2: target.set_text(target.text_buffer + out_text)
					_: target.set_text(out_text)
			elif target and not target.has_method("set_text") and conn.to_port == 1:
				_execute_node(target)
	_visited.erase(source.name)


func _on_notepad_open(node: GraphNode) -> void:
	notepad_selected.emit(node)


const SAVE_PATH := "user://graph.json"

var _asm_dialog: ConfirmationDialog = null
var _asm_edit: CodeEdit = null


func _setup_gal_highlighter(edit: CodeEdit) -> void:
	var hl := SyntaxHighlighter.new()
	# GAL keywords — cyan
	var keywords := ["node", "set", "wire", "trigger", "expect", "var", "import", "func", "call", "end", "if", "else", "endif", "for", "endfor", "while", "endwhile", "return", "break"]
	for kw in keywords:
		hl.add_keyword_color(kw, Color(0.4, 0.8, 1.0))
	# Operators — yellow
	for op in ["==", "!=", ">", "<", "contains", "->"]:
		hl.add_keyword_color(op, Color(1.0, 0.8, 0.2))
	edit.syntax_highlighter = hl
	# Auto-complete
	edit.code_completion_enabled = true
	# Add node type completions
	for type in _NODE_REGISTRY:
		edit.add_code_completion_option(CodeEdit.KIND_CLASS, type, type, Color(0.6, 0.9, 0.6))
	# Add keyword completions
	for kw in keywords:
		edit.add_code_completion_option(CodeEdit.KIND_MEMBER, kw, kw, Color(0.4, 0.8, 1.0))


func _on_assemble_btn() -> void:
	if _asm_dialog == null:
		_asm_dialog = ConfirmationDialog.new()
		_asm_dialog.title = "Graph Assembly"
		var vbox := VBoxContainer.new()
		# Snippet selector
		var snippet_bar := HBoxContainer.new()
		var snippet_btn := MenuButton.new()
		snippet_btn.text = "Snippets"
		var popup: PopupMenu = snippet_btn.get_popup()
		var snippets := _get_gal_snippets()
		var sid := 0
		for s in snippets:
			popup.add_item(s.title, sid)
			sid += 1
		popup.id_pressed.connect(func(id: int): _asm_edit.text = snippets[id].source)
		snippet_bar.add_child(snippet_btn)
		vbox.add_child(snippet_bar)
		# Code editor
		_asm_edit = CodeEdit.new()
		_asm_edit.placeholder_text = "# Enter assembly source\nnode a notepad\nset a.text Hello\nwire a -> b"
		_asm_edit.custom_minimum_size = Vector2i(700, 420)
		_asm_edit.add_theme_color_override("background_color", Color(0.08, 0.08, 0.08))
		_asm_edit.add_theme_color_override("font_color", Color.WHITE)
		_setup_gal_highlighter(_asm_edit)
		vbox.add_child(_asm_edit)
		_asm_dialog.add_child(vbox)
		_asm_dialog.confirmed.connect(_on_assemble_confirmed)
		add_child(_asm_dialog)
	_asm_dialog.popup_centered()


func _on_assemble_confirmed() -> void:
	assemble(_asm_edit.text)


func _get_gal_snippets() -> Array[Dictionary]:
	var snippets: Array[Dictionary] = []
	snippets.append({
		"title": "Hello World",
		"source": "# Basic notepad pipeline\nnode a notepad\nset a.text Hello World\ntrigger a"
	})
	snippets.append({
		"title": "HTTP Fetch",
		"source": "# Fetch a URL and extract JSON\nnode h http\nset h.url https://api.example.com/data\nnode j json\nset j.path result.items\nwire h.response -> j.json\ntrigger h"
	})
	snippets.append({
		"title": "Agent Chat",
		"source": "# Single agent prompt\nnode a agent\nset a.model llama3.2\nset a.max_turns 3\ntrigger a"
	})
	snippets.append({
		"title": "Math Pipeline",
		"source": "# Calculate and display\nnode m math\nset m.mode add\nset m.a 42\nset m.b 8\nnode n notepad\nwire m.result -> n.set\ntrigger m"
	})
	snippets.append({
		"title": "Multi-Agent Chat",
		"source": "# Two agents chatting\nnode a1 agent\nset a1.model llama3.2\nnode a2 agent\nset a2.model llama3.2\nwire a1.result -> a2.prompt\nwire a2.result -> a1.prompt\ntrigger a1"
	})
	snippets.append({
		"title": "Conditional Flow",
		"source": "# If/else branching\nnode n notepad\nset n.text hello world\nnode i if\nset i.condition hello\nwire n.out -> i.data\ntrigger n"
	})
	return snippets


func _on_load_gal_btn() -> void:
	var dialog := FileDialog.new()
	dialog.use_native_dialog = true
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.filters = PackedStringArray(["*.gal"])
	dialog.file_selected.connect(_on_gal_file_selected)
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered(Vector2i(600, 400))


func _on_gal_file_selected(path: String) -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return
	var source := f.get_as_text()
	f.close()
	_last_gal_path = path
	_gal_watcher_mtime = FileAccess.get_modified_time(path)
	_add_recent_file(path)
	_start_gal_watcher()
	assemble(source)


func _on_export_gal_btn() -> void:
	var gal_text := export_gal()
	var dialog := FileDialog.new()
	dialog.use_native_dialog = true
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.filters = PackedStringArray(["*.gal"])
	dialog.file_selected.connect(_on_gal_export_saved.bind(gal_text))
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered(Vector2i(600, 400))


func _on_gal_export_saved(path: String, content: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(content)
		f.close()


func _on_save_template() -> void:
	# Prompt for template name
	var dialog := ConfirmationDialog.new()
	var line_edit := LineEdit.new()
	line_edit.placeholder_text = "template name"
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialog.add_child(line_edit)
	dialog.title = "Save as Template"
	dialog.confirmed.connect(func():
		var name := line_edit.text.strip_edges()
		if name != "":
			save_subgraph_template(name)
		dialog.queue_free()
	)
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered(Vector2i(300, 100))

func _start_gal_watcher() -> void:
	if _gal_watcher != null:
		_gal_watcher.queue_free()
	_gal_watcher = Timer.new()
	_gal_watcher.wait_time = 1.0
	_gal_watcher.one_shot = false
	_gal_watcher.timeout.connect(_check_gal_file_changed)
	add_child(_gal_watcher)
	_gal_watcher.start()


func _check_gal_file_changed() -> void:
	if _last_gal_path == "":
		return
	if not FileAccess.file_exists(_last_gal_path):
		return
	var mtime := FileAccess.get_modified_time(_last_gal_path)
	if mtime != _gal_watcher_mtime:
		_gal_watcher_mtime = mtime
		var f := FileAccess.open(_last_gal_path, FileAccess.READ)
		if f:
			var source := f.get_as_text()
			f.close()
			assemble(source)


func _load_recent_files() -> void:
	if not FileAccess.file_exists(_RECENT_PATH):
		return
	var f := FileAccess.open(_RECENT_PATH, FileAccess.READ)
	if f == null:
		return
	var json := JSON.new()
	if json.parse(f.get_as_text()) == OK and json.data is Array:
		_recent_files = PackedStringArray(json.data)
	f.close()


func _save_recent_files() -> void:
	var f := FileAccess.open(_RECENT_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(_recent_files))
		f.close()


func _add_recent_file(path: String) -> void:
	# Remove if already exists, then prepend
	var idx := _recent_files.find(path)
	if idx >= 0:
		_recent_files.remove_at(idx)
	_recent_files.insert(0, path)
	if _recent_files.size() > MAX_RECENT:
		_recent_files = _recent_files.slice(0, MAX_RECENT)
	_save_recent_files()


func get_recent_files() -> PackedStringArray:
	return _recent_files


func _on_export_png_btn() -> void:
	var dialog := FileDialog.new()
	dialog.use_native_dialog = true
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.filters = PackedStringArray(["*.png"])
	dialog.file_selected.connect(_on_png_saved)
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered(Vector2i(600, 400))


func _on_png_saved(path: String) -> void:
	var img := graph_edit.get_viewport().get_texture().get_image()
	var err := img.save_png(path)
	if err != OK:
		push_error("Failed to save PNG: %s" % path)


func _on_test_btn() -> void:
	var runner: RefCounted = load("res://test_runner.gd").new()
	var result: Dictionary = runner.run_all(self)
	_show_test_results(result)


func _show_test_results(result: Dictionary) -> void:
	var text := "Tests: %d passed, %d failed\n\n" % [result.passed, result.failed]
	for detail in result.details:
		var icon := "PASS" if detail.status == "PASS" else "FAIL"
		text += "[%s] %s\n" % [icon, detail.file.get_file()]
		if detail.has("failures"):
			for f in detail.failures:
				text += "  - %s\n" % f
	var dlg := AcceptDialog.new()
	dlg.title = "Test Results"
	dlg.dialog_text = text
	add_child(dlg)
	dlg.popup_centered()
	dlg.confirmed.connect(dlg.queue_free)


func assemble(source: String) -> Dictionary:
	var parser := AssemblerScript.new()
	var data: Dictionary = parser.parse(source)
	if parser.get_errors().size() > 0:
		var err_text := "Assembly errors:\n"
		for e in parser.get_errors():
			err_text += e + "\n"
		_show_error_overlay(err_text)
		return {}

	_clear_all_nodes()
	# Clear any error overlay from previous failed assembly
	var old_err: Node = get_node_or_null("ErrorOverlay")
	if old_err:
		old_err.queue_free()
	_node_counter = 0
	_visited.clear()

	_assembling = true
	var label_to_node: Dictionary = {}
	var label_to_type: Dictionary = {}
	var auto_idx := 0

	# Phase 1: Create nodes
	for node_data in data.nodes:
		var node := _create_node_by_type(node_data.type)
		node.name = node_data.name
		if node_data._has_pos:
			node.position_offset = Vector2(node_data.x, node_data.y)
		else:
			var col := auto_idx % 3
			var row := auto_idx / 3
			node.position_offset = Vector2(col * 250.0, row * 150.0)
			auto_idx += 1
		# Connect signals
		if node.has_signal("text_updated"):
			node.text_updated.connect(_propagate_text.bind(node))
		if node.has_signal("delete_pressed"):
			node.delete_pressed.connect(_on_node_delete)
		if node.has_signal("open_pressed"):
			node.open_pressed.connect(_on_notepad_open)
		if node.has_signal("run_pressed"):
			node.run_pressed.connect(_on_node_run)
		if node.has_signal("edit_pressed"):
			node.edit_pressed.connect(_on_enter_subgraph)
		graph_edit.add_child(node)
		if node.has_method("_ready"):
			node._ready()
		label_to_node[node_data._label] = node
		label_to_type[node_data._label] = node_data.type
		var num_str := ""
		for c in node_data.name:
			if c >= '0' and c <= '9':
				num_str += c
		if num_str != "":
			_node_counter = maxi(_node_counter, num_str.to_int() + 1)

		# Apply properties
		_apply_props(node, node_data.type, node_data._props)

	# Phase 2: Wire connections
	for conn_data in data.connections:
		var src: GraphNode = label_to_node[conn_data._src_label]
		var dst: GraphNode = label_to_node[conn_data._dst_label]
		var src_type: String = label_to_type[conn_data._src_label]
		var dst_type: String = label_to_type[conn_data._dst_label]

		var from_port := _resolve_output_port(src, src_type, conn_data._src_port)
		var to_port := _resolve_input_port(dst, dst_type, conn_data._dst_port)

		if from_port >= 0 and to_port >= 0:
			graph_edit.connect_node(src.name, from_port, dst.name, to_port)
			if conn_data.has("_type_warn"):
				var key: String = "%s:%d->%s:%d" % [src.name, from_port, dst.name, to_port]
				_type_warnings[key] = conn_data._type_warn

	_assembling = false

	# Phase 3: Propagate
	for label in label_to_node:
		var node: GraphNode = label_to_node[label]
		if node.has_signal("text_updated"):
			_propagate_text(node)

	# Phase 4: Fire triggers
	for label in data.triggers:
		if label_to_node.has(label):
			var node: GraphNode = label_to_node[label]
			if node.get("trigger_port") != null:
				node.set_input(int(node.get("trigger_port")), "true")
			elif node.has_signal("text_updated"):
				_propagate_text(node)

	# Phase 5: Mark breakpoint nodes
	var breaks: Array = data.get("breaks", [])
	for blabel in breaks:
		if label_to_node.has(blabel):
			var bnode: GraphNode = label_to_node[blabel]
			bnode.set_meta("_breakpoint", true)
			_update_node_style(bnode)
	# Also mark nodes with empty break label on all nodes (global break)
	if breaks.has(""):
		for label in label_to_node:
			var n: GraphNode = label_to_node[label]
			n.set_meta("_breakpoint", true)
			_update_node_style(n)

	_update_stats()
	return {"labels": label_to_node, "types": label_to_type, "nodes": data.nodes.size(), "wires": data.connections.size()}


func _on_debug_btn() -> void:
	# Use the same dialog as assemble, but enter debug mode
	if _asm_dialog == null:
		_asm_dialog = ConfirmationDialog.new()
		_asm_dialog.title = "Debug GAL"
		_asm_edit = CodeEdit.new()
		_asm_edit.placeholder_text = "# Enter GAL to debug\nnode a notepad\nset a.text Hello\ntrigger a"
		_asm_edit.custom_minimum_size = Vector2i(700, 450)
		_asm_edit.add_theme_color_override("background_color", Color(0.08, 0.08, 0.08))
		_asm_edit.add_theme_color_override("font_color", Color.WHITE)
		_setup_gal_highlighter(_asm_edit)
		_asm_dialog.add_child(_asm_edit)
		_asm_dialog.confirmed.connect(_on_debug_confirmed)
		add_child(_asm_dialog)
	else:
		_asm_dialog.title = "Debug GAL"
	_asm_dialog.popup_centered()


func _on_debug_confirmed() -> void:
	assemble_debug(_asm_edit.text)


func assemble_debug(source: String) -> Dictionary:
	# Like assemble() but skip trigger firing — enter debug mode
	var parser := AssemblerScript.new()
	var data: Dictionary = parser.parse(source)
	if parser.get_errors().size() > 0:
		var err_text := "Assembly errors:\n"
		for e in parser.get_errors():
			err_text += e + "\n"
		_show_error_overlay(err_text)
		return {}

	_clear_all_nodes()
	var old_err: Node = get_node_or_null("ErrorOverlay")
	if old_err:
		old_err.queue_free()
	_node_counter = 0
	_visited.clear()

	_assembling = true
	var label_to_node: Dictionary = {}
	var label_to_type: Dictionary = {}
	var auto_idx := 0

	# Phase 1: Create nodes
	for node_data in data.nodes:
		var node := _create_node_by_type(node_data.type)
		node.name = node_data.name
		if node_data._has_pos:
			node.position_offset = Vector2(node_data.x, node_data.y)
		else:
			var col := auto_idx % 3
			var row := auto_idx / 3
			node.position_offset = Vector2(col * 250.0, row * 150.0)
			auto_idx += 1
		if node.has_signal("text_updated"):
			node.text_updated.connect(_propagate_text.bind(node))
		if node.has_signal("delete_pressed"):
			node.delete_pressed.connect(_on_node_delete)
		if node.has_signal("open_pressed"):
			node.open_pressed.connect(_on_notepad_open)
		if node.has_signal("run_pressed"):
			node.run_pressed.connect(_on_node_run)
		if node.has_signal("button_pressed"):
			node.button_pressed.connect(_on_node_run)
		graph_edit.add_child(node)
		# Apply properties
		_apply_props(node, node_data.type, node_data._props)
		label_to_node[node_data._label] = node
		label_to_type[node_data._label] = node_data.type

	# Phase 2: Wire connections
	for conn_data in data.connections:
		var src: GraphNode = label_to_node[conn_data._src_label]
		var dst: GraphNode = label_to_node[conn_data._dst_label]
		var src_type: String = label_to_type[conn_data._src_label]
		var dst_type: String = label_to_type[conn_data._dst_label]
		var from_port := _resolve_output_port(src, src_type, conn_data._src_port)
		var to_port := _resolve_input_port(dst, dst_type, conn_data._dst_port)
		if from_port >= 0 and to_port >= 0:
			graph_edit.connect_node(src.name, from_port, dst.name, to_port)
			if conn_data.has("_type_warn"):
				var key: String = "%s:%d->%s:%d" % [src.name, from_port, dst.name, to_port]
				_type_warnings[key] = conn_data._type_warn

	_assembling = false

	# Phase 3: Propagate initial values
	for label in label_to_node:
		var node: GraphNode = label_to_node[label]
		if node.has_signal("text_updated"):
			_propagate_text(node)

	# Phase 5: Mark breakpoint nodes
	var breaks: Array = data.get("breaks", [])
	for blabel in breaks:
		if label_to_node.has(blabel):
			var bnode: GraphNode = label_to_node[blabel]
			bnode.set_meta("_breakpoint", true)
			_update_node_style(bnode)

	# Enter debug mode — store triggers for step-through
	_debug_mode = true
	_debug_triggers = data.triggers.duplicate()
	_debug_idx = 0
	_debug_label_map = label_to_node
	_show_debug_ui(true)
	_update_debug_label()
	_update_stats()
	return {"labels": label_to_node, "types": label_to_type, "nodes": data.nodes.size(), "wires": data.connections.size()}


func _show_debug_ui(show: bool) -> void:
	var step_btn: Button = get_node_or_null("Toolbar/DebugStepBtn")
	var run_btn: Button = get_node_or_null("Toolbar/DebugRunBtn")
	var stop_btn: Button = get_node_or_null("Toolbar/DebugStopBtn")
	var label: Label = get_node_or_null("Toolbar/DebugLabel")
	if step_btn: step_btn.visible = show
	if run_btn: run_btn.visible = show
	if stop_btn: stop_btn.visible = show
	if label: label.visible = show
	# Show/hide debug watch panel
	if show:
		_ensure_debug_watch_panel()
	else:
		var panel: Node = get_node_or_null("DebugWatchPanel")
		if panel:
			panel.queue_free()


func _ensure_debug_watch_panel() -> void:
	if get_node_or_null("DebugWatchPanel") != null:
		return
	var panel := PanelContainer.new()
	panel.name = "DebugWatchPanel"
	panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	panel.offset_left = -250
	panel.offset_top = -200
	panel.offset_right = -10
	panel.offset_bottom = -10
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.05, 0.05, 0.1, 0.9)
	ps.border_color = Color(0.3, 0.7, 1.0)
	ps.set_border_width_all(1)
	ps.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", ps)
	var vbox := VBoxContainer.new()
	vbox.name = "WatchVBox"
	panel.add_child(vbox)
	var header := Label.new()
	header.text = "Debug Watch"
	header.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))
	vbox.add_child(header)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.name = "WatchScroll"
	vbox.add_child(scroll)
	var list := VBoxContainer.new()
	list.name = "WatchList"
	scroll.add_child(list)
	add_child(panel)


func _update_debug_watch() -> void:
	if not _debug_mode: return
	var list: VBoxContainer = get_node_or_null("DebugWatchPanel/WatchVBox/WatchScroll/WatchList")
	if list == null: return
	# Clear old entries
	for child in list.get_children():
		child.queue_free()
	# Populate with node outputs
	for label in _debug_label_map:
		var node: GraphNode = _debug_label_map[label]
		var type: String = ""
		# Find type from registry
		if node.has_method("get_node_type"):
			type = node.get_node_type()
		if type == "": continue
		var outputs: Dictionary = AssemblerScript.OUTPUT_PORTS.get(type, {})
		for port_name in outputs:
			var port_idx: int = outputs[port_name]
			var val: String = _get_output_text(node, port_idx)
			if val == "": continue
			var entry := HBoxContainer.new()
			var name_lbl := Label.new()
			name_lbl.text = "%s.%s" % [label, port_name]
			name_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
			name_lbl.custom_minimum_size.x = 100
			entry.add_child(name_lbl)
			var val_lbl := Label.new()
			val_lbl.text = val.left(40)
			val_lbl.add_theme_color_override("font_color", Color(0.8, 1.0, 0.8))
			entry.add_child(val_lbl)
			list.add_child(entry)


func _update_debug_label() -> void:
	var label: Label = get_node_or_null("Toolbar/DebugLabel")
	if label == null: return
	if not _debug_mode:
		label.text = ""
		return
	label.text = "Trigger %d/%d" % [_debug_idx, _debug_triggers.size()]


func _debug_step() -> void:
	if not _debug_mode: return
	if _debug_idx >= _debug_triggers.size():
		_update_debug_label()
		return
	var trig_label: String = _debug_triggers[_debug_idx]
	_debug_idx += 1
	# Clear previous debug highlight
	_clear_debug_highlight()
	if _debug_label_map.has(trig_label):
		var node: GraphNode = _debug_label_map[trig_label]
		# Highlight the triggered node
		node.set_meta("_debug_active", true)
		_update_node_style(node)
		# Fire the trigger
		if node.get("trigger_port") != null:
			node.set_input(int(node.get("trigger_port")), "true")
		elif node.has_signal("text_updated"):
			_propagate_text(node)
	# Highlight breakpoint nodes that received data (breakpoint hit)
	_highlight_breakpoint_hits()
	_update_debug_watch()
	_update_debug_label()


func _debug_run_all() -> void:
	if not _debug_mode: return
	_clear_debug_highlight()
	while _debug_idx < _debug_triggers.size():
		var trig_label: String = _debug_triggers[_debug_idx]
		_debug_idx += 1
		if _debug_label_map.has(trig_label):
			var node: GraphNode = _debug_label_map[trig_label]
			if node.get("trigger_port") != null:
				node.set_input(int(node.get("trigger_port")), "true")
			elif node.has_signal("text_updated"):
				_propagate_text(node)
	_update_debug_watch()
	_update_debug_label()


func _debug_stop() -> void:
	_debug_mode = false
	_debug_triggers.clear()
	_debug_label_map.clear()
	_clear_debug_highlight()
	_show_debug_ui(false)
	# Remove debug watch panel if present
	var panel: Node = get_node_or_null("DebugWatchPanel")
	if panel:
		panel.queue_free()


func _clear_debug_highlight() -> void:
	for child in graph_edit.get_children():
		if child is GraphNode:
			if child.has_meta("_debug_active"):
				child.remove_meta("_debug_active")
				_update_node_style(child)
			if child.has_meta("_bp_hit"):
				child.remove_meta("_bp_hit")
				_update_node_style(child)


func _highlight_breakpoint_hits() -> void:
	# After firing a trigger, find breakpoint nodes that have output data
	for child in graph_edit.get_children():
		if child is GraphNode and child.has_meta("_breakpoint") and child.get_meta("_breakpoint"):
			# Check if node produced output
			var has_output := false
			if child.has_method("get_port_output"):
				for pi in range(child.get_child_count()):
					var out := _get_output_text(child, pi)
					if out != "":
						has_output = true
						break
			if has_output:
				child.set_meta("_bp_hit", true)
				_update_node_style(child)


func get_node_output(node: GraphNode, port: int) -> String:
	return _get_output_text(node, port)


func resolve_template(text: String) -> String:
	# Replace ${LabelName.port} with live node output values
	var result := text
	var start := 0
	while true:
		var open_pos := result.find("${", start)
		if open_pos == -1:
			break
		var close_pos := result.find("}", open_pos)
		if close_pos == -1:
			break
		var ref: String = result.substr(open_pos + 2, close_pos - open_pos - 2)
		var dot_pos := ref.find(".")
		if dot_pos == -1:
			start = close_pos + 1
			continue
		var label: String = ref.left(dot_pos)
		var port_name: String = ref.substr(dot_pos + 1)
		# Find node by name (could be label or Godot name)
		var target: GraphNode = null
		for child in graph_edit.get_children():
			if child is GraphNode and (String(child.name) == label or child.title == label):
				target = child
				break
		if target == null:
			start = close_pos + 1
			continue
		var t := _get_node_type(target)
		var port_map: Dictionary = AssemblerScript.OUTPUT_PORTS.get(t, {})
		var port_idx = port_map.get(port_name)
		if port_idx == null:
			start = close_pos + 1
			continue
		var value := _get_output_text(target, int(port_idx))
		result = result.left(open_pos) + value + result.substr(close_pos + 1)
		start = open_pos + value.length()
	return result


func _create_node_by_type(type: String) -> GraphNode:
	_ensure_registry()
	var reg: Dictionary = _NODE_REGISTRY.get(type, {})
	if reg.is_empty():
		return _NODE_REGISTRY["notepad"].scene.instantiate()
	return reg.scene.instantiate()


func _apply_props(node: GraphNode, type: String, props: Dictionary) -> void:
	for prop in props:
		var val: String = props[prop].replace("\\n", "\n")
		match prop:
			"text":
				if node.has_method("set_text"):
					node.set_text(val)
			"file_path":
				if node.has_method("set_file"):
					node.set_file(val)
			"enabled":
				node.set("enabled", val != "false" and val != "")
				_update_node_style(node)
			"mode":
				var mode_map: Dictionary = AssemblerScript.MODE_NAMES.get(type, {})
				if node.get("mode_option") != null:
					if mode_map.has(val):
						node.mode_option.selected = mode_map[val]
					elif val.is_valid_int():
						node.mode_option.selected = int(val)
			"output_value":
				node.set("output_value", val)
				if node.get("toggle_btn") != null:
					node.toggle_btn.text = val
			"counter":
				node.set("counter", int(val))
				if node.has_method("_update_display"):
					node.call("_update_display")
			"max":
				if node.get("max_spin") != null:
					node.max_spin.value = int(val)
				if node.has_method("_update_display"):
					node.call("_update_display")
			"prompt_text":
				node.set("prompt_text", val)
				node.set("output_value", val)
			"interval":
				node.set("interval_secs", float(val))
			"count":
				if node.get("count_spin") != null:
					node.count_spin.value = int(val)
			"url":
				node.set("url", val)
				if node.get("url_edit") != null:
					node.url_edit.text = val
			"body":
				node.set("body", val)
			"headers":
				node.set("headers_text", val)
			"method":
				var mode_map: Dictionary = AssemblerScript.MODE_NAMES.get("http", {})
				if node.get("method_option") != null:
					if mode_map.has(val):
						node.method_option.selected = mode_map[val]
					elif val.is_valid_int():
						node.method_option.selected = int(val)
			"condition_text":
				node.set("condition_text", val)
			"data_text":
				node.set("data_text", val)
			"json_text":
				node.set("json_text", val)
			"path":
				node.set("path", val)
			"title":
				node.title = val
			"model":
				node.set("model", val)
				if node.get("model_edit") != null:
					node.model_edit.text = val
			"max_turns":
				node.set("max_turns", int(val))
				if node.get("turns_spin") != null:
					node.turns_spin.value = int(val)
			"api_key":
				node.set("api_key", val)
				if node.get("key_edit") != null:
					node.key_edit.text = val
			"timeout_secs":
				node.set("timeout_secs", float(val))
			"context_limit":
				node.set("context_limit", int(val))
			"comment":
				node.tooltip_text = val
			"cases":
				node.set("cases_text", val)
				if node.get("case_edit") != null:
					node.case_edit.text = val
			"param":
				if node.get("param_edit") != null:
					node.param_edit.text = val


func _resolve_output_port(node: GraphNode, type: String, port_name: String) -> int:
	var map: Dictionary = AssemblerScript.OUTPUT_PORTS.get(type, {})
	return int(map.get(port_name, 0))


func _resolve_input_port(node: GraphNode, type: String, port_name: String) -> int:
	var map: Dictionary = AssemblerScript.INPUT_PORTS.get(type, {})
	var value = map.get(port_name, 0)
	if value is String:
		return int(node.get(value)) if node.get(value) != null else 0
	return int(value)


func _check_connection_types(from_name: String, from_port: int, to_name: String, to_port: int) -> String:
	# Resolve node types and port names, then check PORT_TYPE_MAP for mismatch
	var from_node: GraphNode = graph_edit.get_node_or_null(NodePath(from_name))
	var to_node: GraphNode = graph_edit.get_node_or_null(NodePath(to_name))
	if from_node == null or to_node == null:
		return ""
	var from_type: String = from_node.get_node_type() if from_node.has_method("get_node_type") else ""
	var to_type: String = to_node.get_node_type() if to_node.has_method("get_node_type") else ""
	if from_type == "" or to_type == "":
		return ""
	# Find output port name by index
	var out_map: Dictionary = AssemblerScript.OUTPUT_PORTS.get(from_type, {})
	var from_port_name: String = ""
	for pname in out_map:
		if int(out_map[pname]) == from_port:
			from_port_name = pname
			break
	# Find input port name by index
	var in_map: Dictionary = AssemblerScript.INPUT_PORTS.get(to_type, {})
	var to_port_name: String = ""
	for pname in in_map:
		var val = in_map[pname]
		var idx: int = int(to_node.get(val)) if val is String and to_node.get(val) != null else int(val)
		if idx == to_port:
			to_port_name = pname
			break
	if from_port_name == "" or to_port_name == "":
		return ""
	var src_port_type: String = AssemblerScript.PORT_TYPE_MAP.get(from_type, {}).get(from_port_name, "any")
	var dst_port_type: String = AssemblerScript.PORT_TYPE_MAP.get(to_type, {}).get(to_port_name, "any")
	if src_port_type != "any" and dst_port_type != "any" and src_port_type != dst_port_type:
		return src_port_type + " -> " + dst_port_type
	return ""


func _on_new_graph() -> void:
	_clear_all_nodes()
	graph_file_path = ""
	_node_counter = 0


func _show_error_overlay(err_text: String) -> void:
	# Remove previous error overlay
	var old: Node = get_node_or_null("ErrorOverlay")
	if old:
		old.queue_free()
	var panel := PanelContainer.new()
	panel.name = "ErrorOverlay"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -250
	panel.offset_top = -100
	panel.offset_right = 250
	panel.offset_bottom = 100
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.15, 0.0, 0.0, 0.95)
	ps.border_color = Color.RED
	ps.set_border_width_all(2)
	ps.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", ps)
	var vbox := VBoxContainer.new()
	panel.add_child(vbox)
	var header := Label.new()
	header.text = "GAL Assembly Errors"
	header.add_theme_color_override("font_color", Color.RED)
	vbox.add_child(header)
	var body := Label.new()
	body.text = err_text.left(500)
	body.add_theme_color_override("font_color", Color(1.0, 0.7, 0.7))
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(400, 60)
	vbox.add_child(body)
	var close_btn := Button.new()
	close_btn.text = "Dismiss"
	close_btn.pressed.connect(panel.queue_free)
	vbox.add_child(close_btn)
	add_child(panel)


func _clear_all_nodes() -> void:
	for conn in graph_edit.get_connection_list():
		graph_edit.disconnect_node(conn.from_node, conn.from_port, conn.to_node, conn.to_port)
	var to_remove: Array[Node] = []
	for child in graph_edit.get_children():
		if child is GraphNode:
			to_remove.append(child)
	for child in to_remove:
		child.queue_free()
	_conn_labels.clear()
	_type_warnings.clear()
	_wire_bends.clear()
	_debug_stop()
	_hide_node_info()


func _on_open_graph() -> void:
	var dialog := FileDialog.new()
	dialog.use_native_dialog = true
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.filters = PackedStringArray(["*.json"])
	dialog.file_selected.connect(_on_graph_file_opened)
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered(Vector2i(600, 400))


func _on_graph_file_opened(path: String) -> void:
	graph_file_path = path
	_add_recent_file(path)
	_clear_all_nodes()
	_node_counter = 0
	_load_from_file(path)


func _on_save_graph() -> void:
	if graph_file_path == "":
		_on_save_graph_as()
	else:
		_save_to_file(graph_file_path)


func _on_save_graph_as() -> void:
	var dialog := FileDialog.new()
	dialog.use_native_dialog = true
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.filters = PackedStringArray(["*.json"])
	dialog.file_selected.connect(_on_graph_file_saved)
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered(Vector2i(600, 400))


func _on_graph_file_saved(path: String) -> void:
	graph_file_path = path
	_save_to_file(path)


func _save_to_file(path: String) -> void:
	var data := _serialize_current_graph()
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))
		f.close()


func _load_from_file(path: String) -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return
	var json := JSON.new()
	if json.parse(f.get_as_text()) != OK:
		f.close()
		return
	f.close()
	var data: Dictionary = json.data
	_build_nodes_from_data(data)
	# Restore wire bends, labels, style
	_wire_bends.clear()
	for conn in data.connections:
		if conn.has("bends"):
			var key := "%s:%d->%s:%d" % [conn.from_node, conn.from_port, conn.to_node, conn.to_port]
			var bends: Array = []
			for b in conn.bends:
				bends.append(Vector2(b.x, b.y))
			_wire_bends[key] = bends
		if conn.has("label"):
			var key := "%s:%d->%s:%d" % [conn.from_node, conn.from_port, conn.to_node, conn.to_port]
			_conn_labels[key] = conn.label
	if data.has("wire_style"):
		_wire_style = int(data.wire_style)
		var labels: PackedStringArray = ["Wire: Dot", "Wire: Pulse", "Wire: Static"]
		var btn: Button = $Toolbar/WireStyleBtn
		if btn:
			btn.text = labels[_wire_style]


func save_graph() -> void:
	if _graph_stack.is_empty():
		_save_to_file(SAVE_PATH)
		return
	# Inside a subgraph — merge current state up to root, then save root
	var current_data := _serialize_current_graph()
	for i in range(_graph_stack.size() - 1, -1, -1):
		var entry: Dictionary = _graph_stack[i]
		var parent_data: Dictionary = entry["data"]
		var sg_name: String = entry["subgraph_name"]
		for n in parent_data.nodes:
			if n.name == sg_name and n.has("internal"):
				n.internal = current_data
				break
		current_data = parent_data
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(current_data, "\t"))
		f.close()


func load_graph() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	_load_from_file(SAVE_PATH)
	_update_stats()


func _build_nodes_from_data(data: Dictionary, parent: Node = graph_edit, connect_signals: bool = true) -> void:
	for node_data in data.nodes:
		var type: String = node_data.type
		var node: GraphNode = _create_node_by_type(type)
		node.name = node_data.name
		node.position_offset = Vector2(node_data.x, node_data.y)
		# Connect signals
		if connect_signals:
			if node.has_signal("open_pressed"):
				node.open_pressed.connect(_on_notepad_open)
			if node.has_signal("edit_pressed"):
				node.edit_pressed.connect(_on_enter_subgraph)
			if node.has_signal("run_pressed"):
				node.run_pressed.connect(_on_node_run)
			if node.has_signal("delete_pressed"):
				node.delete_pressed.connect(_on_node_delete)
			if node.has_signal("text_updated"):
				node.text_updated.connect(_propagate_text.bind(node))
		parent.add_child(node)
		# Deserialize node-specific data
		if node.has_method("deserialize_data"):
			node.deserialize_data(node_data)
		# Restore enabled state
		if node_data.has("enabled") and node.get("enabled") != null and type != "notepad":
			node.set("enabled", node_data.enabled)
		_update_node_style(node)
		if node_data.has("comment"):
			node.tooltip_text = node_data.comment
		if node_data.has("color"):
			_node_colors[node.name] = Color.html(node_data.color)
			_update_node_style(node)
		# Track node counter
		if connect_signals:
			var num_str := ""
			for c in node_data.name:
				if c >= '0' and c <= '9':
					num_str += c
			if num_str != "":
				_node_counter = maxi(_node_counter, num_str.to_int() + 1)
	if parent is GraphEdit:
		for conn_data in data.connections:
			parent.connect_node(
				StringName(conn_data.from_node), conn_data.from_port,
				StringName(conn_data.to_node), conn_data.to_port
			)
	if parent is GraphEdit:
		_update_stats()


func _evaluate_subgraph_internals(sg_node: GraphNode) -> void:
	var nodes_data: Array = sg_node.internal_data.get("nodes", [])
	if nodes_data.is_empty():
		return
	# 1. Create temp GraphEdit, build real nodes
	var temp := GraphEdit.new()
	add_child(temp)
	temp.visible = false
	_build_nodes_from_data(sg_node.internal_data, temp, false)
	# 2. Connect each node's text_updated to propagate within temp graph
	for child in temp.get_children():
		if child is GraphNode and child.has_signal("text_updated"):
			child.text_updated.connect(_propagate_in.bind(temp, child))
	# 3. Feed stored inputs → triggers propagation naturally
	var idx := 0
	for child in temp.get_children():
		if child is GraphNode and _get_node_type(child) == "graph_input":
			if idx < sg_node.stored_inputs.size():
				child.set_text(sg_node.stored_inputs[idx])
			idx += 1
	# 4. Read outputs
	var outputs: Array = []
	for child in temp.get_children():
		if child is GraphNode and _get_node_type(child) == "graph_output":
			outputs.append(child.text_buffer if child.get("text_buffer") != null else "")
	sg_node.stored_outputs = outputs
	# 5. Clean up
	temp.queue_free()
