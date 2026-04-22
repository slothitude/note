extends Control

var current_file_path: String = ""
var unsaved: bool = false
var _temp_path := OS.get_temp_dir().path_join("note_untitled.tmp")
var _dragging := false
var _drag_start := Vector2i()
var _win_start := Vector2i()
var _pending_action: String = ""
var _current_view: String = "edit"
var _selected_notepad: GraphNode = null

@onready var file_button: MenuButton = %FileButton
@onready var view_button: MenuButton = %ViewButton
@onready var close_button: Button = %CloseButton
@onready var title_bar: HBoxContainer = %TitleBar
@onready var text_edit: TextEdit = %EditorView
@onready var graph_view: VBoxContainer = %GraphView
@onready var panel: PanelContainer = %Panel
@onready var open_dialog: FileDialog = %OpenDialog
@onready var save_dialog: FileDialog = %SaveDialog

enum FileItem { NEW, OPEN, SAVE, SEP1, QUIT }
enum ViewItem { EDIT, GRAPH }


func _ready() -> void:
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	_setup_menu()
	_setup_style()
	_connect_signals()
	_update_title()
	_load_temp()
	_load_window_state()
	_select_default_notepad()
	text_edit.grab_focus()
	_switch_view("edit")


func _setup_menu() -> void:
	var fp := file_button.get_popup()
	fp.add_item("New", FileItem.NEW)
	fp.add_item("Open", FileItem.OPEN)
	fp.add_item("Save", FileItem.SAVE)
	fp.add_separator()
	fp.add_item("Quit", FileItem.QUIT)

	var vp := view_button.get_popup()
	vp.add_item("Edit", ViewItem.EDIT)
	vp.add_item("Graph", ViewItem.GRAPH)


func _setup_style() -> void:
	var black := Color.BLACK
	var white := Color.WHITE
	var dark := Color(0.1, 0.1, 0.1, 1.0)

	# Panel
	var ps := StyleBoxFlat.new()
	ps.bg_color = black
	ps.border_color = white
	ps.set_border_width_all(1)
	ps.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", ps)

	# Title bar
	var bs := StyleBoxFlat.new()
	bs.bg_color = dark
	title_bar.add_theme_stylebox_override("panel", bs)

	# Text edit
	text_edit.add_theme_color_override("background_color", black)
	text_edit.add_theme_color_override("font_color", white)
	text_edit.add_theme_color_override("caret_color", white)

	# Menu buttons
	_style_menu_btn(file_button, dark, white)
	_style_menu_btn(view_button, dark, white)

	# Close button
	close_button.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
	close_button.add_theme_color_override("font_hover_color", Color(1.0, 0.3, 0.3, 1.0))
	var cn := StyleBoxFlat.new()
	cn.bg_color = dark; cn.border_color = white; cn.set_border_width_all(1); cn.set_corner_radius_all(4)
	close_button.add_theme_stylebox_override("normal", cn)
	var ch := StyleBoxFlat.new()
	ch.bg_color = Color(0.3, 0.0, 0.0, 1.0); ch.border_color = white; ch.set_border_width_all(1); ch.set_corner_radius_all(4)
	close_button.add_theme_stylebox_override("hover", ch)

	# Popups
	_style_popup(file_button.get_popup(), dark, white)
	_style_popup(view_button.get_popup(), dark, white)

	# Graph toolbar
	var toolbar := graph_view.get_node_or_null("Toolbar")
	if toolbar:
		for child in toolbar.get_children():
			if child is Button:
				_style_menu_btn(child, dark, white)


func _style_menu_btn(btn: Control, dark: Color, white: Color) -> void:
	btn.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
	btn.add_theme_color_override("font_hover_color", white)
	var n := StyleBoxFlat.new()
	n.bg_color = dark; n.border_color = white; n.set_border_width_all(1); n.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal", n)
	var h := StyleBoxFlat.new()
	h.bg_color = Color(0.2, 0.2, 0.2, 1.0); h.border_color = white; h.set_border_width_all(1); h.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("hover", h)


func _style_popup(p: PopupMenu, dark: Color, white: Color) -> void:
	p.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
	p.add_theme_color_override("font_hover_color", white)
	var ps := StyleBoxFlat.new()
	ps.bg_color = dark; ps.border_color = Color(0.3, 0.3, 0.3, 1.0); ps.set_border_width_all(1); ps.set_corner_radius_all(2)
	p.add_theme_stylebox_override("panel", ps)
	var hs := StyleBoxFlat.new()
	hs.bg_color = Color(0.2, 0.2, 0.2, 1.0)
	p.add_theme_stylebox_override("hover", hs)


