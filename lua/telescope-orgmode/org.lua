local OrgApi = require('orgmode.api')
local OrgAgendaApi = require('orgmode.api.agenda')

local M = {}

-- Source bridge: every pipeline loader delegates to a source (default:
-- telescope-orgmode.lib.sources.default), resolved through
-- sources.resolve_source against the global config, so both opts.source
-- and picker_defaults[*].source take effect.
--
-- Sources enumerate what exists; the policy chains below decide what the
-- user sees. They are deliberately not uniform: load_files ignores
-- only_current_file, and get_headlines_for_tag applies no policy at all.
local sources = require('telescope-orgmode.lib.sources')
local filters = require('telescope-orgmode.lib.entry_filters')

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

---Policy chain shared by the two headline loaders.
---@param results table[]
---@param opts table
---@return table[]
local function apply_headline_policy(results, opts)
  results = filters.only_current_file(results, opts)
  results = filters.exclude_archive_files(results, opts)
  results = filters.exclude_archived_subtrees(results, opts)
  results = filters.max_depth(results, opts)
  return filters.sort_by_file_mtime(results)
end

function M.load_files(opts)
  opts = opts or {}
  local source = resolve(opts)
  -- No only_current_file: the files picker has never scoped to the
  -- current file, and the orgfiles path forwards raw user opts.
  local results = filters.exclude_archive_files(source.enumerate_files(opts), opts)
  results = filters.sort_by_file_mtime(results)
  for _, entry in ipairs(results) do
    sources.normalize_file(entry)
  end
  return results
end

function M.load_headlines(opts)
  opts = opts or {}
  local source = resolve(opts)
  local results = apply_headline_policy(source.enumerate_headlines(opts), opts)
  for _, entry in ipairs(results) do
    sources.normalize_headline(entry)
  end
  return results
end

---Runs `query` against the source: uses the source's own query support
---when it has any, otherwise falls back to enumerate_headlines plus a
---Search post-filter.
---@param source OrgmodeSource
---@param query string
---@param opts table
---@return table[]
local function enumerate_by_query(source, query, opts)
  if source.enumerate_headlines_by_query then
    return source.enumerate_headlines_by_query(query, opts)
  end

  sources.notify_fallback(source)
  local Search = require('orgmode.files.elements.search')
  local search = Search:new(query)

  local results = {}
  for _, headline in ipairs(source.enumerate_headlines(opts)) do
    -- Search:check expects a table with tags / props / todo. The
    -- fallback path only has the normalized schema to work with.
    local matches = search:check({
      tags = headline.all_tags or {},
      props = headline.properties or {},
      todo = headline.todo_value,
    })
    if matches then
      table.insert(results, headline)
    end
  end
  return results
end

--- Load headlines using orgmode Search API with tag-based filtering.
---@param query string Orgmode search query (e.g., "+work", "tag1|tag2")
---@param opts table
---@return table[] headline entries
function M.load_headlines_by_search(query, opts)
  opts = opts or {}
  local source = resolve(opts)
  local results = apply_headline_policy(enumerate_by_query(source, query, opts), opts)
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

---Load tags with occurrence counts, respecting opts.source.
---
---`.org_archive` files are always excluded; opts.archived has no effect
---here, because a tag spans files and cannot be filtered out of a
---finished tag entry.
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
---(todo_value, priority, ...).
---
---Deliberately policy-free: the tag preview has always shown raw file
---order and included archived subtrees. It caps the result itself
---instead, so truncation does not depend on an ordering step.
---@param tag string Tag to search for
---@param opts? { max_count?: number, source?: string }
---@return table[] headline entries
function M.get_headlines_for_tag(tag, opts)
  opts = vim.tbl_extend('keep', opts or {}, { max_count = 50 })
  local source = resolve(opts)

  local results = {}
  for _, headline in ipairs(source.enumerate_headlines(opts)) do
    if vim.tbl_contains(headline.all_tags or {}, tag) then
      table.insert(results, headline)
      if #results >= opts.max_count then
        break
      end
    end
  end

  for _, entry in ipairs(results) do
    sources.normalize_headline(entry)
  end
  return results
end

return M
