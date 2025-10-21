local PickerState = require('telescope-orgmode.lib.state')
local operations = require('telescope-orgmode.lib.operations')
local config = require('telescope-orgmode.lib.config')
local org = require('telescope-orgmode.org')
local headlines_entry = require('telescope-orgmode.entry_maker.headlines')
local orgfiles_entry = require('telescope-orgmode.entry_maker.orgfiles')
local lib_actions = require('telescope-orgmode.lib.actions')
local highlights = require('telescope-orgmode.lib.highlights')

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

---Navigate to selected item
---@param item table Snacks item
local function navigate_to(item)
  if not item then
    return
  end
  local entry = item.__entry or item

  if not entry or not entry.filename then
    return
  end

  local success = lib_actions.execute_navigate(entry)
  if not success then
    vim.notify('Could not navigate to ' .. (entry.filename or 'unknown'), vim.log.levels.ERROR)
  end
end

---Refile source headline to selected destination
---@param source_headline table Original headline to refile
---@param item table Selected destination item
local function refile_action(source_headline, item)
  if not item then
    return
  end
  local entry = item.__entry or item

  if not entry or not entry.filename then
    return
  end

  local success, message = lib_actions.execute_refile(source_headline, entry)
  vim.notify(message, success and vim.log.levels.INFO or vim.log.levels.WARN)
end

---Insert link to selected item
---@param item table Selected item
local function insert_link_action(item)
  if not item then
    return
  end
  local entry = item.__entry or item

  if not entry or not entry.filename then
    return
  end

  -- Use lib_actions for insert link workflow
  local success, message = lib_actions.execute_insert_link(entry)
  vim.notify(message, success and vim.log.levels.INFO or vim.log.levels.ERROR)
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
  -- Snacks confirm signature: function(picker, item)
  -- Use vim.schedule to defer action until after picker closes cleanly
  if picker_type == 'search_headings' then
    picker_opts.confirm = function(picker, item)
      if not item then
        return
      end
      picker:close()
      vim.schedule(function()
        navigate_to(item)
      end)
    end
  elseif picker_type == 'refile_heading' then
    -- Get source headline before opening picker
    local source_headline = operations.get_current_headline()
    if not source_headline then
      vim.notify('No headline at cursor to refile', vim.log.levels.WARN)
      return nil
    end

    picker_opts.confirm = function(picker, item)
      if not item then
        return
      end
      picker:close()
      vim.schedule(function()
        refile_action(source_headline, item)
      end)
    end
  elseif picker_type == 'insert_link' then
    picker_opts.confirm = function(picker, item)
      if not item then
        return
      end
      picker:close()
      vim.schedule(function()
        insert_link_action(item)
      end)
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

  -- Capture current query (safely handle picker.input)
  local current_query = ''
  if picker.input and picker.input.filter then
    current_query = picker.input.filter.pattern or ''
  end

  -- Toggle the filter
  local current = state:get_filter('only_current_file')
  state:set_filter('only_current_file', not current)

  -- Close current picker
  picker:close()

  -- Open new picker with preserved query and filter
  create_picker(state, picker_type, base_opts, current_query)
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

---Convert tag_info array to Snacks items
---@param tag_infos table[] Array of tag info objects
---@return table[] Snacks items
local function create_tag_items(tag_infos)
  local tags_lib = require('telescope-orgmode.lib.tags')
  local items = {}

  for _, tag_info in ipairs(tag_infos) do
    local display_text = tags_lib.format_tag_display(tag_info)
    local item = {
      text = display_text,
      _formatted = { { display_text } },
      tag_info = tag_info, -- Keep for lazy preview function
    }

    table.insert(items, item)
  end

  return items
end

---Search tags and navigate to headlines with selected tag
---@param user_opts? table User options
---@return table|nil Snacks picker or nil if no tags found
function M.search_tags(user_opts)
  local tags_lib = require('telescope-orgmode.lib.tags')

  -- Merge config
  local opts = config:new('search_tags', user_opts)

  -- Load and sort tags
  local tags, sort_mode = tags_lib.load_and_sort_tags(opts)

  if #tags == 0 then
    vim.notify('No tags found in org files', vim.log.levels.INFO)
    return nil
  end

  -- Create items (preview computed lazily)
  local items = create_tag_items(tags)

  -- Transform keybindings to Snacks format
  local keys = transform_keybindings({ 'toggle_tag_sort', 'return_to_headlines' }, {
    toggle_tag_sort = function(picker)
      sort_mode = tags_lib.toggle_sort_mode(sort_mode)
      tags = tags_lib.sort_tags(tags, sort_mode)
      local new_items = create_tag_items(tags)
      picker:replace(new_items)
      vim.notify(string.format('Sort: %s', sort_mode), vim.log.levels.INFO)
    end,
    return_to_headlines = function(picker)
      picker:close()
      vim.schedule(function()
        M.search_headings({
          default_text = '',
          context = opts.context,
        })
      end)
    end,
  })

  local picker_opts = {
    title = opts.prompt_title,
    items = items,
    pattern = opts.default_text or '',
    format = format_item,
    -- Lazy preview function - computed on-demand when user navigates to item
    preview = function(ctx)
      if not ctx.item or not ctx.item.tag_info then
        return
      end
      local tag = ctx.item.tag_info.tag
      local preview_lines = tags_lib.get_tag_preview_lines(tag, { max_count = 50 })
      ctx.preview:set_lines(preview_lines)
      ctx.preview:highlight({ ft = 'org' })
    end,
    confirm = function(picker, item)
      if not item or not item.tag_info or not item.tag_info.tag then
        vim.notify('No tag selected', vim.log.levels.WARN)
        return
      end

      picker:close()
      vim.schedule(function()
        local tag = item.tag_info.tag
        M.search_headings({
          tag_query = '+' .. tag,
          default_text = '',
          context = {
            selected_tag = tag,
          },
        })
      end)
    end,
    win = {
      input = {
        keys = keys,
      },
    },
  }

  return require('snacks').picker(picker_opts)
end

return M
