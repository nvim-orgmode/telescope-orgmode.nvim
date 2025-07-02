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
```

## Available functions

```lua
require('telescope').extensions.orgmode.search_headings
require('telescope').extensions.orgmode.refile_heading
require('telescope').extensions.orgmode.insert_link
```

## Toggle between headline and org file search

By pressing `<C-Space>` the picker state can be toggled between two modes.
Every mode is available in every function.

### Current file only mode

In headline mode, you can press `<C-f>` to toggle between showing all headlines
vs only headlines from the current file. This is useful when you want to focus
on the current file's structure.

### Search headlines

This is the first and default mode. It shows all the headlines, initially
sorted by most recently changed org file. The level of headlines can be
[configured](#configuration).

### Search org files

This is the second mode, which shows only org files. If the org file has a
title, it is shown (and used for filtering) instead of the filename. This is
particular useful in connection with
[org-roam.nvim](https://github.com/chipsenkbeil/org-roam.nvim) to fuzzy search
for roam nodes.

## Configuration

You can limit the maximum headline level included in the search. `nil` means
unlimited level, `0` means only search for whole org files. The later is
equivalent with [org file mode](#search-org-files)

To enable the configuration for all commands, you pass the option to the setup
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

For a particular command you can pass it directly in your key mapping to the function:

```lua
require('telescope').extension.orgmode.search_headings({ max_depth = 3 })
```

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
