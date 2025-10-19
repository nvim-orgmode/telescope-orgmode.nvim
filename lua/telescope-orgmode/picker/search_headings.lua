local pickers = require('telescope.pickers')
local finders = require('telescope-orgmode.finders')
local conf = require('telescope.config').values

local config = require('telescope-orgmode.config')
local mappings = require('telescope-orgmode.mappings')

return function(opts)
  opts = config.init_opts(opts, {
    headlines = 'Search headlines',
    orgfiles = 'Search org files',
  }, 'headlines')

  pickers
    .new(opts, {
      prompt_title = opts.prompt_titles[opts.state.current],
      default_text = opts.default_text or '',
      finder = finders.from_options(opts),
      sorter = conf.generic_sorter(opts),
      previewer = conf.grep_previewer(opts),
      attach_mappings = function(_, map)
        mappings.attach_mappings(map, opts)
        return true
      end,
    })
    :find()
end
