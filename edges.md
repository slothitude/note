# Note — Edges

## What It Is
- A Godot 4.6 text editor called "Note"
- Opens .md, .py, .txt files using native OS file dialogs
- Save and Save As functionality
- Black and white — no color
- Borderless window with custom title bar
- Draggable title bar (File button left, Close button right)
- Panel with white border, rounded corners, margin
- Auto-focus on text edit, blinking caret
- Auto-save on close (prompts Save As if no file path)
- Ctrl+O to open, Ctrl+S to save
- Unsaved indicator in window title (filename*)

## What It Is Not
- Not a full IDE — no syntax highlighting, no autocomplete, no terminal
- Not a markdown renderer — just raw text editing
- Not a file manager — just open/edit/save
- No tabs, no split view, no plugins
- No settings, no themes, no preferences dialog
- No confirmation dialogs on close — just saves
- No OS window chrome — fully custom borderless

## Boundaries
- Single window, single file at a time
- Native OS file dialogs for open/save
- Minimal UI — title bar (File, X) and a text area, nothing else
