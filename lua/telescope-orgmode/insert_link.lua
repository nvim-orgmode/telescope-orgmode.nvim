local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local conf = require('telescope.config').values
local action_set = require('telescope.actions.set')
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')

---@type OrgApi
local OrgApi = require('orgmode.api')

local utils = require('telescope-orgmode.utils')
local config = require('telescope-orgmode.config')

---@class MatchEntry
---@field value OrgEntry
---@field ordinal string
---@field filename string
---@field lnum number
---@field display function
---@field location string,
---@field line string,
---@field tags string,

local function insert(prompt_bufnr)
  actions.close(prompt_bufnr)

  ---@type MatchEntry
  local entry = action_state.get_selected_entry()

  -- Link to the filename by default
  local destination = entry.value.file.filename

  -- Link to a specific heading if is set
  if entry.value.headline then
    destination = 'file:' .. entry.value.file.filename .. '::*' .. entry.value.headline.title
  end

  OrgApi.insert_link(destination)
  return true
end

return function(opts)
  opts = vim.tbl_extend('force', config.opts, opts or {})
  opts.state = {
    current = nil,
    next = nil,
    headlines = {
      max_depth = opts.max_depth,
      prompt_title = 'Insert link to headline',
    },
    orgfiles = {
      max_depth = 0,
      prompt_title = 'Insert link to org file',
    },
  }

  pickers
    .new(opts, {
      prompt_title = opts.state.headlines.prompt_title,
      finder = finders.new_table({
        results = utils.get_entries(opts),
        entry_maker = opts.entry_maker or utils.make_entry(opts),
      }),
      sorter = conf.generic_sorter(opts),
      previewer = conf.grep_previewer(opts),
      attach_mappings = function(_, map)
        map('i', '<C-Space>', utils.gen_depth_toggle(opts), { desc = 'Toggle headline/orgfile' })
        for mode, mappings in pairs(opts.mappings or {}) do
          for key, action in pairs(mappings) do
            map(mode, key, action)
          end
        end
        action_set.select:replace(insert)
        return true
      end,
    })
    :find()
end
