local entry_normalize = require('telescope-orgmode.lib.entry_normalize')

local M = {}

---Get preview configuration for entry
---Determines what file to preview and where to position the cursor
---@param entry table Picker entry (can be from any framework)
---@return table preview {file, line, col}
function M.get_preview_config(entry)
  -- Normalize entry to standard format
  local normalized = entry_normalize.normalize_entry(entry)
  local headline_data = normalized.headline

  if headline_data then
    -- Headline preview - jump to headline line
    return {
      file = normalized.filename,
      line = headline_data.line_number or headline_data.lnum or 1,
      col = 0,
    }
  else
    -- Org file preview - show from beginning
    return {
      file = normalized.filename,
      line = 1,
      col = 0,
    }
  end
end

return M
