local pick = require("mini.pick")
local operations = require("telescope-orgmode.lib.operations")
local actions = require('telescope-orgmode.lib.actions')
local config = require('telescope-orgmode.lib.config')
local mini_lib = require('telescope-orgmode.lib.mini')
local opts

local M = {}

local function custom_choose(item)
  local destination = actions.entry_to_destination(item)
  vim.api.nvim_win_call(
    pick.get_picker_state().windows.target,
    function() vim.schedule(function() operations.navigate_to(destination) end) end
  )
  return false
end

function M.start_picker(org_opts)
  opts = config:new('search_headings', org_opts)
  local state = mini_lib.create_state(opts)

  local items, resolved_opts = mini_lib.get_entries(state, opts)

  local pick_opts = vim.tbl_deep_extend("keep", org_opts or {}, {
    window = { prompt_prefix = " Heading: "},
    source = {
      name = "Choose Heading",
      items = items,
      show = mini_lib.make_show(resolved_opts),
      choose = custom_choose
    },
    mappings = {
      toggle_preview = ""
    }
  })

  return pick.start(pick_opts)
end


return M
