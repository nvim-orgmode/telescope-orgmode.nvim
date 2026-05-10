local OrgApi = require('orgmode.api')
local OrgAgendaApi = require('orgmode.api.agenda')

local M = {}

-- Source-Bridge: alle Pipeline-Loader delegieren an einen Source
-- (Default: telescope-orgmode.lib.sources.default). Auflösung erfolgt über
-- sources.resolve_source mit der globalen Config — so wirkt sowohl
-- opts.source als auch picker_defaults[*].source.
local sources = require('telescope-orgmode.lib.sources')

local function get_config()
  local cfg = require('telescope-orgmode.lib.config')
  return {
    sources = cfg.defaults.sources,
    default_source = cfg.defaults.default_source,
    picker_defaults = cfg.picker_defaults,
    source_setup = cfg.defaults.source_setup,
  }
end

local function resolve(opts)
  return sources.resolve_source(opts, get_config())
end

function M.load_files(opts)
  opts = opts or {}
  local source = resolve(opts)
  local results = source.enumerate_files(opts)
  for _, entry in ipairs(results) do
    sources.normalize_file(entry)
  end
  return results
end

function M.load_headlines(opts)
  opts = opts or {}
  local source = resolve(opts)
  local results = source.enumerate_headlines(opts)
  for _, entry in ipairs(results) do
    sources.normalize_headline(entry)
  end
  return results
end

--- Load headlines using orgmode Search API with tag-based filtering.
--- Bevorzugt source.enumerate_headlines_by_query; bei nil wird auf
--- enumerate_headlines + Search:new()-Post-Filter zurückgefallen.
---@param query string Orgmode search query (e.g., "+work", "tag1|tag2")
---@param opts table
---@return table[] headline entries
function M.load_headlines_by_search(query, opts)
  opts = opts or {}
  local source = resolve(opts)

  local results
  if source.enumerate_headlines_by_query then
    results = source.enumerate_headlines_by_query(query, opts)
  else
    sources.notify_fallback(source)
    local Search = require('orgmode.files.elements.search')
    local search = Search:new(query)
    local headlines = source.enumerate_headlines(opts)
    results = {}
    local max_count = opts.max_count
    for _, headline in ipairs(headlines) do
      if max_count and #results >= max_count then
        break
      end
      -- Search:check erwartet eine Tabelle mit tags / props / todo. Im
      -- Fallback-Pfad steht uns nur das normalisierte Schema zur Verfügung.
      local matches = search:check({
        tags = headline.all_tags or {},
        props = headline.properties or {},
        todo = headline.todo_value,
      })
      if matches then
        table.insert(results, headline)
      end
    end
  end

  for _, entry in ipairs(results) do
    sources.normalize_headline(entry)
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
  -- Handle invalid input
  if not filename or filename == '' then
    return nil
  end

  local success, api_file = pcall(OrgApi.load, filename)
  if not success then
    return nil
  end

  if not api_file then
    return nil
  end

  return api_file
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

---Load tags with occurrence counts, respecting opts.source and
---opts.archived.
---@param opts? table
---@return { tag: string, count: number, files: string[] }[]
function M.load_tags(opts)
  opts = opts or {}
  local tag_collection = require('telescope-orgmode.tag_collection')
  local tags = tag_collection.collect_tags_with_counts(opts)

  -- Sort by frequency by default
  return tag_collection.sort_tags(tags, 'frequency')
end

---Returns headlines tagged with `tag` in the full headline schema
---(todo_value, priority, ...). Backed by load_headlines_by_search('+'..tag).
---@param tag string Tag to search for
---@param opts? { max_count?: number, archived?: boolean, source?: string }
---@return table[] headline entries
function M.get_headlines_for_tag(tag, opts)
  opts = opts or {}
  return M.load_headlines_by_search('+' .. tag, vim.tbl_extend('keep', { max_count = 50 }, opts))
end

return M
