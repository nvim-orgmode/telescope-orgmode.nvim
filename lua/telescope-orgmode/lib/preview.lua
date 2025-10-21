local M = {}

---Get preview configuration for entry
---Determines what file to preview and where to position the cursor
---@param entry table Picker entry (can be from Telescope or Snacks)
---@return table preview {file, line, col}
function M.get_preview_config(entry)
  -- Handle different entry structures from different adapters
  -- Telescope: entry.value = { filename, headline? }
  -- Snacks: entry.__entry = { filename, headline? }
  local data = entry.value or entry.__entry or entry

  local headline_data = data.headline

  if headline_data then
    -- Headline preview - jump to headline line
    return {
      file = data.filename,
      line = headline_data.line_number or headline_data.lnum or 1,
      col = 0,
    }
  else
    -- Org file preview - show from beginning
    return {
      file = data.filename,
      line = 1,
      col = 0,
    }
  end
end

return M
