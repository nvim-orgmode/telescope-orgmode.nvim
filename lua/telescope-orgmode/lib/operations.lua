local org = require('telescope-orgmode.org')

local M = {}

---Refile source headline to destination
---Uses internal API (._section) for file context switching, following orgmode agenda pattern
---This is necessary because OrgApiHeadline.file (public wrapper) lacks update() method
---@param source_headline table OrgApiHeadline
---@param destination table OrgApiHeadline or OrgApiFile
---@return boolean|nil success (nil on error)
function M.refile(source_headline, destination)
  if not source_headline or not source_headline._section or not source_headline._section.file then
    return nil
  end

  -- Extract internal headline object (OrgHeadline, not OrgApiHeadline wrapper)
  -- RATIONALE: Using internal API because public API doesn't support file context switching
  -- TODO: Propose upstream API extension (see claudedocs/bugs/orgmode-api-gap-file-context-switching.md)
  local internal_headline = source_headline._section

  -- Use internal object's file:update() method for context switching
  local update = internal_headline.file:update(function()
    -- Internal headline's :get_range() works correctly in callback context
    vim.fn.cursor({ internal_headline:get_range().start_line, 1 })
    return org.refile({
      source = source_headline, -- orgmode.refile() expects API wrapper
      destination = destination,
    })
  end)

  local wait_success, result = pcall(function()
    return update:wait()
  end)

  return wait_success and result or nil
end

---Insert link to selected entry
---@param entry table { filename: string, value: { headline?: table } }
---@param opts table { original_file?: string }
---@return boolean|nil success
function M.insert_link(entry, opts)
  local destination
  if entry.value and entry.value.headline then
    -- Link to headline
    local success, api_headline = pcall(org.get_api_headline, entry.filename, entry.value.headline.line_number)
    if not success or not api_headline then
      return nil
    end
    destination = api_headline
  else
    -- Link to file
    local success, api_file = pcall(org.get_api_file, entry.filename)
    if not success or not api_file then
      return nil
    end
    destination = api_file
  end

  local promise = org.insert_link(destination)
  local success, result = pcall(function()
    return promise:wait()
  end)

  return success and result or nil
end

---Navigate to entry (handles both simple format and OrgApiHeadline/OrgApiFile)
---@param entry table { filename: string, lnum: number } | OrgApiHeadline | OrgApiFile
---@return boolean success
function M.navigate_to(entry)
  -- Extract filename and line number from different formats
  local filename, lnum

  if entry.file and entry.position then
    -- OrgApiHeadline format
    filename = entry.file.filename
    lnum = entry.position.start_line
  elseif entry.filename then
    -- Simple format or OrgApiFile
    filename = entry.filename
    lnum = entry.lnum or entry.position and entry.position.start_line
  else
    return false
  end

  vim.cmd('edit ' .. vim.fn.fnameescape(filename))
  if lnum then
    vim.api.nvim_win_set_cursor(0, { lnum, 0 })
  end
  return true
end

---Get headline at cursor position
---@return table|nil headline
function M.get_current_headline()
  return org.get_closest_headline()
end

return M
