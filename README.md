# telescope-orgmode.nvim

Provides integration for [orgmode](https://github.com/nvim-orgmode/orgmode) and
[org-roam.nvim](https://github.com/chipsenkbeil/org-roam.nvim) with
[telescope.nvim](https://github.com/nvim-telescope/telescope.nvim).

## Demo

Jump to to any heading in `org_agenda_files` with `:Telescope orgmode search_headings`

[![asciicast](https://asciinema.org/a/Oko0GT32HS6JCpzuSznUG0D1D.svg)](https://asciinema.org/a/Oko0GT32HS6JCpzuSznUG0D1D)

Refile heading from capture or current file under destination with `:Telescope orgmode refile_heading`

[![asciicast](https://asciinema.org/a/1X4oG6s5jQZrJJI3DfEzJU3wN.svg)](https://asciinema.org/a/1X4oG6s5jQZrJJI3DfEzJU3wN)

## Installation

### With lazyvim

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

      vim.keymap.set("n", "<leader>r", require("telescope").extensions.orgmode.refile_heading)
      vim.keymap.set("n", "<leader>fh", require("telescope").extensions.orgmode.search_headings)
      vim.keymap.set("n", "<leader>li", require("telescope").extensions.orgmode.insert_link)
      vim.keymap.set("n", "<leader>ot", require("telescope").extensions.orgmode.search_tags)
    end,
  }
```

### Without lazyvim

You can setup the extension by doing:

```lua
require('telescope').load_extension('orgmode')
```

To replace the default refile prompt:

```lua
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'org',
  group = vim.api.nvim_create_augroup('orgmode_telescope_nvim', { clear = true }),
  callback = function()
    vim.keymap.set('n', '<leader>or', require('telescope').extensions.orgmode.refile_heading)
  end,
})
```

## Available commands

```viml
:Telescope orgmode search_headings
:Telescope orgmode refile_heading
:Telescope orgmode insert_link
:Telescope orgmode search_tags
```

## Available functions

```lua
require('telescope').extensions.orgmode.search_headings
require('telescope').extensions.orgmode.refile_heading
require('telescope').extensions.orgmode.insert_link
require('telescope').extensions.orgmode.search_tags
```

## Features

### Search headlines

Search and navigate to any headline across your org files with fuzzy matching.
Headlines are sorted by most recently modified file by default. TODO states and
priorities are displayed as columns and can be filtered in the search.

**Keybindings:**

- `<C-Space>`: Toggle between headline and org file search modes
- `<C-f>`: Toggle between all headlines and current file only
- `<C-t>`: Open tag picker for tag-based filtering

The maximum headline level and column visibility can be [configured](#configuration).

### Search org files

Search through org files rather than individual headlines. When org files have
a `#+TITLE:` property, it is used for display and filtering instead of the
filename. This is particularly useful with
[org-roam.nvim](https://github.com/chipsenkbeil/org-roam.nvim) for fuzzy
searching roam nodes.

**Keybindings:**

- `<C-Space>`: Toggle back to headline search mode

### Search by tags

Tag-based navigation workflow for quickly filtering headlines by org tags.
Shows all tags with occurrence counts (e.g., `:work: (42)`) sorted by
frequency. The preview pane displays up to 50 headlines containing the
selected tag. Selecting a tag opens the headline search pre-filtered by
that tag, allowing further refinement.

**Keybindings:**

- `<C-s>`: Toggle sort mode (frequency ↔ alphabetical)
- `<C-t>`: Return to headline search (preserves tag filter)
- `<CR>`: Select tag and open filtered headline search

The initial sort mode can be [configured](#tag-search-options).

## Configuration

### Maximum headline level

You can limit the maximum headline level included in the search. `nil` means
unlimited level, `0` means only search for whole org files. The latter is
equivalent with [org file search mode](#search-org-files).

To enable the configuration for all commands, pass the option to the setup
function of telescope:

```lua
require('telescope').setup({
    extensions = {
        orgmode = {
            max_depth = 3
        }
    }
})
```

For a particular command you can pass it directly in your key mapping:

```lua
require('telescope').extensions.orgmode.search_headings({ max_depth = 3 })
```

### Column visibility

All columns are shown by default. To selectively disable columns:

```lua
require('telescope').setup({
    extensions = {
        orgmode = {
            show_location = false,
            show_tags = false,
            show_todo_state = false,
            show_priority = false,
        }
    }
})
```

### Column widths

Maximum widths for location and tags columns:

```lua
require('telescope').setup({
    extensions = {
        orgmode = {
            location_max_width = 15,
            tags_max_width = 15,
        }
    }
})
```

### Tag search options

The tag search can be configured with an initial sort mode:

```lua
-- Sort tags alphabetically by default
vim.keymap.set("n", "<leader>ot", function()
  require("telescope").extensions.orgmode.search_tags({ initial_sort = "alphabetical" })
end)

-- Sort tags by frequency by default (default behavior)
vim.keymap.set("n", "<leader>ot", function()
  require("telescope").extensions.orgmode.search_tags({ initial_sort = "frequency" })
end)
```

Tags are case-sensitive (`:work:` ≠ `:Work:`).

### Custom keymaps

You can customize the telescope picker keymaps by passing a `mappings` table:

```lua
require('telescope').extensions.orgmode.search_headings({
  mappings = {
    i = {
      ['<C-l>'] = require('telescope-orgmode.actions').toggle_current_file_only,
      ['<C-s>'] = require('telescope-orgmode.actions').toggle_headlines_orgfiles,
    },
    n = {
      ['<C-l>'] = require('telescope-orgmode.actions').toggle_current_file_only,
      ['<C-s>'] = require('telescope-orgmode.actions').toggle_headlines_orgfiles,
    }
  }
})
```

You can also create key mappings for specific modes:

```lua
-- Search only org files
vim.keymap.set(
  "n",
  "<Leader>off",
  function()
    require('telescope').extensions.orgmode.search_headings({ mode = "orgfiles" })
  end,
  { desc = "Find org files"}
)

-- Search headlines in current file only
vim.keymap.set(
  "n",
  "<Leader>ofc",
  function()
    require('telescope').extensions.orgmode.search_headings({ only_current_file = true })
  end,
  { desc = "Find headlines in current file"}
)
```
