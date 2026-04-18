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
	if view == "edit":
		text_edit.visible = true
		graph_view.visible = false
		if _selected_notepad != null:
			text_edit.text = _selected_notepad.text_buffer
		text_edit.grab_focus()
	else:
		text_edit.visible = false
		graph_view.visible = true
	_update_title()


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

	if event is InputEventKey and event.pressed and event.keycode == KEY_F1:
		_switch_view("graph" if _current_view == "edit" else "edit")
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
	_update_title()


func _auto_save_and_quit() -> void:
	_save_temp()
	graph_view.save_graph()
	if current_file_path != "" and unsaved:
		_write_file(current_file_path)
	get_tree().quit()


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
	DisplayServer.window_set_title("Note [%s] - %s%s" % [v, fn, s])
