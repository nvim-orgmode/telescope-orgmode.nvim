local headlines = require('telescope-orgmode.entry_maker.headlines')
local orgfiles = require('telescope-orgmode.entry_maker.orgfiles')

local finders = require('telescope.finders')

local M = {}

function M.headlines(opts)
  local results, widths = headlines.get_entries(opts)
  opts.widths = widths
  return finders.new_table({
    results = results,
    entry_maker = opts.entry_maker or headlines.make_entry(opts),
  })
end

function M.orgfiles(opts)
  return finders.new_table({
    results = orgfiles.get_entries(opts),
    entry_maker = opts.entry_maker or orgfiles.make_entry(),
  })
end

-- return the correct finder for the current state
function M.from_options(opts)
  if opts.state.current == 'headlines' then
    return M.headlines(opts)
  elseif opts.state.current == 'orgfiles' then
    return M.orgfiles(opts)
  else
    -- this should not happen
    error(string.format('Invalid state %s', opts.state.current))
  end
end

return M
