local PickerState = require('telescope-orgmode.lib.state')
local operations = require('telescope-orgmode.lib.operations')
local config = require('telescope-orgmode.lib.config')
local org = require('telescope-orgmode.org')
local headlines_entry = require('telescope-orgmode.entry_maker.headlines')
local orgfiles_entry = require('telescope-orgmode.entry_maker.orgfiles')

local M = {}

---Get highlight group for TODO state
---@param todo_type string|nil
---@return string|nil
local function get_todo_highlight(todo_type)
  if todo_type == 'TODO' then
    return '@org.keyword.todo'
  elseif todo_type == 'DONE' then
    return '@org.keyword.done'
  end
  return nil
end

---Get highlight group for headline depth
---@param level number Headline level (1-9)
---@return string Highlight group
local function get_level_highlight(level)
  -- Cycle through org headline levels
  local level_mod = ((level - 1) % 8) + 1
  return '@org.headline.level' .. level_mod
end

---Pad or truncate string to exact width
---@param str string
---@param width number
---@return string
local function pad(str, width)
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

---Format headline entry for display with highlights and column padding
---@param entry table Raw entry with headline data
---@param opts table Display options with widths
---@return table[] segments, string text Array of {text, highlight} segments and plain text for searching
local function format_headline_display(entry, opts)
  local headline = entry.headline
  local segments = {}
  local text_parts = {}
  local widths = opts.widths or {}

  -- Location (filename:line) - dimmed, padded
  if opts.show_location then
    if widths.location and widths.location > 0 then
      local location = string.format('%s:%i', vim.fn.fnamemodify(entry.filename, ':t'), headline.line_number)
      local max_width = opts.location_max_width and math.min(widths.location, opts.location_max_width)
        or widths.location
      table.insert(segments, { pad(location, max_width) .. '  ', 'Comment' })
      table.insert(text_parts, location)
    end
  end

  -- Tags - special highlight, padded (ALWAYS reserve space if show_tags is true)
  if opts.show_tags then
    if widths.tags and widths.tags > 0 then
      local max_width = opts.tags_max_width and math.min(widths.tags, opts.tags_max_width) or widths.tags
      if #headline.all_tags > 0 then
        local tags = ':' .. table.concat(headline.all_tags, ':') .. ':'
        table.insert(segments, { pad(tags, max_width) .. ' ', '@org.tag' })
        table.insert(text_parts, tags)
      else
        -- Add empty space to maintain column alignment
        table.insert(segments, { string.rep(' ', max_width + 1) })
      end
    end
  end

  -- TODO state - colored based on type, padded (ALWAYS reserve space if show_todo_state is true)
  if opts.show_todo_state then
    if widths.todo and widths.todo > 0 then
      if headline.todo_value then
        local hl = get_todo_highlight(headline.todo_type)
        table.insert(segments, { pad(headline.todo_value, widths.todo) .. ' ', hl })
        table.insert(text_parts, headline.todo_value)
      else
        -- Add empty space to maintain column alignment
        table.insert(segments, { string.rep(' ', widths.todo + 1) })
      end
    end
  end

  -- Priority - warning color, padded (ALWAYS reserve space if show_priority is true)
  if opts.show_priority then
    if widths.priority and widths.priority > 0 then
      if headline.priority then
        local priority = '[#' .. headline.priority .. ']'
        table.insert(segments, { pad(priority, widths.priority) .. ' ', '@org.priority' })
        table.insert(text_parts, priority)
      else
        -- Add empty space to maintain column alignment
        table.insert(segments, { string.rep(' ', widths.priority + 1) })
      end
    end
  end

  -- Title with level indicator - colored by depth
  local title = string.format('%s %s', string.rep('*', headline.level), headline.title)
  local level_hl = get_level_highlight(headline.level)
  table.insert(segments, { title, level_hl })
  table.insert(text_parts, title)

  -- Return both formatted segments and plain text for searching
  return segments, table.concat(text_parts, ' ')
end

