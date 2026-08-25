local config = require('telescope-orgmode.lib.config')
local mini_lib = require('telescope-orgmode.lib.mini')
local lib_actions = require('telescope-orgmode.lib.actions')
local pick = require('mini.pick')

local M = {}

local function custom_choose(item)
  vim.schedule(function ()
    local promise = lib_actions.execute_insert_link(item)
    if not promise then
      vim.notify('Could not find link target', vim.log.levels.ERROR)
      return
    end

    promise
      :next(function(result)
        if result then
          vim.notify('Link inserted successfully', vim.log.levels.INFO)
        else
          vim.notify('Link insertion cancelled', vim.log.levels.INFO)
        end
      end)
      :catch(function(err)
        vim.notify('Failed to insert link: ' .. tostring(err), vim.log.levels.ERROR)
      end)
  end)
end

function M.insert_link(org_opts)
  local opts = config:new('insert_link', org_opts)

  opts.original_buffer = vim.api.nvim_get_current_buf()
  opts.original_file = vim.api.nvim_buf_get_name(opts.original_buffer)
  opts.current_file = opts.original_file

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
      choose = custom_choose
    }
  })

  return pick.start(pick_opts)
end


return M