func _connect_signals() -> void:
	file_button.get_popup().id_pressed.connect(_on_file_menu)
	view_button.get_popup().id_pressed.connect(_on_view_menu)
	close_button.pressed.connect(_auto_save_and_quit)
	text_edit.text_changed.connect(_on_text_changed)
	open_dialog.file_selected.connect(_on_file_opened)
	save_dialog.file_selected.connect(_on_save_selected)
	graph_view.notepad_selected.connect(_on_notepad_selected)


func _new_file() -> void:
	_switch_view("graph")
	graph_view.add_default_notepad()


func _on_file_menu(id: int) -> void:
	match id:
		FileItem.NEW: _new_file()
		FileItem.OPEN: open_dialog.popup_centered(Vector2i(600, 400))
		FileItem.SAVE: _save()
		FileItem.QUIT: _auto_save_and_quit()


func _on_view_menu(id: int) -> void:
	match id:
		ViewItem.EDIT: _switch_view("edit")
		ViewItem.GRAPH: _switch_view("graph")


func _switch_view(view: String) -> void:
	if _selected_notepad != null and _current_view == "edit":
		_selected_notepad.set_text(text_edit.text)
	_current_view = view
	_clear_graph_buttons()
	if view == "edit":
		text_edit.visible = true
		graph_view.visible = false
		if _selected_notepad != null:
			var raw_text: String = _selected_notepad.text_buffer
			text_edit.text = graph_view.resolve_template(raw_text)
		_show_graph_buttons()
		text_edit.grab_focus()
	else:
		text_edit.visible = false
		graph_view.visible = true
	_update_title()


func _clear_graph_buttons() -> void:
	for child in title_bar.get_children():
		if child.name.begins_with("GBtn_"):
			child.queue_free()


func _show_graph_buttons() -> void:
	var ge: GraphEdit = graph_view.get_node_or_null("GraphEdit")
	if not ge:
		return
	var dark := Color(0.1, 0.1, 0.1, 1.0)
	var white := Color.WHITE
	var spacer := title_bar.get_node("Spacer")
	for child in ge.get_children():
		if child is GraphNode and child.get("is_button_node") != null:
			var btn := Button.new()
			btn.name = "GBtn_" + child.name
			btn.text = child.title
			btn.pressed.connect(child.press)
			_style_menu_btn(btn, dark, white)
			title_bar.add_child(btn)
			title_bar.move_child(btn, spacer.get_index() + 1)


func _on_notepad_selected(node: GraphNode) -> void:
	if _selected_notepad != null and _current_view == "edit":
		_selected_notepad.set_text(text_edit.text)
	_selected_notepad = node
	_switch_view("edit")


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var spacer := title_bar.get_node("Spacer")
			if spacer.get_global_rect().has_point(spacer.get_global_mouse_position()):
				_dragging = event.pressed
				_drag_start = DisplayServer.mouse_get_position()
				_win_start = DisplayServer.window_get_position()
			elif not event.pressed:
				_dragging = false
	if event is InputEventMouseMotion and _dragging:
		DisplayServer.window_set_position(_win_start + DisplayServer.mouse_get_position() - _drag_start)

	if event is InputEventKey and event.pressed and event.ctrl_pressed:
		match event.keycode:
			KEY_N: _new_file(); get_viewport().set_input_as_handled()
			KEY_O: open_dialog.popup_centered(Vector2i(600, 400)); get_viewport().set_input_as_handled()
			KEY_S: _save(); get_viewport().set_input_as_handled()

	if event is InputEventKey and event.pressed and event.ctrl_pressed and _current_view == "graph":
		match event.keycode:
			KEY_Z:
				if event.shift_pressed:
					graph_view.redo(); get_viewport().set_input_as_handled()
				else:
					graph_view.undo(); get_viewport().set_input_as_handled()
			KEY_C:
				graph_view.copy_selected(); get_viewport().set_input_as_handled()
			KEY_V:
				graph_view.paste_nodes(); get_viewport().set_input_as_handled()
			KEY_F:
				_toggle_search(); get_viewport().set_input_as_handled()
			KEY_D:
				graph_view.duplicate_selected(); get_viewport().set_input_as_handled()

	if event is InputEventKey and event.pressed and event.keycode == KEY_F1:
		_switch_view("graph" if _current_view == "edit" else "edit")
		get_viewport().set_input_as_handled()

	if event is InputEventKey and event.pressed and event.keycode == KEY_F2:
		_toggle_help()
		get_viewport().set_input_as_handled()

	if event is InputEventKey and event.pressed and _current_view == "graph":
		match event.keycode:
			KEY_F5:
				graph_view._debug_step(); get_viewport().set_input_as_handled()
			KEY_F6:
				graph_view._debug_run_all(); get_viewport().set_input_as_handled()

	if event is InputEventKey and event.pressed and _help_visible():
		_hide_help()
		get_viewport().set_input_as_handled()

	# Search bar: Enter to find next, Escape to close
	if event is InputEventKey and _search_visible():
		if event.keycode == KEY_ENTER:
			graph_view.search_next()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE:
			_hide_search()
			get_viewport().set_input_as_handled()


