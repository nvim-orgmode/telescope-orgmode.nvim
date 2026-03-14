# telescope-orgmode.nvim

[![tests](https://github.com/nvim-orgmode/telescope-orgmode.nvim/actions/workflows/tests.yml/badge.svg)](https://github.com/nvim-orgmode/telescope-orgmode.nvim/actions/workflows/tests.yml)

Fuzzy search, refile, and link insertion for [orgmode](https://github.com/nvim-orgmode/orgmode) with [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) or [snacks.nvim](https://github.com/folke/snacks.nvim) picker.

## Features

### Search Headlines

Jump to any heading in your `org_agenda_files`. You can filter by typing — the search matches against filename, tags, TODO state, and title.

https://github.com/user-attachments/assets/ea07829d-d80f-422d-b69b-2a42451dd5b8

### Search Org Files

Press `<C-Space>` to switch to file-level search. Files with a `#+TITLE:` show the title instead of the filename.

### Refile

Move a headline under a different parent. Position your cursor on a headline, open the refile picker, and pick the destination.

https://github.com/user-attachments/assets/497f3767-b679-49c6-8ed6-9928c75016ac

### Tag Search

Pick a tag, then browse the headlines that have it. `<C-t>` takes you back to the tag list.

https://github.com/user-attachments/assets/289dd36a-e6b9-401a-b1cd-f5624405fc8d

### Insert Link

Search for a headline or file and insert an org link at the cursor.

https://github.com/user-attachments/assets/938a13ee-4867-468a-b260-09406844994a

## Installation

### Snacks.picker

```lua
{
  "nvim-orgmode/telescope-orgmode.nvim",
  event = "VeryLazy",
  dependencies = {
    "nvim-orgmode/orgmode",
    "folke/snacks.nvim",
  },
  config = function()
    local tom = require("telescope-orgmode")
    tom.setup({ adapter = "snacks" })

    vim.keymap.set("n", "<leader>fh", tom.search_headings, { desc = "Org headlines" })
    vim.keymap.set("n", "<leader>ft", tom.search_tags, { desc = "Org tags" })
    vim.keymap.set("n", "<leader>r", tom.refile_heading, { desc = "Org refile" })
    vim.keymap.set("n", "<leader>li", tom.insert_link, { desc = "Org insert link" })
  end,
}
```

### Telescope

```lua
{
  "nvim-orgmode/telescope-orgmode.nvim",
  event = "VeryLazy",
  dependencies = {
    "nvim-orgmode/orgmode",
    "nvim-telescope/telescope.nvim",
  },
  config = function()
    require("telescope").load_extension("orgmode")

    local ext = require("telescope").extensions.orgmode
    vim.keymap.set("n", "<leader>fh", ext.search_headings, { desc = "Org headlines" })
    vim.keymap.set("n", "<leader>ft", ext.search_tags, { desc = "Org tags" })
    vim.keymap.set("n", "<leader>r", ext.refile_heading, { desc = "Org refile" })
    vim.keymap.set("n", "<leader>li", ext.insert_link, { desc = "Org insert link" })
  end,
}
```

### Without plugin manager

```lua
-- Telescope
require("telescope").load_extension("orgmode")

-- Snacks
require("telescope-orgmode").setup({ adapter = "snacks" })
```

## Keybindings

| Key | Action | Context |
|-----|--------|---------|
| `<C-Space>` | Toggle between headline and org file search | All pickers |
| `<C-f>` | Toggle current file filter | Headlines |
| `<C-t>` | Open tag picker / return to tag list | Headlines / Tags |
| `<C-s>` | Toggle tag sort (frequency ↔ alphabetical) | Tags |
| `<CR>` | Confirm selection | All |

## Configuration

Pass options to `setup()` (Snacks) or `telescope.setup({ extensions = { orgmode = { ... } } })` (Telescope). You can also pass them per call.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `adapter` | string | `'telescope'` | `'telescope'` or `'snacks'` |
| `max_depth` | number\|nil | nil | Max headline level (nil = all, 0 = files only) |
| `show_location` | boolean | true | Show filename/category column |
| `show_tags` | boolean | true | Show tags column |
| `show_todo_state` | boolean | true | Show TODO state column |
| `show_priority` | boolean | true | Show priority column |
| `location_max_width` | number | 15 | Max width for location column |
| `tags_max_width` | number | 15 | Max width for tags column |

### Per-call examples

```lua
-- Org files only
tom.search_headings({ mode = "orgfiles" })

-- Current file only
tom.search_headings({ only_current_file = true })

-- Limit depth
tom.refile_heading({ max_depth = 3 })

-- Sort tags alphabetically
tom.search_tags({ initial_sort = "alphabetical" })
```

## Architecture

```
lua/telescope-orgmode/
├── adapters/        # Telescope & Snacks implementations
├── lib/             # Shared logic (actions, config, state, filters)
├── entry_maker/     # Headline/file → picker entry conversion
├── org.lua          # Orgmode API wrapper
└── init.lua         # Public API, adapter routing
```

## Contributing

```bash
make test       # Run tests
make format     # Format with StyLua
make lint       # Check formatting
make demo-env   # Interactive demo environment
make demo       # Record demo videos (requires VHS)
```
