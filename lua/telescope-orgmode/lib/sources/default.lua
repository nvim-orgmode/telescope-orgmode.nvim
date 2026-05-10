-- Default source: enumerates files, headlines and tags from
-- `require('orgmode').files:all()`. Filters archive files (extension
-- `.org_archive`) and archived subtrees unless `opts.archived` is true.

local M = {
  name = 'default',
}

---File-Liste mit Sort + Archive-Filter + only_current_file.
---@param opts table
---@return table[] org files
local function enumerate_org_files(opts)
  opts = opts or {}
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

  return files
end

---Property-Loader (kleiner Helper, lokal zur Default-Pipeline).
---@param headline table orgmode API headline
---@param show_properties OrgmodePropertyConfig[]|nil
---@return table<string, string>
local function load_properties(headline, show_properties)
  local properties = {}
  if show_properties and #show_properties > 0 then
    for _, prop_config in ipairs(show_properties) do
      properties[prop_config.name] = headline:get_property(prop_config.name) or ''
    end
  end
  return properties
end

---Headline → Schema-Tabelle. Reine Projektion, keine Filter.
---@param file table orgmode API file
---@param headline table orgmode API headline
---@param show_properties OrgmodePropertyConfig[]|nil
---@return table headline-entry
local function build_headline_entry(file, headline, show_properties)
  local todo_keyword = headline:get_todo()
  local priority = headline:get_priority()

  return {
    filename = file.filename,
    title = headline:get_title(),
    level = headline:get_level(),
    line_number = headline:get_range().start_line,
    all_tags = headline:get_tags(),
    is_archived = headline:is_archived(),
    todo_value = todo_keyword,
    todo_type = todo_keyword and (headline:is_done() and 'DONE' or 'TODO') or '',
    priority = (priority and priority ~= '') and priority or nil,
    properties = load_properties(headline, show_properties),
  }
end

---@param opts table
---@return { filename: string, title: string }[]
function M.enumerate_files(opts)
  opts = opts or {}
  local files = enumerate_org_files(opts)
  return vim.tbl_map(function(file)
    return { filename = file.filename, title = file:get_title() }
  end, files)
end

---@param opts table
---@return table[] headline entries (full schema)
function M.enumerate_headlines(opts)
  opts = opts or {}
  local files = enumerate_org_files(opts)
  local results = {}
  for _, file in ipairs(files) do
    local headlines = opts.archived and file:get_headlines_including_archived() or file:get_headlines()
    for _, headline in ipairs(headlines) do
      if
        (not opts.max_depth or headline:get_level() <= opts.max_depth) and (opts.archived or not headline:is_archived())
      then
        table.insert(results, build_headline_entry(file, headline, opts.show_properties))
      end
    end
  end
  return results
end

---@param query string Orgmode search query (e.g. "+work", "tag1|tag2")
---@param opts table
---@return table[] headline entries (full schema)
function M.enumerate_headlines_by_query(query, opts)
  opts = opts or {}
  local Search = require('orgmode.files.elements.search')
  local search = Search:new(query)

  local files = enumerate_org_files(opts)

  local results = {}
  local max_count = opts.max_count
  local count = 0
  for _, file in ipairs(files) do
    if max_count and count >= max_count then
      break
    end
    for _, headline in ipairs(file:apply_search(search, false)) do
      if max_count and count >= max_count then
        break
      end
      if not opts.max_depth or headline:get_level() <= opts.max_depth then
        if opts.archived or not headline:is_archived() then
          table.insert(results, build_headline_entry(file, headline, opts.show_properties))
          count = count + 1
        end
      end
    end
  end

  return results
end

---@param opts table
---@return { tag: string, count: integer, files: string[] }[]
function M.enumerate_tags(opts)
  opts = opts or {}
  local tag_info = {} -- { [tag] = { count, files = set } }
  local orgmode = require('orgmode')

  for _, orgfile in ipairs(orgmode.files:all()) do
    if not orgfile:is_archive_file() then
      local filename = orgfile.filename
      for _, headline in ipairs(orgfile:get_headlines()) do
        for _, tag in ipairs(headline:get_tags()) do
          if not tag_info[tag] then
            tag_info[tag] = { count = 0, files = {} }
          end
          tag_info[tag].count = tag_info[tag].count + 1
          tag_info[tag].files[filename] = true
        end
      end
    end
  end

  local result = {}
  for tag, info in pairs(tag_info) do
    table.insert(result, {
      tag = tag,
      count = info.count,
      files = vim.tbl_keys(info.files),
    })
  end
  return result
end

return M
