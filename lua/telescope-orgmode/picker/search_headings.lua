local pickers = require('telescope.pickers')
local finders = require('telescope-orgmode.finders')
local conf = require('telescope.config').values

local config = require('telescope-orgmode.config')
local mappings = require('telescope-orgmode.mappings')

return function(opts)
  opts = config.init_opts(opts, {
    headlines = 'Search headlines',
    orgfiles = 'Search org files',
  }, "headlines")

  -- Capture the current buffer before opening telescope
  opts.original_buffer = vim.api.nvim_get_current_buf()
  opts.original_file = vim.api.nvim_buf_get_name(opts.original_buffer)

  pickers
    .new(opts, {
      prompt_title = opts.prompt_titles[opts.state.current],
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
