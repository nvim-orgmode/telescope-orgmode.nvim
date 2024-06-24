local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local conf = require('telescope.config').values
local action_set = require('telescope.actions.set')
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')

local utils = require('telescope-orgmode.utils')
local config = require('telescope-orgmode.config')

local OrgApi = require('orgmode.api')

local M = {}

M.refile = function(prompt_bufnr)
  local entry = action_state.get_selected_entry()
  actions.close(prompt_bufnr)

  -- Refile to the file by default
  local destination = entry.value.file

  -- Refile to a specific heading if is set
  if entry.value.headline then
    destination = entry.value.headline
  end

  return OrgApi.refile({
    source = M.closest_headline,
    destination = destination,
  })
end

M.closest_headline = nil

return function(opts)
  opts = vim.tbl_extend('force', config.opts, opts or {})
  opts.state = {
    current = nil,
    next = nil,
    headlines = {
      max_depth = opts.max_depth,
      prompt_title = 'Refile to headline',
    },
    orgfiles = {
      max_depth = 0,
      prompt_title = 'Refile to org files',
    },
  }

  M.closest_headline = OrgApi.current():get_closest_headline()

  pickers
    .new(opts, {
      -- TODO: alter prompt title when depth is 0: Refile under file, Refile
      -- under Headline
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
        action_set.select:replace(M.refile)
        return true
      end,
    })
    :find()
end
