local pickers = require('telescope.pickers')
local conf = require('telescope.config').values
local action_set = require('telescope.actions.set')

local config = require('telescope-orgmode.config')
local finders = require('telescope-orgmode.finders')
local actions = require('telescope-orgmode.actions')
local org = require('telescope-orgmode.org')
local mappings = require('telescope-orgmode.mappings')

return function(opts)
  opts = config.init_opts(opts, {
    headlines = 'Refile to headline',
    orgfiles = 'Refile to orgfile',
  }, 'headlines')

  local closest_headline = org.get_closest_headline()

  if not closest_headline then
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

  pickers
    .new(opts, {
      prompt_title = opts.prompt_titles[opts.state.current],
      finder = finders.from_options(opts),
      sorter = conf.generic_sorter(opts),
      previewer = conf.grep_previewer(opts),
      attach_mappings = function(_, map)
        action_set.select:replace(actions.refile(closest_headline))
        mappings.attach_mappings(map, opts)
        return true
      end,
    })
    :find()
end
