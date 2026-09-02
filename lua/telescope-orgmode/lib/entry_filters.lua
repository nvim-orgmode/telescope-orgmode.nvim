-- Policy layer for source output. Sources enumerate what exists; this
-- module decides what the user sees.
--
-- Each loader in `org.lua` composes its own chain: the policies are NOT
-- uniform across loaders, and unifying them silently changes results.
-- `load_files` ignores `only_current_file`, the tag preview applies no
-- policy at all. See memories/glossary.org for the Source/Policy split.
--
-- Framework-agnostic: operates on projected entry tables carrying
-- `filename`, and where relevant `level` and `is_archived`.

local M = {}

---Resolves the file the picker was opened from.
---@param opts table
---@return string
local function current_filename(opts)
  local filename = opts.original_file or vim.api.nvim_buf_get_name(0)
  if filename == '' then
    filename = vim.fn.expand('%:p')
  end
  return filename
end

---@param filename string
---@return boolean
local function is_archive_file(filename)
  return vim.fn.fnamemodify(filename, ':e') == 'org_archive'
end

---Keeps only entries from the file the picker was opened from.
---@param entries table[]
---@param opts table
---@return table[]
function M.only_current_file(entries, opts)
  if not opts.only_current_file then
    return entries
  end
  local filename = current_filename(opts)
  return vim.tbl_filter(function(entry)
    return entry.filename == filename
  end, entries)
end

---Drops entries living in `.org_archive` files, unless `opts.archived`.
---@param entries table[]
---@param opts table
---@return table[]
function M.exclude_archive_files(entries, opts)
  if opts.archived then
    return entries
  end
  return vim.tbl_filter(function(entry)
    return not is_archive_file(entry.filename)
  end, entries)
end

---Drops headlines inside archived subtrees, unless `opts.archived`.
---@param entries table[] headline entries carrying `is_archived`
---@param opts table
---@return table[]
function M.exclude_archived_subtrees(entries, opts)
  if opts.archived then
    return entries
  end
  return vim.tbl_filter(function(entry)
    return not entry.is_archived
  end, entries)
end

---Caps headline depth.
---@param entries table[] headline entries carrying `level`
---@param opts table
---@return table[]
function M.max_depth(entries, opts)
  if not opts.max_depth then
    return entries
  end
  return vim.tbl_filter(function(entry)
    return entry.level <= opts.max_depth
  end, entries)
end

---Orders entries by file mtime, newest first.
---
---Stable: entries from the same file keep their incoming order, so
---within-file document order survives. `table.sort` is not stable on its
---own, hence the index tiebreak.
---@param entries table[]
---@return table[]
function M.sort_by_file_mtime(entries)
  local mtimes = {}
  local function mtime_of(filename)
    local cached = mtimes[filename]
    if cached == nil then
      local stat = vim.uv.fs_stat(filename)
      cached = stat and stat.mtime.sec or 0
      mtimes[filename] = cached
    end
    return cached
  end

  local indexed = {}
  for index, entry in ipairs(entries) do
    table.insert(indexed, { entry = entry, index = index })
  end

  table.sort(indexed, function(a, b)
    local mtime_a = mtime_of(a.entry.filename)
    local mtime_b = mtime_of(b.entry.filename)
    if mtime_a ~= mtime_b then
      return mtime_a > mtime_b
    end
    return a.index < b.index
  end)

  return vim.tbl_map(function(item)
    return item.entry
  end, indexed)
end

return M
