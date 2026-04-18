# Note — Graph Plan

## What It Is
Visual flow editor inside Note. Notepad nodes hold text, OS Execute nodes run commands. Connect them like n8n. Stdout and stderr route back to notepad nodes.

## Structure

### New Files
- `graph.tscn` — GraphEdit scene
- `graph.gd` — Graph logic, node management, connections, execution
- `notepad_node.tscn` — GraphNode for text buffers
- `notepad_node.gd` — Notepad node logic
- `exec_node.tscn` — GraphNode for OS Execute
- `exec_node.gd` — Execute node logic

### Main Menu Changes
- Add "Graph" and "Edit" items to the File button
- "Edit" shows the text editor view (current behavior)
- "Graph" shows the GraphEdit view

### Notepad Node
- Title bar with node name (editable)
- Text area inside the node (or minimal — just shows preview)
- Output port on the right (slot 0) — sends text content
- Input port on the left (slot 0) — receives text (e.g. from exec output)
- Clicking a notepad node in graph view selects it for editing in editor view

### OS Execute Node
- Title bar with node name
- Input port on the left (slot 0) — receives command text from a notepad
- Output port on the right (slot 0) — stdout
- Output port on the right (slot 1) — stderr
- A "Run" button on the node
- When run: takes connected input text, executes via OS, sends stdout/stderr to connected notepad nodes

### Execution Flow
1. Notepad node output → connected to OS Execute input
2. OS Execute runs the text as an OS command
3. stdout → sent to connected notepad node input (if connected)
4. stderr → sent to connected notepad node input (if connected)
5. Only connected ports pass data

### View Switching
- Main menu: Edit | Graph
- Edit view: current text editor, editing selected notepad node's text
- Graph view: GraphEdit canvas with nodes and connections
- Switching saves current state automatically