func _on_text_changed() -> void:
	if not unsaved: unsaved = true
	_save_temp()
	_update_title()


func _on_file_opened(path: String) -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null: return
	text_edit.text = f.get_as_text()
	f.close()
	current_file_path = path
	unsaved = false
	_update_title()
	text_edit.grab_focus()


func _save() -> void:
	if current_file_path == "":
		save_dialog.popup_centered(Vector2i(600, 400))
		return
	_write_file(current_file_path)
	text_edit.grab_focus()


func _on_save_selected(path: String) -> void:
	_write_file(path)
	if _pending_action == "save_quit": get_tree().quit()
	else: text_edit.grab_focus()


func _write_file(path: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null: return
	f.store_string(text_edit.text)
	f.close()
	current_file_path = path
	unsaved = false
	if _selected_notepad and _selected_notepad.has_method("set_file"):
		_selected_notepad.set_file(path)
	_update_title()


func _auto_save_and_quit() -> void:
	_save_temp()
	_save_window_state()
	graph_view.save_graph()
	if current_file_path != "" and unsaved:
		_write_file(current_file_path)
	get_tree().quit()


const _WINDOW_STATE_PATH := "user://window_state.json"

func _save_window_state() -> void:
	var data := {
		"pos_x": DisplayServer.window_get_position().x,
		"pos_y": DisplayServer.window_get_position().y,
		"size_x": DisplayServer.window_get_size().x,
		"size_y": DisplayServer.window_get_size().y,
	}
	var f := FileAccess.open(_WINDOW_STATE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))
		f.close()


func _load_window_state() -> void:
	if not FileAccess.file_exists(_WINDOW_STATE_PATH):
		return
	var f := FileAccess.open(_WINDOW_STATE_PATH, FileAccess.READ)
	if f == null:
		return
	var json := JSON.new()
	if json.parse(f.get_as_text()) != OK:
		f.close()
		return
	f.close()
	var data: Dictionary = json.data
	if data.has("pos_x") and data.has("pos_y"):
		DisplayServer.window_set_position(Vector2i(int(data.pos_x), int(data.pos_y)))
	if data.has("size_x") and data.has("size_y"):
		DisplayServer.window_set_size(Vector2i(int(data.size_x), int(data.size_y)))


func _select_default_notepad() -> void:
	var ge: GraphEdit = graph_view.get_node_or_null("GraphEdit")
	if ge:
		for child in ge.get_children():
			if child is GraphNode and child.has_method("set_text"):
				_selected_notepad = child
				break


func _load_temp() -> void:
	if FileAccess.file_exists(_temp_path):
		var f := FileAccess.open(_temp_path, FileAccess.READ)
		if f:
			text_edit.text = f.get_as_text()
			f.close()
			unsaved = true


func _save_temp() -> void:
	if current_file_path == "":
		var f := FileAccess.open(_temp_path, FileAccess.WRITE)
		if f:
			f.store_string(text_edit.text)
			f.close()


func _update_title() -> void:
	var fn := "Untitled" if current_file_path == "" else current_file_path.get_file()
	var s := "*" if unsaved else ""
	var v := "Graph" if _current_view == "graph" else "Edit"
	DisplayServer.window_set_title("Loom [%s] - %s%s" % [v, fn, s])


