extends SceneTree

# Headless test runner: godot --headless -s test_headless.gd

const AssemblerScript := preload("res://assembler.gd")

var _passed := 0
var _failed := 0


func _init() -> void:
	print("\n=== GAL Test Runner ===\n")
	_run_parser_tests()
	_run_assembly_tests()
	_print_summary()
	quit()


func _fix_onready(node: Node) -> void:
	# Workaround: @onready doesn't resolve in headless mode.
	# Manually set typed @onready vars from scene children.
	for child in node.get_children():
		var cname: String = child.name
		if child is OptionButton:
			if cname == "ModeOption":
				node.set("mode_option", child)
			elif cname == "MethodOption":
				node.set("method_option", child)
		elif child is Label:
			if cname == "Result":
				node.set("result_label", child)
			elif cname == "Preview":
				node.set("preview", child)
			elif cname == "StatusLabel":
				node.set("status_label", child)
		elif child is LineEdit:
			if cname == "UrlEdit":
				node.set("url_edit", child)
			elif cname == "ModelEdit":
				node.set("model_edit", child)
		elif child is SpinBox:
			if cname == "MaxSpin":
				node.set("max_spin", child)
			elif cname == "CountSpin":
				node.set("count_spin", child)
			elif cname == "TurnsSpin":
				node.set("turns_spin", child)


func _run_parser_tests() -> void:
	print("--- Parser Tests ---")
	var p: AssemblerScript
	var d: Dictionary

	p = AssemblerScript.new(); d = p.parse("node a notepad")
	_check("valid node declaration", p.get_errors().is_empty() and d.nodes.size() == 1)

	p = AssemblerScript.new(); p.parse("node a fake")
	_check("unknown type error", p.get_errors().size() > 0)

	p = AssemblerScript.new(); p.parse("node a notepad\nnode a notepad")
	_check("duplicate label error", p.get_errors().size() > 0)

	p = AssemblerScript.new(); d = p.parse("node a notepad\nset a.text hello")
	_check("valid set", p.get_errors().is_empty() and d.nodes[0]._props.has("text"))

	p = AssemblerScript.new(); p.parse("set a.text hi")
	_check("unknown label in set", p.get_errors().size() > 0)

	p = AssemblerScript.new(); d = p.parse("node a notepad\nnode b notepad\nwire a -> b")
	_check("wire default ports", p.get_errors().is_empty() and d.connections.size() == 1)

	p = AssemblerScript.new(); p.parse("node a notepad\nwire a -> b")
	_check("unknown target in wire", p.get_errors().size() > 0)

	p = AssemblerScript.new(); d = p.parse("node a notepad\ntrigger a")
	_check("valid trigger", p.get_errors().is_empty() and d.triggers.size() == 1)

	p = AssemblerScript.new(); d = p.parse("node a notepad\nexpect a.out == hello")
	_check("valid expect", p.get_errors().is_empty() and d.expects.size() == 1 and d.expects[0].value == "hello")

	p = AssemblerScript.new(); p.parse("expect a.out == x")
	_check("expect unknown label", p.get_errors().size() > 0)

	p = AssemblerScript.new(); p.parse("node a notepad\nexpect a.fake == x")
	_check("expect unknown port", p.get_errors().size() > 0)

	p = AssemblerScript.new(); p.parse("node a notepad\nexpect a.out hello")
	_check("expect missing ==", p.get_errors().size() > 0)

	p = AssemblerScript.new(); p.parse("node a notepad\nset b.text hi\nnode a notepad")
	_check("atomic on error", p.get_errors().size() > 0)

	p = AssemblerScript.new(); d = p.parse("# comment\n\nnode a notepad\n# another")
	_check("comments and blanks", p.get_errors().is_empty() and d.nodes.size() == 1)

	p = AssemblerScript.new(); p.parse("blah blah")
	_check("unknown keyword", p.get_errors().size() > 0)

	p = AssemblerScript.new(); d = p.parse("node a notepad at 100 200")
	_check("position parsing", d.nodes[0].x == 100.0 and d.nodes[0].y == 200.0)

	p = AssemblerScript.new(); p.parse("node m math\nset m.mode ADD")
	_check("valid mode", p.get_errors().is_empty())

	p = AssemblerScript.new(); p.parse("node m math\nset m.mode FAKE")
	_check("invalid mode", p.get_errors().size() > 0)

	p = AssemblerScript.new(); d = p.parse("node ag agent\nset ag.model llama3.2\nset ag.max_turns 3")
	_check("agent node type", p.get_errors().is_empty() and d.nodes[0]._props.has("model") and d.nodes[0]._props.has("max_turns"))

	p = AssemblerScript.new(); p.parse("node ag agent\nset ag.fake_prop x")
	_check("agent invalid prop", p.get_errors().size() > 0)

	p = AssemblerScript.new(); d = p.parse("node ag agent\nnode np notepad\nwire np.out -> ag.prompt")
	_check("agent wire to prompt", p.get_errors().is_empty() and d.connections.size() == 1)

	p = AssemblerScript.new(); d = p.parse("node ag agent\nnode np notepad\nwire ag.result -> np.set")
	_check("agent wire from result", p.get_errors().is_empty() and d.connections.size() == 1)

	p = AssemblerScript.new(); d = p.parse("node a notepad\nnode m math\nwire a.out -> m.a")
	_check("wire named ports", p.get_errors().is_empty() and d.connections.size() == 1)

	var all_gal := "node a notepad\nnode b exec\nnode c find_file\nnode d bool\nnode e math\nnode f if\nnode g binary\nnode h pc\nnode i timer\nnode j http\nnode k json\nnode l button\nnode m agent"
	p = AssemblerScript.new(); d = p.parse(all_gal)
	_check("all 13 node types", p.get_errors().is_empty() and d.nodes.size() == 13)

	var claude_gal := FileAccess.open("res://claude_chat.gal", FileAccess.READ)
	if claude_gal != null:
		var source := claude_gal.get_as_text()
		claude_gal.close()
		p = AssemblerScript.new(); d = p.parse(source)
		_check("claude_chat.gal parses", p.get_errors().is_empty() and d.nodes.size() == 6)
	else:
		_check("claude_chat.gal parses", false)


