local config = require('telescope-orgmode.lib.config')
local tags_lib = require('telescope-orgmode.lib.tags')

local pick = require('mini.pick')
local mini_headings = require('telescope-orgmode.mini.headings')

local M = {}

local function show(buf_id, items_arr, query)
  local lines = {}
  for _, item in ipairs(items_arr) do
    local line = item.tag .. " (" .. item.count .. ")"
    table.insert(lines, line)
  end

  pick.default_show(buf_id, lines, query)
end

local function custom_choose(item)
  mini_headings.start_picker({
    tag_query = '+' .. item.tag,
    default_text = '',
    context = {
      selected_tag = item.tag
    }
  })

  return false
end

local function preview(buf_id, item)
  local lines = tags_lib.get_tag_preview_lines(item.tag, { max_count = 50 })
  vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
end

local function copy_to_text_property(items, original_property_name)
  for _, item in ipairs(items) do
    item.text = item[original_property_name]
  end
  return items
end

function M.search_tags(org_opts)
  local opts = config:new('search_tags', org_opts)

  opts.original_buffer = vim.api.nvim_get_current_buf()
  opts.original_file = vim.api.nvim_buf_get_name(opts.original_buffer)
  opts.current_file = opts.original_file

  local tags, sort_mode = tags_lib.load_and_sort_tags(opts)

  if #tags == 0 then
    vim.notify('No tags found in org files', vim.log.levels.INFO)
    return
  end

  local items = copy_to_text_property(tags, "tag")

  local pick_opts = vim.tbl_deep_extend("keep", org_opts or {}, {
    window = { prompt_prefix = " Tag: " },
    source = {
      name = "Choose Tag",
      items = items,
      show = show,
      choose = custom_choose,
      preview = preview
    }
  })

  return pick.start(pick_opts)
end

return M
