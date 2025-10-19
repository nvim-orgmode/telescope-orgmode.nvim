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

  ---@type { filename: string, title: string, level: number, line_number: number, all_tags: string[], is_archived: boolean, todo_value?: string, todo_type?: 'TODO'|'DONE'|'', priority?: string }[]
  local results = {}
  for _, file in ipairs(files) do
    -- Skip archive files unless explicitly requested
    local headlines = opts.archived and file:get_headlines_including_archived() or file:get_headlines()
    for _, headline in ipairs(headlines) do
      if
        (not opts.max_depth or headline:get_level() <= opts.max_depth) and (opts.archived or not headline:is_archived())
      then
        local todo_keyword = headline:get_todo()
        local priority = headline:get_priority()
        table.insert(results, {
          filename = file.filename,
          title = headline:get_title(),
          level = headline:get_level(),
          line_number = headline:get_range().start_line,
          all_tags = headline:get_tags(),
          is_archived = headline:is_archived(),
          todo_value = todo_keyword,
          todo_type = todo_keyword and (headline:is_done() and 'DONE' or 'TODO') or '',
          priority = (priority and priority ~= '') and priority or nil,
        })
      end
    end
  end

  return results
end

--- Load headlines using orgmode Search API with tag-based filtering
--- Returns same data structure as load_headlines() for consistency
---@param query string Orgmode search query (e.g., "+work", "tag1|tag2")
---@param opts { only_current_file?: boolean, archived?: boolean, max_depth?: number, original_file?: string }
---@return { filename: string, title: string, level: number, line_number: number, all_tags: string[], is_archived: boolean, todo_value?: string, todo_type?: 'TODO'|'DONE'|'', priority?: string }[]
function M.load_headlines_by_search(query, opts)
  local Search = require('orgmode.files.elements.search')
  local search = Search:new(query)

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

  local results = {}
  for _, file in ipairs(files) do
    for _, headline in ipairs(file:apply_search(search, false)) do
      if not opts.max_depth or headline:get_level() <= opts.max_depth then
        if opts.archived or not headline:is_archived() then
          local todo_keyword = headline:get_todo()
          local priority = headline:get_priority()
          table.insert(results, {
            filename = file.filename,
            title = headline:get_title(),
            level = headline:get_level(),
            line_number = headline:get_range().start_line,
            all_tags = headline:get_tags(),
            is_archived = headline:is_archived(),
            todo_value = todo_keyword,
            todo_type = todo_keyword and (headline:is_done() and 'DONE' or 'TODO') or '',
            priority = (priority and priority ~= '') and priority or nil,
          })
        end
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
--- In case of nested sections, it is the closest headline within the headline tree.
---
--- Works in both org files and agenda views:
--- - For org files: Uses treesitter parser to search the tree
--- - For agenda views: Uses the agenda API to get the headline at cursor
---@return table|nil
function M.get_closest_headline()
  if vim.bo.filetype == 'org' then
    return OrgApi.current():get_closest_headline()
  elseif vim.bo.filetype == 'orgagenda' then
    return OrgAgendaApi.get_headline_at_cursor()
  end
  return nil
end

--- Converts data table to orgmode API object for refile operations
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

--- Converts filename to orgmode API file object
---@param filename string
---@return table|nil
function M.get_api_file(filename)
  return OrgApi.load(filename)
end

--- Intra-file links are simpler and work without IDs
---@param entry { filename: string, value: { headline: { title: string } } }
---@return string
function M.get_intra_file_link(entry)
  return '*' .. entry.value.headline.title
end

--- Inter-file links require full API resolution for IDs
---@param entry { filename: string, value: { headline?: { line_number: number } } }
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

--- Chooses simpler format when possible (intra-file links don't need IDs)
---@param entry { filename: string, value: { headline?: table } }
---@param opts { original_file?: string }
---@return string
function M.get_link_destination(entry, opts)
  if entry.value.headline and opts.original_file and entry.filename == opts.original_file then
    return M.get_intra_file_link(entry)
  end
  return M.get_inter_file_link(entry)
end

return M
