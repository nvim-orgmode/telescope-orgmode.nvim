-- Demo environment for recording screenshots and GIFs
-- Usage: nvim --clean -u scripts/demo/init.lua scripts/test-fixture/notes/work.org
--
-- This extends the test fixture with a nice colorscheme for demos.
-- All plugins install into scripts/test-fixture/.repro/ (shared with test fixture).

-- Resolve paths
local demo_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':h')
local fixture_dir = vim.fn.fnamemodify(demo_dir, ':h') .. '/test-fixture'
local plugin_dev_dir = vim.fn.fnamemodify(demo_dir, ':h:h')

-- Leader keys (must be set before lazy.nvim loads plugins)
vim.g.mapleader = ' '
vim.g.maplocalleader = ','

-- Isolate all plugin data
vim.env.LAZY_STDPATH = fixture_dir .. '/.repro'

-- Bootstrap lazy.nvim
load(vim.fn.system('curl -s https://raw.githubusercontent.com/folke/lazy.nvim/main/bootstrap.lua'))()

require('lazy.minit').repro({
  spec = {
    -- Colorscheme
    {
      'folke/tokyonight.nvim',
      lazy = false,
      priority = 1000,
      config = function()
        require('tokyonight').setup({
          style = 'night',
          transparent = false,
        })
        vim.cmd.colorscheme('tokyonight-night')
      end,
    },
    -- Treesitter for org syntax highlighting
    {
      'nvim-treesitter/nvim-treesitter',
      build = ':TSUpdate',
      config = function()
        vim.treesitter.language.add('org')
      end,
    },
    -- Orgmode
    {
      'nvim-orgmode/orgmode',
      config = function()
        require('orgmode').setup({
          org_agenda_files = { fixture_dir .. '/notes/*.org' },
          org_default_notes_file = fixture_dir .. '/notes/work.org',
          org_id_link_to_org_use_id = true,
          org_startup_folded = 'showeverything',
          org_startup_indented = true,
          org_todo_keywords = { 'TODO', 'NEXT', 'IN-PROGRESS', 'WAITING', '|', 'DONE' },
          org_todo_keyword_faces = {
            ['TODO'] = ':foreground #f7768e :weight bold',
            ['NEXT'] = ':foreground #ff9e64 :weight bold',
            ['IN-PROGRESS'] = ':foreground #e0af68 :weight bold',
            ['WAITING'] = ':foreground #bb9af7 :weight bold',
            ['DONE'] = ':foreground #9ece6a :weight bold',
          },
        })
      end,
    },
    -- Picker dependencies
    'nvim-telescope/telescope.nvim',
    'nvim-lua/plenary.nvim',
    {
      'folke/snacks.nvim',
      opts = {
        picker = {
          layout = {
            preset = 'vertical',
            layout = {
              box = 'vertical',
              width = 0.95,
              height = 0.95,
              border = true,
              title = '{title} {live} {flags}',
              title_pos = 'center',
              { win = 'input', height = 1, border = 'bottom' },
              { win = 'list', border = 'none', height = 0.5 },
              { win = 'preview', title = '{preview}', height = 0.5, border = 'top' },
            },
          },
        },
      },
    },
    -- telescope-orgmode (local dev copy)
    {
      dir = plugin_dev_dir,
      name = 'telescope-orgmode.nvim',
      config = function()
        local tom = require('telescope-orgmode')
        tom.setup({
          adapter = 'snacks',
          location_max_width = 100,
          tags_max_width = 100,
        })

        -- Simple keybindings for demo
        vim.keymap.set('n', '<leader>fh', function()
          tom.search_headings()
        end, { desc = 'Search headlines' })

        vim.keymap.set('n', '<leader>ff', function()
          tom.search_headings({ mode = 'orgfiles' })
        end, { desc = 'Search orgfiles' })

        vim.keymap.set('n', '<leader>fc', function()
          tom.search_headings({ only_current_file = true })
        end, { desc = 'Headlines (current file)' })

        vim.keymap.set('n', '<leader>ft', function()
          tom.search_tags()
        end, { desc = 'Search tags' })

        vim.keymap.set('n', '<leader>r', function()
          tom.refile_heading({ max_depth = 3 })
        end, { desc = 'Refile heading' })

        vim.keymap.set('n', '<leader>li', function()
          tom.insert_link({ max_depth = 3 })
        end, { desc = 'Insert link' })
      end,
    },
  },
})

-- Editor settings
vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.signcolumn = 'yes'
vim.opt.cursorline = true
vim.opt.laststatus = 3
vim.opt.cmdheight = 1
vim.opt.showmode = false

-- Suppress all messages for clean demo recording
vim.opt.shortmess:append('aIFWs')
vim.opt.swapfile = false
vim.opt.cmdheight = 0
vim.notify = function() end
print = function() end

-- Clean statusline - just filename
vim.opt.statusline = ' %t'
