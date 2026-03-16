local M = {}

-- Default field order for ordinal string construction.
-- Fields listed first get a slight ranking boost from fuzzy matchers.
M.DEFAULT_FIELD_ORDER = { 'state', 'priority', 'headline', 'location', 'tags', 'properties' }

---Build ordinal string from headline data based on field config
---@param fields string[] Ordered list of field names
---@param data table { headline, location, tags, line, opts }
---@return string ordinal
function M.build(fields, data)
  local parts = {}
  local builders = {
    headline = function()
      return data.line
    end,
    state = function()
      return data.headline.todo_value
    end,
    priority = function()
      return data.headline.priority and ('[#' .. data.headline.priority .. ']')
    end,
    location = function()
      return data.location
    end,
    tags = function()
      if not data.tags then
        return nil
      end
      if type(data.tags) == 'table' then
        return #data.tags > 0 and table.concat(data.tags, ':') or nil
      end
      return data.tags ~= '' and data.tags or nil
    end,
    properties = function()
      if not data.opts.show_properties or not data.headline.properties then
        return nil
      end
      local vals = {}
      for _, prop_config in ipairs(data.opts.show_properties) do
        local val = data.headline.properties[prop_config.name]
        if val and val ~= '' then
          table.insert(vals, val)
        end
      end
      return #vals > 0 and table.concat(vals, ' ') or nil
    end,
  }

  for _, field in ipairs(fields) do
    local builder = builders[field]
    if builder then
      local val = builder()
      if val then
        table.insert(parts, val)
      end
    end
  end

  return table.concat(parts, ' ')
end

-- Map from field name to the show_* flag that controls its visibility
local field_visibility = {
  state = 'show_todo_state',
  priority = 'show_priority',
  headline = nil, -- always included
  location = 'show_location',
  tags = 'show_tags',
  properties = 'show_properties',
}

---Check if a field is active based on opts
---@param field string Field name
---@param opts table Config with show_* flags
---@return boolean
local function is_field_active(field, opts)
  local flag = field_visibility[field]
  if not flag then
    return true -- headline is always active
  end
  local val = opts[flag]
  if type(val) == 'table' then
    return #val > 0 -- show_properties = {} means inactive
  end
  return val == true
end

---Resolve effective ordinal fields from config
---@param opts table Config with show_* flags and optional ordinal_fields
---@return string[]
function M.resolve_fields(opts)
  if opts.ordinal_fields then
    return opts.ordinal_fields
  end

  -- Filter DEFAULT_FIELD_ORDER by active show_* flags
  local fields = {}
  for _, field in ipairs(M.DEFAULT_FIELD_ORDER) do
    if is_field_active(field, opts) then
      table.insert(fields, field)
    end
  end
  return fields
end

return M
