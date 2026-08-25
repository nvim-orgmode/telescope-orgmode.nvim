local config = require('telescope-orgmode.lib.config')
local org = require('telescope-orgmode.org')
local lib_actions = require('telescope-orgmode.lib.actions')

local pick = require('mini.pick')
local mini_lib = require('telescope-orgmode.lib.mini')

local M = {}

local function custom_choose(source_headline)
  return function(item)
    vim.schedule(function()
      local success, message = lib_actions.execute_refile(source_headline, item)
      vim.notify(message, success and vim.log.levels.INFO or vim.log.levels.WARN)
    end)
    return false
  end
end

function M.refile_heading(org_opts)
  local opts = config:new('refile_heading', org_opts)

  opts.original_buffer = vim.api.nvim_get_current_buf()
  opts.original_file = vim.api.nvim_buf_get_name(opts.original_buffer)
  opts.current_file = opts.original_file

  local source_headline = org.get_closest_headline()

  if not source_headline then
    local filetype = vim.bo.filetype
    if filetype == 'org' then
      vim.notify('No headline found at cursor position in org file', vim.log.levels.WARN)
    else
      vim.notify(
        'No headline found at cursor position. Make sure cursor is on a valid agenda item or org headline.',
        vim.log.levels.WARN
      )
    end
    return
  end

  local state = mini_lib.create_state(opts)
  local items, resolved_opts = mini_lib.get_entries(state, opts)

  local base_title = opts.prompt_titles[state:get_current()]
  local full_title = state:get_full_title(base_title)
  local formatted_title = " " .. full_title .. ": "

  local pick_opts = vim.tbl_deep_extend("keep", org_opts or {}, {
    window = { prompt_prefix = formatted_title },
    source = {
      name = "Refile",
      items = items,
      show = mini_lib.make_show(resolved_opts),
      choose = custom_choose(source_headline)
    }
  })

  return pick.start(pick_opts)
end

return M
