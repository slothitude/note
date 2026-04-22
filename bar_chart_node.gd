extends GraphNode

const AssemblerScript := preload("res://assembler.gd")

signal delete_pressed(node: GraphNode)
signal text_updated

var data_text: String = ""
var title_text: String = "Bar Chart"
var enabled: bool = true
var enable_port: int = -1
var trigger_port: int = -1

@onready var chart_panel: Panel = $ChartPanel
@onready var title_edit: LineEdit = $TitleEdit


func _ready() -> void:
	title = "Bar Chart"
	AssemblerScript.configure_slots(self, "bar_chart")
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


func _parse_data() -> Dictionary:
	# Parse "label:value" lines or comma-separated values
	var labels: Array[String] = []
	var values: Array[float] = []
	for line in data_text.split("\n"):
		var trimmed := line.strip_edges()
		if trimmed == "":
			continue
		if ":" in trimmed:
			var parts: PackedStringArray = trimmed.split(":", 2)
			labels.append(parts[0].strip_edges())
			values.append(parts[1].strip_edges().to_float())
		elif "," in trimmed:
			var parts: PackedStringArray = trimmed.split(",", false)
			for p in parts:
				var v := p.strip_edges().to_float()
				if v != 0.0 or p.strip_edges() == "0":
					labels.append(str(labels.size() + 1))
					values.append(v)
		else:
			var v := trimmed.to_float()
			if v != 0.0 or trimmed == "0":
				labels.append(str(labels.size() + 1))
				values.append(v)
	return {"labels": labels, "values": values}


func _redraw_chart() -> void:
	if chart_panel == null:
		return
	chart_panel.queue_redraw()


func _on_chart_draw() -> void:
	if chart_panel == null:
		return
	var rect := Rect2(Vector2.ZERO, chart_panel.size)
	if rect.size.x < 10 or rect.size.y < 10:
		return
	var data := _parse_data()
	if data.values.is_empty():
		chart_panel.draw_string(ThemeDB.fallback_font, rect.position + Vector2(10, 20), "No data", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.GRAY)
		return
	var font: Font = ThemeDB.fallback_font
	var max_val: float = 0.001
	var vals: Array = data.values
	var lbls: Array = data.labels
	for v in vals:
		if v > max_val:
			max_val = v
	var margin := Vector2(30, 20)
	var chart_rect := Rect2(rect.position + margin, rect.size - margin * 2)
	var bar_count: int = vals.size()
	var bar_width: float = chart_rect.size.x / (bar_count * 1.5)
	var colors := [Color(0.4, 0.7, 1.0), Color(0.4, 1.0, 0.6), Color(1.0, 0.7, 0.4), Color(1.0, 0.4, 0.7), Color(0.7, 0.4, 1.0)]
	for i in range(bar_count):
		var bar_height: float = (vals[i] / max_val) * chart_rect.size.y
		var x: float = chart_rect.position.x + i * (bar_width * 1.5) + bar_width * 0.25
		var y: float = chart_rect.position.y + chart_rect.size.y - bar_height
		var bar_rect := Rect2(x, y, bar_width, bar_height)
		chart_panel.draw_rect(bar_rect, colors[i % colors.size()])
		# Value label
		chart_panel.draw_string(font, Vector2(x, y - 4), str(vals[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
		# Category label
		if i < lbls.size():
			var lbl: String = lbls[i].left(6)
			chart_panel.draw_string(font, Vector2(x, chart_rect.position.y + chart_rect.size.y + 14), lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.7, 0.7, 0.7))
	# Title
	if title_text != "":
		chart_panel.draw_string(font, rect.position + Vector2(rect.size.x / 2, 14), title_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color.WHITE)


func _on_delete_pressed() -> void:
	delete_pressed.emit(self)


func _on_title_changed(new_text: String) -> void:
	title_text = new_text
	_redraw_chart()


func get_node_type() -> String:
	return "bar_chart"


func serialize_data() -> Dictionary:
	var d: Dictionary = {"data_text": data_text, "title_text": title_text}
	return d


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
