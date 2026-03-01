-- Isolated test fixture for telescope-orgmode.nvim
-- Usage: nvim --clean -u scripts/test-fixture/init.lua scripts/test-fixture/notes/work.org
--    or: make e2e
--
-- This bootstraps a fully isolated Neovim environment via lazy.nvim.
-- All plugins install into scripts/test-fixture/.repro/ (gitignored).
-- Zero interference with your personal Neovim config.

-- Resolve paths relative to this init.lua file
local init_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':h')
local plugin_dev_dir = vim.fn.fnamemodify(init_dir, ':h:h')
local fixture_dir = init_dir

-- Isolate all plugin data into .repro/ next to this file
vim.env.LAZY_STDPATH = init_dir .. '/.repro'

-- Bootstrap lazy.nvim (downloads on first run, cached after)
load(vim.fn.system('curl -s https://raw.githubusercontent.com/folke/lazy.nvim/main/bootstrap.lua'))()

require('lazy.minit').repro({
  spec = {
    {
      'nvim-treesitter/nvim-treesitter',
      build = ':TSUpdate',
      config = function()
        require('nvim-treesitter.configs').setup({
          ensure_installed = { 'org' },
          sync_install = true,
          highlight = { enable = true },
        })
      end,
    },
    {
      'nvim-orgmode/orgmode',
      config = function()
        require('orgmode').setup({
          org_agenda_files = { fixture_dir .. '/notes/*.org' },
          org_default_notes_file = fixture_dir .. '/notes/work.org',
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
    'nvim-telescope/telescope.nvim',
    'nvim-lua/plenary.nvim',
    'folke/snacks.nvim',
    {
      dir = plugin_dev_dir,
      name = 'telescope-orgmode.nvim',
      config = function()
        local tom = require('telescope-orgmode')

        -- Telescope adapter keybindings (\t prefix)
        vim.keymap.set('n', '<localleader>th', function()
          tom.search_headings({ adapter = 'telescope' })
        end, { desc = 'Telescope: headlines' })

        vim.keymap.set('n', '<localleader>tr', function()
          tom.refile_heading({ adapter = 'telescope' })
        end, { desc = 'Telescope: refile' })

        vim.keymap.set('n', '<localleader>ti', function()
          tom.insert_link({ adapter = 'telescope' })
        end, { desc = 'Telescope: insert link' })

        vim.keymap.set('n', '<localleader>tt', function()
          tom.search_tags({ adapter = 'telescope' })
        end, { desc = 'Telescope: tags' })

        vim.keymap.set('n', '<localleader>tf', function()
          tom.search_headings({ adapter = 'telescope', mode = 'orgfiles' })
        end, { desc = 'Telescope: orgfiles' })

        vim.keymap.set('n', '<localleader>tc', function()
          tom.search_headings({ adapter = 'telescope', only_current_file = true })
        end, { desc = 'Telescope: current file' })

        -- Snacks adapter keybindings (\s prefix)
        vim.keymap.set('n', '<localleader>sh', function()
          tom.search_headings({ adapter = 'snacks' })
        end, { desc = 'Snacks: headlines' })

        vim.keymap.set('n', '<localleader>sr', function()
          tom.refile_heading({ adapter = 'snacks' })
        end, { desc = 'Snacks: refile' })

        vim.keymap.set('n', '<localleader>si', function()
          tom.insert_link({ adapter = 'snacks' })
        end, { desc = 'Snacks: insert link' })

        vim.keymap.set('n', '<localleader>st', function()
          tom.search_tags({ adapter = 'snacks' })
        end, { desc = 'Snacks: tags' })

        vim.keymap.set('n', '<localleader>sf', function()
          tom.search_headings({ adapter = 'snacks', mode = 'orgfiles' })
        end, { desc = 'Snacks: orgfiles' })

        vim.keymap.set('n', '<localleader>sc', function()
          tom.search_headings({ adapter = 'snacks', only_current_file = true })
        end, { desc = 'Snacks: current file' })
      end,
    },
  },
})

-- Basic editor settings
vim.g.maplocalleader = ','
vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.signcolumn = 'yes'

-- Help window (persistent split)
local help_lines = {
  'telescope-orgmode.nvim - Test Fixture',
  '======================================',
  '',
  'Telescope (,t):          Snacks (,s):',
  '  ,th  Headlines            ,sh  Headlines',
  '  ,tf  Orgfiles             ,sf  Orgfiles',
  '  ,tc  Current file         ,sc  Current file',
  '  ,tr  Refile               ,sr  Refile',
  '  ,ti  Insert link          ,si  Insert link',
  '  ,tt  Tags                 ,st  Tags',
  '',
  'In picker:',
  '  <C-Space>   Toggle headlines/files',
  '  <C-f>       Toggle current file filter',
  '',
  'Press ? to toggle this help window',
}

local help_buf = nil
local help_win = nil

local function toggle_help()
  if help_win and vim.api.nvim_win_is_valid(help_win) then
    vim.api.nvim_win_close(help_win, true)
    help_win = nil
    return
  end

  if not help_buf or not vim.api.nvim_buf_is_valid(help_buf) then
    help_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(help_buf, 0, -1, false, help_lines)
    vim.bo[help_buf].modifiable = false
    vim.bo[help_buf].buftype = 'nofile'
    vim.bo[help_buf].filetype = 'help'
  end

  vim.cmd('topleft vsplit')
  help_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(help_win, help_buf)
  vim.api.nvim_win_set_width(help_win, 52)
  vim.wo[help_win].number = false
  vim.wo[help_win].signcolumn = 'no'
  vim.wo[help_win].winfixwidth = true
  vim.cmd('wincmd l')
end

vim.keymap.set('n', '?', toggle_help, { desc = 'Toggle test fixture help' })
vim.defer_fn(toggle_help, 200)
