local M = {}

-- Default source is registered eagerly so M.defaults.sources works
-- without calling setup().
local sources = require('telescope-orgmode.lib.sources')
local default_source = require('telescope-orgmode.lib.sources.default')

---@class OrgmodePropertyConfig
---@field name string Property name as in drawer (case-sensitive)
---@field max_width number|nil Maximum column width (default 15)
---@field highlight string|nil Neovim highlight group (default 'Comment')

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
---@field show_properties OrgmodePropertyConfig[]
---@field ordinal_fields string[]|nil
---@field snacks table|nil Snacks-only picker options. Adapter-owned fields are ignored.

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
  -- Location column format preference (ordered priority)
  -- First available value in list will be displayed
  location_preference = { 'category', 'filename' },
  show_properties = {},
  -- Source registry: name -> source table, or factory(source_setup) ->
  -- source. The default source is always registered; user-defined
  -- sources are merged in by setup().
  sources = { default = default_source },
  default_source = 'default',
  -- Per-source setup tables (e.g. roam_db.path), passed to factories.
  source_setup = {},
}

-- Picker-specific defaults
-- source = nil → falls back to default_source.
M.picker_defaults = {
  search_headings = {
    source = nil,
    mode = 'headlines',
    prompt_titles = {
      headlines = 'Search Headlines',
      orgfiles = 'Search Org Files',
    },
  },
  insert_link = {
    source = nil,
    mode = 'headlines',
    prompt_titles = {
      headlines = 'Insert Link to Headline',
      orgfiles = 'Insert Link to File',
    },
  },
  refile_heading = {
    source = nil,
    mode = 'headlines',
    prompt_titles = {
      headlines = 'Refile to Headline',
      orgfiles = 'Refile to File',
    },
  },
  search_tags = {
    source = nil,
    initial_sort = 'frequency',
    prompt_title = 'Org Tags',
  },
}

---Create config for specific picker
---@param picker_type string
---@param opts table|nil
---@return OrgmodePickerConfig
function M:new(picker_type, opts)
  return vim.tbl_extend('force', self.defaults, self.picker_defaults[picker_type] or {}, opts or {})
end

---Merges user options into defaults. sources is shallow-merged,
---picker_defaults is deep-merged, defaults uses force-merge. Throws on
---unknown source references.
---@param ext_opts table
function M.setup(ext_opts)
  ext_opts = ext_opts or {}
  sources.invalidate_cache()

  -- sources and picker_defaults are merged separately so the final
  -- tbl_extend cannot overwrite them: sources wants a merge rather than
  -- a replace, and picker_defaults does not live in M.defaults.
  local rest = vim.tbl_extend('force', {}, ext_opts)
  rest.sources = nil
  rest.picker_defaults = nil

  if ext_opts.sources then
    M.defaults.sources = vim.tbl_extend('force', M.defaults.sources, ext_opts.sources)
  end

  if ext_opts.picker_defaults then
    M.picker_defaults = vim.tbl_deep_extend('force', M.picker_defaults, ext_opts.picker_defaults)
  end

  M.defaults = vim.tbl_extend('force', M.defaults, rest)

  local ok, err = sources.validate_setup({
    sources = M.defaults.sources,
    default_source = M.defaults.default_source,
    picker_defaults = M.picker_defaults,
  })
  if not ok then
    error(err)
  end
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

  if config.location_preference then
    if type(config.location_preference) ~= 'table' then
      return false, 'location_preference must be a table'
    end

    for _, key in ipairs(config.location_preference) do
      if key ~= 'category' and key ~= 'filename' and key ~= 'title' then
        return false, 'location_preference values must be: category, filename, or title'
      end
    end
  end

  if config.show_properties then
    if type(config.show_properties) ~= 'table' then
      return false, 'show_properties must be a table'
    end

    for i, prop in ipairs(config.show_properties) do
      if type(prop) ~= 'table' then
        return false, string.format('show_properties[%d] must be a table', i)
      end

      if not prop.name or type(prop.name) ~= 'string' or prop.name == '' then
        return false, string.format('show_properties[%d].name must be a non-empty string', i)
      end

      if prop.max_width ~= nil and (type(prop.max_width) ~= 'number' or prop.max_width < 1) then
        return false, string.format('show_properties[%d].max_width must be a positive number', i)
      end

      if prop.highlight ~= nil and type(prop.highlight) ~= 'string' then
        return false, string.format('show_properties[%d].highlight must be a string', i)
      end
    end
  end

  if config.ordinal_fields ~= nil then
    if type(config.ordinal_fields) ~= 'table' then
      return false, 'ordinal_fields must be a table'
    end

    local valid_fields =
      { headline = true, state = true, priority = true, location = true, tags = true, properties = true }
    for i, field in ipairs(config.ordinal_fields) do
      if type(field) ~= 'string' or not valid_fields[field] then
        return false,
          string.format('ordinal_fields[%d] must be one of: headline, state, priority, location, tags, properties', i)
      end
    end
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
