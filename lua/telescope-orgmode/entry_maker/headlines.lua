require('telescope-orgmode.entry_maker.types')
local org = require('telescope-orgmode.org')
local entry_display = require('telescope.pickers.entry_display')

---@param headline_results { filename: string, title: string, level: number, line_number: number, all_tags: string[], is_archived: boolean }[]
---@return OrgHeadlineEntry[]
local function index_headlines(headline_results, opts)
  local results = {}
  for _, headline in ipairs(headline_results) do
    local entry = {
      filename = headline.filename,
      headline = headline,
    }
    table.insert(results, entry)
  end

  return results
end

local M = {}
---Fetches entries from OrgApi and extracts the relevant information
---Routes to search-based or bulk loading based on tag_query presence
---@param opts { tag_query?: string, only_current_file?: boolean, archived?: boolean, max_depth?: number }
---@return OrgHeadlineEntry[]
M.get_entries = function(opts)
  -- Route to search-based loader if tag_query provided
  local headline_data
  if opts.tag_query then
    headline_data = org.load_headlines_by_search(opts.tag_query, opts)
  else
    headline_data = org.load_headlines(opts)
  end

  return index_headlines(headline_data, opts)
end

---Entry-Maker for Telescope
---@param opts { location_width?: number, tags_width?: number }
---@return fun(entry: OrgHeadlineEntry):MatchEntry
M.make_entry = function(opts)
  local displayer = entry_display.create({
    separator = ' ',
    items = {
      { width = vim.F.if_nil(opts.location_width, 24) },
      { width = vim.F.if_nil(opts.tags_width, 20) },
      { remaining = true },
    },
  })

  ---@param entry MatchEntry
  local function make_display(entry)
    return displayer({
      { entry.location, 'TelescopeResultsComment' },
      { entry.tags, '@org.tag' },
      { entry.line, '@org.headline.level' .. entry.headline_level },
    })
  end

  return function(entry)
    local headline = entry.headline
    local lnum = headline.line_number
    local location = string.format('%s:%i', vim.fn.fnamemodify(entry.filename, ':t'), lnum)
    local line = string.format('%s %s', string.rep('*', headline.level), headline.title)
    local tags = table.concat(headline.all_tags, ':')
    local ordinal = tags .. ' ' .. line .. ' ' .. location

    return {
      value = entry,
      ordinal = ordinal,
      filename = entry.filename,
      lnum = lnum,
      display = make_display,
      location = location,
      line = line,
      tags = tags,
      headline_level = headline.level,
    }
  end
end

return M
