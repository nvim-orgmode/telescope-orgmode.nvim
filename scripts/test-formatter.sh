#!/usr/bin/env bash
# Format plenary test output for better readability
#
# Transforms flat plenary output into hierarchical sections with grouped tests
# and provides detailed failure summaries at the end.
#
# Expected test naming convention: describe('[Section Name]', function() ...)

set -uo pipefail  # Don't use -e: our processor functions use return codes for flow control

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly BOLD='\033[1m'
readonly RESET='\033[0m'

# Counters for test results
total_success=0
total_failed=0

# State tracking across line processing
current_file=""       # Currently processing test file
last_section=""       # Last printed section heading (avoid duplicates)
error_buffer=""       # Accumulates error detail lines for current failure
unsectioned_printed="" # Track if unsectioned header was printed for current file

# Parallel arrays (indexed by failure number) storing failure details
declare -a failed_tests     # Array of test description strings
declare -a failed_files     # Array of filename strings
declare -a failed_sections  # Array of section name strings (or empty for non-sectioned tests)
declare -a failed_errors    # Array of multi-line error detail strings

# Global communication variables (bash limitation: can't return multiple values)
# Used by parse_test_name() to return both section and test_description
section=""           # Set by parse_test_name(): extracted section name or empty
test_description=""  # Set by parse_test_name(): test description without section marker

strip_ansi() {
  local line="$1"
  # Plenary adds its own colors which interfere with our regex matching
  # shellcheck disable=SC2001  # Can't use parameter expansion for ANSI escape sequences
  echo "$line" | sed 's/\x1b\[[0-9;]*m//g'
}

# Extracts section from test names like "[Section] test description"
# Sets global 'section' and 'test_description' (bash limitation: can't return multiple values)
parse_test_name() {
  local full_name="$1"

  if [[ "$full_name" =~ ^\[([^\]]+)\][[:space:]]+(.+)$ ]]; then
    section="${BASH_REMATCH[1]}"
    test_description="${BASH_REMATCH[2]}"
    return 0
  else
    section=""
    test_description="$full_name"
    return 1
  fi
}

print_section_heading() {
  local section="$1"

  # Avoid printing duplicate section headings for consecutive tests
  if [[ "$section" != "$last_section" ]]; then
    echo -e "\n  ${BOLD}${section}${RESET}"
    last_section="$section"
    unsectioned_printed=""  # Reset when entering a new section
  fi
}

print_unsectioned_heading() {
  # Only print once per file
  if [[ -z "$unsectioned_printed" ]]; then
    echo -e "\n  ${BOLD}${YELLOW}[Unsectioned Tests]${RESET}"
    unsectioned_printed="true"
    last_section=""  # Clear last_section to avoid conflicts
  fi
}

process_file_header() {
  local clean_line="$1"

  if [[ "$clean_line" =~ ^Testing:[[:space:]]*(.+\.lua)$ ]]; then
    current_file="${BASH_REMATCH[1]}"
    echo -e "\n${BLUE}${BOLD}▶ Testing:${RESET} ${current_file}"
    last_section=""        # Reset section tracking for new file
    unsectioned_printed="" # Reset unsectioned heading for new file
    return 0
  fi
  return 1
}

process_success() {
  local clean_line="$1"

  if [[ "$clean_line" =~ ^Success.*\|\|[[:space:]]*(.+)$ ]]; then
    local full_name="${BASH_REMATCH[1]}"

    # Section tests get 4-space indent, non-sectioned tests get 2-space indent
    # parse_test_name() sets globals: section, test_description
    if parse_test_name "$full_name"; then
      print_section_heading "$section"
      echo -e "    ${GREEN}✓${RESET} ${test_description}"
    else
      # Print unsectioned header before first unsectioned test
      print_unsectioned_heading
      echo -e "    ${GREEN}✓${RESET} ${test_description}"
    fi

    ((total_success++))
    return 0
  fi
  return 1
}

