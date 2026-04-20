extends RefCounted

const AssemblerScript := preload("res://assembler.gd")


func run_all(graph, test_dir: String = "res://tests/") -> Dictionary:
	var passed := 0
	var failed := 0
	var details: Array[Dictionary] = []

	var dir := DirAccess.open(test_dir)
	if dir == null:
		return {"passed": 0, "failed": 0, "total": 0, "details": []}

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".gal"):
			var full_path := test_dir + file_name
			var result := _run_single_test(graph, full_path)
			details.append(result)
			if result.status == "PASS":
				passed += 1
			else:
				failed += 1
		file_name = dir.get_next()
	dir.list_dir_end()

	return {"passed": passed, "failed": failed, "total": passed + failed, "details": details}


func _run_single_test(graph, file_path: String) -> Dictionary:
	var f := FileAccess.open(file_path, FileAccess.READ)
	if f == null:
		return {"file": file_path, "status": "FAIL", "failures": ["Could not open file"]}
	var source := f.get_as_text()
	f.close()

	var asm_result: Dictionary = graph.assemble(source)
	if asm_result.is_empty():
		return {"file": file_path, "status": "FAIL", "failures": ["Assembly errors"]}

	# Parse expects from source directly
	var parser := AssemblerScript.new()
	var parse_result: Dictionary = parser.parse(source)
	var expects: Array = parse_result.get("expects", [])

	var failures: Array[String] = []
	for exp in expects:
		var label: String = exp.label
		var port_name: String = exp.port
		var expected: String = exp.value

		if not asm_result.labels.has(label):
			failures.append("Label '%s' not found" % label)
			continue

		var node: GraphNode = asm_result.labels[label]
		var type: String = asm_result.types[label]
		var port_idx = AssemblerScript.OUTPUT_PORTS[type].get(port_name)
		if port_idx == null:
			failures.append("Unknown port '%s' for %s" % [port_name, type])
			continue

		var actual: String = graph.get_node_output(node, int(port_idx))
		if actual != expected:
			failures.append("expect %s.%s == '%s', got '%s'" % [label, port_name, expected, actual])

	if failures.is_empty():
		return {"file": file_path, "status": "PASS"}
	else:
		return {"file": file_path, "status": "FAIL", "failures": failures}
