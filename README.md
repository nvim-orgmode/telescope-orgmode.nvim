# telescope-orgmode.nvim

[![tests](https://github.com/nvim-orgmode/telescope-orgmode.nvim/actions/workflows/tests.yml/badge.svg)](https://github.com/nvim-orgmode/telescope-orgmode.nvim/actions/workflows/tests.yml)

Fuzzy search, refile, and link insertion for [orgmode](https://github.com/nvim-orgmode/orgmode) with [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) or [snacks.nvim](https://github.com/folke/snacks.nvim).

> Full reference: [`DOCS.org`](DOCS.org) (source) — or `:help telescope-orgmode` once installed.

## Features

### Search Headlines

Jump to any heading in your `org_agenda_files`. Filter by typing — the search matches against filename, tags, TODO state, and title.

https://github.com/user-attachments/assets/ea07829d-d80f-422d-b69b-2a42451dd5b8

### Search Org Files

Press `<C-Space>` to switch to file-level search. Files with a `#+TITLE:` show the title instead of the filename.

### Refile

Move a headline under a different parent. Place the cursor on a headline, open the refile picker, pick the destination.

https://github.com/user-attachments/assets/497f3767-b679-49c6-8ed6-9928c75016ac

### Tag Search

Pick a tag, then browse the headlines that carry it. `<C-t>` returns to the tag list.

https://github.com/user-attachments/assets/289dd36a-e6b9-401a-b1cd-f5624405fc8d

### Insert Link

Search a headline or file and insert an org link at the cursor.

https://github.com/user-attachments/assets/938a13ee-4867-468a-b260-09406844994a

## Quick start

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
    vim.keymap.set("n", "<leader>ft", tom.search_tags,     { desc = "Org tags" })
    vim.keymap.set("n", "<leader>r",  tom.refile_heading,  { desc = "Org refile" })
    vim.keymap.set("n", "<leader>li", tom.insert_link,     { desc = "Org insert link" })
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
    vim.keymap.set("n", "<leader>ft", ext.search_tags,     { desc = "Org tags" })
    vim.keymap.set("n", "<leader>r",  ext.refile_heading,  { desc = "Org refile" })
    vim.keymap.set("n", "<leader>li", ext.insert_link,     { desc = "Org insert link" })
  end,
}
```

See [`DOCS.org`](DOCS.org) for `Without plugin manager` and other setups.

## Documentation

The full reference manual lives in [`DOCS.org`](DOCS.org) and ships as a
Vim help file. After install: `:help telescope-orgmode`.

- [Pickers](DOCS.org) — `search_headings`, `search_tags`, `refile_heading`, `insert_link`
- [Keybindings](DOCS.org) — `<C-Space>`, `<C-f>`, `<C-t>`, `<C-s>`
- [Configuration](DOCS.org) — display options, custom property columns, search priority, picker defaults
- [Adapter options](DOCS.org) — Telescope passthrough and Snacks `snacks` sub-namespace
- [Profiles](DOCS.org) — custom data sources, factory resolvers, resolver interface
- [Architecture](DOCS.org) — adapter / lib / entry_maker layering

## Contributing

```bash
make test       # Run tests
make format     # Format with StyLua
make lint       # Check formatting
make docs       # Regenerate doc/telescope-orgmode.txt from DOCS.org
make demo-env   # Interactive demo environment
```

`doc/telescope-orgmode.txt` is generated from `DOCS.org` via
[panvimdoc](https://github.com/kdheepak/panvimdoc) — do not edit it
directly. CI rebuilds and commits it on push to `main`.
