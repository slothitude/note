# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Note** — a minimal black-and-white notepad with a visual node graph system, built in **Godot 4.6** (GDScript). Windows-only (exec node uses `cmd /C`), borderless window, black/white theme.

## Running the Project

Open in Godot 4.6 editor and press F5. No build step, no package manager, no tests.

## Architecture

**Dual-mode UI** toggled via F1:
- **Edit view**: Text editor (`note.gd`) for writing/reading notepad content
- **Graph view**: Visual node editor (`graph.gd`) for building automated workflows

**Main scene** (`main.tscn`): `note.gd` extends `Control`, hosts both views as children, manages file I/O, window dragging, and keyboard shortcuts.

### Core Files

| File | Role |
|------|------|
| `graph.gd` | Central graph controller — extends `VBoxContainer`, manages all node CRUD, connections, serialization, propagation, sub-graphs, and GAL assembly |
| `note.gd` | App root — text editor, file operations, view switching, window chrome |
| `assembler.gd` | GAL parser — extends `RefCounted`, parses text into node/wire/trigger data for `graph.gd.assemble()` |

### Node Pattern

Each node type has a `.gd` script + `.tscn` scene. Nodes extend `GraphNode` and follow this contract:
- **Signal**: `delete_pressed(node)` and `text_updated`
- **Method**: `set_input(port, text)` — receive data on a port
- **Method**: `get_port_output(port)` — multi-port output resolution (used by If, HTTP, PC, Math, JSON nodes)
- **Properties**: Dynamic `enable_port`/`trigger_port` ints set by `_add_control_ports()`, resolved at runtime

### Trigger + Enable Pattern

All nodes (except Graph Input/Output) have dynamically-created trigger/enable ports:

| Port | Color | Behavior |
|------|-------|----------|
| Enable | Yellow input | `""` or `"false"` = disabled. Any other text = enabled. Always processed first |
| Trigger | Red input | Non-empty text = evaluate & propagate (if enabled) |
| Data | existing colors | Store values, do NOT auto-evaluate |

Direct user actions (Run button, Send button, toggle, text edits, Button press) bypass trigger requirement.

### Data Propagation

1. `text_updated` signal → `graph.gd._propagate_text()` → `_propagate_in()` on downstream nodes
2. `_visited` array prevents infinite cycles
3. `_assembling` flag blocks propagation during GAL assembly construction
4. `_get_output_text()` returns `""` for any disabled node

### Sub-Graphs

Stack-based nesting: `_graph_stack` in `graph.gd`. Entering pushes current state, exiting pops. Sub-graph evaluation creates a temporary `GraphEdit` with real nodes to compute outputs. Graph Input/Output nodes define the sub-graph's interface.

### Serialization

JSON format with `nodes[]` and `connections[]`. Auto-saves to `user://graph.json` on quit. Node type detection in `_get_node_type()` uses property-based duck typing (checks for `subgraph`, `notepad`, `output_true`, `response_text`, etc.).

### Graph Assembly Language (GAL)

Text-based graph builder parsed by `assembler.gd`. Keywords: `node`, `set`, `wire`, `trigger`. Parser is atomic — all errors collected, no graph changes if any error. Port maps defined in constants: `INPUT_PORTS`, `OUTPUT_PORTS`, `MODE_NAMES`, `VALID_PROPS`, `TYPE_PREFIXES`.

## Node Types (16 total)

Notepad, Execute, Find File, Bool, Math, Binary, PC (Program Counter), Timer, Sub-Graph, Graph Input, Graph Output, If, HTTP, Button, JSON, Agent

## Conventions

- All UI styling done in code (no theme resources) — black background, white text, programmatic `StyleBoxFlat`
- Node scenes use `.tscn` files with inline structure; ports configured via `set_slot()` calls in `_ready()`
- Port indices are hardcoded integers — changing port order requires updating both the node script and `assembler.gd` constants
- Files at project root are user-created notepad content (.md files), not project documentation

### Agent Node

Self-contained ReAct agent loop that calls Ollama, parses structured JSON responses, executes tools, and loops until done.

**Ports**: Prompt (in, WHITE), System (in, MAGENTA), URL (in, CYAN), Result (out, GREEN), Log (out, RED) + enable/trigger

**Tools**: `exec(command)`, `read_file(path)`, `write_file(path\ncontent)`

**GAL example**: `agent_chat.gal` — replace the complex HTTP+JSON pipeline with a single node
