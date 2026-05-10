-- Snapshot projection helpers for source/loader output. Projects
-- orgmode-API tables onto a deterministic subset (drops Treesitter refs /
-- closures) and fills defaults for optional fields.
--
-- No sorting here: ordering is the pipeline's job (mtime sort and so
-- on). A helper that sorted as well would hide real drift.

local M = {}

---@param entry table
---@return { filename: string, line_number: integer, title: string, level: integer, todo_value: string|nil, todo_type: string, priority: string|nil, all_tags: string[], is_archived: boolean, properties: table<string, string> }
function M.project_headline(entry)
  return {
    filename = entry.filename,
    line_number = entry.line_number,
    title = entry.title,
    level = entry.level,
    todo_value = entry.todo_value,
    todo_type = entry.todo_type or '',
    priority = entry.priority,
    all_tags = entry.all_tags or {},
    is_archived = entry.is_archived == true,
    properties = entry.properties or {},
  }
end

---@param entry table
---@return { filename: string, title: string }
function M.project_file(entry)
  return {
    filename = entry.filename,
    title = entry.title or vim.fn.fnamemodify(entry.filename, ':t:r'),
  }
end

---@param entry table
---@return { tag: string, count: integer, files: string[] }
function M.project_tag(entry)
  return {
    tag = entry.tag,
    count = entry.count or 1,
    files = entry.files or {},
  }
end

---Apply a projector to each entry in a list, returning a new list.
---@generic T, U
---@param entries T[]
---@param projector fun(entry: T): U
---@return U[]
function M.project_list(entries, projector)
  local out = {}
  for i, entry in ipairs(entries) do
    out[i] = projector(entry)
  end
  return out
end

return M
