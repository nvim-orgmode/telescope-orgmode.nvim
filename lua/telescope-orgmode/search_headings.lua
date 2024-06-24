local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local conf = require('telescope.config').values

local utils = require('telescope-orgmode.utils')
local config = require('telescope-orgmode.config')

return function(opts)
  opts = vim.tbl_extend('force', config.opts, opts or {})
  opts.state = {
    current = nil,
    next = nil,
    headlines = {
      max_depth = opts.max_depth,
      prompt_title = 'Search headlines',
    },
    orgfiles = {
      max_depth = 0,
      prompt_title = 'Search org files',
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
        map('i', '<C-Space>', utils.gen_depth_toggle(opts), { desc = 'Toggle headline/orgfile jump' })
        for mode, mappings in pairs(opts.mappings or {}) do
          for key, action in pairs(mappings) do
            map(mode, key, action)
          end
        end
        return true
      end,
    })
    :find()
end
