require('telescope-orgmode.entry_maker.types')
local org = require('telescope-orgmode.org')
local entry_display = require('telescope.pickers.entry_display')
local highlights = require('telescope-orgmode.highlights')

---@param headline_results { filename: string, title: string, level: number, line_number: number, all_tags: string[], is_archived: boolean, todo_value?: string, todo_type?: 'TODO'|'DONE'|'', priority?: string }[]
---@return OrgHeadlineEntry[], { todo: number, priority: number }
local function index_headlines(headline_results, opts)
  local results = {}
  local widths = { todo = 0, priority = 0 }

  for _, headline in ipairs(headline_results) do
    -- Calculate max widths from result set
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

---Entry-Maker for Telescope
---@param opts { location_width?: number, tags_width?: number, show_todo_state?: boolean, show_priority?: boolean, widths?: { todo: number, priority: number } }
---@return fun(entry: OrgHeadlineEntry):MatchEntry
M.make_entry = function(opts)
  local widths = opts.widths or { todo = 0, priority = 0 }

  -- Build displayer items based on configuration
  local items = {
    { width = vim.F.if_nil(opts.location_width, 24) },
    { width = vim.F.if_nil(opts.tags_width, 20) },
  }

  if opts.show_todo_state and widths.todo > 0 then
    table.insert(items, { width = widths.todo })
  end

  if opts.show_priority and widths.priority > 0 then
    table.insert(items, { width = widths.priority })
  end

  table.insert(items, { remaining = true })

  local displayer = entry_display.create({
    separator = ' ',
    items = items,
  })

  ---@param entry MatchEntry
  local function make_display(entry)
    local columns = {
      { entry.location, 'TelescopeResultsComment' },
      { entry.tags, '@org.tag' },
    }

    if opts.show_todo_state and entry.todo_value then
      local hl = highlights.get_todo_highlight(entry.todo_value, entry.todo_type)
      table.insert(columns, { entry.todo_value, hl })
    elseif opts.show_todo_state and widths.todo > 0 then
      table.insert(columns, { '', '' })
    end

    if opts.show_priority and entry.priority then
      local priority_text = '[#' .. entry.priority .. ']'
      local hl = highlights.get_priority_highlight(entry.priority)
      table.insert(columns, { priority_text, hl })
    elseif opts.show_priority and widths.priority > 0 then
      table.insert(columns, { '', '' })
    end

    table.insert(columns, { entry.line, '@org.headline.level' .. entry.headline_level })

    return displayer(columns)
  end

  return function(entry)
    local headline = entry.headline
    local lnum = headline.line_number
    local location = string.format('%s:%i', vim.fn.fnamemodify(entry.filename, ':t'), lnum)
    local line = string.format('%s %s', string.rep('*', headline.level), headline.title)
    local tags = table.concat(headline.all_tags, ':')

    -- Build ordinal field based on visible columns
    local ordinal_parts = { tags, line, location }

    if opts.show_todo_state and headline.todo_value then
      table.insert(ordinal_parts, 1, headline.todo_value)
    end

    if opts.show_priority and headline.priority then
      table.insert(ordinal_parts, 1, '[#' .. headline.priority .. ']')
    end

    local ordinal = table.concat(ordinal_parts, ' ')

    return {
      value = entry,
      ordinal = ordinal,
      filename = entry.filename,
      lnum = lnum,
      display = make_display,
      location = location,
      line = line,
      tags = tags,
      headline_level = headline.level,
      todo_value = headline.todo_value,
      todo_type = headline.todo_type,
      priority = headline.priority,
    }
  end
end

return M
