---Framework-agnostic tags operations
local org = require('telescope-orgmode.org')
local tag_collection = require('telescope-orgmode.tag_collection')

local M = {}

---Load and sort tags
---@param opts? { initial_sort?: 'frequency'|'alphabetical', archived?: boolean }
---@return table[] tags Array of { tag, count, files }
---@return string sort_mode Initial sort mode
function M.load_and_sort_tags(opts)
  opts = opts or {}
  local sort_mode = opts.initial_sort or 'frequency'

  local tags = org.load_tags(opts)
  tags = tag_collection.sort_tags(tags, sort_mode)

  return tags, sort_mode
end

---Toggle sort mode
---@param current_mode string Current sort mode
---@return string new_mode New sort mode
function M.toggle_sort_mode(current_mode)
  return (current_mode == 'frequency') and 'alphabetical' or 'frequency'
end

---Sort tags by mode
---@param tags table[] Array of tag info
---@param sort_mode 'frequency'|'alphabetical'
---@return table[] sorted_tags
function M.sort_tags(tags, sort_mode)
  return tag_collection.sort_tags(tags, sort_mode)
end

---Format tag for display
---@param tag_info table { tag, count, files }
---@return string display_text
function M.format_tag_display(tag_info)
  return string.format('%s (%d)', tag_info.tag, tag_info.count)
end

---Get preview lines for a tag
---@param tag string Tag name
---@param opts? { max_count?: number }
---@return string[] lines Preview lines
function M.get_tag_preview_lines(tag, opts)
  opts = opts or {}
  local headlines = org.get_headlines_for_tag(tag, opts)

  local lines = {}

  if #headlines == 0 then
    return { 'No headlines found with this tag' }
  end

  for _, hl in ipairs(headlines) do
    local file_short = vim.fn.fnamemodify(hl.filename, ':~:.')
    local line = string.format('%s %s %s', hl.todo, hl.priority, hl.title)
    table.insert(lines, line)
    table.insert(lines, '  → ' .. file_short)
    table.insert(lines, '')
  end

  if #headlines >= (opts.max_count or 50) then
    table.insert(lines, string.format('... (showing first %d headlines)', opts.max_count or 50))
  end

  return lines
end

return M
