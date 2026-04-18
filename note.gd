extends Control

var current_file_path: String = ""
var unsaved: bool = false
var _dragging := false
var _drag_start := Vector2i()
var _win_start := Vector2i()
var _pending_action: String = ""
var _current_view: String = "edit"  # "edit" or "graph"
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

enum FileMenu { OPEN, SAVE, SEP, QUIT }
enum ViewMenu { EDIT, GRAPH }


func _ready() -> void:
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	_setup_menu()
	_setup_style()
	_connect_signals()
	_update_title()
	text_edit.grab_focus()


func _setup_menu() -> void:
	var file_popup := file_button.get_popup()
	file_popup.add_item("Open", FileMenu.OPEN)
	file_popup.add_item("Save", FileMenu.SAVE)
	file_popup.add_separator()
	file_popup.add_item("Quit", FileMenu.QUIT)

	var view_popup := view_button.get_popup()
	view_popup.add_item("Edit", ViewMenu.EDIT)
	view_popup.add_item("Graph", ViewMenu.GRAPH)


func _setup_style() -> void:
	var black := Color.BLACK
	var white := Color.WHITE
	var dark := Color(0.1, 0.1, 0.1, 1.0)

	# Panel
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = black
	panel_style.border_color = white
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", panel_style)

	# Title bar
	var bar_style := StyleBoxFlat.new()
	bar_style.bg_color = dark
	title_bar.add_theme_stylebox_override("panel", bar_style)

	# Text edit
	text_edit.add_theme_color_override("background_color", black)
	text_edit.add_theme_color_override("font_color", white)
	text_edit.add_theme_color_override("caret_color", white)

	# Buttons
	_style_menu_button(file_button, dark, white)
	_style_menu_button(view_button, dark, white)

	# Close button
	close_button.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
	close_button.add_theme_color_override("font_hover_color", Color(1.0, 0.3, 0.3, 1.0))
	var close_normal := StyleBoxFlat.new()
	close_normal.bg_color = dark
	close_normal.border_color = white
	close_normal.set_border_width_all(1)
	close_normal.set_corner_radius_all(4)
	close_button.add_theme_stylebox_override("normal", close_normal)
	var close_hover := StyleBoxFlat.new()
	close_hover.bg_color = Color(0.3, 0.0, 0.0, 1.0)
	close_hover.border_color = white
	close_hover.set_border_width_all(1)
	close_hover.set_corner_radius_all(4)
	close_button.add_theme_stylebox_override("hover", close_hover)

	# Popup menus
	_style_popup(file_button.get_popup(), dark, white)
	_style_popup(view_button.get_popup(), dark, white)

	# Graph toolbar buttons
	_style_graph_toolbar(dark, white)


func _style_menu_button(btn: MenuButton, dark: Color, white: Color) -> void:
	btn.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
	btn.add_theme_color_override("font_hover_color", white)
	var normal := StyleBoxFlat.new()
	normal.bg_color = dark
	normal.border_color = white
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal", normal)
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.2, 0.2, 0.2, 1.0)
	hover.border_color = white
	hover.set_border_width_all(1)
	hover.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("hover", hover)


func _style_popup(popup: PopupMenu, dark: Color, white: Color) -> void:
	popup.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
	popup.add_theme_color_override("font_hover_color", white)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = dark
	panel_style.border_color = Color(0.3, 0.3, 0.3, 1.0)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(2)
	popup.add_theme_stylebox_override("panel", panel_style)
	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = Color(0.2, 0.2, 0.2, 1.0)
	popup.add_theme_stylebox_override("hover", hover_style)


func _style_graph_toolbar(dark: Color, white: Color) -> void:
	var toolbar := graph_view.get_node("Toolbar")
	if toolbar == null:
		return
	for child in toolbar.get_children():
		if child is Button:
			child.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
			child.add_theme_color_override("font_hover_color", white)
			var btn_normal := StyleBoxFlat.new()
			btn_normal.bg_color = dark
			btn_normal.border_color = white
			btn_normal.set_border_width_all(1)
			btn_normal.set_corner_radius_all(2)
			child.add_theme_stylebox_override("normal", btn_normal)
			var btn_hover := StyleBoxFlat.new()
			btn_hover.bg_color = Color(0.2, 0.2, 0.2, 1.0)
			btn_hover.border_color = white
			btn_hover.set_border_width_all(1)
			btn_hover.set_corner_radius_all(2)
			child.add_theme_stylebox_override("hover", btn_hover)


func _connect_signals() -> void:
	file_button.get_popup().id_pressed.connect(_on_file_menu)
	view_button.get_popup().id_pressed.connect(_on_view_menu)
	close_button.pressed.connect(_auto_save_and_quit)
	text_edit.text_changed.connect(_on_text_changed)
	open_dialog.file_selected.connect(_on_file_opened)
	save_dialog.file_selected.connect(_on_save_selected)
	graph_view.notepad_selected.connect(_on_notepad_selected)


func _on_file_menu(id: int) -> void:
	match id:
		FileMenu.OPEN:
			open_dialog.popup_centered(Vector2i(600, 400))
		FileMenu.SAVE:
			_save()
		FileMenu.QUIT:
			_auto_save_and_quit()


func _on_view_menu(id: int) -> void:
	match id:
		ViewMenu.EDIT:
			_switch_view("edit")
		ViewMenu.GRAPH:
			_switch_view("graph")


func _switch_view(view: String) -> void:
	# Save current notepad text before switching
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


func _on_notepad_selected(node: GraphNode) -> void:
	# Save previous selection
	if _selected_notepad != null and _current_view == "edit":
		_selected_notepad.set_text(text_edit.text)

	_selected_notepad = node
	_switch_view("edit")


func _on_title_bar_input(event: InputEvent) -> void:
	pass


func _input(event: InputEvent) -> void:
	# Drag window
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_pos := title_bar.get_global_mouse_position()
			if title_bar.get_global_rect().has_point(mouse_pos):
				_dragging = event.pressed
				_drag_start = DisplayServer.mouse_get_position()
				_win_start = DisplayServer.window_get_position()
			elif not event.pressed:
				_dragging = false
	if event is InputEventMouseMotion and _dragging:
		var current := DisplayServer.mouse_get_position()
		DisplayServer.window_set_position(_win_start + current - _drag_start)

	# Shortcuts
	if event is InputEventKey and event.pressed:
		if event.ctrl_pressed:
			match event.keycode:
				KEY_O:
					open_dialog.popup_centered(Vector2i(600, 400))
					get_viewport().set_input_as_handled()
				KEY_S:
					_save()
					get_viewport().set_input_as_handled()


func _on_text_changed() -> void:
	if not unsaved:
		unsaved = true
	_update_title()


func _on_file_opened(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	text_edit.text = file.get_as_text()
	file.close()
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
	if _pending_action == "save_quit":
		get_tree().quit()
	else:
		text_edit.grab_focus()


func _write_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(text_edit.text)
	file.close()
	current_file_path = path
	unsaved = false
	_update_title()


func _auto_save_and_quit() -> void:
	if current_file_path != "" and unsaved:
		_write_file(current_file_path)
		get_tree().quit()
	elif current_file_path == "" and text_edit.text != "":
		_pending_action = "save_quit"
		save_dialog.popup_centered(Vector2i(600, 400))
	else:
		get_tree().quit()


func _update_title() -> void:
	var filename := "Untitled" if current_file_path == "" else current_file_path.get_file()
	var star := "*" if unsaved else ""
	var view_label := "Graph" if _current_view == "graph" else "Edit"
	DisplayServer.window_set_title("Note [%s] - %s%s" % [view_label, filename, star])
