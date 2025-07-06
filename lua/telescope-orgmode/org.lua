local OrgApi = require('orgmode.api')
local OrgAgendaApi = require('orgmode.api.agenda')

local M = {}

function M.load_files(opts)
  ---@type { filename: string, title: string }[]
  local file_results = vim.tbl_map(function(file)
    return { filename = file.filename, title = file:get_title() }
  end, require('orgmode').files:all())

  if not opts.archived then
    file_results = vim.tbl_filter(function(entry)
      return not (vim.fn.fnamemodify(entry.filename, ':e') == 'org_archive')
    end, file_results)
  end

  table.sort(file_results, function(a, b)
    local stat_a = vim.uv.fs_stat(a.filename)
    local stat_b = vim.uv.fs_stat(b.filename)
    local mtime_a = stat_a and stat_a.mtime.sec or 0
    local mtime_b = stat_b and stat_b.mtime.sec or 0
    return mtime_a > mtime_b
  end)

  return file_results
end

function M.load_headlines(opts)
  -- Get files sorted by modification time (most recent first)
  local files = require('orgmode').files:all()

  if opts.only_current_file then
    local current_file = opts.original_file or vim.api.nvim_buf_get_name(0)
    if current_file == '' then
      current_file = vim.fn.expand('%:p')
    end
    files = vim.tbl_filter(function(file)
      return file.filename == current_file
    end, files)
  end

  if not opts.archived then
    files = vim.tbl_filter(function(file)
      return not (vim.fn.fnamemodify(file.filename, ':e') == 'org_archive')
    end, files)
  end

  table.sort(files, function(a, b)
    local stat_a = vim.uv.fs_stat(a.filename)
    local stat_b = vim.uv.fs_stat(b.filename)
    local mtime_a = stat_a and stat_a.mtime.sec or 0
    local mtime_b = stat_b and stat_b.mtime.sec or 0
    return mtime_a > mtime_b
  end)

  ---@type { filename: string, title: string, level: number, line_number: number, all_tags: string[], is_archived: boolean }[]
  local results = {}
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
--- Works in both org files and agenda views:
--- - For org files: Uses treesitter parser to search the tree
--- - For agenda views: Uses the agenda API to get the headline at cursor
function M.get_closest_headline()
  -- Handle different buffer types explicitly
  if vim.bo.filetype == 'org' then
    return OrgApi.current():get_closest_headline()
  elseif vim.bo.filetype == 'orgagenda' then
    return OrgAgendaApi.get_headline_at_cursor()
  end

  -- Not in org or agenda buffer
  return nil
end

--- Get the API headline object for a given filename and line number
---@param filename string
---@param line_number number
---@return table|nil
function M.get_api_headline(filename, line_number)
  local api_file = OrgApi.load(filename)
  if api_file then
    for _, headline in ipairs(api_file.headlines) do
      if headline.position.start_line == line_number then
        return headline
      end
    end
  end
  return nil
end

--- Get the API file object for a given filename
---@param filename string
---@return table|nil
function M.get_api_file(filename)
  return OrgApi.load(filename)
end

--- Get intra-file link for headline (simple *Headline format)
---@param entry table
---@return string
function M.get_intra_file_link(entry)
  return '*' .. entry.value.headline.title
end

--- Get inter-file link using full API format
---@param entry table
---@return string
function M.get_inter_file_link(entry)
  if entry.value.headline then
    local api_headline = M.get_api_headline(entry.filename, entry.value.headline.line_number)
    if api_headline then
      return api_headline:get_link()
    end
    error('Could not find headline for link')
  else
    local api_file = M.get_api_file(entry.filename)
    if api_file then
      return api_file:get_link()
    end
    error('Could not find file for link')
  end
end

--- Get link destination (chooses intra-file vs inter-file format)
---@param entry table
---@param opts table
---@return string
function M.get_link_destination(entry, opts)
  -- Use intra-file format for headlines in the same file
  if entry.value.headline and opts.original_file and entry.filename == opts.original_file then
    return M.get_intra_file_link(entry)
  end

  -- Use inter-file format for everything else
  return M.get_inter_file_link(entry)
end

return M
