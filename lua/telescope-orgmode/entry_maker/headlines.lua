require('telescope-orgmode.entry_maker.types')
local org = require('telescope-orgmode.org')

---Get location text by preference order (for width calculation)
---@param headline table Headline data
---@param preference string[] Priority order
---@return string location_text
local function get_location_text(headline, preference)
  preference = preference or { 'category', 'filename' }

  for _, key in ipairs(preference) do
    if key == 'category' and headline.category then
      return headline.category
    elseif key == 'filename' then
      return vim.fn.fnamemodify(headline.filename, ':t')
    elseif key == 'title' and headline.title then
      return headline.title
    end
  end

  return 'unknown'
end

---@param headline_results { filename: string, title: string, level: number, line_number: number, all_tags: string[], is_archived: boolean, todo_value?: string, todo_type?: 'TODO'|'DONE'|'', priority?: string, properties?: table<string, string> }[]
---@return OrgHeadlineEntry[], { location: number, tags: number, todo: number, priority: number }
local function index_headlines(headline_results, opts)
  local results = {}
  local widths = { location = 0, tags = 0, todo = 0, priority = 0 }

  for _, headline in ipairs(headline_results) do
    -- Calculate max widths from result set (using location preference)
    local location_text = get_location_text(headline, opts.location_preference)
    local location = string.format('%s:%i', location_text, headline.line_number)
    widths.location = math.max(widths.location, vim.fn.strdisplaywidth(location))

    if #headline.all_tags > 0 then
      local tags = table.concat(headline.all_tags, ':')
      widths.tags = math.max(widths.tags, vim.fn.strdisplaywidth(tags))
    end

    if headline.todo_value then
      widths.todo = math.max(widths.todo, vim.fn.strdisplaywidth(headline.todo_value))
    end
    if headline.priority then
      local priority_text = '[#' .. headline.priority .. ']'
      widths.priority = math.max(widths.priority, vim.fn.strdisplaywidth(priority_text))
    end

    local entry = {
      filename = headline.filename,
      headline = headline,
    }
    table.insert(results, entry)
  end

  -- Calculate property column widths (auto-hide: 0 width = column hidden)
  local property_widths = {}
  for _, prop_config in ipairs(opts.show_properties or {}) do
    local max_w = 0
    for _, headline in ipairs(headline_results) do
      local val = (headline.properties or {})[prop_config.name] or ''
      max_w = math.max(max_w, vim.fn.strdisplaywidth(val))
    end
    if max_w > 0 then
      property_widths[prop_config.name] = math.min(max_w, prop_config.max_width or 15)
    end
  end
  widths.properties = property_widths

  return results, widths
end

local M = {}
---Fetches entries from OrgApi and extracts the relevant information
---Routes to search-based or bulk loading based on tag_query presence
---@param opts { tag_query?: string, only_current_file?: boolean, archived?: boolean, max_depth?: number }
---@return OrgHeadlineEntry[], { todo: number, priority: number }
M.get_entries = function(opts)
  -- Route to search-based loader if tag_query provided
  local headline_data
  if opts.tag_query then
    headline_data = org.load_headlines_by_search(opts.tag_query, opts)
  else
    headline_data = org.load_headlines(opts)
  end

  return index_headlines(headline_data, opts)
end

return M
