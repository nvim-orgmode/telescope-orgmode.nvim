# Test Architecture

This document describes the test organization for telescope-orgmode.nvim, which follows a multi-layer architecture with configuration as a cross-cutting concern.

## Directory Structure

```
spec/
├── unit/
│   └── lib/                          # Pure business logic (mocked dependencies)
│       ├── actions_spec.lua          [Unit: lib/actions]
│       ├── config_spec.lua           [Unit: lib/config]
│       ├── highlights_spec.lua       [Unit: lib/highlights]
│       ├── operations_spec.lua       [Unit: lib/operations]
│       └── state_spec.lua            [Unit: lib/state]
│
├── integration/
│   ├── data/                         # Data layer integration (org.lua)
│   │   └── headline_loading_spec.lua [Data: Headline Loading]
│   │
│   ├── entry_makers/                 # Entry maker implementations
│   │   ├── headlines_spec.lua        [Entry Maker: Headlines]
│   │   └── ...                       (future: tags, todo, categories, links)
│   │
│   ├── configuration/                # Cross-cutting configuration concerns
│   │   └── precedence_spec.lua       [Config: Precedence & Validation]
│   │
│   └── adapters/                     # Adapter integration smoke tests
│       ├── telescope_spec.lua        [Integration: Telescope]
│       └── snacks_spec.lua           [Integration: Snacks]
│
├── e2e/
│   ├── lib/                          # E2E tests for lib/ modules
│   │   └── actions_spec.lua          [E2E: Action Execution]
│   │
│   └── adapters/                     # E2E tests for adapters
│       ├── telescope_spec.lua        [E2E: Telescope Adapter]
│       └── snacks_spec.lua           [E2E: Snacks Adapter]
│
├── helpers/
│   └── e2e_helpers.lua               # E2E test utilities
│
└── minimal_init.lua                  # Test setup and initialization
```

## Test Layers

### Unit Tests (`unit/lib/`)

**Purpose**: Test pure business logic functions in isolation with mocked dependencies.

**Characteristics**:
- No external dependencies (orgmode, file I/O)
- Fast execution
- High coverage of edge cases
- Mock all external interactions

**Example**:
```lua
describe('[Unit: lib/config]', function()
  describe('merge logic', function()
    it('merges user options with defaults')
  end)

  describe('validation rules', function()
    it('rejects invalid max_depth')
  end)
end)
```

### Data Integration Tests (`integration/data/`)

**Purpose**: Test org.lua integration with orgmode using real org file fixtures.

**Responsibilities**:
- Data loading from orgmode API (`org.load_headlines()`, `org.load_headlines_by_search()`)
- Data extraction (todo_value, todo_type, priority from headline objects)
- Filtering logic (archived, max_depth, only_current_file)
- File loading and sorting

**Characteristics**:
- Creates temporary org files
- Tests orgmode API integration
- Verifies data structure correctness
- Tests all configuration options that affect what data is returned

**Test sections**:
- `basic loading` - Multi-file headline loading
- `archive filtering` - Archive file inclusion/exclusion
- `todo and priority extraction` - TODO keyword and priority data extraction
- `search-based loading` - Tag search with org.load_headlines_by_search()
- `max_depth filtering` - Headline depth limiting
- `current file filtering` - Single file filtering

**Example**:
```lua
describe('[Data: Headline Loading]', function()
  describe('todo and priority extraction', function()
    it('extracts todo_value, todo_type, and priority from headlines')
  end)

  describe('max_depth filtering', function()
    it('filters headlines by max_depth option')
  end)
end)
```

### Entry Maker Integration Tests (`integration/entry_makers/`)

**Purpose**: Test entry maker implementations - transformation of data into telescope entries.

**Responsibilities**:
- Width calculation from data sets (`index_headlines()`)
- Entry structure creation (wrapping data in entry objects)
- Entry maker function creation (`make_entry()`)
- Ordinal field construction based on visible columns
- Display function creation with proper formatting
- Configuration impact on entry transformation

**Characteristics**:
- Calls `entry_maker.get_entries()` to get indexed data
- Tests `entry_maker.make_entry()` transformation
- Verifies telescope entry structure correctness
- Tests display features (columns, highlights, widths)

**Configuration aspects tested**:
- `show_*` options - Column visibility impact on ordinal and display
- `*_max_width` options - Column width limits

**Test sections**:
- `width calculation` - Max width calculation from result sets
- `highlight integration` - Highlight group selection
- `entry creation` - Entry structure and ordinal construction
- `column visibility` - Configuration impact on entries

**Current entry makers**:
- `headlines_spec.lua` - Headline search entries (TODO, priority, tags, location)
- Future: `tags_spec.lua`, `todo_spec.lua`, `categories_spec.lua`, `links_spec.lua`

