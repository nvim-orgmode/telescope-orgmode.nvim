---@class TagInfo
---@field tag string Tag name
---@field count number Number of occurrences
---@field files string[] Files containing this tag

local M = {}

--- Collect all tags with occurrence counts through the resolved source.
--- opts is passed along so opts.source / opts.archived take effect.
--- lib.sources and lib.config are required lazily to avoid a circular
--- module load (config requires sources).
---@param opts? table { source?: string, archived?: boolean, ... }
---@return TagInfo[]
function M.collect_tags_with_counts(opts)
  opts = opts or {}
  local sources = require('telescope-orgmode.lib.sources')
  local cfg = require('telescope-orgmode.lib.config')
  local source = sources.resolve_source(opts, {
    sources = cfg.defaults.sources,
    default_source = cfg.defaults.default_source,
    picker_defaults = cfg.picker_defaults,
    source_setup = cfg.defaults.source_setup,
  })
  local tags = source.enumerate_tags(opts)
  for _, entry in ipairs(tags) do
    sources.normalize_tag(entry)
  end
  return tags
end

--- Sort tags by frequency or alphabetically
---@param tags TagInfo[]
---@param sort_by 'frequency' | 'alphabetical'
---@return TagInfo[]
function M.sort_tags(tags, sort_by)
  if sort_by == 'frequency' then
    table.sort(tags, function(a, b)
      if a.count == b.count then
        return a.tag < b.tag -- Alphabetical tiebreaker
      end
      return a.count > b.count -- Descending frequency
    end)
  else -- alphabetical
    table.sort(tags, function(a, b)
      return a.tag < b.tag
    end)
  end
  return tags
end

--- Benchmark a function execution
---@param name string Operation name
---@param fn function Function to benchmark
---@return any result Result from function
function M.benchmark(name, fn)
  local start = vim.loop.hrtime()
  local result = fn()
  local duration = (vim.loop.hrtime() - start) / 1e6 -- Convert to ms
  vim.notify(string.format('%s: %.2fms', name, duration), vim.log.levels.DEBUG)
  return result
end

return M
