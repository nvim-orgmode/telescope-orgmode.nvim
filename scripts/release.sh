#!/usr/bin/env bash
set -euo pipefail

# Release script for telescope-orgmode.nvim
# Usage: ./scripts/release.sh [patch|minor|major]

TYPE="${1:-patch}"

# Validate type
if [[ "$TYPE" != "patch" && "$TYPE" != "minor" && "$TYPE" != "major" ]]; then
    echo "Usage: $0 [patch|minor|major]"
    exit 1
fi

# Get latest tag
LATEST=$(git tag --sort=-v:refname | head -1)
if [[ -z "$LATEST" ]]; then
    echo "Error: No existing tags found"
    exit 1
fi

# Parse version
IFS='.' read -r MAJOR MINOR PATCH <<< "$LATEST"

# Bump
case "$TYPE" in
    major) MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0 ;;
    minor) MINOR=$((MINOR + 1)); PATCH=0 ;;
    patch) PATCH=$((PATCH + 1)) ;;
esac

VERSION="${MAJOR}.${MINOR}.${PATCH}"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Release: ${LATEST} → ${VERSION} (${TYPE})"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Pre-flight checks
echo "Checking prerequisites..."

if [[ -n "$(git status --porcelain)" ]]; then
    echo "Error: Working tree not clean"
    exit 1
fi

BRANCH=$(git branch --show-current)
if [[ "$BRANCH" != "main" ]]; then
    echo "Error: Not on main branch (on: ${BRANCH})"
    exit 1
fi

if ! command -v gh &>/dev/null; then
    echo "Error: gh CLI not installed"
    exit 1
fi

if ! command -v vhs &>/dev/null; then
    echo "Warning: VHS not installed, skipping demo recording"
    SKIP_DEMOS=true
else
    SKIP_DEMOS=false
fi

echo "  ✓ Clean tree"
echo "  ✓ On main branch"
echo "  ✓ gh CLI available"

# Run tests
echo ""
echo "Running tests..."
make test
echo ""

# Check formatting
echo "Checking formatting..."
make lint
echo ""

# Check changelog
if ! grep -q "## ${VERSION}" CHANGELOG.md 2>/dev/null; then
    echo "Warning: No CHANGELOG.md entry for ${VERSION}"
    echo "Continue anyway? [y/N]"
    read -r CONFIRM
    if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
        echo "Aborted. Add changelog entry first."
        exit 1
    fi
fi

# Record demos
if [[ "$SKIP_DEMOS" == "false" ]]; then
    echo "Recording demos..."
    make demo
    echo ""
fi

# Confirm
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Ready to release ${VERSION}"
echo ""
echo "  This will:"
echo "    1. Create tag ${VERSION}"
echo "    2. Push main + tag to origin"
echo "    3. Create GitHub release"
if [[ "$SKIP_DEMOS" == "false" ]]; then
    echo "    4. Upload demo videos"
fi
echo ""
echo "  Continue? [y/N]"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
read -r CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo "Aborted."
    exit 0
fi

# Tag
git tag "$VERSION"
echo "Tagged ${VERSION}"

# Push
git push origin main --tags
echo "Pushed to origin"

# Extract changelog for this version
NOTES=$(sed -n "/^## ${VERSION}/,/^## /{/^## [^${VERSION}]/d; p}" CHANGELOG.md | tail -n +2)

# Create release
gh release create "$VERSION" --title "$VERSION" --notes "$NOTES"
echo "Created GitHub release ${VERSION}"

# Upload demos
if [[ "$SKIP_DEMOS" == "false" && -d out ]]; then
    WEBM_COUNT=$(find out -name '*.webm' | wc -l)
    if [[ "$WEBM_COUNT" -gt 0 ]]; then
        gh release upload "$VERSION" out/*.webm --clobber
        echo "Uploaded ${WEBM_COUNT} demo videos"
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✓ Released ${VERSION}"
echo "  https://github.com/nvim-orgmode/telescope-orgmode.nvim/releases/tag/${VERSION}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
