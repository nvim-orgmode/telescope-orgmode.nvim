-- Telescope entry makers.
--
-- Turns the framework-agnostic entries produced by entry_maker/ into
-- telescope MatchEntries backed by an entry_display displayer. This lives in
-- adapters/ because entry_display is telescope-specific; entry_maker/ stays
-- agnostic and is shared with the snacks adapter.

require('telescope-orgmode.entry_maker.types')
local highlights = require('telescope-orgmode.lib.highlights')
local ordinal_mod = require('telescope-orgmode.lib.ordinal')

local M = {}

---Entry-Maker for Telescope
---@param opts { location_max_width?: number, tags_max_width?: number, show_location?: boolean, show_tags?: boolean, show_todo_state?: boolean, show_priority?: boolean, widths?: { location: number, tags: number, todo: number, priority: number } }
---@return fun(entry: OrgHeadlineEntry):MatchEntry
M.make_headline_entry = function(opts)
  local entry_display = require('telescope.pickers.entry_display')
  local widths = opts.widths or { location = 0, tags = 0, todo = 0, priority = 0 }

  -- Build displayer items based on configuration
  local items = {}

  if opts.show_location and widths.location > 0 then
    local location_width = opts.location_max_width and math.min(widths.location, opts.location_max_width)
      or widths.location
    table.insert(items, { width = location_width })
  end

  -- Property columns (after location, before tags)
  if opts.show_properties then
    for _, prop_config in ipairs(opts.show_properties) do
      local prop_width = (widths.properties or {})[prop_config.name]
      if prop_width and prop_width > 0 then
        table.insert(items, { width = prop_width })
      end
    end
  end

  if opts.show_tags and widths.tags > 0 then
    local tags_width = opts.tags_max_width and math.min(widths.tags, opts.tags_max_width) or widths.tags
    table.insert(items, { width = tags_width })
  end

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
    local columns = {}

    if opts.show_location and entry.location then
      table.insert(columns, { entry.location, 'TelescopeResultsComment' })
    elseif opts.show_location and widths.location > 0 then
      table.insert(columns, { '', '' })
    end

    -- Property columns (after location, before tags)
    if opts.show_properties then
      for _, prop_config in ipairs(opts.show_properties) do
        local prop_width = (widths.properties or {})[prop_config.name]
        if prop_width and prop_width > 0 then
          local val = (entry.properties or {})[prop_config.name] or ''
          local hl = prop_config.highlight or 'Comment'
          table.insert(columns, { val, hl })
        end
      end
    end

    if opts.show_tags and entry.tags and #entry.tags > 0 then
      table.insert(columns, { entry.tags, '@org.tag' })
    elseif opts.show_tags and widths.tags > 0 then
      table.insert(columns, { '', '' })
    end

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

  local ordinal_fields = ordinal_mod.resolve_fields(opts)

  return function(entry)
    local headline = entry.headline
    local lnum = headline.line_number
    local location = string.format('%s:%i', vim.fn.fnamemodify(entry.filename, ':t'), lnum)
    local line = string.format('%s %s', string.rep('*', headline.level), headline.title)
    local tags = table.concat(headline.all_tags, ':')

    local ordinal = ordinal_mod.build(ordinal_fields, {
      headline = headline,
      location = location,
      tags = tags,
      line = line,
      opts = opts,
    })

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
      properties = headline.properties,
    }
  end
end

---Entry-Maker for Telescope
---@return fun(entry: OrgFileEntry):MatchEntry
M.make_orgfile_entry = function()
  local entry_display = require('telescope.pickers.entry_display')
  local orgfile_displayer = entry_display.create({
    separator = ' ',
    items = {
      { remaining = true },
    },
  })

  ---@param entry MatchEntry
  local function make_display(entry)
    return orgfile_displayer({ entry.line })
  end

  return function(entry)
    local lnum = nil
    local location = vim.fn.fnamemodify(entry.filename, ':t')
    local line = entry.title or location
    local tags = ''
    local ordinal = line

    return {
      value = entry,
      ordinal = ordinal,
      filename = entry.filename,
      lnum = lnum,
      display = make_display,
      location = location,
      line = line,
      tags = tags,
    }
  end
end

return M
