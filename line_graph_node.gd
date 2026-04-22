extends GraphNode

const AssemblerScript := preload("res://assembler.gd")

signal delete_pressed(node: GraphNode)
signal text_updated

var data_text: String = ""
var title_text: String = "Line Graph"
var enabled: bool = true
var enable_port: int = -1
var trigger_port: int = -1

@onready var chart_panel: Panel = $ChartPanel
@onready var title_edit: LineEdit = $TitleEdit


func _ready() -> void:
	title = "Line Graph"
	AssemblerScript.configure_slots(self, "line_graph")
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
	if port == 3:
		return data_text
	return ""


func set_input(port: int, text: String) -> void:
	if port == enable_port:
		enabled = text.strip_edges() != "" and text.strip_edges().to_lower() != "false"
		return
	if port == trigger_port:
		if enabled:
			_redraw_chart()
		return
	if not enabled:
		return
	if port == 0:
		data_text = text
		_redraw_chart()
	elif port == 1:
		title_text = text
		if title_edit:
			title_edit.text = title_text
		_redraw_chart()
	elif port == 2:
		title_text = text
		if title_edit:
			title_edit.text = title_text
		_redraw_chart()


func _parse_values() -> Array[float]:
	var values: Array[float] = []
	for line in data_text.split("\n"):
		var trimmed := line.strip_edges()
		if trimmed == "":
			continue
		# Support comma-separated or newline-separated
		if "," in trimmed:
			for part in trimmed.split(","):
				var v := part.strip_edges().to_float()
				values.append(v)
		else:
			var v := trimmed.to_float()
			values.append(v)
	return values


func _redraw_chart() -> void:
	if chart_panel:
		chart_panel.queue_redraw()


func _on_chart_draw() -> void:
	if chart_panel == null:
		return
	var rect := Rect2(Vector2.ZERO, chart_panel.size)
	if rect.size.x < 10 or rect.size.y < 10:
		return
	var values := _parse_values()
	var font: Font = ThemeDB.fallback_font
	if values.is_empty():
		chart_panel.draw_string(font, rect.position + Vector2(10, 20), "No data", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.GRAY)
		return
	var margin := Vector2(30, 20)
	var chart_rect := Rect2(rect.position + margin, rect.size - margin * 2)
	var min_val: float = values[0]
	var max_val: float = values[0]
	for v in values:
		if v < min_val:
			min_val = v
		if v > max_val:
			max_val = v
	if max_val == min_val:
		max_val = min_val + 1.0
	# Draw grid lines
	var grid_lines: int = 4
	for g in range(grid_lines + 1):
		var y: float = chart_rect.position.y + chart_rect.size.y * g / grid_lines
		chart_panel.draw_line(Vector2(chart_rect.position.x, y), Vector2(chart_rect.position.x + chart_rect.size.x, y), Color(0.2, 0.2, 0.2), 1)
		var gv: float = max_val - (max_val - min_val) * g / grid_lines
		chart_panel.draw_string(font, Vector2(chart_rect.position.x - 28, y + 4), "%.1f" % gv, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.5, 0.5, 0.5))
	# Draw line
	var points := PackedVector2Array()
	for i in range(values.size()):
		var x: float
		if values.size() > 1:
			x = chart_rect.position.x + (chart_rect.size.x * i / max(1, values.size() - 1))
		else:
			x = chart_rect.position.x + chart_rect.size.x / 2.0
		var y: float = chart_rect.position.y + chart_rect.size.y * (1.0 - (values[i] - min_val) / (max_val - min_val))
		points.append(Vector2(x, y))
	if points.size() >= 2:
		chart_panel.draw_polyline(points, Color(0.4, 0.8, 1.0), 2.0, true)
		# Fill area under line
		var fill_points := PackedVector2Array(points)
		var last_pt: Vector2 = points[points.size() - 1]
		var first_pt: Vector2 = points[0]
		fill_points.append(Vector2(last_pt.x, chart_rect.position.y + chart_rect.size.y))
		fill_points.append(Vector2(first_pt.x, chart_rect.position.y + chart_rect.size.y))
		chart_panel.draw_colored_polygon(fill_points, Color(0.4, 0.8, 1.0, 0.15))
	# Draw dots
	for p in points:
		chart_panel.draw_circle(p, 3.0, Color(0.4, 0.8, 1.0))
	# Title
	if title_text != "":
		chart_panel.draw_string(font, rect.position + Vector2(rect.size.x / 2, 14), title_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color.WHITE)


func _on_title_changed(new_text: String) -> void:
	title_text = new_text
	_redraw_chart()


func _on_delete_pressed() -> void:
	delete_pressed.emit(self)


func get_node_type() -> String:
	return "line_graph"


func serialize_data() -> Dictionary:
	return {"data_text": data_text, "title_text": title_text}


func deserialize_data(d: Dictionary) -> void:
	if d.has("data_text"):
		data_text = d.data_text
	if d.has("title_text"):
		title_text = d.title_text
		if title_edit:
			title_edit.text = title_text


func get_gal_props(nd: Dictionary) -> Dictionary:
	var props: Dictionary = {}
	if nd.has("data_text") and nd.data_text != "":
		props["data"] = nd.data_text
	if nd.has("title_text") and nd.title_text != "":
		props["title"] = nd.title_text
	return props
