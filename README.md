# Note

A minimal black-and-white notepad with a visual node graph system. Built in Godot 4.6.

Dual-mode interface: write text in the editor, or switch to the graph to build automated workflows where notepads, commands, logic gates, and counters connect like circuits.

---

## Controls

| Key | Action |
|-----|--------|
| `Ctrl+N` | New notepad |
| `Ctrl+O` | Open file |
| `Ctrl+S` | Save file |
| `F1` | Toggle Edit / Graph view |

---

## Node Types

### Notepad
Holds text. Has an Open button to edit in the text editor.

| Port | Side | Color | Description |
|------|------|-------|-------------|
| 0 | Input | White | Replace content (`set`) |
| 1 | Input | Cyan | Prepend (`prepend`) |
| 2 | Input | Cyan | Append (`append`) |
| 3 | Input | Yellow | Enable |
| - | Input | Red | Trigger |
| 0 | Output | White | Emits text content (`out`) |

- Linked files show filename as title
- Preview shows first 3 lines

### Execute
Runs a Windows command via `cmd /C`.

| Port | Side | Color | Description |
|------|------|-------|-------------|
| 0 | Input | White | Command text (`command`) |
| 2 | Input | Red | Trigger — any data fires execution |
| - | Input | Yellow | Enable |
| 0 | Output | White | stdout (`stdout`) |
| 1 | Output | Red | stderr (`stderr`) |

### Find File
Searches for a file by name.

| Port | Side | Color | Description |
|------|------|-------|-------------|
| 0 | Input | White | Filename to search (`query`) |
| - | Input | Yellow | Enable |
| - | Input | Red | Trigger |
| 0 | Output | Green | Full path or `"false"` (`result`) |

- Searches `C:\Users\aaron\exploring` recursively
- Returns `"false"` if not found

### Bool
Boolean logic with AND, OR, NOT modes.

| Port | Side | Color | Description |
|------|------|-------|-------------|
| 0 | Input | Cyan | Input A (`a`) |
| 1 | Input | Cyan | Input B (`b`) |
| - | Input | Yellow | Enable |
| - | Input | Red | Trigger |
| 2 | Output | Green | `"true"` or `"false"` (`result`) |

- **AND**: true when both inputs are truthy
- **OR**: true when either input is truthy
- **NOT**: true when Input A is empty/falsy

### Math
Arithmetic: ADD, SUB, MUL, DIV, MOD, POW.

| Port | Side | Color | Description |
|------|------|-------|-------------|
| 0 | Input | Cyan | Input A (`a`) |
| 1 | Input | Cyan | Input B (`b`) |
| - | Input | Yellow | Enable |
| - | Input | Red | Trigger |
| 2 | Output | White | Raw output (`raw`) |
| 3 | Output | Green | Formatted result (`result`) |

### If
Routes data to `true` or `false` output based on condition.

| Port | Side | Color | Description |
|------|------|-------|-------------|
| 0 | Input | Yellow | Condition (`condition`) |
| 1 | Input | Cyan | Data (`data`) |
| - | Input | Yellow | Enable |
| - | Input | Red | Trigger |
| 2 | Output | Green | Data when condition is truthy (`true`) |
| 3 | Output | Red | Data when condition is falsy (`false`) |

### Binary
Outputs `true` or `false` via toggle button.

| Port | Side | Color | Description |
|------|------|-------|-------------|
| - | Input | Yellow | Enable |
| - | Input | Red | Trigger |
| 0 | Output | Green | `"true"` or `"false"` (`out`) |

### Program Counter (PC)
6-step counter/sequencer.

| Port | Side | Color | Description |
|------|------|-------|-------------|
| 0 | Input | Cyan | Increment (`increment`) |
| 1 | Input | Cyan | Restart (`restart`) |
| 2 | Input | Cyan | Jump to value (`jump`) |
| - | Input | Yellow | Enable |
| 3-8 | Output | Green | Active port emits `"true"`, rest emit `"false"` (`out0`-`out5`) |

- Max count adjustable via SpinBox (1-6)

### Timer
Delays output. Two modes: One-shot and Countdown.

| Port | Side | Color | Description |
|------|------|-------|-------------|
| 0 | Input | Cyan | Prompt text (`prompt`) |
| 1 | Input | Cyan | Start (`start`) |
| 2 | Input | Cyan | Interval in seconds (`interval`) |
| - | Input | Yellow | Enable |
| 5 | Output | Green | Emits prompt text (`out`) |

- **One-shot**: fires once after interval
- **Countdown**: ticks N times, outputs prompt at zero

### HTTP
Sends HTTP requests (GET/POST/PUT/DELETE).

| Port | Side | Color | Description |
|------|------|-------|-------------|
| 0 | Input | Cyan | URL (`url`) |
| 1 | Input | Yellow | Body (`body`) |
| 2 | Input | Magenta | Headers (`headers`) |
| - | Input | Yellow | Enable |
| - | Input | Red | Trigger |
| 3 | Output | Green | Response body (`response`) |
| 4 | Output | Red | Error text (`error`) |

