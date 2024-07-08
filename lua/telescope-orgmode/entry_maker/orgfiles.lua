require('telescope-orgmode.entry_maker.types')
local org = require('telescope-orgmode.org')
local entry_display = require('telescope.pickers.entry_display')

local M = {}

---@param file_results { file: OrgApiFile, filename: string }[]
---@return OrgFileEntry[]
local function index_orgfiles(file_results)
  local results = {}
  for _, file_entry in ipairs(file_results) do
    local entry = {
      file = file_entry.file,
      filename = file_entry.filename,
      -- not beautiful to access a private property, but this is the only way to get the title
      ---@diagnostic disable-next-line: invisible, undefined-field
      title = file_entry.file._file:get_directive('TITLE') or nil,
      headline = nil,
    }
    table.insert(results, entry)
  end
  return results
end

---Fetches entries from OrgApi and extracts the relevant information
---@param opts any
---@return OrgFileEntry[]
M.get_entries = function(opts)
  return index_orgfiles(org.load_files(opts))
end

---Entry-Maker for Telescope
---@return fun(entry: OrgFileEntry):MatchEntry
M.make_entry = function()
  local orgfile_displayer = entry_display.create({
    separator = ' ',
    items = {
      { remaining = true },
    },
  })

  ---@param entry MatchEntry
  local function make_display(entry)
    return orgfile_displayer({ entry.line })
  end

  return function(entry)
    local lnum = nil
    local location = vim.fn.fnamemodify(entry.filename, ':t')
    local line = entry.title or location
    local tags = ''
    local ordinal = line

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
