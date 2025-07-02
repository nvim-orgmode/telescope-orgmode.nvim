local OrgApi = require('orgmode.api')

local M = {}

function M.load_files(opts)
  ---@type { filename: string, last_used: number, title: string }[]
  local file_results = vim.tbl_map(function(file)
    return { filename = file.filename, last_used = file.metadata.mtime, title = file:get_title() }
  end, require('orgmode').files:all())

  if not opts.archived then
    file_results = vim.tbl_filter(function(entry)
      return not (vim.fn.fnamemodify(entry.filename, ':e') == 'org_archive')
    end, file_results)
  end

  table.sort(file_results, function(a, b)
    return a.last_used > b.last_used
  end)

  return file_results
end

function M.load_headlines(opts)
  ---@type { filename: string, title: string, level: number, line_number: number, all_tags: string[], is_archived: boolean }[]
  local results = {}

  -- Get files sorted by modification time (most recent first)
  local files = require('orgmode').files:all()
  if not opts.archived then
    files = vim.tbl_filter(function(file)
      return not (vim.fn.fnamemodify(file.filename, ':e') == 'org_archive')
    end, files)
  end

  table.sort(files, function(a, b)
    return a.metadata.mtime < b.metadata.mtime
  end)

  for _, file in ipairs(files) do
    -- Skip archive files unless explicitly requested
    local headlines = opts.archived and file:get_headlines_including_archived() or file:get_headlines()
    for _, headline in ipairs(headlines) do
      if
        (not opts.max_depth or headline:get_level() <= opts.max_depth) and (opts.archived or not headline:is_archived())
      then
        table.insert(results, {
          filename = file.filename,
          title = headline:get_title(),
          level = headline:get_level(),
          line_number = headline:get_range().start_line,
          all_tags = headline:get_tags(),
          is_archived = headline:is_archived(),
        })
      end
    end
  end

  return results
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