process_failure() {
  local clean_line="$1"

  if [[ "$clean_line" =~ ^Fail.*\|\|[[:space:]]*(.+)$ ]]; then
    local full_name="${BASH_REMATCH[1]}"

    # Section tests get 4-space indent, non-sectioned tests get 2-space indent
    # parse_test_name() sets globals: section, test_description
    if parse_test_name "$full_name"; then
      print_section_heading "$section"
      echo -e "    ${RED}✗${RESET} ${test_description}"

      # Store failure details in parallel global arrays
      failed_tests+=("$test_description")
      failed_files+=("$current_file")
      failed_sections+=("$section")
    else
      # Print unsectioned header before first unsectioned test
      print_unsectioned_heading
      echo -e "    ${RED}✗${RESET} ${test_description}"

      # Store failure details in parallel global arrays (empty section for non-sectioned tests)
      failed_tests+=("$test_description")
      failed_files+=("$current_file")
      failed_sections+=("")
    fi

    ((total_failed++))
    error_buffer=""  # Reset buffer for new failure's error details
    return 0
  fi
  return 1
}

process_error_details() {
  local clean_line="$1"

  # Plenary indents error details with 12+ spaces
  if [[ "$clean_line" =~ ^[[:space:]]{12,} ]]; then
    echo -e "    ${YELLOW}${clean_line}${RESET}"

    # Accumulate error lines in global error_buffer for later storage
    if [[ -n "$error_buffer" ]]; then
      error_buffer="${error_buffer}"$'\n'"${clean_line}"
    else
      error_buffer="${clean_line}"
    fi
    return 0
  fi
  return 1
}

store_error_buffer() {
  # Save accumulated error details when we transition from error lines to other content
  if [[ -n "$error_buffer" && $total_failed -gt 0 ]]; then
    # Store accumulated buffer in global failed_errors array at index of last failure
    failed_errors[total_failed - 1]="$error_buffer"
    error_buffer=""
  fi
}

should_skip_line() {
  local clean_line="$1"

  # Skip plenary's own summary counts (we track our own)
  [[ "$clean_line" =~ ^(Success|Failed|Errors):.*[0-9] ]] && return 0

  # Skip noise: separators, startup messages, scheduling info
  [[ "$clean_line" =~ ^=+$ ]] && return 0
  [[ "$clean_line" == "Starting..." ]] && return 0
  [[ "$clean_line" =~ ^Scheduling: ]] && return 0

  return 1
}

print_success_summary() {
  echo -e "\n${BOLD}═══════════════════════════════════════${RESET}"
  echo -e "${GREEN}${BOLD}✓ All tests passed!${RESET} (${total_success} tests)"
  echo -e "\n${BOLD}═══════════════════════════════════════${RESET}\n"
}

print_failure_summary() {
  echo -e "\n${BOLD}═══════════════════════════════════════${RESET}"
  echo -e "${RED}${BOLD}✗ Tests failed!${RESET}"
  echo -e "  ${GREEN}✓${RESET} Passed: ${total_success}"
  echo -e "  ${RED}✗${RESET} Failed: ${total_failed}"

  echo -e "\n${BOLD}Failed Tests:${RESET}"
  for i in "${!failed_tests[@]}"; do
    echo -e "\n${RED}${BOLD}[$((i + 1))]${RESET} ${failed_tests[$i]}"

    if [[ -n "${failed_sections[$i]}" ]]; then
      echo -e "    ${BLUE}Section:${RESET} ${failed_sections[$i]}"
    fi

    echo -e "    ${BLUE}File:${RESET} ${failed_files[$i]}"

    if [[ -n "${failed_errors[$i]}" ]]; then
      echo -e "    ${YELLOW}Error:${RESET}"
      echo -e "${failed_errors[$i]}" | sed 's/^/      /'
    fi
  done

  echo -e "\n${BOLD}═══════════════════════════════════════${RESET}\n"
}

process_line() {
  local line="$1"
  local clean_line
  clean_line=$(strip_ansi "$line")

  # Chain of responsibility: each processor returns 0 if it handled the line
  process_file_header "$clean_line" && return
  process_success "$clean_line" && return
  process_failure "$clean_line" && return
  process_error_details "$clean_line" && return

  # Not an error line anymore, save accumulated buffer
  store_error_buffer

  should_skip_line "$clean_line"
}

main() {
  while IFS= read -r line; do
    process_line "$line"
  done

  if [ $total_failed -eq 0 ]; then
    print_success_summary
    exit 0
  else
    print_failure_summary
    exit 1
  fi
}

# Allow sourcing for testing without auto-execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main
fi
