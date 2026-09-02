-- Default source: enumerates files, headlines and tags from
-- `require('orgmode').files:all()`.
--
-- Provider only. No archive filtering, no depth cap, no ordering: policy
-- lives in lib/entry_filters.lua and is composed per loader in org.lua.
-- A source that can apply a policy step faster than the central path may
-- push it down via an optional method, the way
-- `enumerate_headlines_by_query` pushes down the search itself.

local M = {
  name = 'default',
}

---@return table[] orgmode API files
local function all_org_files()
  return require('orgmode').files:all()
end

---Property loader (small helper, local to the default pipeline).
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

---Headline to schema table. Pure projection, no filters.
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

---@param _opts table
---@return { filename: string, title: string }[]
function M.enumerate_files(_opts)
  return vim.tbl_map(function(file)
    return { filename = file.filename, title = file:get_title() }
  end, all_org_files())
end

---Archived subtrees are included; `exclude_archived_subtrees` drops them
---when the caller's policy says so.
---@param opts table
---@return table[] headline entries (full schema)
function M.enumerate_headlines(opts)
  opts = opts or {}
  local results = {}
  for _, file in ipairs(all_org_files()) do
    for _, headline in ipairs(file:get_headlines_including_archived()) do
      table.insert(results, build_headline_entry(file, headline, opts.show_properties))
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

  local results = {}
  for _, file in ipairs(all_org_files()) do
    for _, headline in ipairs(file:apply_search(search, false)) do
      table.insert(results, build_headline_entry(file, headline, opts.show_properties))
    end
  end
  return results
end

---Archive-file exclusion happens during aggregation rather than in the
---policy layer: a tag spans files, so it cannot be filtered out of a
---finished tag entry.
---@param _opts table
---@return { tag: string, count: integer, files: string[] }[]
function M.enumerate_tags(_opts)
  local tag_info = {} -- { [tag] = { count, files = set } }

  for _, orgfile in ipairs(all_org_files()) do
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
