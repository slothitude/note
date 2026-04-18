# Note — Graph TODO

## Main Menu Update
- [ ] Add "Graph" and "Edit" items to the File button popup
- [ ] Create view switching logic in note.gd (show/hide editor vs graph)
- [ ] Track current view state

## Notepad Node
- [ ] Create `notepad_node.tscn` — GraphNode with input slot (left) and output slot (right)
- [ ] Title bar with editable name
- [ ] Preview of text content inside the node
- [ ] Store text buffer as a variable
- [ ] Create `notepad_node.gd` — handles text storage, slot configuration

## OS Execute Node
- [ ] Create `exec_node.tscn` — GraphNode with input slot (left), stdout slot (right), stderr slot (right)
- [ ] Title bar with name
- [ ] "Run" button on the node
- [ ] Create `exec_node.gd` — handles command execution, stdout/stderr output

## Graph Scene
- [ ] Create `graph.tscn` — GraphEdit scene
- [ ] Create `graph.gd` — manages nodes, connections, execution
- [ ] Add node buttons: "Add Notepad", "Add Exec"
- [ ] Handle connection signals (connection_request, disconnection_request)
- [ ] Handle delete node

## Execution Logic
- [ ] When exec node Run pressed: gather input text from connected notepad node
- [ ] Execute command via OS (OS.execute or subprocess)
- [ ] Send stdout to connected notepad node (update its text buffer)
- [ ] Send stderr to connected notepad node (update its text buffer)

## View Switching
- [ ] Edit view: text editor edits the selected notepad node's text buffer
- [ ] Graph view: shows graph, clicking notepad node selects it
- [ ] Switching views preserves state
- [ ] Style graph view to match black and white theme

## Polish
- [ ] Graph toolbar styled black and white
- [ ] Nodes styled black and white with white borders
- [ ] Test: create notepad → type command → connect to exec → run → output flows to another notepad
