---@class PickerState
---@field current 'headlines'|'orgfiles'
---@field next 'headlines'|'orgfiles'
---@field filters table
local PickerState = {}

---@param initial_mode 'headlines'|'orgfiles'
---@return PickerState
function PickerState:new(initial_mode)
  local instance = {
    current = initial_mode or 'headlines',
    next = initial_mode == 'headlines' and 'orgfiles' or 'headlines',
    filters = {},
  }
  setmetatable(instance, { __index = self })
  return instance
end

---Toggle between headlines and orgfiles modes
---@return nil
function PickerState:toggle()
  self.current, self.next = self.next, self.current
end

---@return 'headlines'|'orgfiles'
function PickerState:get_current()
  return self.current
end

---@param key string
---@param value any
---@return nil
function PickerState:set_filter(key, value)
  self.filters[key] = value
end

---@param key string
---@return any
function PickerState:get_filter(key)
  return self.filters[key]
end

---@return table
function PickerState:get_all_filters()
  return self.filters
end

---Generate title context string showing active filters
---Format: "[tag:work] [file:todo.org]"
---@return string
function PickerState:get_title_context()
  local parts = {}

  -- Tag filter
  if self.filters.tag_query then
    table.insert(parts, string.format('[tag:%s]', self.filters.tag_query))
  end

  -- File filter (only_current_file)
  if self.filters.only_current_file then
    -- Extract filename from path for brevity
    local file = self.filters.current_file or 'current'
    local filename = file:match('([^/]+)$') or file
    table.insert(parts, string.format('[file:%s]', filename))
  end

  -- Archived filter (only if explicitly disabled)
  if self.filters.archived == false then
    table.insert(parts, '[no-archive]')
  end

  -- Max depth filter (only if not default)
  if self.filters.max_depth and self.filters.max_depth > 0 then
    table.insert(parts, string.format('[depth:%d]', self.filters.max_depth))
  end

  return table.concat(parts, ' ')
end

---Construct full picker title with filter context
---Framework-agnostic title construction for adapter use
---@param base_title string Base title without context (e.g., "Org Headlines")
---@return string Full title with context (e.g., "Org Headlines [file:todo.org]")
function PickerState:get_full_title(base_title)
  local context = self:get_title_context()
  return context ~= '' and (base_title .. ' ' .. context) or base_title
end

return PickerState