func _run_assembly_tests() -> void:
	print("\n--- Assembly Integration Tests ---")
	var test_dir := "res://tests/"
	var dir := DirAccess.open(test_dir)
	if dir == null:
		print("  No tests/ directory, skipping")
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".gal"):
			_run_integration_test(test_dir + file_name)
		file_name = dir.get_next()
	dir.list_dir_end()


func _run_integration_test(file_path: String) -> void:
	var f := FileAccess.open(file_path, FileAccess.READ)
	if f == null:
		print("  [FAIL] %s - could not open" % file_path.get_file())
		_failed += 1
		return
	var source := f.get_as_text()
	f.close()

	var graph: Node = load("res://graph.tscn").instantiate()
	root.add_child(graph)

	var gedit: GraphEdit = graph.find_child("GraphEdit", true, false)
	if gedit == null:
		print("  [FAIL] %s - no GraphEdit" % file_path.get_file())
		_failed += 1
		graph.queue_free()
		return
	graph.set("graph_edit", gedit)

	var asm_result: Dictionary = graph.call("assemble", source)

	if asm_result.is_empty():
		print("  [FAIL] %s - assembly errors" % file_path.get_file())
		_failed += 1
		graph.queue_free()
		return

	var parser := AssemblerScript.new()
	var parse_result: Dictionary = parser.parse(source)
	var expects: Array = parse_result.get("expects", [])

	var test_failures: Array[String] = []
	for exp in expects:
		var label: String = exp.label
		var port_name: String = exp.port
		var expected: String = exp.value

		if not asm_result.labels.has(label):
			test_failures.append("Label '%s' not found" % label)
			continue

		var node: GraphNode = asm_result.labels[label]
		var type: String = asm_result.types[label]
		var port_idx = AssemblerScript.OUTPUT_PORTS[type].get(port_name)
		if port_idx == null:
			test_failures.append("Unknown port '%s' for %s" % [port_name, type])
			continue

		var actual: String = graph.call("get_node_output", node, int(port_idx))
		if actual != expected:
			test_failures.append("expect %s.%s == '%s', got '%s'" % [label, port_name, expected, actual])

	graph.queue_free()

	if test_failures.is_empty():
		print("  [PASS] %s" % file_path.get_file())
		_passed += 1
	else:
		print("  [FAIL] %s" % file_path.get_file())
		for fail in test_failures:
			print("    - %s" % fail)
		_failed += 1


func _check(name: String, passed: bool) -> void:
	if passed:
		print("  [PASS] %s" % name)
		_passed += 1
	else:
		print("  [FAIL] %s" % name)
		_failed += 1


func _print_summary() -> void:
	var total := _passed + _failed
	print("\n=== Results: %d/%d passed, %d failed ===" % [_passed, total, _failed])
	if _failed > 0:
		print("SOME TESTS FAILED")
	else:
		print("ALL TESTS PASSED")
