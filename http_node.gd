extends GraphNode

signal delete_pressed(node: GraphNode)
signal text_updated

var url: String = ""
var body: String = ""
var headers_text: String = ""
var response_text: String = ""
var error_text: String = ""

@onready var method_option: OptionButton = $MethodOption
@onready var url_edit: LineEdit = $UrlEdit
@onready var status_label: Label = $StatusLabel


func _ready() -> void:
	title = "HTTP"
	set_slot(0, true, 0, Color.CYAN, false, 0, Color.WHITE)
	set_slot(1, true, 0, Color.YELLOW, false, 0, Color.WHITE)
	set_slot(2, true, 0, Color.MAGENTA, false, 0, Color.WHITE)
	set_slot(3, false, 0, Color.WHITE, true, 0, Color.GREEN)
	set_slot(4, false, 0, Color.WHITE, true, 0, Color.RED)

	var http := HTTPRequest.new()
	http.name = "HTTPRequest"
	add_child(http)
	http.request_completed.connect(_on_request_completed)


func set_input(port: int, text: String) -> void:
	if port == 0:
		url = text.strip_edges()
		url_edit.text = url
	elif port == 1:
		body = text
	elif port == 2:
		headers_text = text


func _on_send() -> void:
	url = url_edit.text.strip_edges()
	if url == "":
		status_label.text = "No URL"
		return
	var http: HTTPRequest = $HTTPRequest
	var method := HTTPClient.METHOD_GET
	match method_option.selected:
		1: method = HTTPClient.METHOD_POST
		2: method = HTTPClient.METHOD_PUT
		3: method = HTTPClient.METHOD_DELETE
	status_label.text = "Sending..."
	var headers: PackedStringArray = _parse_headers()
	if method != HTTPClient.METHOD_GET:
		var has_ct := false
		for h in headers:
			if h.to_lower().begins_with("content-type:"):
				has_ct = true
				break
		if not has_ct:
			headers.append("Content-Type: application/json")
	var err := http.request(url, headers, method, body if method != HTTPClient.METHOD_GET else "")
	if err != OK:
		status_label.text = "Request failed: %d" % err
		error_text = "Request error: %d" % err
		response_text = ""
		text_updated.emit()


func _parse_headers() -> PackedStringArray:
	var result: PackedStringArray = []
	for line in headers_text.split("\n"):
		var trimmed := line.strip_edges()
		if trimmed != "" and ":" in trimmed:
			result.append(trimmed)
	return result


func _on_request_completed(_result: int, _code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	response_text = body.get_string_from_utf8()
	if _result != HTTPRequest.RESULT_SUCCESS:
		error_text = "HTTP error (result=%d, code=%d)" % [_result, _code]
		status_label.text = "Error: %d" % _code
	else:
		error_text = ""
		status_label.text = "OK: %d (%d bytes)" % [_code, body.size()]
	text_updated.emit()


func _on_delete_pressed() -> void:
	delete_pressed.emit(self)