func _toggle_help() -> void:
	if _help_visible():
		_hide_help()
		return
	var overlay := PanelContainer.new()
	overlay.name = "HelpOverlay"
	overlay.set_anchors_preset(Control.PRESET_CENTER)
	overlay.offset_left = -200
	overlay.offset_top = -180
	overlay.offset_right = 200
	overlay.offset_bottom = 180
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.05, 0.05, 0.05, 0.95)
	ps.border_color = Color.WHITE
	ps.set_border_width_all(1)
	ps.set_corner_radius_all(8)
	overlay.add_theme_stylebox_override("panel", ps)
	var vbox := VBoxContainer.new()
	overlay.add_child(vbox)
	var header := Label.new()
	header.text = "Keyboard Shortcuts"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(header)
	var shortcuts := [
		"F1  —  Toggle Edit / Graph view",
		"F2  —  Show this help",
		"Ctrl+N  —  New file",
		"Ctrl+O  —  Open file",
		"Ctrl+S  —  Save file",
		"Ctrl+Z  —  Undo (graph)",
		"Ctrl+Shift+Z  —  Redo (graph)",
		"Ctrl+C  —  Copy nodes (graph)",
		"Ctrl+V  —  Paste nodes (graph)",
		"Ctrl+F  —  Find nodes (graph)",
		"Ctrl+D  —  Duplicate nodes (graph)",
		"Ctrl+A  —  Select all nodes (graph)",
		"1-9  —  Quick-add node types (graph)",
		"Delete  —  Delete selected nodes (graph)",
		"Ctrl+Shift+L  —  Align selected left (graph)",
		"Ctrl+Shift+T  —  Align selected top (graph)",
		"Ctrl+Shift+H  —  Distribute horizontal (graph)",
		"Ctrl+Shift+V  —  Distribute vertical (graph)",
		"F5  —  Debug step (graph)",
		"F6  —  Debug run all (graph)",
	]
	for s in shortcuts:
		var lbl := Label.new()
		lbl.text = s
		lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
		vbox.add_child(lbl)
	var hint := Label.new()
	hint.text = "Press any key to close"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1.0))
	vbox.add_child(hint)
	add_child(overlay)


func _help_visible() -> bool:
	return get_node_or_null("HelpOverlay") != null


func _hide_help() -> void:
	var overlay := get_node_or_null("HelpOverlay")
	if overlay:
		overlay.queue_free()


func _toggle_search() -> void:
	if _search_visible():
		_hide_search()
		return
	var bar := HBoxContainer.new()
	bar.name = "SearchBar"
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_top = 4
	bar.offset_bottom = 32
	bar.offset_left = 100
	bar.offset_right = -100
	var edit := LineEdit.new()
	edit.name = "SearchEdit"
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.placeholder_text = "Search nodes..."
	edit.clear_button_enabled = true
	var dark := Color(0.1, 0.1, 0.1, 1.0)
	var white := Color.WHITE
	edit.add_theme_color_override("background_color", dark)
	edit.add_theme_color_override("font_color", white)
	edit.add_theme_color_override("caret_color", white)
	edit.add_theme_color_override("placeholder_color", Color(0.5, 0.5, 0.5, 1.0))
	var style := StyleBoxFlat.new()
	style.bg_color = dark; style.border_color = white; style.set_border_width_all(1); style.set_corner_radius_all(4)
	edit.add_theme_stylebox_override("normal", style)
	edit.text_changed.connect(_on_search_text_changed)
	bar.add_child(edit)
	var count_lbl := Label.new()
	count_lbl.name = "SearchCount"
	count_lbl.text = "0/0"
	count_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
	bar.add_child(count_lbl)
	add_child(bar)
	edit.grab_focus()


func _on_search_text_changed(text: String) -> void:
	graph_view.search_nodes(text)
	var bar := get_node_or_null("SearchBar")
	if bar:
		var count_lbl: Label = bar.get_node_or_null("SearchCount")
		if count_lbl:
			var results: int = graph_view._search_results.size()
			var idx: int = graph_view._search_index + 1 if results > 0 else 0
			count_lbl.text = "%d/%d" % [idx, results]


func _search_visible() -> bool:
	return get_node_or_null("SearchBar") != null


func _hide_search() -> void:
	var bar := get_node_or_null("SearchBar")
	if bar:
		bar.queue_free()
