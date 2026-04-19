extends GraphNode

signal delete_pressed(node: GraphNode)
signal text_updated

var prompt_text: String = ""
var output_value: String = ""
var interval_secs: float = 1.0
var countdown_remaining: int = 0
var enabled: bool = true
var enable_port: int = -1

@onready var status_label: Label = $StatusLabel
@onready var mode_option: OptionButton = $ModeOption
@onready var count_spin: SpinBox = $CountSpin

var _timer: Timer


func _ready() -> void:
	title = "Timer"
	set_slot(0, true, 0, Color.CYAN, false, 0, Color.WHITE)
	set_slot(1, true, 0, Color.CYAN, false, 0, Color.WHITE)
	set_slot(2, true, 0, Color.CYAN, false, 0, Color.WHITE)
	mode_option.add_item("One-shot")
	mode_option.add_item("Countdown")
	set_slot(5, false, 0, Color.WHITE, true, 0, Color.GREEN)
	_add_enable_port()
	_timer = Timer.new()
	add_child(_timer)
	_timer.timeout.connect(_on_timer_tick)
	_update_status()


func _add_enable_port() -> void:
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


func set_input(port: int, text: String) -> void:
	if port == enable_port:
		enabled = text.strip_edges() != "" and text.strip_edges().to_lower() != "false"
		return
	if not enabled:
		return
	match port:
		0:  # prompt
			prompt_text = text
			output_value = text
		1:  # start
			_start_timer()
		2:  # interval
			var v := text.strip_edges()
			if v.is_valid_float():
				interval_secs = float(v)


func _start_timer() -> void:
	_timer.stop()
	countdown_remaining = int(count_spin.value)
	_timer.wait_time = maxf(interval_secs, 0.1)
	_timer.one_shot = false
	_timer.start()
	_update_status()


func _on_timer_tick() -> void:
	if not enabled:
		return
	match mode_option.selected:
		0:  # One-shot
			_timer.stop()
		1:  # Countdown
			countdown_remaining -= 1
			if countdown_remaining <= 0:
				_timer.stop()
			else:
				_update_status()
				return
	output_value = prompt_text
	text_updated.emit()
	_update_status()


func _update_status() -> void:
	if _timer == null or _timer.is_stopped():
		status_label.text = "Stopped"
	else:
		match mode_option.selected:
			0: status_label.text = "Fired"
			1: status_label.text = "Running (%d)" % countdown_remaining


func _on_mode_changed(_index: int) -> void:
	_update_status()


func _on_delete_pressed() -> void:
	if _timer:
		_timer.stop()
	delete_pressed.emit(self)
