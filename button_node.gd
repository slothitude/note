extends GraphNode

const AssemblerScript := preload("res://assembler.gd")

signal delete_pressed(node: GraphNode)
signal text_updated

var output_value: String = ""
var is_button_node := true

@onready var press_btn: Button = $PressBtn


func _ready() -> void:
	title = "Button"
	AssemblerScript.configure_slots(self, "button")
	if not Engine.is_editor_hint() and DisplayServer.get_name() == "headless":
		return
	_ask_name()


func _ask_name() -> void:
	var dialog := ConfirmationDialog.new()
	var edit := LineEdit.new()
	edit.placeholder_text = "Button name"
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialog.add_child(edit)
	dialog.title = "Name this button"
	dialog.ok_button_text = "OK"
	dialog.cancel_button_text = "Cancel"
	dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_PRIMARY_SCREEN
	dialog.min_size = Vector2i(300, 100)
	dialog.confirmed.connect(func(): _set_name(edit.text); dialog.queue_free())
	dialog.canceled.connect(func(): dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered()
	edit.grab_focus()


func _set_name(name: String) -> void:
	var n := name.strip_edges()
	if n != "":
		title = n
		press_btn.text = n


func press() -> void:
	output_value = "true"
	text_updated.emit()


func _on_press_pressed() -> void:
	press()


func _on_delete_pressed() -> void:
	delete_pressed.emit(self)


func get_node_type() -> String:
	return "button"


func serialize_data() -> Dictionary:
	return {}


func deserialize_data(_d: Dictionary) -> void:
	pass


func get_gal_props(_nd: Dictionary) -> Dictionary:
	return {}
