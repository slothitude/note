extends GraphNode

signal run_pressed(node: GraphNode)

@onready var run_button: Button = $RunButton


func _ready() -> void:
	title = "Execute"
	# Slot 0: input on left (command), stdout output on right
	set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)
	# Slot 1: no input, stderr output on right
	set_slot(1, false, 0, Color.WHITE, true, 1, Color.RED)


func _on_run_pressed() -> void:
	run_pressed.emit(self)
