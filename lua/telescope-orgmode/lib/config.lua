local M = {}

---@class OrgmodePickerConfig
---@field max_depth number|nil
---@field archived boolean
---@field only_current_file boolean
---@field show_location boolean
---@field show_tags boolean
---@field show_todo_state boolean
---@field show_priority boolean
---@field location_max_width number
---@field tags_max_width number

-- Business logic defaults
M.defaults = {
  max_depth = nil,
  archived = false,
  only_current_file = false,
  show_location = true,
  show_tags = true,
  show_todo_state = true,
  show_priority = true,
  location_max_width = 15,
  tags_max_width = 15,
}

-- Picker-specific defaults
M.picker_defaults = {
  search_headings = {
    mode = 'headlines',
    prompt_titles = {
      headlines = 'Search Headlines',
      orgfiles = 'Search Org Files',
    },
  },
  insert_link = {
    mode = 'headlines',
    prompt_titles = {
      headlines = 'Insert Link to Headline',
      orgfiles = 'Insert Link to File',
    },
  },
  refile_heading = {
    mode = 'headlines',
    prompt_titles = {
      headlines = 'Refile to Headline',
      orgfiles = 'Refile to File',
    },
  },
}

---Create config for specific picker
---@param picker_type string
---@param opts table|nil
---@return OrgmodePickerConfig
function M:new(picker_type, opts)
  return vim.tbl_extend('force', self.defaults, self.picker_defaults[picker_type] or {}, opts or {})
end

---Setup global defaults
---@param ext_opts table
function M.setup(ext_opts)
  M.defaults = vim.tbl_extend('force', M.defaults, ext_opts or {})
end

---Merge user options with defaults
---@param opts table|nil User-provided options
---@return OrgmodePickerConfig
function M.merge(opts)
  return vim.tbl_deep_extend('force', M.defaults, opts or {})
end

---Validate configuration
---@param config OrgmodePickerConfig
---@return boolean valid
---@return string|nil error_message
function M.validate(config)
  if config.max_depth and (type(config.max_depth) ~= 'number' or config.max_depth < 1) then
    return false, 'max_depth must be a positive number'
  end

  if config.location_max_width and (type(config.location_max_width) ~= 'number' or config.location_max_width < 1) then
    return false, 'location_max_width must be a positive number'
  end

  if config.tags_max_width and (type(config.tags_max_width) ~= 'number' or config.tags_max_width < 1) then
    return false, 'tags_max_width must be a positive number'
  end

  return true, nil
end

---Get current buffer filename for filtering
---@return string
function M.get_original_file()
  local bufnr = vim.api.nvim_get_current_buf()
  local filename = vim.api.nvim_buf_get_name(bufnr)
  if filename == '' then
    filename = vim.fn.expand('%:p')
  end
  return filename
end

return M
