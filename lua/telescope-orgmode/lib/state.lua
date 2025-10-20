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

return PickerState
