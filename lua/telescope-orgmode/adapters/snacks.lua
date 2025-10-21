local PickerState = require('telescope-orgmode.lib.state')
local operations = require('telescope-orgmode.lib.operations')
local config = require('telescope-orgmode.lib.config')
local org = require('telescope-orgmode.org')
local headlines_entry = require('telescope-orgmode.entry_maker.headlines')
local orgfiles_entry = require('telescope-orgmode.entry_maker.orgfiles')
local lib_actions = require('telescope-orgmode.lib.actions')
local highlights = require('telescope-orgmode.lib.highlights')
local keybindings = require('telescope-orgmode.lib.keybindings')

local M = {}

---Format headline entry for display with highlights and column padding
---@param entry table Raw entry with headline data
---@param opts table Display options with widths
---@return table[] segments, string text Array of {text, highlight} segments and plain text for searching
local function format_headline_display(entry, opts)
  -- Use highlights library for segment generation
  return highlights.get_headline_segments(entry.headline, entry.filename, opts)
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
            mode = { 'i', 'n' },
            desc = 'Toggle between headlines and org files',
          },
          ['<C-f>'] = {
            function(picker)
              toggle_current_file(state, picker_type, base_opts, picker)
            end,
            mode = { 'i', 'n' },
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
  -- Capture current query (safely handle picker.input)
  local current_query = ''
  if picker.input and picker.input.filter then
    current_query = picker.input.filter.pattern or ''
  end

  -- Refresh function for keybindings library
  local function refresh(updated_state)
    -- Close current picker
    picker:close()
    -- Open new picker with preserved query
    create_picker(updated_state, picker_type, base_opts, current_query)
  end

  -- Execute action using keybindings library
  keybindings.execute_action('toggle_mode', {
    state = state,
    opts = base_opts,
    refresh_fn = refresh,
  })
end

---Toggle current file filter (headlines mode only)
---@param state PickerState
---@param picker_type string
---@param base_opts table
---@param picker table Current Snacks picker
function toggle_current_file(state, picker_type, base_opts, picker)
  -- Capture current query (safely handle picker.input)
  local current_query = ''
  if picker.input and picker.input.filter then
    current_query = picker.input.filter.pattern or ''
  end

  -- Refresh function for keybindings library
  local function refresh(updated_state)
    -- Close current picker
    picker:close()
    -- Open new picker with preserved query and filter
    create_picker(updated_state, picker_type, base_opts, current_query)
  end

  -- Execute action using keybindings library
  keybindings.execute_action('toggle_current_file', {
    state = state,
    opts = base_opts,
    refresh_fn = refresh,
  })
end

---Navigate to selected item
---@param item table Snacks item
local function navigate_to(item)
  local entry = item.__entry
  local success = lib_actions.execute_navigate(entry)
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

  -- Use lib_actions for refile workflow
  local success, message = lib_actions.execute_refile(source_headline, entry)
  vim.notify(message, success and vim.log.levels.INFO or vim.log.levels.WARN)
end

---Insert link to selected item
---@param item table Selected item
local function insert_link_action(item)
  local entry = item.__entry
  if not entry then
    vim.notify('Invalid entry', vim.log.levels.ERROR)
    return
  end

  -- Use lib_actions for insert link workflow
  local success, message = lib_actions.execute_insert_link(entry)
  vim.notify(message, success and vim.log.levels.INFO or vim.log.levels.ERROR)
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
