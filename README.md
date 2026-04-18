# Note

A minimal black-and-white notepad with a visual node graph system, built in Godot 4.6.

Dual-mode interface: write text in the editor, or switch to the graph to build automated workflows where notepads, commands, logic gates, and counters connect like circuits.

---

## Features

- Borderless, keyboard-driven text editor
- Visual node graph with data propagation chains
- 8 node types: Notepad, Execute, Find File, Bool, Program Counter, Sub-Graph, Graph Input, Graph Output
- Nested sub-graphs (graphs inside graphs)
- Save/open graphs as JSON
- Native OS file dialogs (.md, .py, .txt)
- Automatic temp file for unsaved work
- Right-click to disconnect connections
- Delete confirmation for unsaved content

---

## Keyboard Shortcuts

| Key | Action |
|---|---|
| `Ctrl+N` | New notepad |
| `Ctrl+O` | Open file |
| `Ctrl+S` | Save file |
| `F1` | Toggle Edit / Graph view |

---

## Node Types

### Notepad
Holds text. Has an Open button to edit in the text editor.

| Port | Side | Color | Description |
|---|---|---|---|
| 0 | Input | White | Replace content |
| 1 | Input | Cyan | Prepend (incoming + existing) |
| 2 | Input | Green | Append (existing + incoming) |
| 0 | Output | White | Emits text_buffer |

- Linked files show filename as title
- Preview shows first 3 lines
- `text_updated` signal propagates to downstream nodes

### Execute
Runs a Windows command via `cmd /C`.

| Port | Side | Color | Description |
|---|---|---|---|
| 0 | Input | White | Command text to run |
| 0 | Output | White | stdout output |
| 1 | Output | Red | stderr output |
| 2 | Input | Yellow | Trigger (any data fires execution) |

- Trigger port accepts any data and runs the command
- Command text comes from whatever is connected to port 0

### Find File
Searches for a file by name in the project directory.

| Port | Side | Color | Description |
|---|---|---|---|
| 0 | Input | White | Filename to search |
| 0 | Output | Green | Full path or `"false"` |

- Searches `C:\Users\aaron\exploring` recursively
- Returns the first match
- Outputs `"false"` if not found

### Bool
Boolean logic with AND, OR, NOT modes.

| Port | Side | Color | Description |
|---|---|---|---|
| 0 | Input | Cyan | Input A |
| 1 | Input | Cyan | Input B |
| 2 | Output | Green | `"true"` or `"false"` |

- **AND**: true when both inputs have data
- **OR**: true when either input has data
- **NOT**: true when Input A is empty (ignores B)
- Mode selected via dropdown on the node

### Program Counter (PC)
6-step counter/sequencer.

| Port | Side | Color | Description |
|---|---|---|---|
| 0 | Input | Cyan | Increment (+1, wraps at max) |
| 1 | Input | Cyan | Restart (resets to 0) |
| 2 | Input | Cyan | Jump to value (accepts integers) |
| 3-8 | Output | Green | Outputs 0-5: active port emits `"true"`, rest emit `"false"` |

- Large counter display (48px)
- Max count adjustable via SpinBox (1-6)
- Active output highlighted in green, inactive in gray
- Jump accepts integers and floats (modulo max)

### Sub-Graph
Contains an entire graph inside a single node. Click Edit to enter.

| Port | Side | Description |
|---|---|---|
| Dynamic | Input | One port per Graph Input node inside |
| Dynamic | Output | One port per Graph Output node inside |

- Ports rebuild automatically based on internal Input/Output nodes
- Supports nesting (sub-graphs inside sub-graphs)
- Internal graph saved as part of the parent graph JSON

### Graph Input / Output
Only available inside a Sub-Graph. Define the interface of the parent Sub-Graph node.

| Node | Port | Description |
|---|---|---|
| Input | Output (Cyan) | Passes data into the sub-graph |
| Output | Input (Green) | Captures data leaving the sub-graph |

---

## Data Propagation

Data flows automatically through connections like a template engine (Jinja2-style):

1. **On connection** — connecting two nodes immediately pushes data from source to target
2. **On text change** — any node emitting `text_updated` propagates to all downstream nodes
3. **Chain cascade** — A→B→C propagates fully. If A changes, B updates, then C updates from B
4. **Cycle protection** — visited-node tracking prevents infinite loops
5. **Exec trigger** — connecting a notepad to an Execute node's trigger port fires the command

---

## Graph File Operations

Toolbar buttons for managing graphs:

| Button | Action |
|---|---|
| **New** | Clear all nodes, start fresh |
| **Open** | Load a `.json` graph file |
| **Save** | Save to current file, or prompt Save As |
| **← Back** | Exit current sub-graph, return to parent |

Graphs auto-save to `user://graph.json` on quit. Manual save lets you choose any `.json` path.

---

## Deleting Nodes and Connections

- **Delete button** on each node removes it and clears all connections
- **Unsaved notepads** show a confirmation: "Save or Delete?"
  - Save opens the notepad in the editor
  - Delete removes it
- **Saved notepads** auto-save their content before deletion
- **Connections**: right-click on a connection line to disconnect it

---

## Save Format

Graphs are stored as JSON:

```json
{
  "nodes": [
    {
      "name": "Notepad0",
      "type": "notepad",
      "x": 120.0,
      "y": 120.0,
      "text": "content here",
      "file_path": ""
    }
  ],
  "connections": [
    {
      "from_node": "Notepad0",
      "from_port": 0,
      "to_node": "Exec0",
      "to_port": 0
    }
  ]
}
```

Node types: `notepad`, `exec`, `find_file`, `bool`, `pc`, `subgraph`, `graph_input`, `graph_output`

---

## Styling

- Borderless window with custom titlebar drag
- Black background, white text, white borders
- Rounded corners on panels and titlebars
- Graph grid: dark background with subtle gridlines
- Port colors: white (neutral), cyan (input), green (output/true), red (error), yellow (trigger)
