#!/bin/sh
# Install git hooks by symlinking them from scripts/ to .git/hooks/

# Ensure we are in the project root
if [ ! -d ".git" ]; then
  echo "Error: .git directory not found. Please run this script from the project root."
  exit 1
fi

echo "Installing git hooks..."
ln -sf ../../scripts/pre-commit.sh .git/hooks/pre-commit
chmod +x scripts/pre-commit.sh
echo "Hooks installed successfully."