---Format orgfile entry for display with highlights
---@param entry table Raw entry with filename and optional title
---@return table[] segments, string text Array of {text, highlight} segments and plain text for searching
local function format_orgfile_display(entry)
  local text = entry.title and entry.title ~= '' and entry.title or vim.fn.fnamemodify(entry.filename, ':t')
  return { { text } }, text
end

---Create Snacks finder for current state
---@param state PickerState
---@param opts table
---@return table Snacks items table
local function create_finder(state, opts)
  local mode = state:get_current()

  if mode == 'headlines' then
    -- Get all filters from state
    local filters = state:get_all_filters()
    local headline_opts = vim.tbl_extend('force', opts, filters)

    -- Load headlines with filters and get column widths
    local results, widths = headlines_entry.get_entries(headline_opts)
    headline_opts.widths = widths

    -- Convert to Snacks items with formatted display
    local items = {}
    for _, raw_entry in ipairs(results) do
      local segments, search_text = format_headline_display(raw_entry, headline_opts)
      table.insert(items, {
        -- Store formatted segments for custom formatter
        _formatted = segments,
        -- Plain text for searching/filtering
        text = search_text,
        file = raw_entry.filename,
        pos = { raw_entry.headline.line_number, 0 }, -- {line, col} for preview positioning
        preview = 'file', -- Tell preview to use file previewer
        -- Store original entry data for actions
        __entry = raw_entry,
      })
    end
    return items
  else -- orgfiles
    local results = orgfiles_entry.get_entries(opts)

    -- Convert to Snacks items with formatted display
    local items = {}
    for _, raw_entry in ipairs(results) do
      local segments, search_text = format_orgfile_display(raw_entry)
      table.insert(items, {
        -- Store formatted segments for custom formatter
        _formatted = segments,
        -- Plain text for searching/filtering
        text = search_text,
        file = raw_entry.filename,
        preview = 'file', -- Tell preview to use file previewer
        -- Store original entry data for actions
        __entry = raw_entry,
      })
    end
    return items
  end
end

---Custom format function for items with pre-formatted segments
---@param item table
---@return table[] Array of highlight segments
local function format_item(item)
  -- Return pre-formatted segments if available
  if item._formatted then
    return item._formatted
  end
  -- Fallback to plain text
  return { { item.text or tostring(item) } }
end

---Create new picker with current state
---@param state PickerState
---@param picker_type string
---@param base_opts table
---@param preserved_query? string
---@return table Snacks picker
local function create_picker(state, picker_type, base_opts, preserved_query)
  local picker_config = config:new(picker_type, base_opts)
  local mode = state:get_current()

  local picker_opts = {
    title = picker_config.prompt_titles[mode],
    items = create_finder(state, picker_config),
    pattern = preserved_query or '',
    preview = 'preview', -- Use default file previewer
    format = format_item, -- Custom formatter with highlights
    win = {
      input = {
        keys = {
          ['<C-Space>'] = {
            function(picker)
              toggle_mode(state, picker_type, base_opts, picker)
            end,
            desc = 'Toggle between headlines and org files',
          },
          ['<C-f>'] = {
            function(picker)
              toggle_current_file(state, picker_type, base_opts, picker)
            end,
            desc = 'Toggle current file filter',
          },
        },
      },
    },
  }

  -- Add picker-specific confirm action
  if picker_type == 'search_headings' then
    picker_opts.confirm = function(item)
      navigate_to(item)
    end
  elseif picker_type == 'refile_heading' then
    -- Get source headline before opening picker
    local source_headline = operations.get_current_headline()
    if not source_headline then
      vim.notify('No headline at cursor to refile', vim.log.levels.WARN)
      return nil
    end

    picker_opts.confirm = function(item)
      refile_action(source_headline, item)
    end
  elseif picker_type == 'insert_link' then
    picker_opts.confirm = function(item)
      insert_link_action(item)
    end
  end

  return require('snacks').picker(picker_opts)
end

---Toggle between headlines and orgfiles mode
---@param state PickerState
---@param picker_type string
---@param base_opts table
---@param picker table Current Snacks picker
function toggle_mode(state, picker_type, base_opts, picker)
  -- Capture current query
  local current_query = picker.input.filter.pattern

  -- Toggle state
  state:toggle()

  -- Close current picker
  picker:close()

  -- Open new picker with preserved query
  create_picker(state, picker_type, base_opts, current_query)
