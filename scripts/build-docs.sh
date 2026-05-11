#!/usr/bin/env bash
# Local preview build of doc/telescope-orgmode.txt from DOCS.org.
#
# The authoritative build runs in CI (.github/workflows/docs.yml) via the
# kdheepak/panvimdoc GitHub Action. This script reproduces that build
# locally for previewing changes before pushing.
#
# Requires: pandoc, curl.
set -euo pipefail

PANVIMDOC_VERSION="v4.0.1"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/telescope-orgmode"
FILTER="$CACHE_DIR/panvimdoc-$PANVIMDOC_VERSION.lua"
INPUT="$ROOT/DOCS.org"
OUTPUT_DIR="$ROOT/doc"
OUTPUT="$OUTPUT_DIR/telescope-orgmode.txt"

if ! command -v pandoc >/dev/null 2>&1; then
  echo "error: pandoc is required (apt: pandoc, brew: pandoc)" >&2
  exit 1
fi

if [[ ! -f "$INPUT" ]]; then
  echo "error: $INPUT not found" >&2
  exit 1
fi

mkdir -p "$CACHE_DIR" "$OUTPUT_DIR"

if [[ ! -f "$FILTER" ]]; then
  echo "Fetching panvimdoc $PANVIMDOC_VERSION..."
  curl -fsSL \
    "https://raw.githubusercontent.com/kdheepak/panvimdoc/$PANVIMDOC_VERSION/scripts/panvimdoc.lua" \
    -o "$FILTER"
fi

echo "Building $OUTPUT from DOCS.org..."
pandoc \
  --shift-heading-level-by=0 \
  --metadata=project:telescope-orgmode \
  --metadata=vimversion:"NVIM v0.10.0" \
  --metadata=toc:true \
  --metadata=description:"Fuzzy search, refile and link insertion for orgmode" \
  --metadata=titledatepattern:"%Y %B %d" \
  --metadata=dedupsubheadings:true \
  --metadata=ignorerawblocks:true \
  --metadata=docmapping:false \
  --metadata=docmappingproject:true \
  --metadata=treesitter:true \
  --metadata=incrementheadinglevelby:0 \
  -t "$FILTER" \
  "$INPUT" \
  -o "$OUTPUT"

echo "Wrote $OUTPUT"
