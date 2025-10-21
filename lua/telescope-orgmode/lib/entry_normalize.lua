---Entry normalization for different picker frameworks
---
---This module provides a consistent interface for accessing entry data
---regardless of which picker framework (Telescope, Snacks, fzf-lua) created it.
---
---Entry format contracts:
---  Telescope: { value = { filename, headline? } }
---  Snacks:    { __entry = { filename, headline? }, file, text, ... }
---  fzf-lua:   { data = { filename, headline? } } (TBD - may differ)
---  Direct:    { filename, headline? }
---
---Normalized format: { filename: string, headline?: table }

local M = {}

---Normalize Telescope entry to standard format
---Telescope wraps the actual entry data in a `value` field
---@param entry table Telescope entry with value wrapper
---@return table normalized { filename: string, headline?: table }
function M.normalize_telescope_entry(entry)
  -- Telescope entries have structure: { value = { filename, headline? }, ... }
  return entry.value or entry
end

---Normalize Snacks entry to standard format
---Snacks stores original data in `__entry` field
---@param entry table Snacks entry with __entry field
---@return table normalized { filename: string, headline?: table }
function M.normalize_snacks_entry(entry)
  -- Snacks entries have structure: { __entry = { filename, headline? }, file, text, ... }
  return entry.__entry or entry
end

---Normalize fzf-lua entry to standard format (future implementation)
---@param entry table fzf-lua entry
---@return table normalized { filename: string, headline?: table }
function M.normalize_fzf_entry(entry)
  -- fzf-lua format TBD - may use `data` field or direct structure
  -- For now, assume direct structure or data field
  return entry.data or entry
end

---Automatically detect and normalize entry from any framework
---Tries each normalization strategy until it finds valid data
---@param entry table Entry from any picker framework
---@return table normalized { filename: string, headline?: table }
function M.normalize_entry(entry)
  if not entry then
    return {}
  end
  -- Try known wrapper fields first
  if entry.value then
    return entry.value
  elseif entry.__entry then
    return entry.__entry
  elseif entry.data then
    return entry.data
  else
    -- Already in direct format
    return entry
  end
end

---Extract filename from normalized or raw entry
---@param entry table Entry in any format
---@return string|nil filename
function M.get_filename(entry)
  local normalized = M.normalize_entry(entry)
  return normalized.filename or normalized.file
end

---Extract headline data from normalized or raw entry
---@param entry table Entry in any format
---@return table|nil headline
function M.get_headline(entry)
  local normalized = M.normalize_entry(entry)
  return normalized.headline
end

---Check if entry represents a headline (vs org file)
---@param entry table Entry in any format
---@return boolean is_headline
function M.is_headline_entry(entry)
  return M.get_headline(entry) ~= nil
end

return M
