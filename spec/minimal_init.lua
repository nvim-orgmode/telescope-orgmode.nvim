local cwd = vim.fn.getcwd()

if vim.endswith(cwd, 'lua') or vim.endswith(cwd, 'lua/') or vim.endswith(cwd, 'lua\\') then
  cwd = vim.fs.dirname(cwd)
end

local function getenv(name)
  local value = vim.fn.getenv(name)
  if value ~= vim.NIL then
    return value
  end
end

-- Enable verbose test output with TELESCOPE_ORGMODE_TEST_REPORT=true
local report_enabled = getenv('TELESCOPE_ORGMODE_TEST_REPORT')
local function report(...)
  if report_enabled then
    print(...)
  end
end

-- Allow testing against specific plugin versions via environment variables
local telescope_branch = getenv('TELESCOPE_ORGMODE_TELESCOPE_BRANCH')
local orgmode_branch = getenv('TELESCOPE_ORGMODE_ORGMODE_BRANCH')

local function ensure_plugin_downloaded(plugin, path)
  if vim.fn.isdirectory(path) ~= 0 then
    return
  end

  local branch_info = plugin.branch and (' @ ' .. plugin.branch) or ''
  report('Downloading ' .. plugin.name .. branch_info)

  -- Build git clone command: shallow clone of specific branch if provided,
  -- otherwise clone default branch
  local cmd = { 'git', 'clone', '--depth=1' }
  if plugin.branch then
    vim.list_extend(cmd, { '--branch', plugin.branch, '--single-branch' })
  end
  vim.list_extend(cmd, { plugin.repo, path })

  local result = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then
    error(string.format('Failed to clone %s: %s', plugin.name, result))
  end
end

local function load_plugin(plugin, path)
  report('Loading ' .. plugin.name)
  vim.opt.rtp:prepend(path)
end

local function configure_plugin(plugin)
  if not plugin.config then
    return
  end

  local ok, err = pcall(plugin.config)
  if not ok then
    error(string.format('Failed to configure %s: %s', plugin.name, err))
  end
end

local plugins = {
  {
    name = 'plenary.nvim',
    repo = 'https://github.com/nvim-lua/plenary.nvim',
  },
  {
    name = 'telescope.nvim',
    repo = 'https://github.com/nvim-telescope/telescope.nvim',
    branch = telescope_branch,
  },
  {
    name = 'orgmode',
    repo = 'https://github.com/nvim-orgmode/orgmode',
    branch = orgmode_branch,
    config = function()
      report('Configuring orgmode')
      require('orgmode').setup({
        org_agenda_files = {},
        org_default_notes_file = '',
        org_todo_keywords = { 'TODO', 'PROGRESS', '|', 'DONE' },
      })
    end,
  },
}

for _, plugin in ipairs(plugins) do
  local path = cwd .. '/vendor/' .. plugin.name
  ensure_plugin_downloaded(plugin, path)
  load_plugin(plugin, path)
  configure_plugin(plugin)
end

-- Register telescope-orgmode itself and configure test environment
vim.opt.rtp:prepend(cwd)
vim.opt.swapfile = false -- Avoid .swp file clutter from temp test files
vim.opt.termguicolors = true -- Required for telescope highlight groups

report('Test environment ready')