**Example**:
```lua
describe('[Entry Maker: Headlines]', function()
  describe('width calculation', function()
    it('calculates max widths from result set')
  end)

  describe('entry creation', function()
    it('creates entries with TODO and priority fields')
    it('excludes TODO from ordinal when show_todo_state=false')
  end)
end)
```

### Configuration Integration Tests (`integration/configuration/`)

**Purpose**: Test cross-cutting configuration concerns that don't belong to specific features.

**Scope**:
- Configuration precedence (defaults → setup() → per-call opts)
- Validation enforcement
- Picker-specific defaults

**Note**: Most configuration testing happens in feature tests (data, entry_makers, adapters). This directory only contains tests that truly don't fit elsewhere.

**Example**:
```lua
describe('[Config: Precedence & Validation]', function()
  describe('configuration precedence', function()
    it('per-call opts override setup() globally')
  end)

  describe('validation enforcement', function()
    it('rejects invalid config at setup() time')
  end)
end)
```

### Adapter Integration Tests (`integration/adapters/`)

**Purpose**: Integration smoke tests for adapter module loading and basic initialization.

**Characteristics**:
- Minimal smoke tests for module loading
- Tests basic adapter initialization without crashes
- Tests complete workflow: org files → data → entry maker → adapter

**Example**:
```lua
describe('[Integration: Telescope]', function()
  describe('module loading', function()
    it('loads Telescope adapter without errors')
  end)

  describe('basic initialization', function()
    it('creates Telescope picker without crash')
  end)
end)
```

### E2E Tests (`e2e/`)

**Purpose**: Programmatic end-to-end tests validating real API usage and integration.

**Why E2E Tests?**:
- Catch adapter-specific bugs that unit tests miss (proven by Snacks preview performance issue)
- Validate hexagonal architecture with real picker APIs
- Test real orgmode API usage
- Ensure actions execute without crashes

**Approach: Programmatic (Not Feedkeys)**

Traditional feedkeys-based E2E tests don't work in headless mode (Neovim architectural limitation). Instead, we use programmatic API calls with real objects.

**Pattern**:
```lua
-- Open picker
telescope_orgmode.search_headings({ adapter = 'telescope' })

-- Test doesn't crash
local ok = pcall(some_operation)
assert.is_true(ok, 'Operation should not crash')

-- Clean up
pcall(function()
  local picker = get_current_picker()
  if picker then close_picker(picker) end
end)
```

**Test Categories**:
- **Action Execution** (`e2e/lib/`): Test lib/actions.lua with real state and entries
- **Adapter E2E** (`e2e/adapters/`): Test adapter integration with real picker APIs

**Coverage**:
- Unit tests: 60% (business logic, state, filters)
- Integration tests: +15% (data loading, entry makers)
- E2E tests: +12% (adapter integration, real API usage)
- Manual testing: +10% (visual, UX, keybinding feel)
- **Total**: ~97% coverage

**Example**:
```lua
describe('[E2E: Telescope Adapter]', function()
  it('should create search_headings picker without crashing', function()
    local ok = pcall(telescope_orgmode.search_headings, { adapter = 'telescope' })
    assert.is_true(ok, 'search_headings should not crash')

    -- Clean up
    pcall(function()
      local picker = e2e_helpers.get_current_picker_telescope()
      if picker then e2e_helpers.close_picker_telescope(picker) end
    end)
  end)
end)
```

**Spike Findings**: See `spike-final-2025-10-23` memory and `claudedocs/analysis/feedkeys-blocking-picker-limitation-2025-10-23.md` for empirical evidence supporting programmatic approach.

## Naming Convention

**Format**: `[Layer: Component - Specific Concern]` (optional specific concern)

**Examples**:
- `[Unit: lib/actions]` - Unit tests for actions module
- `[Unit: lib/config]` - Unit tests for config module
- `[Data: Headline Loading]` - Data layer integration tests
- `[Entry Maker: Headlines]` - Headlines entry maker tests
- `[Config: Precedence & Validation]` - Cross-cutting config tests
- `[E2E: Telescope]` - Telescope adapter E2E tests

**Subsection naming**: Use lowercase for subsections within test files
- `describe('basic loading', function()`
- `describe('archive filtering', function()`
- `describe('column visibility', function()`

## Layer Boundaries and Responsibilities

The test architecture follows clear separation of concerns:

### Data Layer → Entry Maker Layer → Adapter Layer

**Data Layer** (`integration/data/`):
- **Input**: orgmode API (files, headlines)
- **Output**: Raw data arrays `{ filename, title, level, todo_value, priority, ... }`
- **Tests**: org.load_headlines(), data extraction, filtering options
- **Focus**: What data is loaded and how it's structured

