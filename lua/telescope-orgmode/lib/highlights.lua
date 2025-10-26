local M = {}

---Get highlight group for TODO keyword
---Uses orgmode's highlight map for custom keyword support (WAITING, NEXT, etc.)
---@param todo_value string|nil The TODO keyword (e.g., "TODO", "DONE", "WAITING")
---@param todo_type 'TODO'|'DONE'|'' The TODO type
---@return string|nil highlight_group Neovim highlight group name
function M.get_todo_highlight(todo_value, todo_type)
  if not todo_value then
    return nil
  end

  -- Get orgmode's highlight mapping (includes custom keywords)
  local ok, hl_mod = pcall(require, 'orgmode.colors.highlights')
  if not ok then
    -- Orgmode not loaded - use basic defaults
    return todo_type == 'DONE' and '@org.keyword.done' or '@org.keyword.todo'
  end

  local hl_map = hl_mod.get_agenda_hl_map()

  -- Return custom highlight if defined, otherwise default based on type
  return hl_map[todo_value] or (todo_type == 'DONE' and '@org.keyword.done') or '@org.keyword.todo'
end

---Get highlight group for headline level
---@param level number Headline depth (1-9)
---@return string highlight_group
function M.get_level_highlight(level)
  -- Cycle through org headline levels
  local level_mod = ((level - 1) % 8) + 1
  return '@org.headline.level' .. level_mod
end

---Get highlight group for priority
---@param priority string|nil The priority letter (e.g., "A", "B", "C")
---@return string|nil highlight_group Neovim highlight group name
function M.get_priority_highlight(priority)
  if not priority then
    return nil
  end

  if priority == 'A' then
    return '@org.priority.highest'
  elseif priority == 'B' then
    return '@org.priority.default'
  elseif priority == 'C' then
    return '@org.priority.lowest'
  end

  -- Unknown priority letter
  return '@org.priority.default'
end

---Pad or truncate string to exact width
---@param str string
---@param width number
---@return string
function M.pad(str, width)
  local len = vim.fn.strdisplaywidth(str)
  if len > width then
    -- Truncate and add ellipsis
    return vim.fn.strcharpart(str, 0, width - 1) .. '…'
  elseif len < width then
    -- Pad with spaces
    return str .. string.rep(' ', width - len)
  end
  return str
end

---Get location text by preference order
---@param headline table Headline data
---@param filename string File path
---@param preference string[] Priority order for location display
---@return string location Location text
local function get_location_by_preference(headline, filename, preference)
  preference = preference or { 'category', 'filename' }

  for _, key in ipairs(preference) do
    if key == 'category' and headline.category then
      return headline.category
    elseif key == 'filename' then
      return vim.fn.fnamemodify(filename, ':t')
    elseif key == 'title' and headline.title then
      return headline.title
    end
  end

  return 'unknown'
end

---Build headline display segments (framework-agnostic data structure)
---Returns both segments for display and plain text for searching
---@param headline table Headline data from entry
---@param filename string File path
---@param opts table Display options {show_location, show_tags, show_todo_state, show_priority, show_level, widths}
---@return table[] segments Array of {text, highlight} or {text} segments
---@return string plain_text Plain text for searching
function M.get_headline_segments(headline, filename, opts)
  local segments = {}
  local text_parts = {}
  local widths = opts.widths or {}

  -- Location - dimmed, padded (uses preference: category > filename by default)
  if opts.show_location and widths.location and widths.location > 0 then
    local location_text = get_location_by_preference(headline, filename, opts.location_preference)
    local location = string.format('%s:%i', location_text, headline.line_number)
    local max_width = opts.location_max_width and math.min(widths.location, opts.location_max_width) or widths.location
    table.insert(segments, { M.pad(location, max_width) .. '  ', 'Comment' })
    table.insert(text_parts, location)
  end

  -- Tags - special highlight, padded (ALWAYS reserve space if show_tags is true)
  if opts.show_tags and widths.tags and widths.tags > 0 then
    local max_width = opts.tags_max_width and math.min(widths.tags, opts.tags_max_width) or widths.tags
    if #headline.all_tags > 0 then
      local tags = table.concat(headline.all_tags, ':')
      table.insert(segments, { M.pad(tags, max_width) .. ' ', '@org.tag' })
      table.insert(text_parts, tags)
    else
      -- Add empty space to maintain column alignment
      table.insert(segments, { string.rep(' ', max_width + 1) })
    end
  end

  -- TODO state - colored based on type, padded (ALWAYS reserve space if show_todo_state is true)
  if opts.show_todo_state and widths.todo and widths.todo > 0 then
    if headline.todo_value then
      local hl = M.get_todo_highlight(headline.todo_value, headline.todo_type)
      table.insert(segments, { M.pad(headline.todo_value, widths.todo) .. ' ', hl })
      table.insert(text_parts, headline.todo_value)
    else
      -- Add empty space to maintain column alignment
      table.insert(segments, { string.rep(' ', widths.todo + 1) })
    end
  end

  -- Priority - warning color, padded (ALWAYS reserve space if show_priority is true)
  if opts.show_priority and widths.priority and widths.priority > 0 then
    if headline.priority then
      local priority_str = '[#' .. headline.priority .. ']'
      table.insert(
        segments,
        { M.pad(priority_str, widths.priority) .. ' ', M.get_priority_highlight(headline.priority) }
      )
      table.insert(text_parts, priority_str)
    else
      -- Add empty space to maintain column alignment
      table.insert(segments, { string.rep(' ', widths.priority + 1) })
    end
  end

  -- Title with level indicator - colored by depth
  local title = string.format('%s %s', string.rep('*', headline.level), headline.title)
  local level_hl = M.get_level_highlight(headline.level)
  table.insert(segments, { title, level_hl })
  table.insert(text_parts, title)

  -- Return both formatted segments and plain text for searching
  return segments, table.concat(text_parts, ' ')
end

return M
