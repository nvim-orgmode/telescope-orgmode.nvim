local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local conf = require('telescope.config').values

local utils = require('telescope-orgmode.utils')

return function(opts)
  opts = opts or {}

  pickers
    .new(opts, {
      prompt_title = 'Search Headings',
      finder = finders.new_table({
        results = utils.get_entries(opts),
        entry_maker = opts.entry_maker or utils.make_entry(opts),
      }),
      sorter = conf.generic_sorter(opts),
      previewer = conf.grep_previewer(opts),
    })
    :find()
end
