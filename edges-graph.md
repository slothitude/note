# Note — Graph Edges

## What It Is
- Many notepad nodes — each holds text, each has an output port
- OS Execute nodes — take text input, run it as an OS command
- OS Execute has two outputs: stdout and stderr
- stdout connects to a notepad node's input (if connected)
- stderr connects to a notepad node's input (if connected)
- Only connected ports pass data — like n8n
- Main menu switches between editor view and graph view
- Editor view: edit text of the selected notepad node
- Graph view: add, delete, connect nodes visually

## What It Is Not
- Not a terminal — fire and forget, no interactive session
- Not a general graph editor — only notepad nodes and OS Execute nodes
- Not error handling or retry logic — run once
- Not a debugger
- Not a build tool or package manager

## Boundaries
- Main menu: "Edit" and "Graph" to switch views
- Graph uses Godot GraphEdit and GraphNode
- Notepad output → OS Execute input (command to run)
- OS Execute stdout output → Notepad input (captures output)
- OS Execute stderr output → Notepad input (captures errors)
- Connections are optional — only connected ports pass data
- Each notepad node maps to a text buffer (not necessarily a file)
