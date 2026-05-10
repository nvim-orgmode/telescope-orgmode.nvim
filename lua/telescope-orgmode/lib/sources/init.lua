-- Source-Registry und Normalisierungs-Wrapper.
--
-- Aufgaben:
--   * resolve_source(opts, config): Pre-Built ∪ Factory auflösen, mit
--     Setup-Time-Cache. Reihenfolge: opts.source → picker_defaults →
--     default_source. Wirft auf unbekannten Namen.
--   * normalize_*(entry): füllt fehlende Schema-Felder in-place auf
--     (siehe Design §Entry-Schemata).
--   * validate_setup(config): referenzielle Integrität für default_source
--     und picker_defaults[*].source.
--   * invalidate_cache(): leert Modul-State (Lazy.nvim-Reload-Safety).
--
-- Modul-State: _resolved_cache hält Factory-Resultate; gemeinsamer Reset
-- via invalidate_cache(). Tests rufen invalidate_cache() in before_each.

local M = {}

-- Modul-internes Setup-Time-Cache für Factory-Sources.
local _resolved_cache = {}

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
  if _resolved_cache[name] then
    return _resolved_cache[name]
  end

  local entry = config.sources and config.sources[name]
  if entry == nil then
    error('Unknown source: ' .. tostring(name))
  end

  local source
  if type(entry) == 'function' then
    source = entry(config.source_setup and config.source_setup[name] or {})
  else
    source = entry
  end

  _resolved_cache[name] = source
  return source
end

---Auswahl-Reihenfolge: opts.source → picker_defaults[picker_type].source
---→ default_source. Wirft auf unbekannten Namen.
---@param opts table|nil { source?: string, picker_type?: string }
---@param config table { sources, default_source, picker_defaults }
---@return OrgmodeSource
function M.resolve_source(opts, config)
  opts = opts or {}

  local name = opts.source
  if name == nil and opts.picker_type then
    local picker_default = config.picker_defaults and config.picker_defaults[opts.picker_type]
    if picker_default then
      name = picker_default.source
    end
  end
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

---Leert den Factory-Cache. Wird vor jedem Setup-Re-Run aufgerufen,
---damit Lazy.nvim-Reloads sauber funktionieren.
function M.invalidate_cache()
  _resolved_cache = {}
end

return M
