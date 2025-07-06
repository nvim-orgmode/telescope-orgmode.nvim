local pickers = require('telescope.pickers')
local conf = require('telescope.config').values
local action_set = require('telescope.actions.set')

local config = require('telescope-orgmode.config')
local finders = require('telescope-orgmode.finders')
local actions = require('telescope-orgmode.actions')
local mappings = require('telescope-orgmode.mappings')

return function(opts)
  opts = config.init_opts(opts, {
    headlines = 'Insert link to headline',
    orgfiles = 'Insert link to org file',
  }, 'headlines')

  pickers
    .new(opts, {
      prompt_title = opts.prompt_titles[opts.state.current],
      finder = finders.from_options(opts),
      sorter = conf.generic_sorter(opts),
      previewer = conf.grep_previewer(opts),
      attach_mappings = function(_, map)
        action_set.select:replace(actions.insert(opts))
        mappings.attach_mappings(map, opts)
        return true
      end,
    })
    :find()
end
