#!/bin/sh
# Auto-format staged Dart files before commit

# Get staged files that are .dart
# Filter ACMR: Added, Copied, Modified, Renamed
staged_files=$(git diff --cached --name-only --diff-filter=ACMR | grep '\.dart$' || true)

if [ -n "$staged_files" ]; then
  echo "--- Auto-formatting staged Dart files ---"
  dart format $staged_files
  
  # Add the formatted files back to staging
  git add $staged_files
  echo "--- Formatting complete ---"
fi
