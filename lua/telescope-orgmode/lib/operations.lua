local org = require('telescope-orgmode.org')

local M = {}

---Refile source headline to destination
---@param source_headline table OrgApiHeadline
---@param destination table OrgApiHeadline or OrgApiFile
---@return boolean|nil success (nil on error)
function M.refile(source_headline, destination)
  -- Trust source_headline from caller (validated at picker creation)
  -- Orgmode's refile API validates structure and returns errors
  local success, promise = pcall(org.refile, {
    source = source_headline,
    destination = destination,
  })

  if not success then
    return nil
  end

  local wait_success, result = pcall(function()
    return promise:wait()
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

---Navigate to entry
---@param entry table { filename: string, lnum: number }
---@return boolean success
function M.navigate_to(entry)
  vim.cmd('edit ' .. vim.fn.fnameescape(entry.filename))
  if entry.lnum then
    vim.api.nvim_win_set_cursor(0, { entry.lnum, 0 })
  end
  return true
end

---Get headline at cursor position
---@return table|nil headline
function M.get_current_headline()
  return org.get_closest_headline()
end

return M