**Entry Maker Layer** (`integration/entry_makers/`):
- **Input**: Raw data from org.load_headlines()
- **Output**: Telescope entries with ordinal, display, metadata
- **Tests**: index_headlines(), make_entry(), width calculation, entry structure
- **Focus**: How data is transformed into searchable/displayable entries

**Adapter Layer** (`integration/adapters/`):
- **Input**: Entry maker functions
- **Output**: Picker UI in telescope/snacks
- **Tests**: Full stack smoke tests, adapter-specific features
- **Focus**: End-to-end workflows and framework integration

### Clear Test Placement

| What You're Testing | Where It Goes | Why |
|---------------------|---------------|-----|
| "Does org.load_headlines() extract todo_value?" | Data layer | Testing data extraction |
| "Does entry.ordinal include TODO when visible?" | Entry maker | Testing transformation |
| "Does the picker display correctly?" | Adapter | Testing full stack |

**Key Principle**: Tests belong to the layer that owns the responsibility. Data extraction belongs to org.lua (data layer), not entry_maker (transformation layer).

## Configuration as Cross-Cutting Concern

Configuration is tested **where features live**, not in a separate layer:

| Configuration Aspect | Where Tested | Example |
|---------------------|--------------|---------|
| Config utilities | `unit/lib/config_spec.lua` | merge(), validate() |
| Data filtering | `integration/data/headline_loading_spec.lua` | archived, max_depth |
| Column visibility | `integration/entry_makers/headlines_spec.lua` | show_*, *_max_width |
| Adapter options | `integration/adapters/telescope_spec.lua` | layout_strategy |
| Cross-cutting | `integration/configuration/precedence_spec.lua` | setup() precedence |

**Rationale**: Configuration is an aspect of features, not a separate domain. Column visibility is a feature (with multiple future triggers: config, screen width, user toggle). Configuration tests belong with the features they configure.

## Guidelines

### Unit Tests
- **Scope**: Pure functions only
- **Coverage**: Detailed edge cases and error handling
- **Dependencies**: All mocked
- **Speed**: Very fast (no I/O)

### Integration Tests
- **Data layer**: Focus on org.lua integration and data loading
- **Entry makers**: Focus on data extraction, formatting, and display features
- **Adapters**: Minimal happy path smoke tests only
- **Configuration**: Test config effects on the relevant feature

### Test Organization Principles

1. **Feature-based organization**: Tests live with the features they test
2. **Configuration co-location**: Config tests belong to the feature being configured
3. **Minimal E2E layer**: Adapter tests are smoke tests, not exhaustive
4. **Future-proof structure**: Easy to add new entry makers, adapters, and features

### Adding New Tests

**New entry maker** (e.g., tags):
```
lua/telescope-orgmode/entry_maker/tags.lua
spec/integration/entry_makers/tags_spec.lua
```

**New adapter** (e.g., fzf-lua):
```
lua/telescope-orgmode/adapters/fzf-lua.lua
spec/integration/adapters/fzf_lua_spec.lua
```

**New data filtering option** (e.g., tag_filter):
```
# Add test to existing file:
spec/integration/data/headline_loading_spec.lua
  describe('tag filtering', function()
    it('filters headlines by tags when tag_filter configured')
  end)
```

**New column feature** (e.g., category column):
```
# Add test to existing entry maker file:
spec/integration/entry_makers/headlines_spec.lua
  describe('column visibility', function()
    it('hides category column when show_category=false')
  end)
```

## Running Tests

```bash
# Run all tests
make test

# Run specific test file
make test-file FILE=headline_loading_spec.lua

# Run tests with custom formatter
make test  # Uses scripts/test-formatter.sh

# Run tests with plain plenary output
make test-plain
```

## Test Output Example

```
  [Unit: lib/config]
    ✓ merge logic merges user options with defaults
    ✓ validation rules rejects invalid max_depth

  [Data: Headline Loading]
    ✓ basic loading returns headlines from multiple files
    ✓ archive filtering respects archive filtering across files

  [Entry Maker: Headlines]
    ✓ data extraction extracts TODO value and type
    ✓ column visibility hides TODO column when show_todo_state=false

  [E2E: Telescope]
    (TODO: Add smoke tests)
```

## Future Expansion

### Planned Entry Makers
- `tags_spec.lua` - Tag-based search and filtering
- `todo_spec.lua` - TODO keyword search and filtering
- `categories_spec.lua` - Category-based organization
- `links_spec.lua` - Link search and navigation
- `properties_spec.lua` - Custom property search

### Configuration Evolution
As features grow, configuration will expand in multiple dimensions:
- **Display options**: New columns, formatting options, adaptive layout
- **Filter options**: Tag filters, TODO filters, date ranges, custom predicates
- **Adapter options**: Framework-specific customization
- **Feature triggers**: Configuration + screen width + user toggles + context

All configuration tests will continue to live with the features they configure, maintaining clear organization as the project scales.