end

---Toggle current file filter (headlines mode only)
---@param state PickerState
---@param picker_type string
---@param base_opts table
---@param picker table Current Snacks picker
function toggle_current_file(state, picker_type, base_opts, picker)
  -- Only works in headlines mode
  if state:get_current() ~= 'headlines' then
    return
  end

  -- Capture current query
  local current_query = picker.input.filter.pattern

  -- Toggle the filter
  local current = state:get_filter('only_current_file')
  state:set_filter('only_current_file', not current)

  -- Close current picker
  picker:close()

  -- Open new picker with preserved query and filter
  create_picker(state, picker_type, base_opts, current_query)
end

---Navigate to selected item
---@param item table Snacks item
local function navigate_to(item)
  local success = operations.navigate_to(item.file, item.line)
  if not success then
    vim.notify('Could not navigate to ' .. item.file, vim.log.levels.ERROR)
  end
end

---Refile source headline to selected destination
---@param source_headline table Original headline to refile
---@param item table Selected destination item
local function refile_action(source_headline, item)
  local entry = item.__entry
  if not entry then
    vim.notify('Invalid destination entry', vim.log.levels.ERROR)
    return
  end

  -- Get API destination object
  local destination
  if entry.headline then
    -- Refiling to headline
    destination = org.get_api_headline(entry.filename, entry.headline.position.start_line)
  else
    -- Refiling to org file
    destination = org.get_api_file(entry.filename)
  end

  if not destination then
    vim.notify('Could not find destination', vim.log.levels.ERROR)
    return
  end

  -- Perform refile with TOCTOU protection
  local success = operations.refile(source_headline, destination)

  if not success then
    vim.notify('Refile failed - source may have been deleted', vim.log.levels.WARN)
    return
  end

  vim.notify('Refiled successfully', vim.log.levels.INFO)
end

---Insert link to selected item
---@param item table Selected item
local function insert_link_action(item)
  local entry = item.__entry
  if not entry then
    vim.notify('Invalid entry', vim.log.levels.ERROR)
    return
  end

  -- Get API object
  local link_target
  if entry.headline then
    -- Link to headline
    link_target = org.get_api_headline(entry.filename, entry.headline.position.start_line)
  else
    -- Link to org file
    link_target = org.get_api_file(entry.filename)
  end

  if not link_target then
    vim.notify('Could not find link target', vim.log.levels.ERROR)
    return
  end

  -- Insert link
  local success = operations.insert_link(link_target)

  if not success then
    vim.notify('Failed to insert link', vim.log.levels.ERROR)
    return
  end

  vim.notify('Link inserted', vim.log.levels.INFO)
end

---Search and navigate to headlines
---@param opts? table User options
---@return table Snacks picker
function M.search_headings(opts)
  opts = opts or {}
  local picker_config = config:new('search_headings', opts)

  -- Initialize state
  local state = PickerState:new(picker_config.mode, {
    only_current_file = picker_config.only_current_file,
    archived = picker_config.archived,
    max_depth = picker_config.max_depth,
  })

  return create_picker(state, 'search_headings', opts)
end

---Refile current headline to selected destination
---@param opts? table User options
---@return table|nil Snacks picker or nil if no source headline
function M.refile_heading(opts)
  opts = opts or {}
  local picker_config = config:new('refile_heading', opts)

  -- Initialize state
  local state = PickerState:new(picker_config.mode, {
    only_current_file = picker_config.only_current_file,
    archived = picker_config.archived,
    max_depth = picker_config.max_depth,
  })

  return create_picker(state, 'refile_heading', opts)
end

---Insert link to selected headline or file
---@param opts? table User options
---@return table Snacks picker
function M.insert_link(opts)
  opts = opts or {}
  local picker_config = config:new('insert_link', opts)

  -- Initialize state
  local state = PickerState:new(picker_config.mode, {
    only_current_file = picker_config.only_current_file,
    archived = picker_config.archived,
    max_depth = picker_config.max_depth,
  })

  return create_picker(state, 'insert_link', opts)
end

return M
