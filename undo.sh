#!/bin/bash
# undo.sh — reverse the last change, then log why
cd /c/Users/aaron/exploring/note
echo "=== REVERSE CALLED ===" >> reverse_log.md
echo "Date: $(date)" >> reverse_log.md
echo "Reverting: $(git log -1 --pretty=%B)" >> reverse_log.md
echo "" >> reverse_log.md
git reset --hard HEAD~1
echo "Reverted to previous checkpoint"
