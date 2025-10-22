local config = require('telescope-orgmode.lib.config')

local M = {}

-- Active adapter (lazy loaded based on config)
local active_adapter = nil
local adapter_name = 'telescope' -- default

---Get or load the active adapter
---@return table adapter module
local function get_adapter()
  if not active_adapter then
    local ok, adapter = pcall(require, 'telescope-orgmode.adapters.' .. adapter_name)

    if not ok then
      vim.notify(
        string.format('Failed to load adapter "%s", falling back to telescope', adapter_name),
        vim.log.levels.WARN
      )
      adapter = require('telescope-orgmode.adapters.telescope')
    end

    active_adapter = adapter
  end

  return active_adapter
end

function M.setup(opts)
  opts = opts or {}

  -- Store adapter preference (before it's passed to config.setup)
  if opts.adapter then
    adapter_name = opts.adapter
  end

  -- Setup global config
  config.setup(opts)
end

function M.refile_heading(opts)
  return get_adapter().refile_heading(opts)
end

function M.search_headings(opts)
  return get_adapter().search_headings(opts)
end

function M.insert_link(opts)
  return get_adapter().insert_link(opts)
end

function M.search_tags(opts)
  return get_adapter().search_tags(opts)
end

---Set the active adapter at runtime
---@param name 'telescope'|'snacks'
function M.set_adapter(name)
  adapter_name = name
  active_adapter = nil -- Force reload on next call
end

---Toggle between telescope and snacks adapter
function M.toggle_adapter()
  M.set_adapter(adapter_name == 'telescope' and 'snacks' or 'telescope')
  vim.notify('telescope-orgmode: ' .. adapter_name, vim.log.levels.INFO)
end

---Get the current adapter name
---@return string
function M.get_adapter_name()
  return adapter_name
end

return M
