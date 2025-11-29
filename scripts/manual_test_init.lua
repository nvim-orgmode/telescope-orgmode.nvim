-- Minimal Neovim configuration for manual keybinding testing
-- Isolated from user's personal config

-- Add plugin directories to runtimepath
local plugin_dir = vim.fn.getcwd()
vim.opt.runtimepath:append(plugin_dir)

-- Add vendor dependencies (downloaded locally)
local vendor_dir = plugin_dir .. '/vendor'
local vendor_deps = {
  vendor_dir .. '/orgmode',
  vendor_dir .. '/telescope.nvim',
  vendor_dir .. '/plenary.nvim',
}

for _, dep in ipairs(vendor_deps) do
  if vim.fn.isdirectory(dep) == 1 then
    vim.opt.runtimepath:prepend(dep)  -- Use prepend so vendor takes precedence
  end
end

-- Set up orgmode filetype detection
vim.cmd([[
  augroup orgmode_ft_detection
    autocmd!
    autocmd BufRead,BufNewFile *.org setfiletype org
  augroup END
]])

-- Try to add snacks.nvim from user's setup if available
local user_snacks = vim.fn.stdpath('data') .. '/lazy/snacks.nvim'
if vim.fn.isdirectory(user_snacks) == 1 then
  vim.opt.runtimepath:append(user_snacks)
end

-- Basic Neovim settings
vim.opt.termguicolors = true
vim.opt.completeopt = { 'menu', 'menuone', 'noselect' }
vim.opt.hidden = true

-- Initialize orgmode (required for telescope-orgmode)
-- Must be done AFTER filetype detection is set up
local orgmode = require('orgmode')
orgmode.setup({
  org_agenda_files = { plugin_dir .. '/scripts/*.org' },
  org_default_notes_file = plugin_dir .. '/scripts/manual_test_telescope.org',
  -- Custom TODO keywords for manual testing
  -- UNTESTED = not tested yet
  -- PASS = working correctly
  -- FAIL = broken/not working
  org_todo_keywords = { 'UNTESTED', 'PASS', '|', 'FAIL' },
})

-- Ensure orgmode is fully loaded
vim.cmd('runtime! ftplugin/org.lua')
vim.cmd('runtime! syntax/org.vim')

-- Orgmode's native TODO state cycling is 'cit' (change inner TODO)
-- No custom keybinding needed - just use orgmode's default

-- Initialize telescope-orgmode with both adapters available
local telescope_orgmode = require('telescope-orgmode')

-- Set up convenience keybindings for testing
vim.keymap.set('n', '<leader>th', function()
  telescope_orgmode.search_headings({ adapter = 'telescope' })
end, { desc = 'Test: Telescope headlines' })

vim.keymap.set('n', '<leader>sh', function()
  telescope_orgmode.search_headings({ adapter = 'snacks' })
end, { desc = 'Test: Snacks headlines' })

vim.keymap.set('n', '<leader>tt', function()
  telescope_orgmode.search_tags({ adapter = 'telescope' })
end, { desc = 'Test: Telescope tags' })

vim.keymap.set('n', '<leader>st', function()
  telescope_orgmode.search_tags({ adapter = 'snacks' })
end, { desc = 'Test: Snacks tags' })

vim.keymap.set('n', '<leader>tr', function()
  telescope_orgmode.refile_heading({ adapter = 'telescope' })
end, { desc = 'Test: Telescope refile' })

vim.keymap.set('n', '<leader>sr', function()
  telescope_orgmode.refile_heading({ adapter = 'snacks' })
end, { desc = 'Test: Snacks refile' })

vim.keymap.set('n', '<leader>ti', function()
  telescope_orgmode.insert_link({ adapter = 'telescope' })
end, { desc = 'Test: Telescope insert link' })

vim.keymap.set('n', '<leader>si', function()
  telescope_orgmode.insert_link({ adapter = 'snacks' })
end, { desc = 'Test: Snacks insert link' })

-- Print welcome message
vim.defer_fn(function()
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
  print('  telescope-orgmode.nvim - Interactive Keybinding Test')
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
  print('')
  print('  IMPORTANT KEYBINDINGS:')
  print('    Leader key: \\ (backslash)')
  print('    Toggle TODO state: cit (in normal mode, orgmode default)')
  print('      UNTESTED → PASS → FAIL → (none) → UNTESTED')
  print('')
  print('  Test commands available:')
  print('    \\th - Telescope headlines    |  \\sh - Snacks headlines')
  print('    \\tt - Telescope tags          |  \\st - Snacks tags')
  print('    \\tr - Telescope refile        |  \\sr - Snacks refile')
  print('    \\ti - Telescope insert link   |  \\si - Snacks insert link')
  print('')
  print('  Workflow:')
  print('    1. Navigate to test headline (e.g., "** UNTESTED Test 1: Open Headlines Picker")')
  print('    2. Press cit to mark: UNTESTED → PASS (working) or FAIL (broken)')
  print('    3. Open picker with test command (e.g., \\th)')
  print('    4. Test the keybinding, then mark the checkbox')
  print('    5. Save and exit: :wq')
  print('')
  print('  Results will be analyzed automatically when you exit.')
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
end, 100)
