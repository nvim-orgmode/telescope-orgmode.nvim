--- E2E Test Helpers for Adapter Integration Tests
--- Based on orgmode test patterns and telescope-orgmode requirements

local M = {}

--- Simulate keystrokes in the current buffer
--- @param keys string The keys to simulate (supports special keys like <CR>, <C-Space>)
function M.feed(keys)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, true, true), 'x', true)
end

--- Wait for a condition to be true with timeout
--- @param timeout number Timeout in milliseconds
--- @param condition function Function that returns true when condition is met
--- @param interval? number Check interval in milliseconds (default: 50)
--- @return boolean success Whether the condition was met before timeout
function M.wait_for(timeout, condition, interval)
  return vim.wait(timeout or 1000, condition, interval or 50)
end

--- Get the buffer number of the first picker window
--- @return number|nil Buffer number of picker, or nil if not found
function M.get_picker_buffer()
  -- Look for floating windows (telescope/snacks pickers are floating)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local config = vim.api.nvim_win_get_config(win)
    if config.relative ~= '' then -- It's a floating window
      local buf = vim.api.nvim_win_get_buf(win)
      -- Check if it looks like a picker buffer
      local buftype = vim.api.nvim_buf_get_option(buf, 'buftype')
      if buftype == 'nofile' or buftype == 'prompt' then
        return buf
      end
    end
  end
  return nil
end

--- Wait for a picker to open
--- @param timeout? number Timeout in milliseconds (default: 1000)
--- @return boolean success Whether picker opened before timeout
function M.wait_for_picker(timeout)
  return M.wait_for(timeout or 1000, function()
    return M.get_picker_buffer() ~= nil
  end)
end

--- Get the visible lines from the picker buffer
--- @return string[] Lines visible in the picker
function M.get_picker_items()
  local buf = M.get_picker_buffer()
  if not buf then
    return {}
  end
  return vim.api.nvim_buf_get_lines(buf, 0, -1, false)
end

--- Check if picker contains a specific pattern in any line
--- @param pattern string Pattern to search for
--- @return boolean found Whether the pattern was found
function M.picker_contains(pattern)
  local items = M.get_picker_items()
  for _, line in ipairs(items) do
    if line:match(pattern) then
      return true
    end
  end
  return false
end

--- Close all floating windows (pickers)
function M.close_all_pickers()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    -- Check if window is still valid
    if vim.api.nvim_win_is_valid(win) then
      local ok, config = pcall(vim.api.nvim_win_get_config, win)
      if ok and config.relative ~= '' then
        pcall(vim.api.nvim_win_close, win, true)
      end
    end
  end
end

--- Close all buffers (cleanup)
function M.close_all_buffers()
  vim.cmd([[silent! %bw!]])
end

--- Create a temporary org file with given content
--- @param lines string[] Lines to write to the file
--- @return string filename The path to the created file
function M.create_temp_org_file(lines)
  local fname = vim.fn.tempname() .. '.org'
  vim.fn.writefile(lines or {}, fname)
  return fname
end

--- Wait for picker to be ready (has items)
--- @param timeout? number Timeout in milliseconds (default: 1000)
--- @return boolean success Whether picker is ready before timeout
function M.wait_for_picker_ready(timeout)
  return M.wait_for(timeout or 1000, function()
    local buf = M.get_picker_buffer()
    if not buf then
      return false
    end
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    return #lines > 0 -- Has items
  end)
end

--- Get the current mode of the picker (detect from content)
--- This is a heuristic based on expected content patterns
--- @return string mode Either 'headlines' or 'orgfiles'
function M.get_picker_mode()
  local items = M.get_picker_items()
  if #items == 0 then
    return 'unknown'
  end

  -- Check if items look like org files (.org extension pattern)
  -- Orgfiles mode shows files with .org extension
  for _, line in ipairs(items) do
    if line:match('%.org') and not line:match('%[') then
      -- Has .org but no headline indicators like [level]
      return 'orgfiles'
    end
  end

  return 'headlines'
end

--- Assert that picker is in expected mode
--- @param expected_mode string Expected mode ('headlines' or 'orgfiles')
function M.assert_picker_mode(expected_mode)
  local actual_mode = M.get_picker_mode()
  assert.equals(
    expected_mode,
    actual_mode,
    string.format("Expected picker mode '%s' but got '%s'", expected_mode, actual_mode)
  )
end

return M
