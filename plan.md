# Note — Godot Notepad Clone

## What It Is
A minimal text editor built in Godot. Opens .md, .py, .txt files from the OS filesystem. Save and Save As. Black and white everywhere.

## What It Is Not
No syntax highlighting. No autocomplete. No terminal. No markdown rendering. No tabs. No split view. No plugins. No settings. No themes. No preferences.

## Structure
Single scene. Single script.

### UI Layout
- Menu bar at top: File menu (Open, Save, Save As)
- TextEdit node fills the rest of the window
- Black background, white text, white borders

### File Operations
- Open: Native OS file dialog, filtered to .md .py .txt
- Save: Writes to current file path (prompts Save As if no path)
- Save As: Native OS file dialog to pick save location

### State
- Track: current file path, unsaved changes flag
- Window title shows filename or "Untitled"
- Warn on unsaved changes before opening new file or closing
