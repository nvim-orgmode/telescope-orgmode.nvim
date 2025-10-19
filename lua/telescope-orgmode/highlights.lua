local M = {}

---Get highlight group for TODO keyword
---@param todo_value string|nil The TODO keyword (e.g., "TODO", "DONE", "WAITING")
---@param todo_type 'TODO'|'DONE'|'' The TODO type
---@return string|nil Highlight group name
function M.get_todo_highlight(todo_value, todo_type)
  if not todo_value then
    return nil
  end

  -- Get orgmode's highlight mapping (includes custom keywords)
  local ok, highlights = pcall(require, 'orgmode.colors.highlights')
  if not ok then
    -- Orgmode not loaded - use basic defaults
    return todo_type == 'DONE' and '@org.keyword.done' or '@org.keyword.todo'
  end

  local hl_map = highlights.get_agenda_hl_map()

  -- Return custom highlight if defined, otherwise default based on type
  return hl_map[todo_value] or (todo_type == 'DONE' and '@org.keyword.done') or '@org.keyword.todo'
end

---Get highlight group for priority
---@param priority string|nil The priority letter (e.g., "A", "B", "C")
---@return string|nil Highlight group name
function M.get_priority_highlight(priority)
  if not priority then
    return nil
  end

  -- For v1: Only highest priority has dedicated highlight
  -- orgmode defines @org.priority.highest but not per-priority highlights
  if priority == 'A' then
    return '@org.priority.highest'
  end

  -- Other priorities use default text color
  return nil
end

return M
