extends GraphNode

signal run_pressed(node: GraphNode)
signal delete_pressed(node: GraphNode)

@onready var run_button: Button = $RunButton


func _ready() -> void:
	title = "Execute"
	set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)
	set_slot(1, false, 0, Color.WHITE, true, 1, Color.RED)
	print("ExecNode _ready called: ", name)


func _on_run_pressed() -> void:
	print("Run button pressed on: ", name)
	run_pressed.emit(self)


func _on_delete_pressed() -> void:
	delete_pressed.emit(self)
