extends GraphNode

const AssemblerScript := preload("res://assembler.gd")

signal delete_pressed(node: GraphNode)
signal text_updated

var _file_path: String = ""
var _last_mtime: int = -1
var _last_content: String = ""
var _watching: bool = false
var _change_count: int = 0
var enabled: bool = true
var enable_port: int = -1
var trigger_port: int = -1

var _poll_timer: Timer

@onready var path_edit: LineEdit = $PathEdit
@onready var interval_spin: SpinBox = $IntervalSpin
@onready var status_label: Label = $StatusLabel


func _ready() -> void:
	if enable_port >= 0:
		return
	title = "File Watch"
	AssemblerScript.configure_slots(self, "file_watch")
	_add_control_ports()

	_poll_timer = Timer.new()
	_poll_timer.name = "PollTimer"
	add_child(_poll_timer)
	_poll_timer.timeout.connect(_on_poll_tick)


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
	match port:
		1: return _last_content
		2: return _file_path
	return ""


func set_input(port: int, text: String) -> void:
	if port == enable_port:
		enabled = text.strip_edges() != "" and text.strip_edges().to_lower() != "false"
		if not enabled and _watching:
			_stop_watching()
		return
	if port == trigger_port:
		if enabled:
			_check_file()
		return
	if not enabled:
		return
	if port == 0:
		_file_path = text.strip_edges()
		if path_edit != null:
			path_edit.text = _file_path


func _on_toggle_watching() -> void:
	if _watching:
		_stop_watching()
	else:
		_start_watching()


func _start_watching() -> void:
	_read_fields()
	if _file_path == "":
		status_label.text = "No path"
		return
	# Resolve user:// paths
	var resolved := _resolve_path(_file_path)
	if not FileAccess.file_exists(resolved):
		status_label.text = "File not found"
		return
	_watching = true
	_change_count = 0
	_last_mtime = -1
	var interval := 2.0
	if interval_spin != null:
		interval = interval_spin.value
	_poll_timer.wait_time = maxf(interval, 0.5)
	_poll_timer.start()
	_check_file()
	status_label.text = "Watching..."


func _stop_watching() -> void:
	_watching = false
	if _poll_timer:
		_poll_timer.stop()
	status_label.text = "Stopped"


func _on_poll_tick() -> void:
	if _watching and enabled:
		_check_file()


func _check_file() -> void:
	_read_fields()
	if _file_path == "":
		return
	var resolved := _resolve_path(_file_path)
	if not FileAccess.file_exists(resolved):
		return
	var f := FileAccess.open(resolved, FileAccess.READ)
	if f == null:
		return
	var mtime := FileAccess.get_modified_time(resolved)
	f.close()
	if _last_mtime >= 0 and mtime != _last_mtime:
		# File changed — read new content
		var f2 := FileAccess.open(resolved, FileAccess.READ)
		if f2 != null:
			_last_content = f2.get_as_text()
			f2.close()
		_change_count += 1
		status_label.text = "Changed (%d)" % _change_count
		text_updated.emit()
	elif _last_mtime < 0:
		# First check — read initial content silently
		var f2 := FileAccess.open(resolved, FileAccess.READ)
		if f2 != null:
			_last_content = f2.get_as_text()
			f2.close()
		status_label.text = "Watching..."
	_last_mtime = mtime


func _resolve_path(path: String) -> String:
	if path.begins_with("user://") or path.begins_with("res://"):
		return path
	# Treat as local file — convert to absolute if needed
	if not path.is_absolute_path():
		return ProjectSettings.globalize_path("user://") + path
	return path


func _read_fields() -> void:
	if path_edit != null:
		_file_path = path_edit.text.strip_edges()


func _on_delete_pressed() -> void:
	if _poll_timer:
		_poll_timer.stop()
	delete_pressed.emit(self)


func get_node_type() -> String:
	return "file_watch"


func serialize_data() -> Dictionary:
	var d: Dictionary = {"file_path": _file_path, "change_count": _change_count}
	if interval_spin != null:
		d["interval"] = interval_spin.value
	return d


func deserialize_data(d: Dictionary) -> void:
	if d.has("file_path"):
		_file_path = d.file_path
		if path_edit != null:
			path_edit.text = _file_path
	if d.has("change_count"):
		_change_count = int(d.change_count)
	if d.has("interval") and interval_spin != null:
		interval_spin.value = float(d.interval)


func get_gal_props(nd: Dictionary) -> Dictionary:
	var props: Dictionary = {}
	if nd.has("file_path") and nd.file_path != "":
		props["file_path"] = nd.file_path
	if nd.has("interval"):
		props["interval"] = str(nd.interval)
	return props
