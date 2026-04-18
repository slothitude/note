#!/bin/bash
# checkpoint.sh — save current state before any change
# Usage: ./checkpoint.sh "description of what's about to change"
cd /c/Users/aaron/exploring/note
git add -A
git commit -m "checkpoint: $1" --allow-empty 2>/dev/null
echo "Checkpoint saved: $1"
