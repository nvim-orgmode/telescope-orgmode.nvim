require('telescope-orgmode.typehints')
local org = require('telescope-orgmode.org')
local entry_display = require('telescope.pickers.entry_display')

---@class OrgHeadlineEntry
---@field file OrgApiFile
---@field filename string
---@field headline OrgApiHeadline

---@param file_results { file: OrgApiFile, filename: string }[]
---@return OrgHeadlineEntry[]
local function index_headlines(file_results, opts)
  local results = {}
  for _, file_entry in ipairs(file_results) do
    for _, headline in ipairs(file_entry.file.headlines) do
      local allowed_depth = opts.max_depth == nil or headline.level <= opts.max_depth
      local allowed_archive = opts.archived or not headline.is_archived
      if allowed_depth and allowed_archive then
        local entry = {
          file = file_entry.file,
          filename = file_entry.filename,
          headline = headline,
        }
        table.insert(results, entry)
      end
    end
  end

  return results
end

local M = {}
---Fetches entrys from OrgApi and extracts the relevant information
---@param opts any
---@return OrgHeadlineEntry[]
M.get_entries = function(opts)
  return index_headlines(org.load_files(opts), opts)
end

---Entry-Maker for Telescope
---@param opts any
---@return fun(entry: OrgHeadlineEntry):MatchEntry
M.make_entry = function(opts)
  local displayer = entry_display.create({
    separator = ' ',
    items = {
      { width = vim.F.if_nil(opts.location_width, 20) },
      { remaining = true },
    },
  })

  ---@param entry MatchEntry
  local function make_display(entry)
    return displayer({ entry.location, entry.tags .. ' ' .. entry.line })
  end

  return function(entry)
    local headline = entry.headline
    local lnum = headline.position.start_line
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
    }
  end
end

return M
