# Note — TODO

## Project Setup
- [x] Create Godot project (4.6) in `note/`
- [x] Set project name to "Note"
- [x] Set default window title to "Note - Untitled"
- [x] Set window size to something reasonable (800x600)

## Scene
- [x] Create main scene: `Control` root
- [x] Add title bar with File button (left) and Close button (right)
- [x] Add `TextEdit` node, anchored to fill below title bar
- [x] Set TextEdit: black background, white text, white caret

## Styling
- [x] Black background on everything
- [x] White text everywhere
- [x] White borders on panel, buttons, rounded corners
- [x] No other colors
- [x] Borderless window
- [x] Panel with margin, white border, rounded corners

## Script — Core
- [x] Create `note.gd` on root node
- [x] Track state: `current_file_path = ""`, `unsaved = false`
- [x] Connect TextEdit `text_changed` signal → set `unsaved = true`, update title with *
- [x] Autofocus text edit on ready

## Script — File Menu
- [x] Open: show native OS `FileDialog` (filters *.md;*.py;*.txt)
- [x] On file selected: read file, set TextEdit text, store path, clear unsaved, update title
- [x] Save: if `current_file_path != ""` write file, else trigger Save As
- [x] Save As: show native OS `FileDialog` (save mode)
- [x] On save location chosen: write file, store path, clear unsaved, update title
- [x] Ctrl+O to open, Ctrl+S to save

## Script — Window
- [x] Drag title bar to move window
- [x] Close button auto-saves then quits
- [x] Auto-save on quit (save as if no file path)
- [x] Unsaved indicator in title (filename*)

## Polish
- [x] Quit menu item closes app
- [x] Test: open a .txt, edit, save, reopen — content matches
- [x] Test: save as new file, verify it exists on disk
- [x] Test: drag window, borderless, theme works
