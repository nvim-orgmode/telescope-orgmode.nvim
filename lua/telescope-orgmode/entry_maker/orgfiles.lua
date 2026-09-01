require('telescope-orgmode.entry_maker.types')
local org = require('telescope-orgmode.org')

local M = {}

---@param file_results { filename: string, title: string, headline: string }[]
---@return OrgFileEntry[]
local function index_orgfiles(file_results)
  local results = {}
  for _, file_entry in ipairs(file_results) do
    local entry = {
      filename = file_entry.filename,
      title = file_entry.title,
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

return M
