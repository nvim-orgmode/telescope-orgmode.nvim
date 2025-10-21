local org = require('telescope-orgmode.org')
local operations = require('telescope-orgmode.lib.operations')
local entry_normalize = require('telescope-orgmode.lib.entry_normalize')

local M = {}

---Convert picker entry to destination (handles multiple entry formats)
---@param entry table Entry from any picker framework
---@return table|nil destination OrgApiHeadline or OrgApiFile
function M.entry_to_destination(entry)
  -- Normalize entry to standard format
  local normalized = entry_normalize.normalize_entry(entry)
  local filename = normalized.filename
  local headline_data = normalized.headline

  if headline_data then
    -- Headline destination
    return org.get_api_headline(filename, headline_data.line_number or headline_data.lnum)
  else
    -- File destination
    return org.get_api_file(filename)
  end
end

---Execute refile workflow (framework-agnostic)
---@param source_headline table OrgApiHeadline to refile
---@param destination_entry table Picker entry (any format)
---@return boolean success Whether refile succeeded
---@return string message Success/error message
function M.execute_refile(source_headline, destination_entry)
  -- Normalize entry to get destination
  local destination = M.entry_to_destination(destination_entry)
  if not destination then
    return false, 'Could not find destination'
  end

  -- Perform refile with TOCTOU protection
  local success = operations.refile(source_headline, destination)

  if success then
    return true, 'Refiled successfully'
  else
    return false, 'Refile failed - source may have been deleted'
  end
end

---Execute insert link workflow
---@param link_entry table Picker entry to link to
---@return boolean success
---@return string message
function M.execute_insert_link(link_entry)
  local link_target = M.entry_to_destination(link_entry)
  if not link_target then
    return false, 'Could not find link target'
  end

  local success = operations.insert_link(link_target)
  return success, success and 'Link inserted successfully' or 'Failed to insert link'
end

---Execute navigate workflow
---@param entry table Picker entry
---@return boolean success
function M.execute_navigate(entry)
  local destination = M.entry_to_destination(entry)
  if not destination then
    return false
  end

  operations.navigate_to(destination)
  return true
end

return M
