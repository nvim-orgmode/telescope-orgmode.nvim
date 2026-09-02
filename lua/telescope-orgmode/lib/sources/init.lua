-- Source registry. Looks up sources (pre-built or factory) and
-- exposes schema-normalization helpers for callers.

local M = {}

-- Factory sources are instantiated once per registry. The cache is keyed
-- on the registry table, not on the source name: two configs registering
-- the same name get their own instance, and a registry that goes out of
-- scope takes its instances with it.
local _resolved_cache = setmetatable({}, { __mode = 'k' })

-- Tracks per-source fallback warnings (one notify per source name) for
-- sources that don't implement `enumerate_headlines_by_query`.
local _notified_fallbacks = {}

---@class OrgmodeSource
---@field name string
---@field enumerate_files fun(opts: table): table[]
---@field enumerate_headlines fun(opts: table): table[]
---@field enumerate_headlines_by_query? fun(query: string, opts: table): table[]
---@field enumerate_tags fun(opts: table): table[]

---Resolve a source name from the registry, instantiating factories on
---first access and caching the result.
---@param name string
---@param config table { sources = {...} }
---@return OrgmodeSource
local function resolve_registry_entry(name, config)
  local registry = config.sources or {}
  local cached = _resolved_cache[registry]
  if cached and cached[name] then
    return cached[name]
  end

  local entry = registry[name]
  if entry == nil then
    error('Unknown source: ' .. tostring(name))
  end

  local source
  if type(entry) == 'function' then
    source = entry(config.source_setup and config.source_setup[name] or {})
  else
    source = entry
  end

  if not cached then
    cached = {}
    _resolved_cache[registry] = cached
  end
  cached[name] = source
  return source
end

---Resolves a source name from opts.source, falling back to
---config.default_source. Picker-level overrides
---(config.picker_defaults[*].source) are merged into opts upstream in
---`config:new()`, so they reach this function via opts.source.
---@param opts table|nil { source?: string }
---@param config table { sources, default_source }
---@return OrgmodeSource
function M.resolve_source(opts, config)
  opts = opts or {}

  local name = opts.source
  if name == nil then
    name = config.default_source
  end

  return resolve_registry_entry(name, config)
end

---Headline schema defaults.
---@param entry table
---@return table entry (in-place)
function M.normalize_headline(entry)
  if entry.all_tags == nil then
    entry.all_tags = {}
  end
  if entry.is_archived == nil then
    entry.is_archived = false
  end
  if entry.todo_type == nil then
    entry.todo_type = ''
  end
  if entry.properties == nil then
    entry.properties = {}
  end
  -- todo_value and priority stay optional, so nil is left as is.
  return entry
end

---File schema defaults. title is derived from filename.
---@param entry table
---@return table entry (in-place)
function M.normalize_file(entry)
  if entry.title == nil then
    entry.title = vim.fn.fnamemodify(entry.filename, ':t:r')
  end
  return entry
end

---Tag schema defaults.
---@param entry table
---@return table entry (in-place)
function M.normalize_tag(entry)
  if entry.count == nil then
    entry.count = 1
  end
  if entry.files == nil then
    entry.files = {}
  end
  return entry
end

---Setup-time validation: checks that every referenced source name
---exists in config.sources. Returns (true, nil) on success and
---(false, err_msg) on failure.
---@param config table
---@return boolean ok
---@return string|nil err
function M.validate_setup(config)
  local sources = config.sources or {}

  local default_name = config.default_source
  if default_name ~= nil and sources[default_name] == nil then
    return false, string.format("Unknown source '%s' referenced by default_source", default_name)
  end

  local picker_defaults = config.picker_defaults or {}
  for picker_type, picker_cfg in pairs(picker_defaults) do
    local source_name = picker_cfg and picker_cfg.source
    if source_name ~= nil and sources[source_name] == nil then
      return false,
        string.format("Unknown source '%s' referenced by picker_defaults.%s.source", source_name, picker_type)
    end
  end

  return true, nil
end

---Notify once per source name that org.load_headlines_by_search took
---the fallback path, because the source does not implement
---enumerate_headlines_by_query. Keeps every picker open from
---repeating the warning.
---@param source OrgmodeSource
function M.notify_fallback(source)
  local key = source and source.name or tostring(source)
  if _notified_fallbacks[key] then
    return
  end
  _notified_fallbacks[key] = true
  vim.notify(
    string.format("source '%s' does not support query semantics, falling back to enumerate_headlines", key),
    vim.log.levels.WARN
  )
end

---Clears the source and fallback-notify caches. Required to make factory
---sources re-instantiate after a setup re-run (e.g. Lazy.nvim reload).
function M.invalidate_cache()
  _resolved_cache = setmetatable({}, { __mode = 'k' })
  _notified_fallbacks = {}
end

return M
