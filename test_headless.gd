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
			elif cname == "ResultLabel":
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
			elif cname == "ParamEdit":
				node.set("param_edit", child)
			elif cname == "TokenEdit":
				node.set("token_edit", child)
			elif cname == "ChatEdit":
				node.set("chat_edit", child)
			elif cname == "PathEdit":
				node.set("path_edit", child)
			elif cname == "KeyEdit":
				node.set("key_edit", child)
		elif child is OptionButton:
			if cname == "ModeOption":
				node.set("mode_option", child)
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
	_check("expect missing op", p.get_errors().size() > 0)

	p = AssemblerScript.new(); d = p.parse("node a notepad\nexpect a.out != x")
	_check("expect != operator", p.get_errors().is_empty() and d.expects.size() == 1 and d.expects[0].op == "!=")

	p = AssemblerScript.new(); d = p.parse("node a notepad\nexpect a.out > 0")
	_check("expect > operator", p.get_errors().is_empty() and d.expects.size() == 1 and d.expects[0].op == ">")

	p = AssemblerScript.new(); d = p.parse("node a notepad\nexpect a.out contains hello")
	_check("expect contains operator", p.get_errors().is_empty() and d.expects.size() == 1 and d.expects[0].op == "contains")

	# Comment on any node type
	p = AssemblerScript.new(); d = p.parse("node m math\nset m.comment This is a math node")
	_check("comment on any node", p.get_errors().is_empty() and d.nodes[0]._props.has("comment"))

	# Inline expressions in set
	p = AssemblerScript.new(); d = p.parse("var x = 10\nnode a notepad\nset a.text ${x + 5}")
	_check("inline expression add", p.get_errors().is_empty() and d.nodes[0]._props.text == "15")

	p = AssemblerScript.new(); d = p.parse("node a notepad\nset a.text ${3 * 4}")
	_check("inline expression mul", p.get_errors().is_empty() and d.nodes[0]._props.text == "12")

	p = AssemblerScript.new(); d = p.parse("var n = 10\nnode a notepad\nset a.text ${n - 3}")
	_check("inline expression sub", p.get_errors().is_empty() and d.nodes[0]._props.text == "7")

	p = AssemblerScript.new(); p.parse("node a notepad\nset b.text hi\nnode a notepad")
	_check("atomic on error", p.get_errors().size() > 0)

	# Error recovery — partial results returned even with errors
	p = AssemblerScript.new(); d = p.parse("node a notepad\nset b.text hi\nnode c notepad")
	_check("error recovery partial results", p.get_errors().size() > 0 and d.nodes.size() >= 1)

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

	# Telegram Receive node
	p = AssemblerScript.new(); d = p.parse("node recv tg_receive\nset recv.token test_token\nset recv.interval 5")
	_check("tg_receive node type", p.get_errors().is_empty() and d.nodes[0]._props.has("token") and d.nodes[0]._props.has("interval"))

	p = AssemblerScript.new(); p.parse("node recv tg_receive\nset recv.fake_prop x")
	_check("tg_receive invalid prop", p.get_errors().size() > 0)

	# Telegram Send node
	p = AssemblerScript.new(); d = p.parse("node snd tg_send\nset snd.token test_token\nset snd.chat_id 12345")
	_check("tg_send node type", p.get_errors().is_empty() and d.nodes[0]._props.has("token") and d.nodes[0]._props.has("chat_id"))

	# TG wire: receive -> send
	p = AssemblerScript.new(); d = p.parse("node recv tg_receive\nnode snd tg_send\nwire recv.message -> snd.message")
	_check("tg wire recv.message -> snd.message", p.get_errors().is_empty() and d.connections.size() == 1)

	# File Watch node
	p = AssemblerScript.new(); d = p.parse("node fw file_watch\nset fw.file_path test.txt\nset fw.interval 5")
	_check("file_watch node type", p.get_errors().is_empty() and d.nodes[0]._props.has("file_path") and d.nodes[0]._props.has("interval"))

	p = AssemblerScript.new(); p.parse("node fw file_watch\nset fw.fake_prop x")
	_check("file_watch invalid prop", p.get_errors().size() > 0)

	# File Watch wire: content -> notepad
	p = AssemblerScript.new(); d = p.parse("node fw file_watch\nnode np notepad\nwire fw.content -> np.set")
	_check("file_watch wire content -> notepad", p.get_errors().is_empty() and d.connections.size() == 1)

	# Log node
	p = AssemblerScript.new(); d = p.parse("node lg log\nset lg.max 100")
	_check("log node type", p.get_errors().is_empty() and d.nodes[0]._props.has("max"))

	p = AssemblerScript.new(); p.parse("node lg log\nset lg.fake_prop x")
	_check("log invalid prop", p.get_errors().size() > 0)

	# Log wire: notepad -> log
	p = AssemblerScript.new(); d = p.parse("node np notepad\nnode lg log\nwire np.out -> lg.value")
	_check("log wire np.out -> lg.value", p.get_errors().is_empty() and d.connections.size() == 1)

	# Store node
	p = AssemblerScript.new(); d = p.parse("node st store\nset st.mode GET\nset st.key mykey")
	_check("store node type", p.get_errors().is_empty() and d.nodes[0]._props.has("mode") and d.nodes[0]._props.has("key"))

	p = AssemblerScript.new(); p.parse("node st store\nset st.fake_prop x")
	_check("store invalid prop", p.get_errors().size() > 0)

	# Store wire: notepad value -> store
	p = AssemblerScript.new(); d = p.parse("node np notepad\nnode st store\nwire np.out -> st.value")
	_check("store wire np.out -> st.value", p.get_errors().is_empty() and d.connections.size() == 1)

	# Bar Chart node
	p = AssemblerScript.new(); d = p.parse("node bc bar_chart\nset bc.data A:10 B:20\nset bc.title Sales")
	_check("bar_chart node type", p.get_errors().is_empty() and d.nodes[0]._props.has("data") and d.nodes[0]._props.has("title"))

	p = AssemblerScript.new(); d = p.parse("node np notepad\nnode bc bar_chart\nwire np.out -> bc.data")
	_check("bar_chart wire np.out -> bc.data", p.get_errors().is_empty() and d.connections.size() == 1)

	# Pie Chart node
	p = AssemblerScript.new(); d = p.parse("node pc pie_chart\nset pc.data X:30 Y:70")
	_check("pie_chart node type", p.get_errors().is_empty() and d.nodes[0]._props.has("data"))

	# Line Graph node
	p = AssemblerScript.new(); d = p.parse("node lg line_graph\nset lg.data 10,20,30,40")
	_check("line_graph node type", p.get_errors().is_empty() and d.nodes[0]._props.has("data"))

	p = AssemblerScript.new(); d = p.parse("node a notepad\nnode m math\nwire a.out -> m.a")
	_check("wire named ports", p.get_errors().is_empty() and d.connections.size() == 1)

	var all_gal := "node a notepad\nnode b exec\nnode c find_file\nnode d bool\nnode e math\nnode f if\nnode g binary\nnode h pc\nnode i timer\nnode j http\nnode k json\nnode l button\nnode m agent\nnode n watcher\nnode o text\nnode p array\nnode q switch\nnode r random\nnode s dict\nnode t date\nnode u loop\nnode v regex\nnode w csv\nnode x merge\nnode y filter\nnode z subgraph\nnode aa graph_input\nnode ab graph_output\nnode ac tg_receive\nnode ad tg_send\nnode ae file_watch\nnode af log\nnode ag store\nnode ah bar_chart\nnode ai pie_chart\nnode aj line_graph"
	p = AssemblerScript.new(); d = p.parse(all_gal)
	_check("all 36 node types", p.get_errors().is_empty() and d.nodes.size() == 36)

	var claude_gal := FileAccess.open("res://claude_chat.gal", FileAccess.READ)
	if claude_gal != null:
		var source := claude_gal.get_as_text()
		claude_gal.close()
		p = AssemblerScript.new(); d = p.parse(source)
		_check("claude_chat.gal parses", p.get_errors().is_empty() and d.nodes.size() == 6)
	else:
		_check("claude_chat.gal parses", false)

	# Variable tests
	p = AssemblerScript.new(); d = p.parse("var greeting = hello\nnode a notepad\nset a.text $greeting")
	_check("var declaration + expand in set", p.get_errors().is_empty() and d.nodes.size() == 1)

	p = AssemblerScript.new(); d = p.parse("var x = 100\nnode a notepad at $x 200")
	_check("var expand in node position", p.get_errors().is_empty() and d.nodes.size() == 1 and d.nodes[0].x == 100.0)

	p = AssemblerScript.new(); d = p.parse("var msg = test\nnode a notepad\nexpect a.out == $msg")
	_check("var expand in expect", p.get_errors().is_empty() and d.expects.size() == 1 and d.expects[0].value == "test")

	# Import test
	p = AssemblerScript.new(); d = p.parse("import res://tests/test_import_lib.gal\nnode n2 notepad at 100 0")
	_check("import .gal file", p.get_errors().is_empty() and d.nodes.size() == 2)

	p = AssemblerScript.new(); d = p.parse("import res://nonexistent.gal\nnode a notepad")
	_check("import missing file error", p.get_errors().size() > 0)

	# Eval tests
	p = AssemblerScript.new(); d = p.parse("eval 2 + 3 * 4\nnode a notepad\nset a.text $_")
	_check("eval expression", p.get_errors().is_empty() and d.nodes.size() == 1)

	p = AssemblerScript.new(); d = p.parse("eval ")
	_check("eval empty error", p.get_errors().size() > 0)

	# Template tests
	p = AssemblerScript.new(); d = p.parse("template mynp notepad\ninstance a mynp at 100 200")
	_check("template + instance", p.get_errors().is_empty() and d.nodes.size() == 1 and d.nodes[0].x == 100.0)

	p = AssemblerScript.new(); d = p.parse("instance a unknown_tpl")
	_check("instance unknown template error", p.get_errors().size() > 0)

	# Include alias test
	p = AssemblerScript.new(); d = p.parse("include res://nonexistent.gal\nnode a notepad")
	_check("include missing file error", p.get_errors().size() > 0)

	# Function tests
	var func_src := "func hello(n):\nnode $n notepad\nset $n.text hi\nend\ncall hello(a)"
	p = AssemblerScript.new(); d = p.parse(func_src)
	_check("func definition + call", p.get_errors().is_empty() and d.nodes.size() == 1)

	var func_src2 := "func add(n1, n2):\nnode $n1 notepad\nnode $n2 notepad\nwire $n2.out -> $n1.set\nend\ncall add(x, y)"
	p = AssemblerScript.new(); d = p.parse(func_src2)
	_check("func with 2 params + wire", p.get_errors().is_empty() and d.nodes.size() == 2 and d.connections.size() == 1)

	p = AssemblerScript.new(); d = p.parse("call unknown(a)")
	_check("call unknown func error", p.get_errors().size() > 0)

	# GAL export round-trip test
	var graph: Node = load("res://graph.tscn").instantiate()
	root.add_child(graph)
	var gedit: GraphEdit = graph.find_child("GraphEdit", true, false)
	graph.set("graph_edit", gedit)
	var gal_in := "node n1 notepad at 0 0\nset n1.text hello\nnode m1 math at 200 0\nset m1.mode ADD\nwire n1.out -> m1.a"
	graph.call("assemble", gal_in)
	var gal_out: String = graph.call("export_gal")
	# Re-parse the exported GAL — should have at least the nodes
	var p2 := AssemblerScript.new()
	var d2: Dictionary = p2.parse(gal_out)
	_check("GAL export round-trip", p2.get_errors().is_empty() and d2.nodes.size() == 2 and d2.connections.size() == 1)
	graph.queue_free()

	# GAL conditional — if true
	p = AssemblerScript.new(); d = p.parse("var x = hello\nif $x == hello\nnode a notepad\nendif")
	_check("GAL if true", p.get_errors().is_empty() and d.nodes.size() == 1)

	# GAL conditional — if false, else
	p = AssemblerScript.new(); d = p.parse("var x = world\nif x == hello\nnode a notepad\nelse\nnode b exec\nendif")
	_check("GAL if/else", p.get_errors().is_empty() and d.nodes.size() == 1 and d.nodes[0].type == "exec")

	# GAL for loop
	p = AssemblerScript.new(); d = p.parse("for item in a,b,c\nnode $item notepad\nendfor")
	_check("GAL for loop", p.get_errors().is_empty() and d.nodes.size() == 3)

	# GAL break keyword
	p = AssemblerScript.new(); d = p.parse("node a notepad\nbreak a")
	_check("GAL break", p.get_errors().is_empty() and d.breaks.size() == 1)

	p = AssemblerScript.new(); p.parse("break unknown")
	_check("GAL break unknown label", p.get_errors().size() > 0)

	# Type map coverage
	var type_count: int = AssemblerScript.PORT_TYPE_MAP.size()
	_check("PORT_TYPE_MAP has entries", type_count >= 10)

	# GAL while loop
	p = AssemblerScript.new(); d = p.parse("var i = 0\nwhile $i < 3\nnode n$i notepad\nvar i = ${i + 1}\nendwhile")
	_check("GAL while loop", p.get_errors().is_empty() and d.nodes.size() == 3)

	# GAL while loop — zero iterations
	p = AssemblerScript.new(); d = p.parse("var x = 10\nwhile $x < 5\nnode a notepad\nendwhile")
	_check("GAL while zero iterations", p.get_errors().is_empty() and d.nodes.size() == 0)

	# GAL while loop — infinite loop cap
	p = AssemblerScript.new(); d = p.parse("while 1 == 1\nendwhile")
	_check("GAL while infinite cap", p.get_errors().size() > 0)

	# GAL while loop with wire
	p = AssemblerScript.new(); d = p.parse("var i = 0\nwhile $i < 2\nnode n$i notepad\nvar i = ${i + 1}\nendwhile\nwire n0.out -> n1.set")
	_check("GAL while with wire", p.get_errors().is_empty() and d.nodes.size() == 2 and d.connections.size() == 1)

	# GAL return from function
	p = AssemblerScript.new(); d = p.parse("func double(x):\nreturn ${x}x\nend\nvar r = call double(hi)")
	_check("GAL return from func", p.get_errors().is_empty())

	# GAL return stops body execution
	p = AssemblerScript.new(); d = p.parse("func early(y):\nreturn $y\nnode dead notepad\nend\nvar r = call early(ok)")
	_check("GAL return stops body", p.get_errors().is_empty() and d.nodes.size() == 0)

	# GAL var = call captures return
	p = AssemblerScript.new(); d = p.parse("func greet(n):\nreturn hello_$n\nend\nvar msg = call greet(world)\nnode a notepad\nset a.text $msg")
	_check("GAL var = call captures return", p.get_errors().is_empty() and d.nodes.size() == 1 and d.nodes[0]._props.get("text") == "hello_world")

	# GAL inline comments
	p = AssemblerScript.new(); d = p.parse("node a notepad # create notepad\nset a.text hello # set text")
	_check("GAL inline comments", p.get_errors().is_empty() and d.nodes.size() == 1 and d.nodes[0]._props.get("text") == "hello")

	# GAL inline comment on var
	p = AssemblerScript.new(); d = p.parse("var x = 42 # the answer\nnode a notepad\nset a.text $x")
	_check("GAL inline comment on var", p.get_errors().is_empty() and d.nodes[0]._props.get("text") == "42")

	# GAL inline comment on wire
	p = AssemblerScript.new(); d = p.parse("node a notepad\nnode b notepad\nwire a.out -> b.set # connect them")
	_check("GAL inline comment on wire", p.get_errors().is_empty() and d.connections.size() == 1)

	# GAL triple-quoted multiline value
	p = AssemblerScript.new(); d = p.parse("var x = \"\"\"line1\nline2\nline3\"\"\"\nnode a notepad\nset a.text $x")
	_check("GAL triple-quoted multiline", p.get_errors().is_empty() and d.nodes[0]._props.get("text") == "line1\\nline2\\nline3")

	# GAL single-line triple quote
	p = AssemblerScript.new(); d = p.parse("set a.text \"\"\"hello\"\"\"")
	# This is invalid (no node), just checking triple-quote doesn't crash
	# Actually let's do it properly
	p = AssemblerScript.new(); d = p.parse("node a notepad\nset a.text \"\"\"hello world\"\"\"")
	_check("GAL single-line triple quote", p.get_errors().is_empty() and d.nodes[0]._props.get("text") == "hello world")

	# Type warning — number output to string input
	p = AssemblerScript.new(); d = p.parse("node m math\nnode n notepad\nwire m.result -> n.set")
	var has_type_warn: bool = d.connections.size() == 1 and d.connections[0].has("_type_warn")
	_check("type warning on number->string", p.get_errors().is_empty() and has_type_warn)

	# No type warning — same types
	p = AssemblerScript.new(); d = p.parse("node n1 notepad\nnode n2 notepad\nwire n1.out -> n2.set")
	var no_type_warn: bool = d.connections.size() == 1 and not d.connections[0].has("_type_warn")
	_check("no type warning on string->string", p.get_errors().is_empty() and no_type_warn)

	# No type warning — any port
	p = AssemblerScript.new(); d = p.parse("node m math\nnode i if\nwire m.result -> i.data")
	var no_warn_any: bool = d.connections.size() == 1 and not d.connections[0].has("_type_warn")
	_check("no type warning on number->any", p.get_errors().is_empty() and no_warn_any)

	# Debug assembly — creates nodes but doesn't fire triggers
	var dbg: Node = load("res://graph.tscn").instantiate()
	root.add_child(dbg)
	var dgedit: GraphEdit = dbg.find_child("GraphEdit", true, false)
	dbg.set("graph_edit", dgedit)
	var debug_src := "node a notepad\nset a.text Hello\nnode b notepad\nwire a.out -> b.set\ntrigger a"
	var debug_result: Dictionary = dbg.call("assemble_debug", debug_src)
	_check("debug assemble creates nodes", debug_result.nodes == 2 and debug_result.wires == 1)
	var in_debug: bool = dbg.get("_debug_mode") == true
	var trig_count: int = dbg.get("_debug_triggers").size()
	_check("debug mode has triggers", in_debug and trig_count == 1)
	# Step should fire the trigger
	dbg.call("_debug_step")
	var stepped: bool = dbg.get("_debug_idx") == 1
	_check("debug step fires trigger", stepped)
	dbg.call("_debug_stop")
	var stopped: bool = dbg.get("_debug_mode") == false
	_check("debug stop exits mode", stopped)
	dbg.queue_free()


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
		var op: String = exp.get("op", "==")

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
		var passed := false
		var desc := ""
		match op:
			"==":
				passed = actual == expected
				desc = "expect %s.%s == '%s', got '%s'" % [label, port_name, expected, actual]
			"!=":
				passed = actual != expected
				desc = "expect %s.%s != '%s', got '%s'" % [label, port_name, expected, actual]
			">":
				passed = actual.to_float() > expected.to_float()
				desc = "expect %s.%s > '%s', got '%s'" % [label, port_name, expected, actual]
			"<":
				passed = actual.to_float() < expected.to_float()
				desc = "expect %s.%s < '%s', got '%s'" % [label, port_name, expected, actual]
			"contains":
				passed = actual.find(expected) >= 0
				desc = "expect %s.%s contains '%s', got '%s'" % [label, port_name, expected, actual]
			_:
				passed = actual == expected
				desc = "expect %s.%s == '%s', got '%s'" % [label, port_name, expected, actual]
		if not passed:
			test_failures.append(desc)

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