### Button
Named button. Also appears in title bar in Edit view.

| Port | Side | Color | Description |
|------|------|-------|-------------|
| 0 | Output | Green | Emits `"true"` on press (`out`) |

- Prompts for name on creation

### Sub-Graph
Contains a nested graph. Click Edit to enter.

| Port | Side | Description |
|------|------|-------------|
| Dynamic | Input | One per Graph Input node inside |
| Dynamic | Output | One per Graph Output node inside |

### Graph Input / Output
Only inside Sub-Graphs. Define the parent Sub-Graph's interface.

| Node | Port | Description |
|------|------|-------------|
| Input | Output (Cyan) | Passes data into the sub-graph |
| Output | Input (Green) | Captures data leaving the sub-graph |

---

## Port Colors

| Color | Meaning |
|-------|---------|
| White | General data |
| Cyan | Numeric/text input |
| Green | Output |
| Yellow | Enable — gates node output. Empty/false = disabled |
| Red | Trigger — fires evaluation. Data ports only store values |
| Magenta | Headers (HTTP) |

---

## Data Propagation

1. **Trigger/Enable pattern**: Data inputs store values without auto-evaluating. Trigger port fires evaluation. Enable port gates all output.
2. **Auto-propagation**: Nodes with `text_updated` signal propagate to downstream nodes on change.
3. **Chain cascade**: A→B→C propagates fully.
4. **Cycle protection**: visited-node tracking prevents infinite loops.
5. **Direct actions bypass trigger**: Run button, Send button, toggle, text edits, Button press.

---

## Graph Assembly Language (GAL)

Build graphs from text. Click **Assemble** in the Graph toolbar.

```
# Comment
node <label> <type> [at <x> <y>]
set  <label>.<prop> <value>
wire <src>.<port> -> <dst>.<port>
trigger <label>
```

### Example: Add 7 + 5

```
node a notepad
set a.text 7
node b notepad
set b.text 5
node calc math
set calc.mode ADD
node result notepad
wire a.out -> calc.a
wire b.out -> calc.b
wire calc.result -> result.set
trigger calc
```

### Wire Shorthand

Omit port names for defaults: source = `out`, target = `set`.

```
wire a -> b          # same as wire a.out -> b.set
```

### Input Ports

| Type | Ports |
|------|-------|
| notepad | `set`, `prepend`, `append`, `enable`, `trigger` |
| math | `a`, `b`, `enable`, `trigger` |
| bool | `a`, `b`, `enable`, `trigger` |
| if | `condition`, `data`, `enable`, `trigger` |
| binary | `enable`, `trigger` |
| pc | `increment`, `restart`, `jump`, `enable` |
| timer | `prompt`, `start`, `interval`, `enable` |
| http | `url`, `body`, `headers`, `enable`, `trigger` |
| exec | `command`, `trigger`, `enable` |
| find_file | `query`, `enable`, `trigger` |

### Output Ports

| Type | Ports |
|------|-------|
| notepad | `out` |
| math | `raw`, `result` |
| bool | `result` |
| if | `true`, `false` |
| binary | `out` |
| pc | `out0`, `out1`, `out2`, `out3`, `out4`, `out5` |
| timer | `out` |
| http | `response`, `error` |
| exec | `stdout`, `stderr` |
| button | `out` |
| find_file | `result` |

### Properties

| Type | Properties |
|------|------------|
| notepad | `text`, `file_path`, `enabled` |
| math | `mode` (ADD, SUB, MUL, DIV, MOD, POW) |
| bool | `mode` (AND, OR, NOT) |
| if | `condition_text`, `data_text` |
| binary | `output_value` |
| pc | `counter`, `max` |
| timer | `prompt_text`, `interval`, `mode` (one-shot, countdown), `count` |
| http | `url`, `body`, `headers`, `method` (GET, POST, PUT, DELETE) |
| button | `title` |
| exec | `enabled` |

### Trigger

The `trigger` keyword evaluates a node after assembly. Equivalent to pressing its button.

```
trigger calc
```

---

## Graph File Operations

| Button | Action |
|--------|--------|
| **New** | Clear all nodes, start fresh |
| **Open** | Load a `.json` graph file |
| **Save** | Save to current file, or prompt Save As |
| **Assemble** | Build graph from GAL text |
| **← Back** | Exit current sub-graph, return to parent |

Graphs auto-save to `user://graph.json` on quit.

---

## Deleting Nodes

- **Delete button** on each node removes it and clears all connections
- **Unsaved notepads** show a confirmation: Save or Delete
- **Saved notepads** auto-save content before deletion
- **Connections**: right-click a connection line to disconnect

---

## Save Format

Graphs are stored as JSON:

```json
{
  "nodes": [
    { "name": "Notepad0", "type": "notepad", "x": 120.0, "y": 120.0, "text": "content" }
  ],
  "connections": [
    { "from_node": "Notepad0", "from_port": 0, "to_node": "Exec0", "to_port": 0 }
  ]
}
```

---

## Platform

Windows only. Borderless window with black/white theme.
