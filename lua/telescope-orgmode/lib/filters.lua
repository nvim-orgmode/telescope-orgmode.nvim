---@module 'telescope-orgmode.lib.filters'
---File filtering utilities for telescope-orgmode

local M = {}

--- Get list of org files currently loaded as Vim buffers
---@return string[] List of absolute paths to org files
function M.get_open_buffers()
  local buffers = vim.api.nvim_list_bufs()
  local org_files = {}

  for _, buf in ipairs(buffers) do
    if vim.api.nvim_buf_is_loaded(buf) then
      local name = vim.api.nvim_buf_get_name(buf)
      if name ~= '' and name:match('%.org$') then
        table.insert(org_files, name)
      end
    end
  end

  return org_files
end

--- Filter headlines to specified file list
---@param headlines table[] List of headline entries
---@param file_list string[]|nil List of filenames to filter to (empty table = no filter)
---@return table[] Filtered headlines
function M.apply_file_filter(headlines, file_list)
  -- nil or empty table = no filter
  if not file_list or #file_list == 0 then
    return headlines
  end

  -- Build set for O(1) lookup
  local file_set = {}
  for _, filename in ipairs(file_list) do
    file_set[filename] = true
  end

  -- Filter headlines
  local filtered = {}
  for _, headline in ipairs(headlines) do
    if file_set[headline.filename] then
      table.insert(filtered, headline)
    end
  end

  return filtered
end

--- Filter file list to specified file list
---@param files table[] List of file entries
---@param file_list string[]|nil List of filenames to filter to (empty table = no filter)
---@return table[] Filtered files
function M.apply_file_list_filter(files, file_list)
  -- nil or empty table = no filter
  if not file_list or #file_list == 0 then
    return files
  end

  -- Build set for O(1) lookup
  local file_set = {}
  for _, filename in ipairs(file_list) do
    file_set[filename] = true
  end

  -- Filter files
  local filtered = {}
  for _, file in ipairs(files) do
    if file_set[file.filename] then
      table.insert(filtered, file)
    end
  end

  return filtered
end

return M
