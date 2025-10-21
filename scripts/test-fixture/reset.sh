#!/usr/bin/env bash
# Reset test fixture to clean state
# Usage: ./reset.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "Resetting test fixture..."

# Restore org files from git (or from embedded defaults if not tracked)
if git -C ../.. diff --quiet -- scripts/test-fixture/notes/ 2>/dev/null; then
  echo "  Notes already clean."
else
  git -C ../.. checkout -- scripts/test-fixture/notes/ 2>/dev/null && echo "  Notes restored from git." || {
    echo "  Notes not in git, skipping restore."
  }
fi

echo "Done. Ready for testing."
echo ""
echo "Usage:"
echo "  make e2e                         # from project root"
echo "  nvim --clean -u init.lua notes/work.org  # from this directory"
echo ""
echo "Keybindings:"
echo "  \\th / \\sh  - Headlines (Telescope / Snacks)"
echo "  \\tr / \\sr  - Refile    (Telescope / Snacks)"
echo "  \\ti / \\si  - Link      (Telescope / Snacks)"
echo "  \\tt / \\st  - Tags      (Telescope / Snacks)"
echo ""
echo "In picker:"
echo "  <C-Space>    - Toggle headlines/files"
echo "  <C-f>        - Toggle current file filter"
echo ""
