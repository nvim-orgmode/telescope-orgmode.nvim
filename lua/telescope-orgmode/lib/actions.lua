local org = require('telescope-orgmode.org')
local operations = require('telescope-orgmode.lib.operations')
local entry_normalize = require('telescope-orgmode.lib.entry_normalize')

local M = {}

---Convert picker entry to destination (handles multiple entry formats)
---@param entry table Entry from any picker framework
---@return table|nil destination OrgApiHeadline or OrgApiFile
function M.entry_to_destination(entry)
  -- Use entry_normalize.get_filename() which handles both .filename and .file fields
  local filename = entry_normalize.get_filename(entry)
  local headline_data = entry_normalize.get_headline(entry)

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

---Execute insert link workflow (async)
---@param link_entry table Picker entry to link to
---@return table|nil promise OrgPromise, or nil if entry invalid
function M.execute_insert_link(link_entry)
  local link_target = M.entry_to_destination(link_entry)
  if not link_target then
    return nil
  end

  return operations.insert_link(link_target)
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
