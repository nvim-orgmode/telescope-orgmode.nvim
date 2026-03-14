#!/usr/bin/env bash

# Simple manual testing script for telescope-orgmode
# Usage: ./scripts/manual_test.sh [telescope|snacks]

set -e

ADAPTER="${1:-telescope}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Validate adapter
if [[ "$ADAPTER" != "telescope" && "$ADAPTER" != "snacks" ]]; then
    echo "Error: Adapter must be 'telescope' or 'snacks'"
    echo "Usage: $0 [telescope|snacks]"
    exit 1
fi

# Paths
TEMPLATE="$SCRIPT_DIR/manual_test_template.org"
TEST_FILE="$SCRIPT_DIR/manual_test_${ADAPTER}.org"
INIT_LUA="$SCRIPT_DIR/manual_test_init.lua"

# Check dependencies
if ! command -v nvim &> /dev/null; then
    echo "Error: nvim not found in PATH"
    exit 1
fi

if [[ ! -f "$TEMPLATE" ]]; then
    echo "Error: Template not found: $TEMPLATE"
    exit 1
fi

# Generate fresh test file from template
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Manual Test - $ADAPTER Adapter"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Generating test file: $TEST_FILE"

cp "$TEMPLATE" "$TEST_FILE"

echo ""
echo "Instructions:"
echo "  1. Neovim will open with the test file"
echo "  2. Follow the instructions in each headline"
echo "  3. Check boxes as you complete tests (C-c C-c)"
echo "  4. Save and exit when done (:wq)"
echo "  5. Results will be validated automatically"
echo ""
echo "Press Enter to start testing..."
read -r

# Launch Neovim with test file
cd "$PROJECT_DIR"
if [[ -f "$INIT_LUA" ]]; then
    nvim -u "$INIT_LUA" "$TEST_FILE"
else
    # Use normal config if minimal init doesn't exist
    nvim "$TEST_FILE"
fi

# Analyze results
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Analyzing test results..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Count results
TOTAL_MANUAL=6  # Tests 1, 2, 3, 5, 6, and refile verification
CHECKED=$(grep -c "^\*\* PASS" "$TEST_FILE" || echo 0)
FAILED=$(grep -c "^\*\* FAIL" "$TEST_FILE" || echo 0)
SKIPPED=$((TOTAL_MANUAL - CHECKED - FAILED))

# Check if Test 4 was refiled correctly
REFILE_SUCCESS=0
if grep -q "^\*\* .* Test 4: Refile This Headline" "$TEST_FILE"; then
    # Test 4 is still in original location - refile failed
    REFILE_SUCCESS=0
else
    # Check if it's under Refile Destination
    if sed -n '/^\* Refile Destination/,/^\* /p' "$TEST_FILE" | grep -q "Test 4: Refile This Headline"; then
        REFILE_SUCCESS=1
    fi
fi

# Calculate totals
TOTAL_TESTS=$((TOTAL_MANUAL + 1))  # Manual tests + refile test
PASSED=$((CHECKED + REFILE_SUCCESS))
PASS_RATE=$((PASSED * 100 / TOTAL_TESTS))

# Display results
echo ""
echo "Results:"
echo "  Total:      $TOTAL_TESTS tests"
echo "  Passed:     $PASSED / $TOTAL_TESTS"
echo "  Failed:     $FAILED / $TOTAL_TESTS"
echo "  Not tested: $SKIPPED / $TOTAL_TESTS"
echo "  Pass rate:  $PASS_RATE%"
echo ""

if [[ $REFILE_SUCCESS -eq 1 ]]; then
    echo "  ✅ Refile test PASSED (Test 4 moved correctly)"
else
    echo "  ❌ Refile test FAILED (Test 4 not moved or moved incorrectly)"
fi

echo ""

# Determine overall status
if [[ $PASS_RATE -ge 85 ]]; then
    echo "✅ PASS - Core functionality working ($PASS_RATE%)"
    EXIT_CODE=0
elif [[ $SKIPPED -gt 3 ]]; then
    echo "⚠️ INCOMPLETE - Too many tests skipped ($SKIPPED/$TOTAL_TESTS)"
    EXIT_CODE=1
else
    echo "❌ FAIL - Issues found ($FAILED failed, $SKIPPED skipped)"
    EXIT_CODE=1
fi

echo ""
echo "Test file: $TEST_FILE"
echo ""

exit $EXIT_CODE
