require('telescope-orgmode.typehints')

local OrgApiHeadline = require('orgmode.api.headline')
local OrgApiFile = require('orgmode.api.file')
local OrgApi = require('orgmode.api')

local M = {}

function M.load_files(opts)
  ---@type { file: OrgApiFile, filename: string, last_used: number }[]
  local file_results = vim.tbl_map(function(file)
    local file_stat = vim.loop.fs_stat(file.filename) or 0
    return { file = file, filename = file.filename, last_used = file_stat.mtime.sec }
  end, OrgApi.load())

  if not opts.archived then
    file_results = vim.tbl_filter(function(entry)
      return not entry.file.is_archive_file
    end, file_results)
  end

  table.sort(file_results, function(a, b)
    return a.last_used > b.last_used
  end)

  return file_results
end

function M.refile(opts)
  return OrgApi.refile(opts)
end

function M.insert_link(destination)
  return OrgApi.insert_link(destination)
end

--- Returns the headline of the section, the cursor is currently placed in.
--- In case of nested sections, it is the closest headline within the headline
--- tree.
---
--- The precondition to run this function successfully is, that the cursor is
--- placed in an orgfile when the function is called.
function M.get_closest_headline()
  return OrgApi.current():get_closest_headline()
end

return M
